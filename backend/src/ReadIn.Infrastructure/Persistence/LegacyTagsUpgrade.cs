using System.Reflection;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Migrations;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Taxonomy;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Infrastructure.Persistence;

/// <summary>
/// Brings tags made before F32 to its rules, once, at startup right after the migrations (SPEC F32). The <c>Tags</c>
/// migration marks those rows with a placeholder <c>NormalizedName</c> and <c>Slug</c> (<see cref="Marker"/> + id); this
/// step gives each one its cleaned name, normalized name and a URL-safe slug, flags the tags the seed content uses as
/// system tags (the others belong to the writer of their first article), and merges tags that are now one tag (e.g.
/// "Lazy loading" and "Lazy Loading") into the oldest, whose spelling stays. It is done in C# because the rules live in
/// <see cref="TagNames"/>, and it runs before the app serves requests (and before seeding): after the migrations of the
/// <c>seed</c> command, ContentStudio and <c>Database:MigrateOnStartup</c>, and at every other API start, which covers
/// migrations applied as a SQL script or a bundle (<see cref="RunIfMigratedAsync"/>).
/// </summary>
public static class LegacyTagsUpgrade
{
    /// <summary>Starts the placeholder the migration writes; no normalized name or slug can start with it.</summary>
    public const string Marker = "~";

    /// <summary>The migration that writes the placeholders (and adds the columns this step reads).</summary>
    private static readonly string MigrationId = typeof(Migrations.Tags).GetCustomAttribute<MigrationAttribute>()!.Id;

    /// <summary>
    /// <see cref="RunAsync"/> once the <c>Tags</c> migration is applied (before that there is nothing to upgrade, and the
    /// columns it reads don't exist yet). Two small queries when everything is done.
    /// </summary>
    public static async Task<int> RunIfMigratedAsync(AppDbContext db, CancellationToken cancellationToken) =>
        (await db.Database.GetAppliedMigrationsAsync(cancellationToken)).Contains(MigrationId)
            ? await RunAsync(db, cancellationToken)
            : 0;

    /// <returns>How many tags were upgraded (merged ones included); 0 once done.</returns>
    public static async Task<int> RunAsync(AppDbContext db, CancellationToken cancellationToken)
    {
        if (!await db.Tags.AnyAsync(t => t.NormalizedName.StartsWith(Marker), cancellationToken)) return 0;

        var strategy = db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async ct =>
        {
            db.ChangeTracker.Clear(); // a retried attempt starts from a clean slate
            await using var transaction = await db.Database.BeginTransactionAsync(ct);

            // Oldest first: the first spelling of a tag is the one that stays.
            var tags = await db.Tags.OrderBy(t => t.CreatedAt).ThenBy(t => t.Id).ToListAsync(ct);
            var legacy = tags.Where(t => t.NormalizedName.StartsWith(Marker, StringComparison.Ordinal)).ToList();
            var current = tags.Except(legacy).ToDictionary(t => t.NormalizedName, StringComparer.Ordinal);
            var slugs = current.Values.Select(t => t.Slug).ToHashSet(StringComparer.OrdinalIgnoreCase);

            var uses = (await db.Articles.IgnoreQueryFilters()
                    .SelectMany(a => a.Tags.Select(x => new { x.TagId, a.AuthorId, a.CreatedAt }))
                    .ToListAsync(ct))
                .GroupBy(u => u.TagId)
                .ToDictionary(g => g.Key, g => g.OrderBy(u => u.CreatedAt).ToList());

            foreach (var tag in legacy)
            {
                var name = TagNames.Clean(tag.Name) is { Length: > 0 } cleaned ? cleaned : tag.Name.Trim();
                var key = TagNames.Normalize(name) is { Length: > 0 } normalized ? normalized : name.ToLowerInvariant();
                var used = uses.GetValueOrDefault(tag.Id) ?? [];
                var isSystem = used.Any(u => u.AuthorId == SystemUsers.EditorialId);

                if (current.TryGetValue(key, out var into))
                {
                    await MergeAsync(db, tag.Id, into.Id, ct);
                    if (isSystem) into.MarkSystem();
                    db.Tags.Remove(tag);
                    continue;
                }

                var slug = TagNames.UniqueSlug(TagNames.SlugBase(name), slugs);
                slugs.Add(slug);
                tag.Upgrade(name, key, slug, isSystem, used.Select(u => u.AuthorId).FirstOrDefault(id => id is not null));
                current[key] = tag;
            }

            await db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);
            return legacy.Count;
        }, cancellationToken);
    }

    /// <summary>Moves the article links of <paramref name="from"/> to <paramref name="into"/> (an article keeps one of each).</summary>
    private static async Task MergeAsync(AppDbContext db, Guid from, Guid into, CancellationToken ct)
    {
        await db.Database.ExecuteSqlAsync($"""
            UPDATE [at] SET [TagId] = {into}
            FROM [ArticleTags] AS [at]
            WHERE [at].[TagId] = {from}
              AND NOT EXISTS (SELECT 1 FROM [ArticleTags] AS [x] WHERE [x].[ArticleId] = [at].[ArticleId] AND [x].[TagId] = {into})
            """, ct);
        await db.Database.ExecuteSqlAsync($"DELETE FROM [ArticleTags] WHERE [TagId] = {from}", ct);
    }
}
