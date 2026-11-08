using System.Globalization;
using System.Text;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Comments.Queries;

/// <summary>
/// GET /articles/{id}/comments?sort=top|new (SPEC F11): top-level comments with their first replies. The pinned comment
/// comes first on the first page. "Top" ranks by likes and replies; "new" is newest first.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetArticleCommentsQuery(Guid ArticleId, CommentSort Sort, string? Cursor, int Limit = 20) : IQuery<Result<CommentPageDto>>;

/// <summary>GET /comments/{id}/replies: a thread's replies, oldest first.</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetCommentRepliesQuery(Guid CommentId, string? Cursor, int Limit = 20) : IQuery<Result<CursorPage<CommentDto>>>;

/// <summary>GET /comments/{id}: one comment as the viewer sees it; clients refetch it after a live event (F27).</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetCommentQuery(Guid CommentId) : IQuery<Result<CommentDto>>;

/// <summary>GET /users/mention-suggestions?q=: people to @mention while typing (by @username or name).</summary>
[Authenticated]
public sealed record GetMentionSuggestionsQuery(string? Q, int Limit = 8) : IQuery<Result<IReadOnlyList<MentionCandidateDto>>>;

internal sealed class GetArticleCommentsQueryHandler(IAppDbContext db, ICurrentUser viewer, CommentReader reader, BlockRelations blocks)
    : IQueryHandler<GetArticleCommentsQuery, Result<CommentPageDto>>
{
    public async ValueTask<Result<CommentPageDto>> Handle(GetArticleCommentsQuery query, CancellationToken cancellationToken)
    {
        // F36: the comments of an article whose author the viewer is blocked with answer like the article.
        if (await blocks.ArticleErrorAsync(viewer, query.ArticleId, cancellationToken) is { } blocked) return blocked;
        var article = await db.Articles.VisibleTo(viewer).AsNoTracking()
            .Where(a => a.Id == query.ArticleId)
            .Select(a => new { a.CommentCount })
            .FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var comments = reader.All().Where(c => c.ArticleId == query.ArticleId && !c.IsPinned).Where(reader.ListedTopLevel());

        List<Guid> ids;
        string? next = null;
        if (query.Sort == CommentSort.New)
        {
            if (TimeCursor.Decode(query.Cursor) is { } cursor)
                comments = comments.Where(c => c.CreatedAt < cursor.Timestamp || (c.CreatedAt == cursor.Timestamp && c.Id.CompareTo(cursor.Id) < 0));

            var page = await comments.OrderByDescending(c => c.CreatedAt).ThenByDescending(c => c.Id)
                .Take(limit + 1).Select(c => new { c.Id, c.CreatedAt }).ToListAsync(cancellationToken);
            if (page.Count > limit)
            {
                page.RemoveAt(limit);
                next = new TimeCursor(page[^1].CreatedAt, page[^1].Id).Encode();
            }
            ids = [.. page.Select(p => p.Id)];
        }
        else
        {
            // Scores change while people read, so "top" pages by offset; a comment may rarely repeat or be skipped.
            var offset = OffsetCursor.Decode(query.Cursor);
            ids = await comments
                .OrderByDescending(c => c.LikeCount + 2 * c.ReplyCount)
                .ThenByDescending(c => c.CreatedAt)
                .ThenByDescending(c => c.Id)
                .Skip(offset)
                .Take(limit + 1)
                .Select(c => c.Id)
                .ToListAsync(cancellationToken);
            if (ids.Count > limit)
            {
                ids.RemoveAt(limit);
                next = OffsetCursor.Encode(offset + limit);
            }
        }

        if (query.Cursor is null)
        {
            var pinned = await reader.All()
                .Where(c => c.ArticleId == query.ArticleId && c.IsPinned)
                .Where(reader.ReadableBy())
                .Select(c => (Guid?)c.Id)
                .FirstOrDefaultAsync(cancellationToken);
            if (pinned is { } pinnedId) ids.Insert(0, pinnedId);
        }

        var items = await reader.LoadAsync(ids, withReplies: true, cancellationToken);
        return new CommentPageDto(items, next, article.CommentCount);
    }
}

