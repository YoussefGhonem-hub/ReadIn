using Mediator;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

/// <summary>
/// GET /articles/{slug}?lang= — published articles only; cached and invalidated by the article tag. The cached copy is
/// the same for every reader; the author and moderators get <c>canDownload</c> on top of it (ADR 0011).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetArticleBySlugQuery(string Slug, string? Language, string UiLanguage)
    : IQuery<Result<ArticleDetailsDto>>, ICachedQuery, IPersonalizedQuery<Result<ArticleDetailsDto>>
{
    public string CacheKey => $"article:{Slug}:{Language ?? "source"}:{UiLanguage}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Article(Slug), Common.Behaviors.CacheTags.Articles];
    public TimeSpan Expiration => TimeSpan.FromMinutes(10);

    public Result<ArticleDetailsDto> Personalize(Result<ArticleDetailsDto> response, ICurrentUser viewer) =>
        response.IsSuccess ? response.Value.PersonalizedFor(viewer) : response;
}
