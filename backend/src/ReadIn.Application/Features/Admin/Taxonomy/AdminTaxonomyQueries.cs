using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Admin.Taxonomy;

/// <summary>
/// GET /admin/fields (SPEC F23, <c>taxonomy.manage</c>): every field, disabled ones too, in display order, each with all its
/// topics, plus the icons and colors the clients draw. Not cached: an admin screen right after its own edits.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record GetAdminTaxonomyQuery : IQuery<Result<AdminTaxonomyDto>>;

/// <summary>Builds the console's field and topic rows: names in both languages, the taxonomy file's slugs and article counts.</summary>
internal sealed class AdminTaxonomyReader(IAppDbContext db, IContentTaxonomy content)
{
    public async Task<IReadOnlyList<AdminFieldDto>> FieldsAsync(Guid? onlyFieldId, CancellationToken ct)
    {
        var slugs = await content.ReadSlugsAsync(ct);
        var fieldsQuery = db.Fields.AsNoTracking().Include(f => f.Topics).AsQueryable();
        if (onlyFieldId is { } id) fieldsQuery = fieldsQuery.Where(f => f.Id == id);
        var fields = await fieldsQuery.OrderBy(f => f.SortOrder).ThenBy(f => f.Slug).ToListAsync(ct);

        // What readers can see in a field or topic, whether or not the field is enabled: what disabling hides.
        var readable = db.Articles.AsNoTracking().Where(a => a.Status == ArticleStatus.Published && a.HiddenAt == null);
        var fieldIds = fields.Select(f => f.Id).ToList();
        var byField = await readable.Where(a => fieldIds.Contains(a.FieldId))
            .GroupBy(a => a.FieldId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.Key, g => g.Count, ct);
        var byTopic = await readable.Where(a => a.TopicId != null && fieldIds.Contains(a.FieldId))
            .GroupBy(a => a.TopicId!.Value)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.Key, g => g.Count, ct);

        return [.. fields.Select(f => ToDto(f, slugs, byField.GetValueOrDefault(f.Id), byTopic))];
    }

    public async Task<AdminFieldDto> FieldAsync(Guid fieldId, CancellationToken ct) => (await FieldsAsync(fieldId, ct)).Single();

    public async Task<AdminTopicDto> TopicAsync(Guid topicId, CancellationToken ct)
    {
        var fieldId = await db.Topics.AsNoTracking().Where(t => t.Id == topicId).Select(t => t.FieldId).SingleAsync(ct);
        return (await FieldAsync(fieldId, ct)).Topics.Single(t => t.Id == topicId);
    }

    private static AdminFieldDto ToDto(Field field, ContentTaxonomySlugs slugs, int articles, IReadOnlyDictionary<Guid, int> byTopic) => new(
        field.Id, field.Slug, field.NameAr, field.NameEn, field.Icon, field.Color, field.SortOrder, field.IsSensitive, field.RequiresSources,
        field.IsEnabled, slugs.Fields.Contains(field.Slug), field.CustomizedAt, articles,
        [
            .. field.Topics.OrderBy(t => t.SortOrder).ThenBy(t => t.Slug).Select(t => new AdminTopicDto(
                t.Id, t.FieldId, t.Slug, t.NameAr, t.NameEn, t.SortOrder, t.IsEnabled, slugs.Topics.Contains((field.Slug, t.Slug)),
                t.CustomizedAt, byTopic.GetValueOrDefault(t.Id))),
        ]);
}

internal sealed class GetAdminTaxonomyQueryHandler(AdminTaxonomyReader reader) : IQueryHandler<GetAdminTaxonomyQuery, Result<AdminTaxonomyDto>>
{
    public async ValueTask<Result<AdminTaxonomyDto>> Handle(GetAdminTaxonomyQuery query, CancellationToken cancellationToken) =>
        new AdminTaxonomyDto(await reader.FieldsAsync(onlyFieldId: null, cancellationToken), FieldStyles.Icons, FieldStyles.Colors);
}
