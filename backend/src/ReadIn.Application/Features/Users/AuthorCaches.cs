using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Features.Users;

/// <summary>
/// Drops what is cached with a writer's name, @username, avatar or title in it (SPEC F14: "it always shows the writer's
/// current title"): the reader pages and card previews of their articles, the cached lists of cards (Explore, field and
/// tag pages, guests' search; <see cref="CacheTags.Feed"/>) and their category pages. Profiles and comments aren't cached.
/// </summary>
public sealed class AuthorCaches(IAppDbContext db, HybridCache cache)
{
    public async Task DropAsync(Guid userId, CancellationToken ct)
    {
        var articles = await db.Articles.IgnoreQueryFilters().AsNoTracking()
            .Where(a => a.AuthorId == userId)
            .Select(a => new { a.Id, a.Slug })
            .ToListAsync(ct);
        articles = [.. articles.Where(a => !string.IsNullOrEmpty(a.Slug))];

        await cache.RemoveByTagAsync(
            [
                CacheTags.Feed,
                CacheTags.WriterCategories(userId),
                .. articles.Select(a => CacheTags.Article(a.Slug)),
                .. articles.Select(a => CacheTags.ArticleById(a.Id)),
            ],
            ct);
    }
}
