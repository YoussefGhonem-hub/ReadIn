using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Features.Tags;
using ReadIn.Application.Features.WriterCategories;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Demo data only, so local databases never miss it and production never gets it (SPEC F31, §18.1): some demo writers
/// group their demo articles into categories, so the Categories tab, the category pages and the reader's
/// "في قسم {name}" are visible in development. writer1 also has an empty category (only writer1 sees it), and writer2
/// keeps an article without a category ("مقالات تانية"); writer3 has none. Runs after the demo writers and media, which
/// publish these articles. Idempotent: categories are matched by name, articles by slug and author.
/// </summary>
internal sealed class DemoCategoriesSeeder(AppDbContext db, TimeProvider clock) : ISeeder
{
    /// <param name="ArticleSlugs">The writer's articles that go in it (missing ones are skipped).</param>
    internal sealed record Plan(string Handle, string Name, string[] ArticleSlugs);

    internal static readonly Plan[] Plans =
    [
        new("writer1", "ورش Angular", ["demo-media-angular-workshop"]),
        new("writer1", "TypeScript", []),
        new("writer.verified", "Cheat sheets", ["demo-media-clean-architecture-pdf"]),
        new("writer2", "قواعد البيانات", ["demo-writers-covering-indexes"]),
        new("reviewer.ai", "RAG", ["demo-writers-rag-retrieval-first"]),
        new("reviewer.ai", "Prompt engineering", ["demo-writers-prompt-examples"]),
    ];

    public string Name => "demo-categories";
    public int Order => 15;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        [.. Plans.Select(p => $"{p.Handle}|{p.Name}|{string.Join(',', p.ArticleSlugs)}")]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var emails = Plans.Select(p => $"{p.Handle}@readin.test").Distinct().ToList();
        var writers = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email) && !u.IsSystemAccount)
            .ToDictionaryAsync(u => u.Email!.Replace("@readin.test", string.Empty), u => u.Id, cancellationToken);

        foreach (var group in Plans.GroupBy(p => p.Handle))
        {
            if (!writers.TryGetValue(group.Key, out var writerId)) continue;
            var categories = await db.WriterCategories.Where(c => c.UserId == writerId).ToListAsync(cancellationToken);

            var assigned = new List<(WriterCategory Category, string[] Slugs)>();
            foreach (var (plan, position) in group.Select((p, i) => (p, i)))
            {
                var name = WriterCategoryNames.Clean(plan.Name);
                var key = WriterCategoryNames.Normalize(name);
                var category = categories.FirstOrDefault(c => c.NormalizedName == key);
                if (category is null)
                {
                    var slug = TagNames.UniqueSlug(WriterCategoryNames.SlugBase(name), categories.Select(c => c.Slug).ToHashSet(StringComparer.Ordinal));
                    category = new WriterCategory(writerId, name, key, slug, position + 1, now);
                    db.WriterCategories.Add(category);
                    categories.Add(category);
                }
                else
                {
                    category.MoveTo(position + 1);
                }
                assigned.Add((category, plan.ArticleSlugs));
            }
            await db.SaveChangesAsync(cancellationToken);

            foreach (var (category, slugs) in assigned.Where(a => a.Slugs.Length > 0))
            {
                await db.Articles
                    .Where(a => a.AuthorId == writerId && slugs.Contains(a.Slug))
                    .ExecuteUpdateAsync(s => s.SetProperty(a => a.WriterCategoryId, category.Id), cancellationToken);
            }
        }
        return true;
    }
}
