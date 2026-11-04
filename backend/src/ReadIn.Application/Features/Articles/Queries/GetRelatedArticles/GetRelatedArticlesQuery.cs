using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetRelatedArticles;

/// <summary>
/// GET /articles/{id}/related?lang=&amp;limit= — the "Related articles" block at the end of the reader (SPEC F04). Not
/// cached: it leaves out the viewer's own articles and puts the ones they read last.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetRelatedArticlesQuery(Guid ArticleId, string? Language, int Limit, string UiLanguage)
    : IQuery<Result<IReadOnlyList<ArticleCardDto>>>
{
    public const int DefaultLimit = 4;
    public const int MaxLimit = 10;
}
