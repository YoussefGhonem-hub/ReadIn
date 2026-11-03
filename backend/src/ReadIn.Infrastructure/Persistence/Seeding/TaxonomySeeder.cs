using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Domain.Taxonomy;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>Seeder #2 (all environments): fields and topics from content/taxonomy.yaml.</summary>
internal sealed class TaxonomySeeder(AppDbContext db, ContentRepository content) : ISeeder
{
    public string Name => "taxonomy";
    public int Order => 2;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        content.HashFilesAsync([content.TaxonomyPath], cancellationToken);

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var taxonomy = await content.ReadTaxonomyAsync(cancellationToken);
        var fields = await db.Fields.Include(f => f.Topics).ToDictionaryAsync(f => f.Slug, cancellationToken);

        var order = 0;
        foreach (var entry in taxonomy.Fields)
        {
            order++;
            if (!fields.TryGetValue(entry.Slug, out var field))
            {
                field = new Field(entry.Slug, entry.NameAr, entry.NameEn, entry.Icon, entry.Color, order);
                db.Fields.Add(field);
            }
            field.Update(entry.NameAr, entry.NameEn, entry.Icon, entry.Color, order, entry.Sensitive, entry.RequiresSources, entry.Enabled);

            var topicOrder = 0;
            foreach (var topic in entry.Topics)
                field.UpsertTopic(topic.Slug, topic.NameAr, topic.NameEn, ++topicOrder);
        }

        // Fields removed from the file are disabled, never deleted (articles may reference them).
        var listed = taxonomy.Fields.Select(f => f.Slug).ToHashSet();
        foreach (var stale in fields.Values.Where(f => !listed.Contains(f.Slug)))
            stale.Update(stale.NameAr, stale.NameEn, stale.Icon, stale.Color, stale.SortOrder, stale.IsSensitive, stale.RequiresSources, isEnabled: false);

        await db.SaveChangesAsync(cancellationToken);
        return true;
    }
}
