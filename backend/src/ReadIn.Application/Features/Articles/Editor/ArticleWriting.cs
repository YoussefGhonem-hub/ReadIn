using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>Slugs and tags for articles written in the app (F05).</summary>
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

    /// <summary>The ids of the tags named <paramref name="names"/>; unknown names become new tags.</summary>
    public static async Task<List<Guid>> UpsertTagsAsync(IAppDbContext db, IReadOnlyList<string> names, CancellationToken ct)
    {
        var bySlug = names
            .Select(n => n.Trim())
            .Where(n => n.Length > 0)
            .GroupBy(Tag.ToSlug)
            .Where(g => g.Key.Length > 0)
            .ToDictionary(g => g.Key, g => g.First());
        var slugs = bySlug.Keys.ToList();

        var existing = await db.Tags.Where(t => slugs.Contains(t.Slug)).ToListAsync(ct);
        foreach (var slug in slugs.Except(existing.Select(t => t.Slug)))
        {
            var tag = new Tag(slug, bySlug[slug]);
            db.Tags.Add(tag);
            existing.Add(tag);
        }
        return [.. existing.Select(t => t.Id)];
    }
}
