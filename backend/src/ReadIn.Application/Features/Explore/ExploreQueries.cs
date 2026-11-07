using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.LearningPaths;
using ReadIn.Application.Features.Search;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Explore;

/// <summary>
/// GET /explore: every section of the Explore page (SPEC F15). The sections are the same for everyone with the same UI
/// and article language and are cached together; the caller's own state is added on every request.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetExploreQuery(string UiLanguage) : IQuery<Result<ExploreDto>>;

/// <summary>GET /explore/trending: "Trending this week" in full, best first, as feed cards (SPEC F15, F34).</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetTrendingArticlesQuery(string? Cursor, int Limit, string UiLanguage) : IQuery<Result<CursorPage<ArticleCardDto>>>;

/// <summary>GET /explore/most-saved: "Most saved" in full, best first, as feed cards (SPEC F15, F34).</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetMostSavedArticlesQuery(string? Cursor, int Limit, string UiLanguage) : IQuery<Result<CursorPage<ArticleCardDto>>>;

/// <summary>
/// What is cached for <see cref="GetExploreQuery"/>: each list with some spare items, so a caller whose mutes (F28) take a
/// few out still gets full sections. Cards and people are as SQL projects them, paths as guests see them.
/// </summary>
internal sealed record ExploreSnapshot(
    IReadOnlyList<FieldSummaryDto> Fields,
    IReadOnlyList<ArticleCardDto> Trending,
    IReadOnlyList<ArticleCardDto> MostSaved,
    IReadOnlyList<UserSummaryDto> NewWriters,
    IReadOnlyList<PathCardDto> FeaturedPaths,
    IReadOnlyList<ArticleCardDto> FeaturedArticles);

internal sealed class GetExploreQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    ExploreRankings rankings,
    ArticleCards cards,
    PathCards paths,
    HybridCache cache)
    : IQueryHandler<GetExploreQuery, Result<ExploreDto>>
{
    /// <summary>Items cached per list: twice what a section shows.</summary>
    private const int Spare = 2;

    public async ValueTask<Result<ExploreDto>> Handle(GetExploreQuery query, CancellationToken ct)
    {
        var ui = UiLanguages.Normalize(query.UiLanguage);
        var viewerId = currentUser.UserId;
        var articleLanguage = await paths.ArticleLanguageOfAsync(viewerId, ui, ct) ?? ArticleLanguages.ForUi(ui);

        var snapshot = await cache.GetOrCreateAsync(
            $"explore:{ui}:{articleLanguage}",
            (Handler: this, Ui: ui, Lang: articleLanguage),
            static async (state, token) => await state.Handler.BuildAsync(state.Ui, state.Lang, token),
            ExploreRankings.CacheOptions,
            [CacheTags.Feed, CacheTags.Taxonomy],
            ct);

        var fields = snapshot.Fields;
        IReadOnlyList<ArticleCardDto> trending = snapshot.Trending, mostSaved = snapshot.MostSaved, featuredArticles = snapshot.FeaturedArticles;
        if (viewerId is { } viewer)
        {
            // The cached lists are shared, so the caller's mutes and "show less" marks (F28) apply here.
            var articleIds = trending.Concat(mostSaved).Concat(featuredArticles).Select(c => c.Id).Distinct().ToList();
            var keptArticles = (await db.Articles.AsNoTracking().Where(a => articleIds.Contains(a.Id))
                .WithoutMutedFor(db, viewer).WithoutShownLessFor(db, viewer)
                .Select(a => a.Id).ToListAsync(ct)).ToHashSet();
            var keptFields = (await db.Fields.AsNoTracking().WithoutMutedFor(db, viewer).Select(f => f.Id).ToListAsync(ct)).ToHashSet();
            trending = [.. trending.Where(c => keptArticles.Contains(c.Id))];
            mostSaved = [.. mostSaved.Where(c => keptArticles.Contains(c.Id))];
            featuredArticles = [.. featuredArticles.Where(c => keptArticles.Contains(c.Id))];
            fields = [.. fields.Where(f => keptFields.Contains(f.Id))];
        }

        trending = [.. trending.Take(ExploreLimits.SectionArticles)];
        mostSaved = [.. mostSaved.Take(ExploreLimits.SectionArticles)];
        featuredArticles = [.. featuredArticles.Take(ExploreLimits.SectionArticles)];
        var completed = await cards.CompleteAsync([.. trending, .. mostSaved, .. featuredArticles], ct);
        var writers = await rankings.ForViewerAsync(snapshot.NewWriters, viewerId, ct);

        IReadOnlyList<PathCardDto> featured = [.. snapshot.FeaturedPaths.Take(ExploreLimits.SectionPaths)];
        if (viewerId is not null && featured.Count > 0)
            featured = await paths.BuildAsync([.. featured.Select(p => p.Id)], viewerId, ui, articleLanguage, ct);

        return new ExploreDto(
            fields,
            [.. completed.Take(trending.Count)],
            [.. completed.Skip(trending.Count).Take(mostSaved.Count)],
            [.. writers.Take(ExploreLimits.SectionWriters)],
            featured,
            [.. completed.Skip(trending.Count + mostSaved.Count)]);
    }

    private async Task<ExploreSnapshot> BuildAsync(string ui, string articleLanguage, CancellationToken ct)
    {
        var now = rankings.Now;
        var english = ui == UiLanguages.English;
        var visible = rankings.Visible();

        var fields = await db.Fields.AsNoTracking()
            .Where(f => f.IsEnabled)
            .OrderBy(f => f.SortOrder)
            .Select(f => new FieldSummaryDto(
                f.Id, f.Slug, english ? f.NameEn : f.NameAr, f.NameAr, f.NameEn, f.Icon, f.Color, visible.Count(a => a.FieldId == f.Id)))
            .ToListAsync(ct);

        var trendingIds = (await rankings.TrendingAsync(ct)).Take(ExploreLimits.SectionArticles * Spare).ToList();
        var mostSavedIds = (await rankings.MostSavedAsync(ct)).Take(ExploreLimits.SectionArticles * Spare).ToList();
        var trending = await rankings.CardsAsync(trendingIds, ui, articleLanguage, viewerId: null, ct);
        var mostSaved = await rankings.CardsAsync(mostSavedIds, ui, articleLanguage, viewerId: null, ct);

        var writerIds = await rankings.NewWriterIdsAsync(now, ExploreLimits.SectionWriters * Spare, ct);
        var writers = await rankings.UsersAsync(writerIds, ct);

        var featuredIds = await paths.Listed()
            .Where(p => p.IsFeatured)
            .OrderBy(p => p.FeaturedOrder).ThenBy(p => p.SortOrder).ThenBy(p => p.Slug)
            .Select(p => p.Id)
            .ToListAsync(ct);
        var featured = await paths.BuildAsync(featuredIds, progressUserId: null, ui, articleLanguage, ct);

        // F23: the articles featured in the console that readers can open, the most recently featured first.
        var featuredArticleIds = await visible
            .Where(a => a.FeaturedAt != null)
            .OrderByDescending(a => a.FeaturedAt).ThenByDescending(a => a.Id)
            .Select(a => a.Id)
            .Take(ExploreLimits.SectionArticles * Spare)
            .ToListAsync(ct);
        var featuredArticles = await rankings.CardsAsync(featuredArticleIds, ui, articleLanguage, viewerId: null, ct);

        return new ExploreSnapshot(
            fields, trending, mostSaved, writers, [.. featured.Take(ExploreLimits.SectionPaths * Spare)], featuredArticles);
    }
}

