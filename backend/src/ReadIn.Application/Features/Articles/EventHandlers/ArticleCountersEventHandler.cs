using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Articles.EventHandlers;

/// <summary>
/// After a reaction or save change commits, the article's counters are recomputed from SQL and published to the
/// Realtime Database (SPEC §21.2, F27). Idempotent, so the outbox's at-least-once delivery is safe.
/// </summary>
internal sealed class ArticleCountersEventHandler(ArticleCounters counters)
    : IDomainEventHandler<ReactionChangedDomainEvent>, IDomainEventHandler<ArticleSaveChangedDomainEvent>
{
    public Task Handle(ReactionChangedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        counters.RecomputeAsync([domainEvent.ArticleId], cancellationToken);

    public Task Handle(ArticleSaveChangedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        counters.RecomputeAsync([domainEvent.ArticleId], cancellationToken);
}
