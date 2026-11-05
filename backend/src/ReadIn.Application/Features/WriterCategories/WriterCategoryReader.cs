using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Profiles;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Features.WriterCategories;

/// <summary>The writer behind a profile URL (SPEC F14 rules: deleted and suspended accounts are not found).</summary>
internal sealed record CategoryOwner(Guid Id, AuthorDto Author);

/// <summary>
/// A writer's categories with their counts (SPEC F31), the same for every caller: every count is of the articles readers
/// can open (published, not deleted, in an enabled field, not hidden by moderators), drafts never. Mutes (F28) don't
/// apply: these pages belong to the one writer the caller opened, like the profile's Articles tab.
/// </summary>
internal sealed class WriterCategoryReader(IAppDbContext db, HybridCache cache)
{
    /// <summary>How long the shared list (the public tab, the page headers) is cached; writes and publishes drop it sooner.</summary>
    public static readonly TimeSpan CacheExpiration = TimeSpan.FromMinutes(5);

    public async Task<CategoryOwner?> FindOwnerAsync(string? username, DateTime now, CancellationToken ct) =>
        ProfileUsers.Handle(username) is { } handle
            ? await db.Users.AsNoTracking()
                .Shown(handle, now)
                .Select(u => new CategoryOwner(u.Id, new AuthorDto(
                    u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified, u.Headline)))
                .FirstOrDefaultAsync(ct)
            : null;

    /// <summary>The articles of <paramref name="ownerId"/> readers can open.</summary>
    public IQueryable<Article> VisibleArticles(Guid ownerId) =>
        db.Articles.AsNoTracking().Visible().Where(a => a.AuthorId == ownerId && a.PublishedAt != null);

    /// <summary>
    /// All of the writer's categories in their order, empty ones included, with <c>SortOrder</c> 1..N, and the count of
    /// their articles without a category. Read fresh.
    /// </summary>
    public async Task<WriterCategoryListDto> LoadAsync(Guid ownerId, CancellationToken ct)
    {
        var visible = VisibleArticles(ownerId);
        var rows = await db.WriterCategories.AsNoTracking()
            .Where(c => c.UserId == ownerId)
            .OrderBy(c => c.SortOrder).ThenBy(c => c.CreatedAt).ThenBy(c => c.Id)
            .Select(c => new { c.Id, c.Slug, c.Name, Count = visible.Count(a => a.WriterCategoryId == c.Id) })
            .ToListAsync(ct);
        var uncategorized = await visible.CountAsync(a => a.WriterCategoryId == null, ct);
        return new WriterCategoryListDto(
            [.. rows.Select((r, index) => new WriterCategoryDto(r.Id, r.Slug, r.Name, r.Count, index + 1))],
            uncategorized);
    }

    /// <summary>
    /// <see cref="LoadAsync"/> from the shared cache: what the public tab and the category page headers show. Dropped by
    /// every category write of the writer (<see cref="CacheTags.WriterCategories"/>), by publish, Update, hide/unhide
    /// and delete (<see cref="CacheTags.Feed"/>), and by a change of the fields (<see cref="CacheTags.Taxonomy"/>: an
    /// article in a disabled field isn't counted).
    /// </summary>
    public async Task<WriterCategoryListDto> CachedAsync(Guid ownerId, CancellationToken ct) =>
        await cache.GetOrCreateAsync(
            $"writer-categories:{ownerId:N}",
            (Reader: this, OwnerId: ownerId),
            static async (state, token) => await state.Reader.LoadAsync(state.OwnerId, token),
            new HybridCacheEntryOptions { Expiration = CacheExpiration, LocalCacheExpiration = CacheExpiration },
            CachedTags(ownerId),
            ct);

    /// <summary>The tags of everything cached for <paramref name="ownerId"/>'s categories.</summary>
    public static string[] CachedTags(Guid ownerId) => [CacheTags.WriterCategories(ownerId), CacheTags.Feed, CacheTags.Taxonomy];

    /// <summary>The slugs of the category's articles, whose cached details carry its name ("في قسم {name}").</summary>
    public Task<List<string>> ArticleSlugsAsync(Guid categoryId, CancellationToken ct) =>
        db.Articles.AsNoTracking().Where(a => a.WriterCategoryId == categoryId).Select(a => a.Slug).ToListAsync(ct);

    /// <summary>Drops the writer's cached category list and pages, and the cached details of <paramref name="articleSlugs"/>.</summary>
    public async Task InvalidateAsync(Guid ownerId, IEnumerable<string> articleSlugs, CancellationToken ct) =>
        await cache.RemoveByTagAsync([CacheTags.WriterCategories(ownerId), .. articleSlugs.Distinct().Select(CacheTags.Article)], ct);
}
