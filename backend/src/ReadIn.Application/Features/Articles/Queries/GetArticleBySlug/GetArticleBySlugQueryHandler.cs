using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

internal sealed class GetArticleBySlugQueryHandler(IAppDbContext db, TypeAdapterConfig mapping, IFileStorage storage)
    : IQueryHandler<GetArticleBySlugQuery, Result<ArticleDetailsDto>>
{
    public async ValueTask<Result<ArticleDetailsDto>> Handle(GetArticleBySlugQuery query, CancellationToken cancellationToken)
    {
        using var _ = LocalizedProjection.Begin(query.UiLanguage, query.Language);

        var article = await db.Articles.AsNoTracking()
            .Where(a => a.Slug == query.Slug && a.Status == ArticleStatus.Published && a.Field.IsEnabled)
            .ProjectToType<ArticleDetailsDto>(mapping)
            .FirstOrDefaultAsync(cancellationToken);

        if (article is null) return ArticleErrors.NotFound;

        return article.WithPublicUrls(storage) with { Content = storage.ToPublicContent(article.ContentJson) };
    }
}
