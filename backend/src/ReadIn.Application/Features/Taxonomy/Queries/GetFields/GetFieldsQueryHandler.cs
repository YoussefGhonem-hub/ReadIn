using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Taxonomy.Queries.GetFields;

internal sealed class GetFieldsQueryHandler(IAppDbContext db, TypeAdapterConfig mapping)
    : IQueryHandler<GetFieldsQuery, Result<IReadOnlyList<FieldDto>>>
{
    public async ValueTask<Result<IReadOnlyList<FieldDto>>> Handle(GetFieldsQuery query, CancellationToken cancellationToken)
    {
        using var _ = LocalizedProjection.Begin(query.UiLanguage);

        var fields = await db.Fields.AsNoTracking()
            .Where(f => f.IsEnabled)
            .OrderBy(f => f.SortOrder)
            .ProjectToType<FieldDto>(mapping)
            .ToListAsync(cancellationToken);

        return fields;
    }
}
