using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Editor;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Tags;

/// <summary>
/// GET /tags?q=: the editor's suggestions (SPEC F32). A tag matches when a word of its normalized name starts with the
/// normalized <see cref="Query"/>, or its slug starts with the query's slug. The exact match first, then the most used.
/// Hidden tags are never suggested. Cached briefly; a publish or a hide refreshes the counts.
/// </summary>
public sealed record SearchTagsQuery(string? Query, int Limit) : IQuery<Result<IReadOnlyList<TagDto>>>, ICachedQuery
{
    public const int MaxLimit = 20;

    public string CacheKey => $"tags:search:{TagNames.Normalize(TagNames.Clean(Query))}:{Math.Clamp(Limit, 1, MaxLimit)}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Tags, Common.Behaviors.CacheTags.Feed];
    public TimeSpan Expiration => TimeSpan.FromMinutes(5);
}

/// <summary>GET /tags/{slug}: the tag page's header (SPEC F32). <c>tag.not_found</c> for an unknown or hidden tag.</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetTagQuery(string Slug) : IQuery<Result<TagDto>>, ICachedQuery
{
    public string CacheKey => $"tag:{TagSlugs.FromRoute(Slug)}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Tags, Common.Behaviors.CacheTags.Feed];
    public TimeSpan Expiration => TimeSpan.FromMinutes(10);
}

/// <summary>
/// GET /tags/{slug}/articles: every published article with the tag, from all writers, newest first, as feed cards
/// (SPEC F32, F34), keyset-paginated over (PublishedAt DESC, Id DESC). Guests get a cached page (server rendering);
/// a signed-in caller's page leaves out what they muted or marked "show less" (F28).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetTagArticlesQuery(string Slug, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<ArticleCardDto>>>
{
    public const int MaxLimit = 50;
}

internal static class TagSlugs
{
    /// <summary>Slugs are lower case; a route value is trimmed and lower-cased before the lookup.</summary>
    public static string FromRoute(string? slug) => (slug ?? string.Empty).Trim().ToLowerInvariant();

    /// <summary>Published articles readers can see (SPEC F22) that carry <paramref name="tagId"/>.</summary>
    public static IQueryable<Domain.Articles.Article> ArticlesWith(IAppDbContext db, Guid tagId) =>
        db.Articles.AsNoTracking().Visible().Where(a => a.PublishedAt != null && a.Tags.Any(t => t.TagId == tagId));
}

internal sealed class SearchTagsQueryHandler(IAppDbContext db) : IQueryHandler<SearchTagsQuery, Result<IReadOnlyList<TagDto>>>
{
    public async ValueTask<Result<IReadOnlyList<TagDto>>> Handle(SearchTagsQuery query, CancellationToken cancellationToken)
    {
        var cleaned = TagNames.Clean(query.Query);
        if (cleaned.Length > TagNames.MaxLength) return Array.Empty<TagDto>();
        var key = TagNames.Normalize(cleaned);

        var tags = db.Tags.AsNoTracking().Where(t => !t.IsHidden);
        if (key.Length > 0)
        {
            // A word starts at the beginning or after a space, "-", "_" or ".".
            string afterSpace = " " + key, afterDash = "-" + key, afterUnderscore = "_" + key, afterDot = "." + key;
            var slug = TagNames.SlugText(cleaned);
            tags = tags.Where(t => t.NormalizedName.StartsWith(key)
                || t.NormalizedName.Contains(afterSpace) || t.NormalizedName.Contains(afterDash)
                || t.NormalizedName.Contains(afterUnderscore) || t.NormalizedName.Contains(afterDot)
                || (slug.Length > 0 && t.Slug.StartsWith(slug)));
        }

        // Hidden and deleted articles count for nothing, like everywhere readers look.
        var published = db.Articles.Visible();
        var found = await tags
            .Select(t => new { t.Slug, t.Name, Exact = t.NormalizedName == key, Count = published.Count(a => a.Tags.Any(x => x.TagId == t.Id)) })
            .OrderByDescending(t => t.Exact).ThenByDescending(t => t.Count).ThenBy(t => t.Name)
            .Take(Math.Clamp(query.Limit, 1, SearchTagsQuery.MaxLimit))
            .ToListAsync(cancellationToken);

        return found.Select(t => new TagDto(t.Slug, t.Name, t.Count)).ToList();
    }
}

