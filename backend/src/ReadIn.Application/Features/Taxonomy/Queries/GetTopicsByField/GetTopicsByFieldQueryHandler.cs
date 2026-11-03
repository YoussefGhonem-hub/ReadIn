using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Taxonomy.Queries.GetTopicsByField;

internal sealed class GetTopicsByFieldQueryHandler(IAppDbContext db, TypeAdapterConfig mapping)
    : IQueryHandler<GetTopicsByFieldQuery, Result<IReadOnlyList<TopicDto>>>
{
    private static readonly Error FieldNotFound = Error.NotFound("field.not_found", "Field not found.");

    public async ValueTask<Result<IReadOnlyList<TopicDto>>> Handle(GetTopicsByFieldQuery query, CancellationToken cancellationToken)
    {
        var fieldId = await db.Fields.AsNoTracking()
            .Where(f => f.Slug == query.FieldSlug && f.IsEnabled)
            .Select(f => (Guid?)f.Id)
            .FirstOrDefaultAsync(cancellationToken);
        if (fieldId is null) return FieldNotFound;

        using var _ = LocalizedProjection.Begin(query.UiLanguage);

        var topics = await db.Topics.AsNoTracking()
            .Where(t => t.FieldId == fieldId)
            .OrderBy(t => t.SortOrder)
            .ProjectToType<TopicDto>(mapping)
            .ToListAsync(cancellationToken);

        return topics;
    }
}
