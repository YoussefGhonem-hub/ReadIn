using System.Collections.Frozen;
using System.Reflection;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Infrastructure.Persistence.Outbox;

/// <summary>Signals that new outbox messages were committed.</summary>
public interface IOutboxSignal
{
    Task NotifyAsync(CancellationToken cancellationToken);
}

/// <summary>Dispatches committed domain events to their <see cref="IDomainEventHandler{TEvent}"/>s.</summary>
public sealed partial class OutboxProcessor(AppDbContext db, IServiceProvider services, TimeProvider clock, ILogger<OutboxProcessor> logger)
{
    private const int BatchSize = 50;

    private static readonly FrozenDictionary<string, Type> EventTypes = typeof(IDomainEvent).Assembly
        .GetTypes()
        .Where(t => t is { IsAbstract: false, IsInterface: false } && typeof(IDomainEvent).IsAssignableFrom(t))
        .ToFrozenDictionary(t => t.FullName!, t => t);

    private static readonly MethodInfo DispatchMethod =
        typeof(OutboxProcessor).GetMethod(nameof(DispatchAsync), BindingFlags.NonPublic | BindingFlags.Instance)!;

    public async Task<int> ProcessAsync(CancellationToken cancellationToken)
    {
        var batch = await db.OutboxMessages
            .Where(m => m.ProcessedAt == null && m.Attempts < OutboxMessage.MaxAttempts)
            .OrderBy(m => m.OccurredAt)
            .Take(BatchSize)
            .ToListAsync(cancellationToken);

        foreach (var message in batch)
        {
            try
            {
                if (!EventTypes.TryGetValue(message.Type, out var type))
                    throw new InvalidOperationException($"Unknown domain event type '{message.Type}'.");

                var domainEvent = JsonSerializer.Deserialize(message.Content, type)!;
                await (Task)DispatchMethod.MakeGenericMethod(type).Invoke(this, [domainEvent, cancellationToken])!;
                message.MarkProcessed(clock.GetUtcNow().UtcDateTime);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                var error = ex is TargetInvocationException { InnerException: { } inner } ? inner : ex;
                LogFailed(logger, error, message.Id, message.Type);
                message.MarkFailed(error.Message);
            }
        }

        if (batch.Count > 0) await db.SaveChangesAsync(cancellationToken);
        return batch.Count;
    }

    private async Task DispatchAsync<TEvent>(TEvent domainEvent, CancellationToken cancellationToken) where TEvent : IDomainEvent
    {
        foreach (var handler in services.GetServices<IDomainEventHandler<TEvent>>())
            await handler.Handle(domainEvent, cancellationToken);
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Outbox message {MessageId} ({Type}) failed")]
    private static partial void LogFailed(ILogger logger, Exception exception, Guid messageId, string type);
}

/// <summary>Processes the outbox right away in a fresh scope. Used when Hangfire is disabled (tests, tools).</summary>
internal sealed class InlineOutboxSignal(IServiceScopeFactory scopes) : IOutboxSignal
{
    public async Task NotifyAsync(CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<OutboxProcessor>().ProcessAsync(cancellationToken);
    }
}
