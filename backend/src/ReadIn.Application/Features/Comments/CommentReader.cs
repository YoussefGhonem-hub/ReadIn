using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Comments;

/// <summary>
/// Builds <see cref="CommentDto"/>s for the current viewer (SPEC F11). The rules:
/// <list type="bullet">
/// <item>Readers see visible comments in full.</item>
/// <item>A hidden comment is shown in full to its author and to moderators.</item>
/// <item>A deleted or (for others) hidden top-level comment that still has replies is a placeholder; otherwise it is left
/// out. Replies are never placeholders.</item>
/// <item>A comment whose author deleted their account has a null <see cref="CommentDto.Author"/>.</item>
/// <item>A comment by a writer the viewer muted is flagged (<see cref="CommentDto.IsAuthorMuted"/>, F28): clients collapse it.</item>
/// <item>A comment of someone the viewer is blocked with, either way (F36), is left out; a top-level one with replies stays as a
/// placeholder (<see cref="CommentDto.IsUnavailable"/>), and mentions of them lose their link.</item>
/// </list>
/// </summary>
public sealed class CommentReader(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
{
    /// <summary>Replies shown under each top-level comment of a page; the rest load from /comments/{id}/replies.</summary>
    public const int ReplyPreviewCount = 2;

    private Guid? ViewerId => currentUser.UserId;
    private bool IsModerator => currentUser.Permissions.Contains(Permissions.Moderation.Manage);

    /// <summary>Every comment row, deleted ones included; callers filter with <see cref="ReadableBy"/>.</summary>
    public IQueryable<Comment> All() => db.Comments.IgnoreQueryFilters().AsNoTracking();

    /// <summary>What the viewer may read in full.</summary>
    public Expression<Func<Comment, bool>> ReadableBy()
    {
        var viewer = ViewerId;
        var moderator = IsModerator;
        if (viewer is not { } signedIn)
            return c => !c.IsDeleted && (c.HiddenAt == null || moderator);

        // F36: nothing of the people the viewer is blocked with, either way.
        var blocked = db.BlockedWith(signedIn);
        return c => !c.IsDeleted && (c.HiddenAt == null || moderator || c.AuthorId == signedIn)
            && !(c.AuthorId != null && blocked.Contains(c.AuthorId.Value));
    }

    /// <summary>Top-level comments the viewer gets in a list: readable ones, plus placeholders that keep their replies.</summary>
    public Expression<Func<Comment, bool>> ListedTopLevel()
    {
        var viewer = ViewerId;
        var moderator = IsModerator;
        if (viewer is not { } signedIn)
            return c => c.ParentId == null && ((!c.IsDeleted && (c.HiddenAt == null || moderator)) || c.ReplyCount > 0);

        // F36: a blocked person's top-level comment shows only as a placeholder that keeps its replies.
        var blocked = db.BlockedWith(signedIn);
        return c => c.ParentId == null &&
            ((!c.IsDeleted && (c.HiddenAt == null || moderator || c.AuthorId == signedIn) && !(c.AuthorId != null && blocked.Contains(c.AuthorId.Value)))
             || c.ReplyCount > 0);
    }

    /// <summary>
    /// Loads <paramref name="ids"/> in that order. With <paramref name="withReplies"/>, top-level comments carry their
    /// first <see cref="ReplyPreviewCount"/> readable replies.
    /// </summary>
    public async Task<IReadOnlyList<CommentDto>> LoadAsync(IReadOnlyList<Guid> ids, bool withReplies, CancellationToken ct)
    {
        if (ids.Count == 0) return [];

        var rows = await Project(All().Where(c => ids.Contains(c.Id))).ToListAsync(ct);
        var byId = rows.ToDictionary(r => r.Id);
        var ordered = ids.Where(byId.ContainsKey).Select(id => byId[id]).ToList();

        List<CommentRow> replies = [];
        if (withReplies)
        {
            var parents = ordered.Where(r => r.ParentId == null && r.ReplyCount > 0).Select(r => r.Id).ToList();
            if (parents.Count > 0)
            {
                var readable = ReadableBy();
                var candidates = All().Where(readable);
                // The first replies of each thread: those with fewer than N readable replies before them.
                replies = await Project(candidates
                        .Where(r => r.ParentId != null && parents.Contains(r.ParentId.Value))
                        .Where(r => candidates.Count(o => o.ParentId == r.ParentId &&
                            (o.CreatedAt < r.CreatedAt || (o.CreatedAt == r.CreatedAt && o.Id.CompareTo(r.Id) < 0))) < ReplyPreviewCount)
                        .OrderBy(r => r.CreatedAt)
                        .ThenBy(r => r.Id))
                    .ToListAsync(ct);
            }
        }

        var articleIds = ordered.Select(r => r.ArticleId).Distinct().ToList();
        var articleAuthors = await db.Articles.IgnoreQueryFilters().AsNoTracking()
            .Where(a => articleIds.Contains(a.Id))
            .Select(a => new { a.Id, a.AuthorId })
            .ToDictionaryAsync(a => a.Id, a => a.AuthorId, ct);

        var liked = new HashSet<Guid>();
        var muted = new HashSet<Guid>();
        var followed = new HashSet<Guid>();
        var reported = new HashSet<Guid>();
        var blocked = new HashSet<Guid>();
        if (ViewerId is { } viewer)
        {
            // F36: the people the viewer is blocked with, either way (at most 2,000).
            blocked = [.. await db.BlockedWith(viewer).Distinct().ToListAsync(ct)];
            var all = ordered.Select(r => r.Id).Concat(replies.Select(r => r.Id)).ToList();
            // The comments the viewer reported (F22): clients collapse them for the reporter, with "Show".
            reported = [.. await db.Reports.AsNoTracking()
                .Where(r => r.ReporterId == viewer && r.TargetType == ReportTargetType.Comment && all.Contains(r.TargetId))
                .Select(r => r.TargetId)
                .ToListAsync(ct)];
            liked = [.. await db.CommentLikes.AsNoTracking()
                .Where(l => l.UserId == viewer && all.Contains(l.CommentId))
                .Select(l => l.CommentId)
                .ToListAsync(ct)];

            // The writers among these comments the viewer muted (F28).
            var authors = ordered.Concat(replies).Where(r => r.AuthorId != null).Select(r => r.AuthorId!.Value).Distinct().ToList();
            if (authors.Count > 0)
            {
                muted = [.. await db.UserMutes.AsNoTracking()
                    .Where(m => m.MuterId == viewer && authors.Contains(m.MutedUserId))
                    .Select(m => m.MutedUserId)
                    .ToListAsync(ct)];
                // The rows' "متابعة" (F11), seeded into the clients' follow store.
                followed = [.. await db.UserFollows.AsNoTracking()
                    .Where(f => f.FollowerId == viewer && authors.Contains(f.FolloweeId))
                    .Select(f => f.FolloweeId)
                    .ToListAsync(ct)];
            }
        }

        var repliesByParent = replies.ToLookup(r => r.ParentId!.Value);
        return [.. ordered.Select(row =>
        {
            var articleAuthor = articleAuthors.GetValueOrDefault(row.ArticleId);
            var dto = ToDto(row, articleAuthor, liked, muted, followed, reported, blocked);
            if (!withReplies || row.ParentId is not null) return dto;
            return dto with { Replies = [.. repliesByParent[row.Id].Select(r => ToDto(r, articleAuthor, liked, muted, followed, reported, blocked))] };
        })];
    }

    public async Task<CommentDto?> LoadOneAsync(Guid id, CancellationToken ct) =>
        (await LoadAsync([id], withReplies: false, ct)).FirstOrDefault();

    private CommentDto ToDto(
        CommentRow row, Guid? articleAuthorId, HashSet<Guid> liked, HashSet<Guid> muted, HashSet<Guid> followed, HashSet<Guid> reported,
        HashSet<Guid> blocked)
    {
        var viewer = ViewerId;
        var own = viewer is not null && row.AuthorId == viewer;
        var seesHidden = own || IsModerator;

        // F36: a comment of someone the viewer is blocked with, kept only for its replies: no body, no author.
        if (!row.IsDeleted && row.AuthorId is { } blockedAuthor && blocked.Contains(blockedAuthor))
        {
            return new CommentDto
            {
                Id = row.Id,
                ArticleId = row.ArticleId,
                ParentId = row.ParentId,
                ReplyCount = row.ReplyCount,
                CreatedAt = row.CreatedAt,
                IsUnavailable = true,
            };
        }

        if (row.IsDeleted || (row.HiddenAt is not null && !seesHidden))
        {
            return new CommentDto
            {
                Id = row.Id,
                ArticleId = row.ArticleId,
                ParentId = row.ParentId,
                ReplyCount = row.ReplyCount,
                CreatedAt = row.CreatedAt,
                IsDeleted = row.IsDeleted,
                IsHidden = !row.IsDeleted,
                CanModerate = IsModerator && !row.IsDeleted,
            };
        }

        var author = row.Author is { } a ? a with { AvatarUrl = storage.ToPublicUrl(a.AvatarUrl) } : null;
        return new CommentDto
        {
            Id = row.Id,
            ArticleId = row.ArticleId,
            ParentId = row.ParentId,
            Body = row.Body,
            Author = author,
            IsAuthorMuted = !own && row.AuthorId is { } authorId && muted.Contains(authorId),
            ReportedByMe = reported.Contains(row.Id),
            IsFollowingAuthor = !own && row.AuthorId is { } followedId && followed.Contains(followedId),
            IsArticleAuthor = row.AuthorId is not null && row.AuthorId == articleAuthorId,
            // F36: a mention of someone the viewer is blocked with stays as plain text.
            Mentions = blocked.Count == 0 ? row.Mentions : [.. row.Mentions.Where(m => !blocked.Contains(m.UserId))],
            LikeCount = row.LikeCount,
            LikedByMe = liked.Contains(row.Id),
            ReplyCount = row.ReplyCount,
            IsPinned = row.IsPinned,
            CreatedAt = row.CreatedAt,
            EditedAt = row.EditedAt,
            IsHidden = row.HiddenAt is not null,
            CanEdit = own,
            CanDelete = own,
            CanPin = viewer is not null && viewer == articleAuthorId && row.ParentId is null && row.HiddenAt is null,
            CanReport = viewer is not null && !own,
            CanModerate = IsModerator,
        };
    }

    private static IQueryable<CommentRow> Project(IQueryable<Comment> comments) =>
        comments.Select(c => new CommentRow(
            c.Id,
            c.ArticleId,
            c.ParentId,
            c.AuthorId,
            c.Author == null
                ? null
                : new AuthorDto(c.Author.Id, c.Author.DisplayName, c.Author.Username, c.Author.AvatarUrl,
                    c.Author.IsVerified, c.Author.Headline),
            c.Body,
            c.IsPinned,
            c.LikeCount,
            c.ReplyCount,
            c.CreatedAt,
            c.EditedAt,
            c.IsDeleted,
            c.HiddenAt,
            c.Mentions.Select(m => new MentionDto(m.UserId, m.User.Username)).ToList()));

    private sealed record CommentRow(
        Guid Id,
        Guid ArticleId,
        Guid? ParentId,
        Guid? AuthorId,
        AuthorDto? Author,
        string Body,
        bool IsPinned,
        int LikeCount,
        int ReplyCount,
        DateTime CreatedAt,
        DateTime? EditedAt,
        bool IsDeleted,
        DateTime? HiddenAt,
        List<MentionDto> Mentions);
}
