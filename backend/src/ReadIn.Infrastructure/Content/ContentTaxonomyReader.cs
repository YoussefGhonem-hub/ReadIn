using ReadIn.Application.Features.Admin.Taxonomy;

namespace ReadIn.Infrastructure.Content;

/// <summary>
/// Which fields and topics <c>content/taxonomy.yaml</c> lists (SPEC §18, F23 <c>inTaxonomyFile</c>). Read on each call: the
/// console asks rarely, and the file only changes with a deploy. A missing file, or no <c>content/</c> folder at all
/// (production), lists nothing.
/// </summary>
internal sealed class ContentTaxonomyReader(ContentRepository content) : IContentTaxonomy
{
    public async Task<ContentTaxonomySlugs> ReadSlugsAsync(CancellationToken cancellationToken)
    {
        if (content.RootOrNull is null || !File.Exists(content.TaxonomyPath)) return ContentTaxonomySlugs.Empty;

        var taxonomy = await content.ReadTaxonomyAsync(cancellationToken);
        return new ContentTaxonomySlugs(
            taxonomy.Fields.Select(f => f.Slug).ToHashSet(StringComparer.Ordinal),
            taxonomy.Fields.SelectMany(f => f.Topics.Select(t => (f.Slug, t.Slug))).ToHashSet());
    }
}
