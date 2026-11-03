namespace ReadIn.Domain.Reading;

/// <summary>Per-user reading position for an article (SPEC F04: resume + "read" rule).</summary>
public sealed class ReadingProgress
{
    /// <summary>An article counts as read at ≥ 70% scrolled and ≥ 30 seconds spent (SPEC F04).</summary>
    public const int CompletionPercent = 70;
    public const int CompletionSeconds = 30;

    private ReadingProgress() { } // EF

    public ReadingProgress(Guid userId, Guid articleId, string language)
    {
        UserId = userId;
        ArticleId = articleId;
        Language = language;
    }

    public Guid Id { get; private set; } = Guid.CreateVersion7();
    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }
    public string Language { get; private set; } = default!;
    public int Percent { get; private set; }
    public string? LastPosition { get; private set; }
    public int ActiveSeconds { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    public bool IsCompleted => CompletedAt is not null;

    /// <returns>true when this update completed the article for the first time.</returns>
    public bool Record(string language, int percent, string? lastPosition, int activeSecondsDelta, DateTime now)
    {
        Language = language;
        Percent = Math.Clamp(Math.Max(Percent, percent), 0, 100);
        LastPosition = lastPosition;
        ActiveSeconds += Math.Clamp(activeSecondsDelta, 0, 600);
        UpdatedAt = now;

        if (CompletedAt is null && Percent >= CompletionPercent && ActiveSeconds >= CompletionSeconds)
        {
            CompletedAt = now;
            return true;
        }
        return false;
    }
}

/// <summary>The "مقال النهارده" pick for one user on one local date (SPEC F07).</summary>
public sealed class DailyPick
{
    private DailyPick() { } // EF

    public DailyPick(Guid userId, DateOnly date, Guid articleId)
    {
        UserId = userId;
        Date = date;
        ArticleId = articleId;
    }

    public Guid Id { get; private set; } = Guid.CreateVersion7();
    public Guid UserId { get; private set; }
    public DateOnly Date { get; private set; }
    public Guid ArticleId { get; private set; }
    public DateTime? OpenedAt { get; private set; }

    public void MarkOpened(DateTime now) => OpenedAt ??= now;
}
