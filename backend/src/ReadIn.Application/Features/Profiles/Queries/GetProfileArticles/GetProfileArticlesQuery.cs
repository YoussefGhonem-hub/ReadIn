using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Profiles.Queries.GetProfileArticles;

/// <summary>
/// GET /users/{username}/articles — the profile's Articles tab (SPEC F14): published articles, newest first,
/// keyset-paginated over (PublishedAt DESC, Id DESC), as cards like the feeds. Guests are allowed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetProfileArticlesQuery(string Username, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<ArticleCardDto>>>;

internal sealed class GetProfileArticlesQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    BlockRelations blocks,
    TimeProvider clock)
    : IQueryHandler<GetProfileArticlesQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetProfileArticlesQuery query, CancellationToken ct)
    {
        if (await db.FindProfileForAsync(query.Username, clock.GetUtcNow().UtcDateTime, currentUser, ct) is not { } owner) return UserErrors.NotFound;
        if (await blocks.DirectLinkErrorAsync(currentUser, owner.Id, UserErrors.NotFound, ct) is { } blocked) return blocked;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var articles = db.Articles.AsNoTracking()
            .Visible()
            .Where(a => a.AuthorId == owner.Id && a.PublishedAt != null);

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            articles = articles.Where(a =>
                a.PublishedAt < cursor.Timestamp ||
                (a.PublishedAt == cursor.Timestamp && a.Id.CompareTo(cursor.Id) < 0));
        }

        var articleLanguage = currentUser.UserId is { } viewerId
            ? await db.Users.AsNoTracking().Where(u => u.Id == viewerId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct)
            : ArticleLanguages.ForUi(query.UiLanguage);
        using var _ = LocalizedProjection.Begin(query.UiLanguage, articleLanguage);

        var page = await articles
            .OrderByDescending(a => a.PublishedAt)
            .ThenByDescending(a => a.Id)
            .Take(limit + 1)
            .ProjectToType<ArticleCardDto>(mapping)
            .ToListAsync(ct);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            var last = page[^1];
            next = new TimeCursor(last.PublishedAt!.Value, last.Id).Encode();
        }

        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync(page, ct), next);
    }
}
