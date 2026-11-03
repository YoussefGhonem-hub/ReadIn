namespace ReadIn.Domain.Reading;

/// <summary>
/// Reading streaks (SPEC F08, ADR 0013). A streak is a run of local dates with at least one completed article. A single
/// missed day inside a run is covered by a streak freeze when no freeze was used in the 7 days before it (a rolling
/// week): the run continues, and the frozen day itself doesn't add to the count. Two missed days in a row always end
/// the run. Everything is derived from the read dates, so recomputing is always safe.
/// </summary>
public static class Streaks
{
    /// <summary>Milestone celebrations (SPEC F08).</summary>
    public static readonly IReadOnlyList<int> Milestones = [7, 30, 100, 365];

    /// <summary>One free freeze per rolling 7 days.</summary>
    public const int FreezeCooldownDays = 7;

    public static StreakHistory Compute(IEnumerable<DateOnly> readDates)
    {
        DateOnly? last = null, lastFreeze = null;
        int current = 0, longest = 0;
        var freezes = new List<DateOnly>();

        foreach (var date in readDates.Distinct().Order())
        {
            if (last is not { } previous)
            {
                current = 1;
            }
            else
            {
                var missed = date.DayNumber - previous.DayNumber - 1;
                var missedDay = previous.AddDays(1);
                if (missed == 0)
                {
                    current++;
                }
                else if (missed == 1 && CanFreeze(lastFreeze, missedDay))
                {
                    freezes.Add(missedDay);
                    lastFreeze = missedDay;
                    current++;
                }
                else
                {
                    current = 1;
                }
            }

            longest = Math.Max(longest, current);
            last = date;
        }

        return new StreakHistory(current, longest, last, lastFreeze, freezes);
    }

    /// <summary>A freeze can cover <paramref name="missedDay"/> when the previous one is at least 7 days older.</summary>
    public static bool CanFreeze(DateOnly? lastFreeze, DateOnly missedDay) =>
        lastFreeze is not { } used || missedDay.DayNumber - used.DayNumber >= FreezeCooldownDays;

    /// <summary>
    /// The streak as the user sees it on <paramref name="today"/> (their local date). Freezes are used lazily: a missed
    /// yesterday shows as "pending" and becomes a freeze when they read today; two missed days show 0.
    /// </summary>
    public static StreakStatus StatusOn(StreakHistory history, DateOnly today)
    {
        if (history.LastReadDate is not { } last)
            return new StreakStatus(0, history.Longest, ReadToday: false, CanFreeze(history.LastFreezeDate, today), FreezePending: false);

        var sinceLastRead = today.DayNumber - last.DayNumber;
        return sinceLastRead switch
        {
            // ≤ 0: read today (or the time zone moved west since the last read).
            <= 0 => new StreakStatus(history.Current, history.Longest, ReadToday: true, CanFreeze(history.LastFreezeDate, today.AddDays(1)), FreezePending: false),
            1 => new StreakStatus(history.Current, history.Longest, ReadToday: false, CanFreeze(history.LastFreezeDate, today), FreezePending: false),
            2 when CanFreeze(history.LastFreezeDate, last.AddDays(1)) =>
                new StreakStatus(history.Current, history.Longest, ReadToday: false, FreezeAvailable: false, FreezePending: true),
            _ => new StreakStatus(0, history.Longest, ReadToday: false, CanFreeze(history.LastFreezeDate, today), FreezePending: false),
        };
    }

    /// <summary>The milestone reached by the read that made <paramref name="history"/>, if it extended the streak to one.</summary>
    public static int? MilestoneReachedOn(StreakHistory history, DateOnly readDate) =>
        history.LastReadDate == readDate && Milestones.Contains(history.Current) ? history.Current : null;
}

/// <param name="Current">The run ending at <see cref="LastReadDate"/> (whether it is still alive depends on today).</param>
/// <param name="FreezeDays">Missed days covered by a freeze, oldest first (shown on the heatmap).</param>
public sealed record StreakHistory(int Current, int Longest, DateOnly? LastReadDate, DateOnly? LastFreezeDate, IReadOnlyList<DateOnly> FreezeDays)
{
    public static readonly StreakHistory Empty = new(0, 0, null, null, []);
}

/// <param name="Current">0 once the streak is broken.</param>
/// <param name="FreezeAvailable">A freeze is ready to cover the next missed day.</param>
/// <param name="FreezePending">Yesterday was missed; reading today uses a freeze on it and keeps the streak.</param>
public readonly record struct StreakStatus(int Current, int Longest, bool ReadToday, bool FreezeAvailable, bool FreezePending);
