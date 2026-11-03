using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Reading;

/// <summary>The streak as the user sees it on <see cref="Today"/>, their local date (SPEC F08, ADR 0013).</summary>
/// <param name="FreezeAvailable">A freeze is ready to cover the next missed day (one per rolling 7 days).</param>
/// <param name="FreezePending">Yesterday was missed; reading today uses a freeze on it and keeps the streak.</param>
public sealed record StreakDto(int Current, int Longest, bool ReadToday, bool FreezeAvailable, bool FreezePending, DateOnly Today)
{
    public static StreakDto From(StreakStatus status, DateOnly today) =>
        new(status.Current, status.Longest, status.ReadToday, status.FreezeAvailable, status.FreezePending, today);
}

/// <summary>Answer to PUT /articles/{id}/progress.</summary>
/// <param name="CompletedNow">This report made the article "read" (≥ 70% and ≥ 30 s, SPEC F04).</param>
/// <param name="Streak">Set when <paramref name="CompletedNow"/> is true.</param>
/// <param name="Milestone">7, 30, 100 or 365 when this read extended the streak to that length (celebration).</param>
public sealed record ReadingProgressResultDto(int Percent, bool Completed, bool CompletedNow, StreakDto? Streak, int? Milestone);

/// <summary>A field the user reads most, by completed articles.</summary>
public sealed record TopFieldDto(Guid Id, string Slug, string Name, string Icon, string Color, int Articles);

/// <summary>GET /me/stats (SPEC F08). "This week" is the last 7 local days and "this month" the last 30 (rolling).</summary>
public sealed record ReadingStatsDto(
    StreakDto Streak,
    int TotalArticles,
    int MinutesRead,
    int ArticlesThisWeek,
    int MinutesThisWeek,
    int ArticlesThisMonth,
    IReadOnlyList<TopFieldDto> TopFields);

/// <param name="Frozen">A missed day covered by a streak freeze (no articles).</param>
public sealed record HeatmapDayDto(DateOnly Date, int Articles, int Minutes, bool Frozen);

/// <summary>GET /me/stats/heatmap: only days with a completed article or a freeze, oldest first.</summary>
public sealed record ReadingHeatmapDto(DateOnly From, DateOnly To, IReadOnlyList<HeatmapDayDto> Days);
