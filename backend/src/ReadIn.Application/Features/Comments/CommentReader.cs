using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Comments;

/// <summary>
/// Builds <see cref="CommentDto"/>s for the current viewer (SPEC F11). The rules:
/// <list type="bullet">
/// <item>Readers see visible comments in full.</item>
/// <item>A hidden comment is shown in full to its author and to moderators.</item>
/// <item>A deleted or (for others) hidden top-level comment that still has replies is a placeholder; otherwise it is left
/// out. Replies are never placeholders.</item>
/// <item>A comment whose author deleted their account has a null <see cref="CommentDto.Author"/>.</item>
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
        return c => !c.IsDeleted && (c.HiddenAt == null || moderator || (viewer != null && c.AuthorId == viewer));
    }

    /// <summary>Top-level comments the viewer gets in a list: readable ones, plus placeholders that keep their replies.</summary>
    public Expression<Func<Comment, bool>> ListedTopLevel()
    {
        var viewer = ViewerId;
        var moderator = IsModerator;
        return c => c.ParentId == null &&
            ((!c.IsDeleted && (c.HiddenAt == null || moderator || (viewer != null && c.AuthorId == viewer))) || c.ReplyCount > 0);
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
        if (ViewerId is { } viewer)
        {
            var all = ordered.Select(r => r.Id).Concat(replies.Select(r => r.Id)).ToList();
            liked = [.. await db.CommentLikes.AsNoTracking()
                .Where(l => l.UserId == viewer && all.Contains(l.CommentId))
                .Select(l => l.CommentId)
                .ToListAsync(ct)];
        }

        var repliesByParent = replies.ToLookup(r => r.ParentId!.Value);
        return [.. ordered.Select(row =>
        {
            var articleAuthor = articleAuthors.GetValueOrDefault(row.ArticleId);
            var dto = ToDto(row, articleAuthor, liked);
            if (!withReplies || row.ParentId is not null) return dto;
            return dto with { Replies = [.. repliesByParent[row.Id].Select(r => ToDto(r, articleAuthor, liked))] };
        })];
    }

    public async Task<CommentDto?> LoadOneAsync(Guid id, CancellationToken ct) =>
        (await LoadAsync([id], withReplies: false, ct)).FirstOrDefault();

    private CommentDto ToDto(CommentRow row, Guid? articleAuthorId, HashSet<Guid> liked)
    {
        var viewer = ViewerId;
        var own = viewer is not null && row.AuthorId == viewer;
        var seesHidden = own || IsModerator;

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
            IsArticleAuthor = row.AuthorId is not null && row.AuthorId == articleAuthorId,
            Mentions = row.Mentions,
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
                    c.Author.Roles.Any(r => r.RoleId == RoleIds.VerifiedWriter)),
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
