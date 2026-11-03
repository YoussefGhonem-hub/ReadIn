using Mediator;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

/// <summary>GET /articles/{slug}?lang= — published articles only; cached and invalidated by the article tag.</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetArticleBySlugQuery(string Slug, string? Language, string UiLanguage)
    : IQuery<Result<ArticleDetailsDto>>, ICachedQuery
{
    public string CacheKey => $"article:{Slug}:{Language ?? "source"}:{UiLanguage}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Article(Slug), Common.Behaviors.CacheTags.Articles];
    public TimeSpan Expiration => TimeSpan.FromMinutes(10);
}
