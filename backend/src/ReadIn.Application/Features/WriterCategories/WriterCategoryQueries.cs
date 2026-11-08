using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.WriterCategories;

/// <summary>
/// GET /users/{username}/categories: the profile's Categories tab (SPEC F31). The categories with at least one article
/// readers can see, in the writer's order, and how many of those articles have no category ("مقالات تانية"). The same
/// for everyone; the writer's own tab uses <see cref="GetMyCategoriesQuery"/>.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetWriterCategoriesQuery(string Username) : IQuery<Result<WriterCategoryListDto>>;

/// <summary>GET /me/categories: all of your categories in your order, empty ones included (the manage view and the editor's picker).</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record GetMyCategoriesQuery : IQuery<Result<WriterCategoryListDto>>;

/// <summary>
/// GET /users/{username}/categories/{slug}: the category page's header. An empty category answers too; the reserved
/// slug <see cref="WriterCategoryLimits.OtherSlug"/> is the uncategorized list, with no id and no name.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetWriterCategoryQuery(string Username, string Slug) : IQuery<Result<WriterCategoryPageDto>>;

/// <summary>
/// GET /users/{username}/categories/{slug}/articles: the category's articles readers can see, newest first, as feed cards
/// (SPEC F31, F34), keyset-paginated over (PublishedAt DESC, Id DESC). Guests get a cached page (server rendering).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetWriterCategoryArticlesQuery(string Username, string Slug, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<ArticleCardDto>>>;

internal static class CategorySlugs
{
    /// <summary>Slugs are lower case; a route value is trimmed and lower-cased before the lookup.</summary>
    public static string FromRoute(string? slug) => (slug ?? string.Empty).Trim().ToLowerInvariant();

    /// <summary>
    /// The category <paramref name="slug"/> names in <paramref name="list"/>: <c>(null, true)</c> for the uncategorized list,
    /// <c>(category, true)</c> for one of the writer's categories, <c>(null, false)</c> when there is none.
    /// </summary>
    public static (WriterCategoryDto? Category, bool Found) Find(WriterCategoryListDto list, string slug) =>
        slug == WriterCategoryLimits.OtherSlug
            ? (null, true)
            : list.Items.FirstOrDefault(c => c.Slug == slug) is { } category ? (category, true) : (null, false);
}

internal sealed class GetWriterCategoriesQueryHandler(
    WriterCategoryReader reader, ICurrentUser currentUser, BlockRelations blocks, TimeProvider clock)
    : IQueryHandler<GetWriterCategoriesQuery, Result<WriterCategoryListDto>>
{
    public async ValueTask<Result<WriterCategoryListDto>> Handle(GetWriterCategoriesQuery query, CancellationToken ct)
    {
        if (await reader.FindOwnerAsync(query.Username, clock.GetUtcNow().UtcDateTime, ct) is not { } owner) return UserErrors.NotFound;
        if (await blocks.DirectLinkErrorAsync(currentUser, owner.Id, UserErrors.NotFound, ct) is { } blocked) return blocked;

        var list = await reader.CachedAsync(owner.Id, ct);
        return list with { Items = [.. list.Items.Where(c => c.ArticleCount > 0)] };
    }
}

internal sealed class GetMyCategoriesQueryHandler(WriterCategoryReader reader, ICurrentUser currentUser)
    : IQueryHandler<GetMyCategoriesQuery, Result<WriterCategoryListDto>>
{
    public async ValueTask<Result<WriterCategoryListDto>> Handle(GetMyCategoriesQuery query, CancellationToken ct) =>
        await reader.LoadAsync(currentUser.RequireUserId(), ct);
}

