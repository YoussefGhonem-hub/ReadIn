using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using ReadIn.Domain.Common;

namespace ReadIn.Infrastructure.Persistence.Outbox;

/// <summary>
/// Moves domain events raised by aggregates into <see cref="OutboxMessage"/> rows inside the same
/// SaveChanges transaction, then signals the processor once the commit succeeded.
/// </summary>
internal sealed class OutboxInterceptor(IOutboxSignal signal) : SaveChangesInterceptor
{
    private bool _hasNewMessages;

    public override InterceptionResult<int> SavingChanges(DbContextEventData eventData, InterceptionResult<int> result)
    {
        Collect(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData, InterceptionResult<int> result, CancellationToken cancellationToken = default)
    {
        Collect(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    public override async ValueTask<int> SavedChangesAsync(SaveChangesCompletedEventData eventData, int result, CancellationToken cancellationToken = default)
    {
        if (_hasNewMessages)
        {
            _hasNewMessages = false;
            await signal.NotifyAsync(cancellationToken);
        }
        return await base.SavedChangesAsync(eventData, result, cancellationToken);
    }

    private void Collect(DbContext? context)
    {
        if (context is null) return;

        var events = context.ChangeTracker.Entries<AggregateRoot>()
            .SelectMany(entry =>
            {
                var raised = entry.Entity.DomainEvents.ToList();
                entry.Entity.ClearDomainEvents();
                return raised;
            })
            .ToList();

        foreach (var domainEvent in events)
        {
            var type = domainEvent.GetType();
            context.Set<OutboxMessage>().Add(new OutboxMessage(
                type.FullName!,
                JsonSerializer.Serialize(domainEvent, type),
                domainEvent.OccurredAt));
        }

        _hasNewMessages |= events.Count > 0;
    }
}
