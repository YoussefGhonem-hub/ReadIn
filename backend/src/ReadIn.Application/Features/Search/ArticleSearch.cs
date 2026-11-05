using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Search;

/// <summary>
/// <c>GET /search?type=articles</c> (SPEC F16, contract-v1 "Search"): published articles readers can open whose title +
/// text, or attached PDF, hold every word of <see cref="Q"/>, best <see cref="SearchRanking.Score"/> first.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record ArticleSearchQuery(
    string? Q,
    string? FieldSlug,
    string? Language,
    int? MinMinutes,
    int? MaxMinutes,
    string? Cursor,
    int Limit,
    string UiLanguage) : IQuery<Result<CursorPage<SearchArticleDto>>>;

/// <summary>The article filters, checked: a known language, reading times 0–600 with min ≤ max.</summary>
public sealed record ArticleSearchFilters(string? FieldSlug, string? Language, int? MinMinutes, int? MaxMinutes)
{
    public static readonly ArticleSearchFilters None = new(null, null, null, null);

    public static Result<ArticleSearchFilters> Create(string? fieldSlug, string? language, int? minMinutes, int? maxMinutes)
    {
        string? lang = null;
        if (!string.IsNullOrWhiteSpace(language))
        {
            lang = ArticleLanguages.All.FirstOrDefault(l => string.Equals(l, language.Trim(), StringComparison.OrdinalIgnoreCase));
            if (lang is null) return SearchErrors.FilterInvalid;
        }

        if (minMinutes is < 0 or > SearchLimits.MaxMinutes || maxMinutes is < 0 or > SearchLimits.MaxMinutes) return SearchErrors.FilterInvalid;
        if (minMinutes is { } min && maxMinutes is { } max && min > max) return SearchErrors.FilterInvalid;

        var field = string.IsNullOrWhiteSpace(fieldSlug) ? null : fieldSlug.Trim().ToLowerInvariant();
        return new ArticleSearchFilters(field, lang, minMinutes, maxMinutes);
    }

    public string CacheKey => $"{FieldSlug ?? "-"}:{Language ?? "-"}:{MinMinutes?.ToString(System.Globalization.CultureInfo.InvariantCulture) ?? "-"}:{MaxMinutes?.ToString(System.Globalization.CultureInfo.InvariantCulture) ?? "-"}";
}

/// <summary>One article of a ranked result: the version served, where it matched and its score.</summary>
public sealed record RankedArticle(Guid Id, string Language, SearchMatch MatchedIn, double Score, DateTime PublishedAt);

