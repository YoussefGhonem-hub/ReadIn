using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Domain.Learning;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #7 (all environments): editorial learning paths (F09) from <c>learningPaths</c> in content/taxonomy.yaml.
/// A path's items are the imported articles whose meta.json names it, in their <c>order</c>; a path without any
/// imported article stays unpublished. Upsert by path slug; paths that admins created (not in the file) are left alone.
/// Version 2 marks the paths editorial, which makes them read-only for admins (F09).
/// </summary>
internal sealed partial class LearningPathsSeeder(AppDbContext db, ContentRepository content, ILogger<LearningPathsSeeder> logger) : ISeeder
{
    public string Name => "learning-paths";
    public int Order => 7;
    public int Version => 2;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        content.HashFilesAsync([content.TaxonomyPath, .. content.ArticleFolders().Select(f => Path.Combine(f, "meta.json"))], cancellationToken);

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var taxonomy = await content.ReadTaxonomyAsync(cancellationToken);
        var fields = await db.Fields.ToDictionaryAsync(f => f.Slug, f => f.Id, cancellationToken);
        var articles = await db.Articles.ToDictionaryAsync(a => a.Slug, a => a.Id, cancellationToken);
        var paths = await db.LearningPaths.Include(p => p.Items).ToDictionaryAsync(p => p.Slug, cancellationToken);

        var members = new List<(string Path, string Slug, int Order)>();
        foreach (var folder in content.ArticleFolders())
        {
            var meta = await content.ReadMetaAsync(folder, cancellationToken);
            if (meta.LearningPath is { } path) members.Add((path.Slug, meta.Slug, path.Order));
        }

        var complete = true;
        var sortOrder = 0;
        foreach (var entry in taxonomy.LearningPaths)
        {
            sortOrder++;
            if (!fields.TryGetValue(entry.Field, out var fieldId))
            {
                LogUnknownField(logger, entry.Slug, entry.Field);
                complete = false;
                continue;
            }

            if (!paths.TryGetValue(entry.Slug, out var path))
            {
                path = LearningPath.CreateEditorial(entry.Slug, fieldId, entry.TitleAr, entry.TitleEn, sortOrder);
                db.LearningPaths.Add(path);
            }
            path.Update(fieldId, entry.TitleAr, entry.TitleEn, entry.DescriptionAr, entry.DescriptionEn, sortOrder);
            path.SyncEditorial([.. members
                .Where(m => m.Path == entry.Slug && articles.ContainsKey(m.Slug))
                .OrderBy(m => m.Order)
                .Select(m => (articles[m.Slug], m.Order))]);
        }

        await db.SaveChangesAsync(cancellationToken);
        return complete;
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Learning path '{Path}' names unknown field '{Field}'")]
    private static partial void LogUnknownField(ILogger logger, string path, string field);
}
