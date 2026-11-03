using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// Handles a domain event after it was committed through the outbox (SPEC §6.3).
/// Handlers must be idempotent: the outbox guarantees at-least-once delivery.
/// </summary>
public interface IDomainEventHandler<in TEvent> where TEvent : IDomainEvent
{
    Task Handle(TEvent domainEvent, CancellationToken cancellationToken);
}
