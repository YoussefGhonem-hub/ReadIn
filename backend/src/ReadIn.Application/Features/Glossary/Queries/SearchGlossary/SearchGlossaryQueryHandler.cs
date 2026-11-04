using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Glossary.Queries.SearchGlossary;

internal sealed class SearchGlossaryQueryHandler(IAppDbContext db)
    : IQueryHandler<SearchGlossaryQuery, Result<IReadOnlyList<GlossaryTermSummaryDto>>>
{
    public async ValueTask<Result<IReadOnlyList<GlossaryTermSummaryDto>>> Handle(SearchGlossaryQuery query, CancellationToken cancellationToken)
    {
        var limit = Math.Clamp(query.Limit, 1, SearchGlossaryQuery.MaxLimit);
        var q = (query.Q ?? string.Empty).Trim();
        if (q.Length > SearchGlossaryQuery.MaxQueryLength) q = q[..SearchGlossaryQuery.MaxQueryLength];

        var terms = db.GlossaryTerms.AsNoTracking();
        if (q.Length > 0)
        {
            terms = terms
                .Where(t => t.TermEn.Contains(q) || t.Slug.Contains(q))
                .OrderBy(t => t.TermEn.StartsWith(q) || t.Slug.StartsWith(q) ? 0 : 1)
                .ThenBy(t => t.TermEn);
        }
        else
        {
            terms = terms.OrderBy(t => t.TermEn);
        }

        return await terms
            .Take(limit)
            .Select(t => new GlossaryTermSummaryDto(t.Slug, t.TermEn, t.DefinitionEn))
            .ToListAsync(cancellationToken);
    }
}
