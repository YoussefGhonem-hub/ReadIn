using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Glossary;

namespace ReadIn.Application.Features.Glossary;

/// <summary>
/// Keeps <c>ArticleTerms</c> in step with the stored content (SPEC F21): an article uses a term when any of its versions
/// has a <c>term</c> node for it. Term ids that aren't in the glossary are skipped. Rebuilt by the glossary seeder for
/// every article, and for one article when it is published.
/// </summary>
public sealed class ArticleTermsIndex(IAppDbContext db)
{
    private const int BatchSize = 100;

    /// <summary>Rebuilds the rows of <paramref name="articleIds"/>, or of every article when null, and saves them.</summary>
    /// <returns>The number of rows added or removed.</returns>
    public async Task<int> RebuildAsync(IReadOnlyCollection<Guid>? articleIds, CancellationToken cancellationToken)
    {
        var terms = await db.GlossaryTerms.AsNoTracking()
            .ToDictionaryAsync(t => t.Slug, t => t.Id, StringComparer.Ordinal, cancellationToken);

        var ids = articleIds?.Distinct().ToList()
            ?? await db.ArticleTranslations.AsNoTracking().Select(t => t.ArticleId).Distinct().ToListAsync(cancellationToken);

        var changes = 0;
        foreach (var batch in ids.Chunk(BatchSize))
        {
            var contents = await db.ArticleTranslations.AsNoTracking()
                .Where(t => batch.Contains(t.ArticleId))
                .Select(t => new { t.ArticleId, t.ContentJson })
                .ToListAsync(cancellationToken);

            var wanted = batch.ToDictionary(id => id, _ => new HashSet<Guid>());
            foreach (var content in contents)
            {
                foreach (var slug in RDocTermIds.Extract(content.ContentJson))
                    if (terms.TryGetValue(slug, out var termId)) wanted[content.ArticleId].Add(termId);
            }

            var existing = await db.ArticleTerms.Where(t => batch.Contains(t.ArticleId)).ToListAsync(cancellationToken);
            foreach (var row in existing)
            {
                // Rows that are still wanted stay; what's left in `wanted` afterwards is new.
                if (wanted[row.ArticleId].Remove(row.TermId)) continue;
                db.ArticleTerms.Remove(row);
                changes++;
            }

            foreach (var (articleId, termIds) in wanted)
            {
                foreach (var termId in termIds)
                {
                    db.ArticleTerms.Add(new ArticleTerm(articleId, termId));
                    changes++;
                }
            }

            await db.SaveChangesAsync(cancellationToken);
        }
        return changes;
    }
}