internal sealed class GetTrendingArticlesQueryHandler(ICurrentUser currentUser, ExploreRankings rankings, ArticleCards cards, PathCards paths)
    : IQueryHandler<GetTrendingArticlesQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetTrendingArticlesQuery query, CancellationToken ct) =>
        await RankedPages.PageAsync(await rankings.TrendingAsync(ct), query.Cursor, query.Limit, query.UiLanguage, currentUser, rankings, cards, paths, ct);
}

internal sealed class GetMostSavedArticlesQueryHandler(ICurrentUser currentUser, ExploreRankings rankings, ArticleCards cards, PathCards paths)
    : IQueryHandler<GetMostSavedArticlesQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetMostSavedArticlesQuery query, CancellationToken ct) =>
        await RankedPages.PageAsync(await rankings.MostSavedAsync(ct), query.Cursor, query.Limit, query.UiLanguage, currentUser, rankings, cards, paths, ct);
}

/// <summary>A page of a cached ranking: the cursor is the position of the next card (<see cref="OffsetCursor"/>).</summary>
internal static class RankedPages
{
    public static async Task<CursorPage<ArticleCardDto>> PageAsync(
        IReadOnlyList<Guid> ranked, string? cursor, int limit, string uiLanguage,
        ICurrentUser currentUser, ExploreRankings rankings, ArticleCards cards, PathCards paths, CancellationToken ct)
    {
        var size = Math.Clamp(limit, 1, ExploreLimits.MaxLimit);
        var offset = Math.Clamp(OffsetCursor.Decode(cursor), 0, ranked.Count);
        var slice = ranked.Skip(offset).Take(size).ToList();

        var viewerId = currentUser.UserId;
        var ui = UiLanguages.Normalize(uiLanguage);
        var articleLanguage = await paths.ArticleLanguageOfAsync(viewerId, ui, ct);
        var page = await rankings.CardsAsync(slice, ui, articleLanguage, viewerId, ct);

        var next = offset + size < ranked.Count ? new OffsetCursor(offset + size).Encode() : null;
        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync(page, ct), next);
    }
}
