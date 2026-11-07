using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles.Editor;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Tags;

/// <summary>
/// Tags on articles (SPEC F32): the editor's live tag checks and turning names into tags when an article goes live.
/// Names are compared by <see cref="TagNames.Normalize"/>d form, so the first spelling of a tag stays.
/// </summary>
public sealed class ArticleTagging(IAppDbContext db, TimeProvider clock)
{
    /// <summary>
    /// The live checks of the editor's tag names (<paramref name="names"/> as stored): <c>tag.hidden</c> for a hidden tag
    /// the published article doesn't have already, and <c>tag.limit</c> for the new names past what is left of the
    /// writer's <see cref="TagNames.MaxNewPerWindow"/> in <see cref="TagNames.NewTagWindow"/>, in document order.
    /// </summary>
    public async Task<IReadOnlyList<DraftProblemDto>> CheckAsync(
        Guid articleId, Guid authorId, IReadOnlyList<string> names, CancellationToken cancellationToken)
    {
        var keyed = Keyed(names);
        if (keyed.Count == 0) return [];

        var keys = keyed.Select(k => k.Key).ToList();
        var existing = await db.Tags.AsNoTracking()
            .Where(t => keys.Contains(t.NormalizedName))
            .Select(t => new { t.Id, t.NormalizedName, t.IsHidden })
            .ToDictionaryAsync(t => t.NormalizedName, StringComparer.Ordinal, cancellationToken);
        // An alias (a renamed tag's old spelling, a merged tag's name, F23) is an existing name: its tag, and its hidden state.
        var unknown = keys.Where(k => !existing.ContainsKey(k)).ToList();
        if (unknown.Count > 0)
        {
            var aliased = await db.TagAliases.AsNoTracking()
                .Where(a => unknown.Contains(a.NormalizedName))
                .Join(db.Tags.AsNoTracking(), a => a.TagId, t => t.Id, (a, t) => new { a.NormalizedName, t.Id, t.IsHidden })
                .ToListAsync(cancellationToken);
            foreach (var alias in aliased) existing[alias.NormalizedName] = new { alias.Id, alias.NormalizedName, alias.IsHidden };
        }

        var problems = new List<DraftProblemDto>();
        if (existing.Values.Any(t => t.IsHidden))
        {
            // Tags go on an article when it is published, so these are the tags readers had before.
            var current = await db.Articles.AsNoTracking()
                .Where(a => a.Id == articleId)
                .SelectMany(a => a.Tags.Select(t => t.TagId))
                .ToListAsync(cancellationToken);
            problems.AddRange(keyed
                .Where(k => existing.TryGetValue(k.Key, out var tag) && tag.IsHidden && !current.Contains(tag.Id))
                .Select(k => new DraftProblemDto(TaxonomyErrors.TagHidden.Code, Tag: k.Name)));
        }

        var fresh = keyed.Where(k => !existing.ContainsKey(k.Key)).ToList();
        if (fresh.Count == 0) return problems;

        var since = clock.GetUtcNow().UtcDateTime - TagNames.NewTagWindow;
        var created = await db.Tags.CountAsync(t => t.CreatedById == authorId && t.CreatedAt > since, cancellationToken);
        var allowance = Math.Max(0, TagNames.MaxNewPerWindow - created);
        problems.AddRange(fresh.Skip(allowance).Select(k => new DraftProblemDto(TaxonomyErrors.TagLimit.Code, Tag: k.Name)));
        return problems;
    }

    /// <summary>
    /// The ids of the tags named <paramref name="names"/>, in order; a missing tag is created. <paramref name="createdById"/>
    /// is the writer, or null for the seed content, which makes every tag it uses a system tag.
    /// </summary>
    public async Task<List<Guid>> ResolveAsync(IReadOnlyList<string> names, Guid? createdById, CancellationToken cancellationToken)
    {
        var ids = new List<Guid>();
        var now = clock.GetUtcNow().UtcDateTime;
        foreach (var (name, key) in Keyed(names))
        {
            var tag = db.Tags.Local.FirstOrDefault(t => t.NormalizedName == key)
                ?? await db.Tags.FirstOrDefaultAsync(t => t.NormalizedName == key, cancellationToken)
                ?? await AliasedAsync(key, cancellationToken);
            if (tag is null)
            {
                tag = new Tag(name, key, await UniqueSlugAsync(name, cancellationToken), createdById, now);
                db.Tags.Add(tag);
            }
            else if (createdById is null && !tag.IsSystem)
            {
                tag.MarkSystem();
            }
            if (!ids.Contains(tag.Id)) ids.Add(tag.Id);
        }
        return ids;
    }

    /// <summary>The tag an alias leads to (SPEC F23: a renamed tag's old spelling, a merged tag's name); null when none.</summary>
    private async Task<Tag?> AliasedAsync(string key, CancellationToken cancellationToken)
    {
        var tagId = await db.TagAliases.AsNoTracking()
            .Where(a => a.NormalizedName == key)
            .Select(a => (Guid?)a.TagId)
            .FirstOrDefaultAsync(cancellationToken);
        if (tagId is not { } id) return null;
        return db.Tags.Local.FirstOrDefault(t => t.Id == id) ?? await db.Tags.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
    }

    /// <summary>
    /// A free slug for a new tag named <paramref name="name"/>, counting tags added but not saved yet and the slugs merged
    /// tags left behind (they still open the tag they went into, F23).
    /// </summary>
    private async Task<string> UniqueSlugAsync(string name, CancellationToken cancellationToken)
    {
        var slugBase = TagNames.SlugBase(name);
        var prefix = slugBase + "-";
        var taken = await db.Tags.AsNoTracking()
            .Where(t => t.Slug == slugBase || t.Slug.StartsWith(prefix))
            .Select(t => t.Slug)
            .ToListAsync(cancellationToken);
        taken.AddRange(await db.TagAliases.AsNoTracking()
            .Where(a => a.Slug != null && (a.Slug == slugBase || a.Slug.StartsWith(prefix)))
            .Select(a => a.Slug!)
            .ToListAsync(cancellationToken));
        return TagNames.UniqueSlug(slugBase, taken.Concat(db.Tags.Local.Select(t => t.Slug)).ToHashSet(StringComparer.OrdinalIgnoreCase));
    }

    /// <summary>Cleaned names with their normalized key; empty ones and repeats of the same tag dropped.</summary>
    private static List<(string Name, string Key)> Keyed(IReadOnlyList<string> names) =>
        [.. TagNames.Distinct(names).Select(n => (n, TagNames.Normalize(n))).Where(k => k.Item2.Length > 0)];
}
