namespace ReadIn.Domain.Common;

public abstract class Entity
{
    /// <summary>Sequential GUID v7 so clustered indexes stay append-friendly (SPEC §16.1).</summary>
    public Guid Id { get; protected init; } = Guid.CreateVersion7();
}

public abstract class AggregateRoot : Entity
{
    private readonly List<IDomainEvent> _domainEvents = [];

    public IReadOnlyCollection<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    protected void Raise(IDomainEvent domainEvent) => _domainEvents.Add(domainEvent);

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
