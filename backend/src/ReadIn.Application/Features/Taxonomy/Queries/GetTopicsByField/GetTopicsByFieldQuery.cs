using Mediator;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Taxonomy.Queries.GetTopicsByField;

/// <summary>GET /fields/{slug}/topics</summary>
public sealed record GetTopicsByFieldQuery(string FieldSlug, string UiLanguage) : IQuery<Result<IReadOnlyList<TopicDto>>>, ICachedQuery
{
    public string CacheKey => $"topics:{FieldSlug}:{UiLanguage}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Taxonomy];
    public TimeSpan Expiration => TimeSpan.FromHours(1);
}
