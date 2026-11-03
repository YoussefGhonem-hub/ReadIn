using Mediator;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Taxonomy.Queries.GetFields;

/// <summary>GET /fields — enabled fields in display order (cached; taxonomy changes rarely).</summary>
public sealed record GetFieldsQuery(string UiLanguage) : IQuery<Result<IReadOnlyList<FieldDto>>>, ICachedQuery
{
    public string CacheKey => $"fields:{UiLanguage}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Taxonomy];
    public TimeSpan Expiration => TimeSpan.FromHours(1);
}
