namespace ReadIn.Infrastructure.Persistence.Outbox;

/// <summary>A domain event saved in the same transaction as the aggregate that raised it (SPEC §6.3).</summary>
public sealed class OutboxMessage
{
    public const int MaxAttempts = 5;

    private OutboxMessage() { } // EF

    public OutboxMessage(string type, string content, DateTime occurredAt)
    {
        Type = type;
        Content = content;
        OccurredAt = occurredAt;
    }

    public Guid Id { get; private set; } = Guid.CreateVersion7();
    public string Type { get; private set; } = default!;
    public string Content { get; private set; } = default!;
    public DateTime OccurredAt { get; private set; }
    public DateTime? ProcessedAt { get; private set; }
    public int Attempts { get; private set; }
    public string? Error { get; private set; }

    public void MarkProcessed(DateTime now)
    {
        ProcessedAt = now;
        Error = null;
    }

    public void MarkFailed(string error)
    {
        Attempts++;
        Error = error.Length > 2000 ? error[..2000] : error;
    }
}