internal sealed class GetWriterCategoryQueryHandler(
    WriterCategoryReader reader, IFileStorage storage, ICurrentUser currentUser, BlockRelations blocks, TimeProvider clock)
    : IQueryHandler<GetWriterCategoryQuery, Result<WriterCategoryPageDto>>
{
    public async ValueTask<Result<WriterCategoryPageDto>> Handle(GetWriterCategoryQuery query, CancellationToken ct)
    {
        if (await reader.FindOwnerAsync(query.Username, clock.GetUtcNow().UtcDateTime, ct) is not { } owner) return UserErrors.NotFound;
        if (await blocks.DirectLinkErrorAsync(currentUser, owner.Id, UserErrors.NotFound, ct) is { } blocked) return blocked;

        var list = await reader.CachedAsync(owner.Id, ct);
        var slug = CategorySlugs.FromRoute(query.Slug);
        var (category, found) = CategorySlugs.Find(list, slug);
        if (!found) return WriterCategoryErrors.NotFound;

        var author = owner.Author with { AvatarUrl = storage.ToPublicUrl(owner.Author.AvatarUrl) };
        return category is null
            ? new WriterCategoryPageDto(null, WriterCategoryLimits.OtherSlug, null, list.UncategorizedCount, author)
            : new WriterCategoryPageDto(category.Id, category.Slug, category.Name, category.ArticleCount, author);
    }
}

internal sealed class GetWriterCategoryArticlesQueryHandler(
    IAppDbContext db,
    WriterCategoryReader reader,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    HybridCache cache,
    BlockRelations blocks,
    TimeProvider clock)
    : IQueryHandler<GetWriterCategoryArticlesQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetWriterCategoryArticlesQuery query, CancellationToken ct)
    {
        if (await reader.FindOwnerAsync(query.Username, clock.GetUtcNow().UtcDateTime, ct) is not { } owner) return UserErrors.NotFound;
        if (await blocks.DirectLinkErrorAsync(currentUser, owner.Id, UserErrors.NotFound, ct) is { } blocked) return blocked;

        var slug = CategorySlugs.FromRoute(query.Slug);
        var (category, found) = CategorySlugs.Find(await reader.CachedAsync(owner.Id, ct), slug);
        if (!found) return WriterCategoryErrors.NotFound;

        var categoryId = category?.Id;
        var limit = Math.Clamp(query.Limit, 1, WriterCategoryLimits.MaxLimit);
        var cursor = TimeCursor.Decode(query.Cursor);
        CursorPage<ArticleCardDto> page;
        if (currentUser.UserId is { } viewerId)
        {
            var articleLanguage = await db.Users.AsNoTracking()
                .Where(u => u.Id == viewerId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct);
            page = await LoadAsync(owner.Id, categoryId, cursor, limit, query.UiLanguage, articleLanguage, ct);
        }
        else
        {
            // The same for every guest (and the web's server rendering): cached, and dropped by the writer's category
            // writes, by publish, Update, hide/unhide and delete, and by a change of the fields.
            var articleLanguage = ArticleLanguages.ForUi(query.UiLanguage);
            page = await cache.GetOrCreateAsync(
                $"writer-category-articles:{owner.Id:N}:{categoryId?.ToString("N") ?? WriterCategoryLimits.OtherSlug}:{cursor?.Encode() ?? "-"}:{limit}:{query.UiLanguage}:{articleLanguage}",
                (Handler: this, OwnerId: owner.Id, CategoryId: categoryId, Cursor: cursor, Limit: limit, Ui: query.UiLanguage, Lang: articleLanguage),
                static async (state, token) =>
                    await state.Handler.LoadAsync(state.OwnerId, state.CategoryId, state.Cursor, state.Limit, state.Ui, state.Lang, token),
                new HybridCacheEntryOptions { Expiration = WriterCategoryReader.CacheExpiration, LocalCacheExpiration = WriterCategoryReader.CacheExpiration },
                WriterCategoryReader.CachedTags(owner.Id),
                ct);
        }

        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync(page.Items, ct), page.NextCursor);
    }

    /// <summary>One page of cards as SQL projects them, before the viewer's own state is added.</summary>
    private async Task<CursorPage<ArticleCardDto>> LoadAsync(
        Guid ownerId, Guid? categoryId, TimeCursor? cursor, int limit, string uiLanguage, string? articleLanguage, CancellationToken ct)
    {
        var articles = reader.VisibleArticles(ownerId).Where(a => a.WriterCategoryId == categoryId);
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
