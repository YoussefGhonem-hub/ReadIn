using ReadIn.Domain.Common;

namespace ReadIn.Domain.Reading;

/// <summary>Per-user reading position for an article (SPEC F04: resume + "read" rule).</summary>
public sealed class ReadingProgress : AggregateRoot
{
    /// <summary>An article counts as read at ≥ 70% scrolled and ≥ 30 seconds spent (SPEC F04).</summary>
    public const int CompletionPercent = 70;
    public const int CompletionSeconds = 30;

    /// <summary>One report never credits more than this, however long the client waited to send it.</summary>
    public const int MaxSecondsPerReport = 600;

    /// <summary>Network and timer jitter allowed on top of the time that really passed between two reports.</summary>
    public const int ReportSlackSeconds = 10;

    private ReadingProgress() { } // EF

    /// <summary>The first report of an article: it credits no time, since nothing says when reading started.</summary>
    public ReadingProgress(Guid userId, Guid articleId, string language, DateTime now)
    {
        UserId = userId;
        ArticleId = articleId;
        Language = language;
        StartedAt = now;
        UpdatedAt = now;
    }

    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }
    public string Language { get; private set; } = default!;
    public int Percent { get; private set; }
    public string? LastPosition { get; private set; }
    public int ActiveSeconds { get; private set; }
    public DateTime StartedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    public bool IsCompleted => CompletedAt is not null;

    /// <summary>
    /// Applies a client report. Seconds are credited only up to the time that really passed since the previous report
    /// (plus <see cref="ReportSlackSeconds"/>), so a client can't claim 30 seconds in one request.
    /// </summary>
    public ProgressUpdate Record(string language, int percent, string? lastPosition, int activeSecondsDelta, DateTime now)
    {
        // No time has passed (e.g. the first report, made when the row is created): nothing to credit.
        var elapsed = (int)Math.Max(0, Math.Floor((now - UpdatedAt).TotalSeconds));
        var cap = elapsed == 0 ? 0 : Math.Min(MaxSecondsPerReport, elapsed + ReportSlackSeconds);
        var credited = Math.Clamp(activeSecondsDelta, 0, cap);

        Language = language;
        Percent = Math.Clamp(Math.Max(Percent, percent), 0, 100);
        LastPosition = lastPosition;
        ActiveSeconds += credited;
        UpdatedAt = now;

        if (CompletedAt is null && Percent >= CompletionPercent && ActiveSeconds >= CompletionSeconds)
        {
            CompletedAt = now;
            Raise(() => new ArticleReadCompletedDomainEvent(UserId, ArticleId));
            return new ProgressUpdate(credited, CompletedNow: true);
        }
        return new ProgressUpdate(credited, CompletedNow: false);
    }

    /// <summary>Local demo data only (SPEC §18.2): a finished read on a past day.</summary>
    public static ReadingProgress SeededCompleted(Guid userId, Guid articleId, string language, int activeSeconds, DateTime completedAt) =>
        new(userId, articleId, language, completedAt.AddSeconds(-activeSeconds))
        {
            Percent = 100,
            ActiveSeconds = activeSeconds,
            CompletedAt = completedAt,
            UpdatedAt = completedAt,
        };

    /// <summary>Local demo data only: an article left part-way, for "continue reading".</summary>
    public static ReadingProgress SeededInProgress(Guid userId, Guid articleId, string language, int percent, int activeSeconds, DateTime updatedAt) =>
        new(userId, articleId, language, updatedAt.AddSeconds(-activeSeconds))
        {
            Percent = percent,
            ActiveSeconds = activeSeconds,
            UpdatedAt = updatedAt,
        };
}

/// <param name="CreditedSeconds">Seconds actually added by this report (after the anti-cheat clamp).</param>
/// <param name="CompletedNow">This report completed the article for the first time.</param>
public readonly record struct ProgressUpdate(int CreditedSeconds, bool CompletedNow);

/// <summary>An article was read to the end for the first time by this user (SPEC F04); recomputes <c>Articles.ReadCount</c>.</summary>
public sealed record ArticleReadCompletedDomainEvent(Guid UserId, Guid ArticleId) : DomainEvent;

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

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public DateOnly Date { get; private set; }
    public Guid ArticleId { get; private set; }
    public DateTime? OpenedAt { get; private set; }

    /// <summary>When the daily push for this pick was sent (claimed just before sending, so it goes out at most once).</summary>
    public DateTime? NotifiedAt { get; private set; }

    public void MarkOpened(DateTime now) => OpenedAt ??= now;

    /// <returns>false when the push was already claimed.</returns>
    public bool MarkNotified(DateTime now)
    {
        if (NotifiedAt is not null) return false;
        NotifiedAt = now;
        return true;
    }

    /// <summary>Gives the claim back when no device could be reached, so the next job run tries again.</summary>
    public void ReleaseNotification() => NotifiedAt = null;
}
