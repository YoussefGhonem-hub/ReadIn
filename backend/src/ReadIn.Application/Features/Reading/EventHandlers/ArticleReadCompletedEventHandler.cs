using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Reading.EventHandlers;

/// <summary>
/// Recomputes <c>Articles.ReadCount</c> from completed reads after one commits (SPEC §16.1). Recomputed, never
/// incremented, so the outbox's at-least-once delivery is safe. The cached article details keep the old number until
/// they expire: dropping the cache on every read would empty it for popular articles.
/// </summary>
internal sealed class ArticleReadCompletedEventHandler(IAppDbContext db) : IDomainEventHandler<ArticleReadCompletedDomainEvent>
{
    public async Task Handle(ArticleReadCompletedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        await db.Articles.IgnoreQueryFilters()
            .Where(a => a.Id == domainEvent.ArticleId)
            .ExecuteUpdateAsync(
                set => set.SetProperty(a => a.ReadCount, a => db.ReadingProgress.Count(r => r.ArticleId == a.Id && r.CompletedAt != null)),
                cancellationToken);
}