/// <summary>
/// Ranks articles for a query and turns a page of them into <see cref="SearchArticleDto"/>s; shared by the articles tab
/// and the suggestions. A fixed number of queries per search, never one per article.
/// </summary>
public sealed class ArticleSearch(
    IAppDbContext db,
    ISearchEngine engine,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    HybridCache cache,
    TimeProvider clock)
{
    /// <summary>Engine hits looked at per place (text, PDF), best rank first; plenty for the 200 results a query pages through.</summary>
    internal const int MaxCandidates = 1000;

    private static readonly TimeSpan GuestExpiration = TimeSpan.FromMinutes(2);

    /// <summary>
    /// The ranked results (at most <see cref="SearchLimits.MaxResults"/>). Guests share a cached list per query, refreshed
    /// by publish, Update, hide/unhide and delete (<see cref="CacheTags.Feed"/>); a signed-in caller's is never cached.
    /// </summary>
    public async Task<IReadOnlyList<RankedArticle>> RankAsync(SearchTerms terms, ArticleSearchFilters filters, string uiLanguage, CancellationToken ct)
    {
        if (currentUser.UserId is { } viewerId)
        {
            var preferred = await db.Users.AsNoTracking()
                .Where(u => u.Id == viewerId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct);
            return await LoadAsync(terms, filters, preferred ?? ArticleLanguages.ForUi(uiLanguage), viewerId, ct);
        }

        var language = ArticleLanguages.ForUi(uiLanguage);
        return await cache.GetOrCreateAsync(
            $"search:articles:{engine.Kind}:{language}:{filters.CacheKey}:{terms.Phrase}",
            (Search: this, Terms: terms, Filters: filters, Language: language),
            static async (state, token) => await state.Search.LoadAsync(state.Terms, state.Filters, state.Language, viewerId: null, token),
            new HybridCacheEntryOptions { Expiration = GuestExpiration, LocalCacheExpiration = GuestExpiration },
            [CacheTags.Feed, CacheTags.Tags],
            ct);
    }

    /// <summary>The cards of <paramref name="page"/>, in its order, each in its served version, with the caller's own state.</summary>
    public async Task<List<SearchArticleDto>> CardsAsync(IReadOnlyList<RankedArticle> page, string uiLanguage, CancellationToken ct)
    {
        if (page.Count == 0) return [];

        var projected = new Dictionary<Guid, ArticleCardDto>();
        foreach (var version in page.GroupBy(r => r.Language))
        {
            var ids = version.Select(r => r.Id).ToList();
            using (LocalizedProjection.Begin(uiLanguage, version.Key))
            {
                var list = await db.Articles.AsNoTracking().Visible()
                    .Where(a => ids.Contains(a.Id))
                    .ProjectToType<ArticleCardDto>(mapping)
                    .ToListAsync(ct);
                foreach (var card in list) projected[card.Id] = card;
            }
        }

        // A result can drop out between ranking and now (hidden, deleted): it is skipped, never an error.
        var kept = page.Where(r => projected.ContainsKey(r.Id)).ToList();
        var completed = await cards.CompleteAsync(kept.Select(r => projected[r.Id]).ToList(), ct);
        var byId = completed.ToDictionary(c => c.Id);
        return kept.Select(r => new SearchArticleDto(byId[r.Id], r.MatchedIn)).ToList();
    }

    private async Task<List<RankedArticle>> LoadAsync(
        SearchTerms terms, ArticleSearchFilters filters, string preferredLanguage, Guid? viewerId, CancellationToken ct)
    {
        // What readers can open (SPEC F22), then the caller's mutes (F28 seam) and the filters.
        var articles = db.Articles.AsNoTracking().Visible().WithoutMutedFor(viewerId).Where(a => a.PublishedAt != null);
        if (filters.FieldSlug is { } field) articles = articles.Where(a => a.Field.Slug == field);

        var versions = db.ArticleTranslations.AsNoTracking().Where(t => articles.Any(a => a.Id == t.ArticleId));
        if (filters.Language is { } language) versions = versions.Where(t => t.Language == language);
        if (filters.MinMinutes is { } min) versions = versions.Where(t => t.ReadingTimeMinutes >= min);
        if (filters.MaxMinutes is { } max) versions = versions.Where(t => t.ReadingTimeMinutes <= max);

        var textHits = await (
                from hit in engine.ArticleVersions(terms)
                join version in versions on hit.Key equals version.Id
                join article in articles on version.ArticleId equals article.Id
                orderby hit.Rank descending, article.PublishedAt descending
                select new { version.ArticleId, version.Language, version.Title, hit.Rank })
            .Take(MaxCandidates)
            .ToListAsync(ct);

        // A PDF counts while it is attached to an article readers can open, once processed (SPEC §22, F26).
        var documentHits = await (
                from hit in engine.Documents(terms)
                join asset in db.MediaAssets on hit.Key equals asset.Id
                join attachment in db.ArticleAttachments on asset.Id equals attachment.MediaAssetId
                join article in articles on attachment.ArticleId equals article.Id
                where asset.Kind == MediaKind.Document && asset.Status == MediaStatus.Ready
                orderby hit.Rank descending, article.PublishedAt descending
                select new { attachment.ArticleId, hit.Rank })
            .Take(MaxCandidates)
            .ToListAsync(ct);

        var ids = textHits.Select(h => h.ArticleId).Concat(documentHits.Select(h => h.ArticleId)).Distinct().ToList();
        if (ids.Count == 0) return [];

        var info = await db.Articles.AsNoTracking()
            .Where(a => ids.Contains(a.Id))
            .Select(a => new { a.Id, a.QualityScore, a.PublishedAt, a.SourceLanguage })
            .ToDictionaryAsync(a => a.Id, ct);

        // An article only its PDF matched is served in any version the filters keep.
        var textMatched = textHits.Select(h => h.ArticleId).ToHashSet();
        var documentOnly = documentHits.Select(h => h.ArticleId).Where(id => !textMatched.Contains(id)).Distinct().ToList();
        var documentVersions = documentOnly.Count == 0
            ? []
            : await versions.Where(t => documentOnly.Contains(t.ArticleId)).Select(t => new { t.ArticleId, t.Language }).ToListAsync(ct);

        var now = clock.GetUtcNow().UtcDateTime;
        var textByArticle = textHits.ToLookup(h => h.ArticleId);
        var documentRank = documentHits.GroupBy(h => h.ArticleId).ToDictionary(g => g.Key, g => g.Max(h => h.Rank));
        var documentLanguages = documentVersions.ToLookup(v => v.ArticleId, v => v.Language);

        // A title hit holds the words the way the engine matched them: full-text at word starts ("net" isn't in
        // "Internet"), the LIKE fallback anywhere.
        Func<string?, bool> inTitle = engine.Kind == SearchEngineKind.FullText ? terms.AllWordsAtWordStartsIn : terms.AllWordsIn;

        var ranked = new List<RankedArticle>(ids.Count);
        foreach (var id in ids)
        {
            if (!info.TryGetValue(id, out var article) || article.PublishedAt is not { } publishedAt) continue;

            // Every place it matched, with the version of the text hits: the best one gives the score.
            var places = textByArticle[id]
                .Select(h => (h.Language, Place: inTitle(ArabicNormalizer.Normalize(h.Title)) ? SearchMatch.Title : SearchMatch.Text, h.Rank))
                .ToList();
            var score = places.Count == 0
                ? double.MinValue
                : places.Max(p => SearchRanking.Score(p.Place, p.Rank, article.QualityScore, publishedAt, now));
            if (documentRank.TryGetValue(id, out var pdfRank))
                score = Math.Max(score, SearchRanking.Score(SearchMatch.Attachment, pdfRank, article.QualityScore, publishedAt, now));

            // The version served: one whose text matched, else (only the PDF matched) any the filters keep; the caller's
            // article language first, then the source language.
            var candidates = places.Count > 0 ? places.Select(p => p.Language).Distinct().ToList() : documentLanguages[id].Distinct().ToList();
            if (candidates.Count == 0) continue;
            var served = candidates.Contains(preferredLanguage) ? preferredLanguage
                : candidates.Contains(article.SourceLanguage) ? article.SourceLanguage
                : candidates.Order(StringComparer.Ordinal).First();

            var matchedIn = places.Where(p => p.Language == served).Select(p => (SearchMatch?)p.Place).Min() ?? SearchMatch.Attachment;
            ranked.Add(new RankedArticle(id, served, matchedIn, score, publishedAt));
        }

        return ranked
            .OrderByDescending(r => r.Score)
            .ThenByDescending(r => r.PublishedAt)
            .ThenByDescending(r => r.Id)
            .Take(SearchLimits.MaxResults)
            .ToList();
    }
}

