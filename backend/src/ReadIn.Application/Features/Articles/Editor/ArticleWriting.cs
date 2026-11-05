using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>Slugs for articles written in the app (F05); tags are <see cref="ReadIn.Application.Features.Tags.ArticleTagging"/>.</summary>
internal static class ArticleWriting
{
    /// <summary>A never-published draft has no reader URL yet; its slug is a private, unique placeholder.</summary>
    public static string PlaceholderSlug() => $"draft-{Guid.NewGuid():N}";

    /// <summary>A slug from <paramref name="title"/>, with -2, -3… when taken (deleted articles included).</summary>
    public static async Task<string> UniqueSlugAsync(IAppDbContext db, string title, CancellationToken ct)
    {
        var baseSlug = SlugGenerator.FromTitle(title);
        if (baseSlug.Length < 3) baseSlug = $"article-{Guid.NewGuid().ToString("N")[..8]}";

        var taken = await db.Articles.IgnoreQueryFilters().AsNoTracking()
            .Where(a => a.Slug.StartsWith(baseSlug))
            .Select(a => a.Slug)
            .ToListAsync(ct);
        if (!taken.Contains(baseSlug)) return baseSlug;

        for (var i = 2; ; i++)
        {
            var candidate = $"{baseSlug}-{i}";
            if (!taken.Contains(candidate)) return candidate;
        }
    }
}
