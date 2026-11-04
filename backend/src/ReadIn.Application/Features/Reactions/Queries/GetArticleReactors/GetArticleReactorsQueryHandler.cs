using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Reactions.Queries.GetArticleReactors;

internal sealed class GetArticleReactorsQueryHandler(IAppDbContext db, ICurrentUser viewer, IFileStorage storage)
    : IQueryHandler<GetArticleReactorsQuery, Result<CursorPage<ReactorDto>>>
{
    public async ValueTask<Result<CursorPage<ReactorDto>>> Handle(GetArticleReactorsQuery query, CancellationToken cancellationToken)
    {
        if (!await db.Articles.VisibleTo(viewer).AnyAsync(a => a.Id == query.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var reactions = db.Reactions.AsNoTracking().Where(r => r.ArticleId == query.ArticleId);
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
                        r.User.Roles.Any(role => role.RoleId == RoleIds.VerifiedWriter)),
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
