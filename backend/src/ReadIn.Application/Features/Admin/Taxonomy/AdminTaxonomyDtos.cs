namespace ReadIn.Application.Features.Admin.Taxonomy;

/// <summary>GET /admin/fields (SPEC F23): every field, disabled ones too, with all topics and the allowed icons and colors.</summary>
public sealed record AdminTaxonomyDto(IReadOnlyList<AdminFieldDto> Fields, IReadOnlyList<string> Icons, IReadOnlyList<string> Colors);

public sealed record AdminFieldDto(
    Guid Id,
    string Slug,
    string NameAr,
    string NameEn,
    string Icon,
    string Color,
    int SortOrder,
    bool IsSensitive,
    bool RequiresSources,
    bool IsEnabled,
    bool InTaxonomyFile,
    DateTime? CustomizedAt,
    int ArticleCount,
    IReadOnlyList<AdminTopicDto> Topics);

public sealed record AdminTopicDto(
    Guid Id,
    Guid FieldId,
    string Slug,
    string NameAr,
    string NameEn,
    int SortOrder,
    bool IsEnabled,
    bool InTaxonomyFile,
    DateTime? CustomizedAt,
    int ArticleCount);

/// <summary>Body of POST /admin/fields.</summary>
public sealed record CreateFieldRequest(
    string? Slug, string? NameAr, string? NameEn, string? Icon, string? Color, bool IsSensitive, bool RequiresSources, bool IsEnabled);

/// <summary>Body of PUT /admin/fields/{id}: the whole row but the slug.</summary>
public sealed record UpdateFieldRequest(
    string? NameAr, string? NameEn, string? Icon, string? Color, bool IsSensitive, bool RequiresSources, bool IsEnabled);

/// <summary>Body of POST /admin/topics.</summary>
public sealed record CreateTopicRequest(Guid FieldId, string? Slug, string? NameAr, string? NameEn, bool IsEnabled);

/// <summary>Body of PUT /admin/topics/{id}.</summary>
public sealed record UpdateTopicRequest(string? NameAr, string? NameEn, bool IsEnabled);

/// <summary>Body of PUT /admin/fields/order and PUT /admin/fields/{id}/topics/order: every item once, in display order.</summary>
public sealed record OrderRequest(IReadOnlyList<Guid>? Ids);

/// <summary>
/// The icons and colors a field may have (SPEC F23): the Lucide names and color tokens both clients draw. One list on the
/// server; the console's pickers show these.
/// </summary>
public static class FieldStyles
{
    public static readonly IReadOnlyList<string> Icons =
    [
        "atom", "binary", "book-open", "bot", "boxes", "brain", "brain-circuit", "briefcase", "cloud", "code", "code-xml", "coffee",
        "cog", "cpu", "database", "flask-conical", "git-branch", "graduation-cap", "heart-pulse", "landmark", "layers",
        "layout-dashboard", "layout-template", "monitor", "network", "palette", "scale", "server", "shield", "shield-check",
        "smartphone", "sparkles", "sprout", "stethoscope", "trophy", "wrench",
    ];

    public static readonly IReadOnlyList<string> Colors =
    [
        "primary", "accent", "success", "callout-tip-accent", "callout-info-accent", "callout-warning-accent", "callout-danger-accent",
    ];
}

/// <summary>The slugs listed in <c>content/taxonomy.yaml</c>, for <c>inTaxonomyFile</c> (SPEC §18).</summary>
public sealed record ContentTaxonomySlugs(IReadOnlySet<string> Fields, IReadOnlySet<(string Field, string Topic)> Topics)
{
    public static readonly ContentTaxonomySlugs Empty = new(new HashSet<string>(), new HashSet<(string, string)>());
}

/// <summary>Reads which fields and topics the content's taxonomy file lists (Infrastructure: the content folder).</summary>
public interface IContentTaxonomy
{
    Task<ContentTaxonomySlugs> ReadSlugsAsync(CancellationToken cancellationToken);
}