internal sealed class ArticleSearchQueryHandler(ArticleSearch search)
    : IQueryHandler<ArticleSearchQuery, Result<CursorPage<SearchArticleDto>>>
{
    public async ValueTask<Result<CursorPage<SearchArticleDto>>> Handle(ArticleSearchQuery query, CancellationToken ct)
    {
        var terms = SearchTerms.Parse(query.Q);
        if (terms.IsFailure) return terms.Error!;
        var filters = ArticleSearchFilters.Create(query.FieldSlug, query.Language, query.MinMinutes, query.MaxMinutes);
        if (filters.IsFailure) return filters.Error!;

        var ranked = await search.RankAsync(terms.Value, filters.Value, query.UiLanguage, ct);
        var (page, next) = SearchPaging.Page(ranked, query.Cursor, query.Limit);
        return new CursorPage<SearchArticleDto>(await search.CardsAsync(page, query.UiLanguage, ct), next);
    }
}

/// <summary>Offset paging over a ranked list of at most <see cref="SearchLimits.MaxResults"/>.</summary>
internal static class SearchPaging
{
    public static int Limit(int limit) => Math.Clamp(limit, 1, SearchLimits.MaxLimit);

    /// <summary>The page at <paramref name="cursor"/> and the cursor of the next one (null on the last page).</summary>
    public static (IReadOnlyList<T> Page, string? Next) Page<T>(IReadOnlyList<T> ranked, string? cursor, int limit)
    {
        var size = Limit(limit);
        var offset = Math.Clamp(OffsetCursor.Decode(cursor), 0, ranked.Count);
        var page = ranked.Skip(offset).Take(size).ToList();
        var end = offset + page.Count;
        return (page, end < ranked.Count ? new OffsetCursor(end).Encode() : null);
    }

    /// <summary>
    /// For lists ranked in SQL: where to start and how many rows to read (one more than a page, to know whether another
    /// follows), never past <see cref="SearchLimits.MaxResults"/>.
    /// </summary>
    public static (int Offset, int Take, int Size) Window(string? cursor, int limit)
    {
        var size = Limit(limit);
        var offset = Math.Clamp(OffsetCursor.Decode(cursor), 0, SearchLimits.MaxResults);
        return (offset, Math.Max(Math.Min(size + 1, SearchLimits.MaxResults - offset), 0), size);
    }

    /// <summary>The page of <paramref name="rows"/> read with <see cref="Window"/>, and the next cursor.</summary>
    public static (List<T> Page, string? Next) Cut<T>(List<T> rows, int offset, int size)
    {
        var more = rows.Count > size;
        if (more) rows.RemoveRange(size, rows.Count - size);
        var end = offset + rows.Count;
        return (rows, more && end < SearchLimits.MaxResults ? new OffsetCursor(end).Encode() : null);
    }
}
