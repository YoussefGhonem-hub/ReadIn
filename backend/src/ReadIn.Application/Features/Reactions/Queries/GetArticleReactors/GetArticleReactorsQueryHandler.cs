using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Reactions.Queries.GetArticleReactors;

internal sealed class GetArticleReactorsQueryHandler(IAppDbContext db, ICurrentUser viewer, IFileStorage storage, BlockRelations blocks)
    : IQueryHandler<GetArticleReactorsQuery, Result<CursorPage<ReactorDto>>>
{
    public async ValueTask<Result<CursorPage<ReactorDto>>> Handle(GetArticleReactorsQuery query, CancellationToken cancellationToken)
    {
        // F36: the blocker gets 403 block.blocked, the blocked person the same not-found as a deleted article.
        if (await blocks.ArticleErrorAsync(viewer, query.ArticleId, cancellationToken) is { } blocked) return blocked;
        if (!await db.Articles.VisibleTo(viewer).AnyAsync(a => a.Id == query.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var reactions = db.Reactions.AsNoTracking().Where(r => r.ArticleId == query.ArticleId);
        // F36: the people the viewer is blocked with leave the list (the counts stay the same for everyone).
        if (viewer.UserId is { } viewerId)
        {
            var blockedWith = db.BlockedWith(viewerId);
            reactions = reactions.Where(r => !blockedWith.Contains(r.UserId));
        }
        if (ReactionTypes.TryParse(query.Type, out var type)) reactions = reactions.Where(r => r.Type == type);

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            reactions = reactions.Where(r =>
                r.ReactedAt < cursor.Timestamp ||
                (r.ReactedAt == cursor.Timestamp && r.Id.CompareTo(cursor.Id) < 0));
        }

        var page = await reactions
            .OrderByDescending(r => r.ReactedAt)
            .ThenByDescending(r => r.Id)
            .Take(limit + 1)
            .Select(r => new
            {
                r.Id,
                Reactor = new ReactorDto(
                    new AuthorDto(r.User.Id, r.User.DisplayName, r.User.Username, r.User.AvatarUrl,
                        r.User.IsVerified, r.User.Headline),
                    r.Type,
                    r.ReactedAt),
            })
            .ToListAsync(cancellationToken);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].Reactor.ReactedAt, page[^1].Id).Encode();
        }

        return new CursorPage<ReactorDto>(
            [.. page.Select(p => p.Reactor with { User = p.Reactor.User with { AvatarUrl = storage.ToPublicUrl(p.Reactor.User.AvatarUrl) } })],
            next);
    }
}