internal sealed class GetTagQueryHandler(IAppDbContext db) : IQueryHandler<GetTagQuery, Result<TagDto>>
{
    public async ValueTask<Result<TagDto>> Handle(GetTagQuery query, CancellationToken cancellationToken)
    {
        var slug = TagSlugs.FromRoute(query.Slug);
        var tag = await db.Tags.AsNoTracking()
            .Where(t => t.Slug == slug && !t.IsHidden)
            .Select(t => new { t.Id, t.Slug, t.Name })
            .FirstOrDefaultAsync(cancellationToken);
        if (tag is null) return TaxonomyErrors.TagNotFound;

        var count = await TagSlugs.ArticlesWith(db, tag.Id).CountAsync(cancellationToken);
        return new TagDto(tag.Slug, tag.Name, count);
    }
}

internal sealed class GetTagArticlesQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    HybridCache cache)
    : IQueryHandler<GetTagArticlesQuery, Result<CursorPage<ArticleCardDto>>>
{
    private static readonly TimeSpan GuestPageExpiration = TimeSpan.FromMinutes(5);

    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetTagArticlesQuery query, CancellationToken ct)
    {
        var slug = TagSlugs.FromRoute(query.Slug);
        var tagId = await db.Tags.AsNoTracking()
            .Where(t => t.Slug == slug && !t.IsHidden)
            .Select(t => (Guid?)t.Id)
            .FirstOrDefaultAsync(ct);
        if (tagId is not { } id) return TaxonomyErrors.TagNotFound;

        var limit = Math.Clamp(query.Limit, 1, GetTagArticlesQuery.MaxLimit);
        var cursor = TimeCursor.Decode(query.Cursor);
        CursorPage<ArticleCardDto> page;
        if (currentUser.UserId is { } viewerId)
        {
            var articleLanguage = await db.Users.AsNoTracking()
                .Where(u => u.Id == viewerId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct);
            page = await LoadAsync(id, cursor, limit, query.UiLanguage, articleLanguage, viewerId, ct);
        }
        else
        {
            // The same for every guest (and the web's server rendering): cached, and refreshed by publish, Update,
            // hide/unhide and delete (CacheTags.Feed).
            var articleLanguage = ArticleLanguages.ForUi(query.UiLanguage);
            page = await cache.GetOrCreateAsync(
                $"tag-articles:{id:N}:{cursor?.Encode() ?? "-"}:{limit}:{query.UiLanguage}:{articleLanguage}",
                (Handler: this, Id: id, Cursor: cursor, Limit: limit, Ui: query.UiLanguage, Lang: articleLanguage),
                static async (state, token) =>
                    await state.Handler.LoadAsync(state.Id, state.Cursor, state.Limit, state.Ui, state.Lang, viewerId: null, token),
                new HybridCacheEntryOptions { Expiration = GuestPageExpiration, LocalCacheExpiration = GuestPageExpiration },
                [CacheTags.Tags, CacheTags.Feed],
                ct);
        }

        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync(page.Items, ct), page.NextCursor);
    }

    /// <summary>One page of cards as SQL projects them, before the viewer's own state is added.</summary>
    private async Task<CursorPage<ArticleCardDto>> LoadAsync(
        Guid tagId, TimeCursor? cursor, int limit, string uiLanguage, string? articleLanguage, Guid? viewerId, CancellationToken ct)
    {
        var articles = TagSlugs.ArticlesWith(db, tagId).WithoutMutedFor(db, viewerId).WithoutShownLessFor(db, viewerId);
        if (cursor is { } after)
        {
            articles = articles.Where(a =>
                a.PublishedAt < after.Timestamp ||
                (a.PublishedAt == after.Timestamp && a.Id.CompareTo(after.Id) < 0));
        }

        List<ArticleCardDto> items;
        using (LocalizedProjection.Begin(uiLanguage, articleLanguage))
        {
            items = await articles
                .OrderByDescending(a => a.PublishedAt)
                .ThenByDescending(a => a.Id)
                .Take(limit + 1)
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct);
        }

        string? next = null;
        if (items.Count > limit)
        {
            items.RemoveAt(limit);
            var last = items[^1];
            next = new TimeCursor(last.PublishedAt!.Value, last.Id).Encode();
        }
        return new CursorPage<ArticleCardDto>(items, next);
    }
}
