using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Queries.GetSavedArticles;

internal sealed class GetSavedArticlesQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards)
    : IQueryHandler<GetSavedArticlesQuery, Result<CursorPage<SavedArticleDto>>>
{
    public async ValueTask<Result<CursorPage<SavedArticleDto>>> Handle(GetSavedArticlesQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        if (query.CollectionId is { } collectionId &&
            !await db.Collections.AnyAsync(c => c.Id == collectionId && c.UserId == userId, ct))
            return CollectionErrors.NotFound;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var saved = db.SavedArticles.AsNoTracking()
            // ArticleVisibility.Visible() through the navigation: published, enabled field, not hidden (SPEC F22).
            .Where(s => s.UserId == userId && s.Article.Status == ArticleStatus.Published && s.Article.Field.IsEnabled && s.Article.HiddenAt == null);
        // F36: the articles of people you are blocked with, either way, leave your saved list and collections (the saves stay).
        var blockedWith = db.BlockedWith(userId);
        saved = saved.Where(s => !(s.Article.AuthorId != null && blockedWith.Contains(s.Article.AuthorId.Value)));

        if (!string.IsNullOrWhiteSpace(query.FieldSlug))
            saved = saved.Where(s => s.Article.Field.Slug == query.FieldSlug);
        // Titles of any language version, with the search normalization of SPEC §22 on both sides: the collation
        // (Arabic_100_CI_AI) ignores case but not Arabic diacritics.
        if (ArabicNormalizer.Normalize(query.Search) is { Length: > 0 } search)
            saved = saved.Where(s => s.Article.Translations.Any(t => ArabicNormalizer.InSql(t.Title).Contains(search)));
        if (query.CollectionId is { } inCollection)
            saved = saved.Where(s => db.CollectionItems.Any(i => i.CollectionId == inCollection && i.ArticleId == s.ArticleId));

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            saved = saved.Where(s =>
                s.SavedAt < cursor.Timestamp ||
                (s.SavedAt == cursor.Timestamp && s.Id.CompareTo(cursor.Id) < 0));
        }

        var rows = await saved
            .OrderByDescending(s => s.SavedAt)
            .ThenByDescending(s => s.Id)
            .Take(limit + 1)
            .Select(s => new { s.Id, s.ArticleId, s.SavedAt })
            .ToListAsync(ct);

        string? next = null;
        if (rows.Count > limit)
        {
            rows.RemoveAt(limit);
            next = new TimeCursor(rows[^1].SavedAt, rows[^1].Id).Encode();
        }
        if (rows.Count == 0) return new CursorPage<SavedArticleDto>([], next);

        var articleIds = rows.Select(r => r.ArticleId).ToList();
        var articleLanguage = await db.Users.AsNoTracking().Where(u => u.Id == userId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct);

        List<ArticleCardDto> projected;
        using (LocalizedProjection.Begin(query.UiLanguage, articleLanguage))
        {
            projected = await db.Articles.AsNoTracking()
                .Where(a => articleIds.Contains(a.Id))
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct);
        }
        var byId = (await cards.CompleteAsync(projected, ct)).ToDictionary(c => c.Id);

        var memberships = (await db.CollectionItems.AsNoTracking()
                .Where(i => articleIds.Contains(i.ArticleId) && db.Collections.Any(c => c.Id == i.CollectionId && c.UserId == userId))
                .Select(i => new { i.ArticleId, i.CollectionId })
                .ToListAsync(ct))
            .ToLookup(i => i.ArticleId, i => i.CollectionId);

        return new CursorPage<SavedArticleDto>(
            [.. rows.Where(r => byId.ContainsKey(r.ArticleId))
                .Select(r => new SavedArticleDto(r.SavedAt, [.. memberships[r.ArticleId]], byId[r.ArticleId]))],
            next);
    }
}