internal sealed class GetCommentRepliesQueryHandler(IAppDbContext db, ICurrentUser viewer, CommentReader reader, BlockRelations blocks)
    : IQueryHandler<GetCommentRepliesQuery, Result<CursorPage<CommentDto>>>
{
    public async ValueTask<Result<CursorPage<CommentDto>>> Handle(GetCommentRepliesQuery query, CancellationToken cancellationToken)
    {
        var parent = await reader.All().Where(c => c.Id == query.CommentId)
            .Select(c => new { c.ArticleId, c.ParentId }).FirstOrDefaultAsync(cancellationToken);
        if (parent is null || parent.ParentId is not null) return CommentErrors.NotFound;
        // F36: the thread of a comment (or an article) by someone the viewer is blocked with answers like that comment.
        if (await blocks.CommentErrorAsync(viewer, query.CommentId, cancellationToken) is { } blocked) return blocked;
        if (!await db.Articles.VisibleTo(viewer).AnyAsync(a => a.Id == parent.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var replies = reader.All().Where(c => c.ParentId == query.CommentId).Where(reader.ReadableBy());
        if (TimeCursor.Decode(query.Cursor) is { } cursor)
            replies = replies.Where(c => c.CreatedAt > cursor.Timestamp || (c.CreatedAt == cursor.Timestamp && c.Id.CompareTo(cursor.Id) > 0));

        var page = await replies.OrderBy(c => c.CreatedAt).ThenBy(c => c.Id)
            .Take(limit + 1).Select(c => new { c.Id, c.CreatedAt }).ToListAsync(cancellationToken);
        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].CreatedAt, page[^1].Id).Encode();
        }

        return new CursorPage<CommentDto>(await reader.LoadAsync([.. page.Select(p => p.Id)], withReplies: false, cancellationToken), next);
    }
}

internal sealed class GetCommentQueryHandler(IAppDbContext db, ICurrentUser viewer, CommentReader reader, BlockRelations blocks)
    : IQueryHandler<GetCommentQuery, Result<CommentDto>>
{
    public async ValueTask<Result<CommentDto>> Handle(GetCommentQuery query, CancellationToken cancellationToken)
    {
        // F36: the blocker gets 403 block.blocked, the blocked person the same not-found as a deleted comment.
        if (await blocks.CommentErrorAsync(viewer, query.CommentId, cancellationToken) is { } blocked) return blocked;
        var comment = await reader.LoadOneAsync(query.CommentId, cancellationToken);
        if (comment is null) return CommentErrors.NotFound;
        if (!await db.Articles.VisibleTo(viewer).AnyAsync(a => a.Id == comment.ArticleId, cancellationToken)) return ArticleErrors.NotFound;
        return comment;
    }
}

/// <summary>Only people the viewer may mention ("who can mention me", SPEC F18): the comment box and the editor both use it.</summary>
internal sealed class GetMentionSuggestionsQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage, TimeProvider clock)
    : IQueryHandler<GetMentionSuggestionsQuery, Result<IReadOnlyList<MentionCandidateDto>>>
{
    public async ValueTask<Result<IReadOnlyList<MentionCandidateDto>>> Handle(GetMentionSuggestionsQuery query, CancellationToken cancellationToken)
    {
        var term = (query.Q ?? string.Empty).Trim().TrimStart('@');
        if (term.Length == 0) return Result.Success<IReadOnlyList<MentionCandidateDto>>([]);

        var viewer = currentUser.RequireUserId();
        var handle = term.ToLowerInvariant();
        var limit = Math.Clamp(query.Limit, 1, 20);
        var users = await db.Users.AsNoTracking()
            .MentionableBy(db, viewer, clock.GetUtcNow().UtcDateTime)
            .Where(u => u.Id != viewer && (u.Username.StartsWith(handle) || u.DisplayName.Contains(term)))
            .OrderByDescending(u => u.Username.StartsWith(handle))
            .ThenBy(u => u.Username)
            .Take(limit)
            .Select(u => new MentionCandidateDto(u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified))
            .ToListAsync(cancellationToken);

        return users.Select(u => u with { AvatarUrl = storage.ToPublicUrl(u.AvatarUrl) }).ToList();
    }
}

/// <summary>An opaque offset for the "top" order.</summary>
internal static class OffsetCursor
{
    public static string Encode(int offset) =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes($"o:{offset.ToString(CultureInfo.InvariantCulture)}")).TrimEnd('=');

    public static int Decode(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor)) return 0;
        try
        {
            var text = Encoding.UTF8.GetString(Convert.FromBase64String(cursor.PadRight(cursor.Length + (4 - cursor.Length % 4) % 4, '=')));
            return text.StartsWith("o:", StringComparison.Ordinal) && int.TryParse(text[2..], NumberStyles.None, CultureInfo.InvariantCulture, out var offset)
                ? Math.Min(offset, 10_000)
                : 0;
        }
        catch (FormatException)
        {
            return 0;
        }
    }
}
