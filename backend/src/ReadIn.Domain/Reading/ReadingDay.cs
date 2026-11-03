namespace ReadIn.Domain.Reading;

/// <summary>
/// One user's reading on one local date (SPEC F08): the source of streaks and the heatmap. <see cref="Date"/> is the
/// calendar date in the user's time zone when the reading was reported (see <see cref="ReadingClock"/>, ADR 0013).
/// </summary>
public sealed class ReadingDay
{
    private ReadingDay() { } // EF

    public ReadingDay(Guid userId, DateOnly date)
    {
        UserId = userId;
        Date = date;
    }

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public DateOnly Date { get; private set; }

    /// <summary>Articles completed this day. A day counts for the streak when this is at least 1.</summary>
    public int ArticlesRead { get; private set; }

    /// <summary>Active reading time this day, completed or not ("minutes read").</summary>
    public int ActiveSeconds { get; private set; }

    public bool CountsForStreak => ArticlesRead > 0;

    public void AddSeconds(int seconds) => ActiveSeconds += Math.Max(0, seconds);

    public void AddCompletedArticle() => ArticlesRead++;

    /// <summary>Local demo data only (SPEC §18.2).</summary>
    public static ReadingDay Seeded(Guid userId, DateOnly date, int articlesRead, int activeSeconds) =>
        new(userId, date) { ArticlesRead = articlesRead, ActiveSeconds = activeSeconds };
}
