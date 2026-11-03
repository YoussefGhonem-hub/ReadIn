namespace ReadIn.Domain.Common;

public abstract class Entity
{
    /// <summary>
    /// Assigned by EF Core when the entity is added to the context: its sequential GUID generator follows SQL Server's
    /// uniqueidentifier sort order, so inserts stay ordered in the clustered index (SPEC §16.1, ADR 0006).
    /// <see cref="Guid.Empty"/> until then, unless a fixed reference key is set explicitly.
    /// </summary>
    public Guid Id { get; protected init; }
}

public abstract class AggregateRoot : Entity
{
    private readonly List<Func<IDomainEvent>> _domainEvents = [];

    /// <summary>
    /// Builds the raised events. The outbox reads them at SaveChanges, after EF Core assigned the keys, so an event
    /// that references <see cref="Entity.Id"/> never carries <see cref="Guid.Empty"/> (ADR 0006).
    /// </summary>
    public IReadOnlyList<IDomainEvent> DomainEvents => [.. _domainEvents.Select(create => create())];

    /// <summary>Raises an event that is built when collected, so it describes the aggregate as it is saved.</summary>
    protected void Raise(Func<IDomainEvent> domainEvent) => _domainEvents.Add(domainEvent);

    public void ClearDomainEvents() => _domainEvents.Clear();
}

public interface IAuditable
{
    DateTime CreatedAt { get; }
    Guid? CreatedBy { get; }
    DateTime? UpdatedAt { get; }
    Guid? UpdatedBy { get; }
}

public interface ISoftDeletable
{
    bool IsDeleted { get; }
    DateTime? DeletedAt { get; }
}

/// <summary>Marker for aggregates that carry a SQL Server rowversion concurrency token.</summary>
public interface IHasRowVersion
{
    byte[] RowVersion { get; }
}

public interface IDomainEvent
{
    DateTime OccurredAt { get; }
}

public abstract record DomainEvent : IDomainEvent
{
    public DateTime OccurredAt { get; init; } = DateTime.UtcNow;
}
