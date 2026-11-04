using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Glossary;

namespace ReadIn.Application.Features.Glossary.Queries.GetGlossaryTerm;

internal sealed class GetGlossaryTermQueryHandler(IAppDbContext db, TypeAdapterConfig mapping)
    : IQueryHandler<GetGlossaryTermQuery, Result<GlossaryTermDto>>
{
    public async ValueTask<Result<GlossaryTermDto>> Handle(GetGlossaryTermQuery query, CancellationToken cancellationToken)
    {
        if (query.Slug.Length > GlossaryTerm.SlugMaxLength) return GlossaryErrors.TermNotFound;

        var term = await db.GlossaryTerms.AsNoTracking()
            .Where(t => t.Slug == query.Slug)
            .Select(t => new { t.Id, t.Slug, t.TermEn, t.DefinitionEn, t.ExplanationAr })
            .FirstOrDefaultAsync(cancellationToken);
        if (term is null) return GlossaryErrors.TermNotFound;

        using var _ = LocalizedProjection.Begin(query.UiLanguage, query.Language);

        var cards = await db.Articles.AsNoTracking()
            .Visible()
            .Where(a => db.ArticleTerms.Any(t => t.ArticleId == a.Id && t.TermId == term.Id))
            .OrderByDescending(a => a.QualityScore)
            .ThenByDescending(a => a.PublishedAt)
            .ThenByDescending(a => a.Id)
            .Take(GetGlossaryTermQuery.MaxArticles)
            .ProjectToType<ArticleCardDto>(mapping)
            .ToListAsync(cancellationToken);

        return new GlossaryTermDto(
            term.Slug,
            term.TermEn,
            term.DefinitionEn,
            term.ExplanationAr,
            [.. cards.Select(c => new GlossaryArticleDto(c.Id, c.Slug, c.Language, c.Title, c.ReadingTimeMinutes, c.Field))]);
    }
}
