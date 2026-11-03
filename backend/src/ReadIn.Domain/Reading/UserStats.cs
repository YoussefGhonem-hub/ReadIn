namespace ReadIn.Domain.Reading;

/// <summary>
/// Cached reading totals and streak of one user (SPEC §16.2, F08), recomputed from <see cref="ReadingDay"/> whenever a
/// read completes. <see cref="CurrentStreak"/> is the run ending at <see cref="LastReadDate"/>; whether it is still
/// alive today is decided by <see cref="Streaks.StatusOn"/>.
/// </summary>
public sealed class UserStats
{
    private UserStats() { } // EF

    public UserStats(Guid userId) => UserId = userId;

    public Guid UserId { get; private set; }
    public int CurrentStreak { get; private set; }
    public int LongestStreak { get; private set; }
    public DateOnly? LastReadDate { get; private set; }

    /// <summary>The most recent day covered by a freeze; the next one is allowed 7 days later (rolling week).</summary>
    public DateOnly? LastFreezeDate { get; private set; }

    public int TotalArticles { get; private set; }
    public int TotalSeconds { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    public StreakHistory History => new(CurrentStreak, LongestStreak, LastReadDate, LastFreezeDate, []);

    public void AddSeconds(int seconds, DateTime now)
    {
        TotalSeconds += Math.Max(0, seconds);
        UpdatedAt = now;
    }

    public void Apply(StreakHistory history, int totalArticles, DateTime now)
    {
        CurrentStreak = history.Current;
        LongestStreak = history.Longest;
        LastReadDate = history.LastReadDate;
        LastFreezeDate = history.LastFreezeDate;
        TotalArticles = totalArticles;
        UpdatedAt = now;
    }

    /// <summary>Recomputes the totals too (demo seeding and rebuilds).</summary>
    public void Rebuild(StreakHistory history, int totalArticles, int totalSeconds, DateTime now)
    {
        Apply(history, totalArticles, now);
        TotalSeconds = totalSeconds;
    }
}
