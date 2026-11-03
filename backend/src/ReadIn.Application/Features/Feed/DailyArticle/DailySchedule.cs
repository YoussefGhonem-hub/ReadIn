namespace ReadIn.Application.Features.Feed.DailyArticle;

/// <summary>
/// The clock of "مقال النهارده" (SPEC F07, §21.1): the pick is made 30 minutes before the user's reminder time and the
/// push goes out at the reminder time, both in the user's IANA time zone. Everything compares wall-clock times, so daylight
/// saving never moves a reminder: one inside a skipped hour fires right after the jump, and one inside a repeated hour
/// fires once (the pick remembers that it was notified).
/// </summary>
public static class DailySchedule
{
    /// <summary>The pick is made this long before the reminder time (SPEC F07).</summary>
    public static readonly TimeSpan PickLead = TimeSpan.FromMinutes(30);

    /// <summary>
    /// A push that is due but not sent yet (the job was down, the reminder was moved to an earlier time) still goes out up to
    /// this long after the reminder time. Later than that it is dropped rather than arriving hours late; the article stays
    /// the hero card for the day either way.
    /// </summary>
    public static readonly TimeSpan LateWindow = TimeSpan.FromHours(2);

    private static readonly TimeSpan OneDay = TimeSpan.FromDays(1);

    /// <summary>Unknown or empty zones fall back to UTC, the same everywhere (GET /feed/today and the job must agree).</summary>
    public static TimeZoneInfo Zone(string? timeZone) =>
        !string.IsNullOrWhiteSpace(timeZone) && TimeZoneInfo.TryFindSystemTimeZoneById(timeZone, out var zone) ? zone : TimeZoneInfo.Utc;

    public static DateTime LocalNow(DateTime utcNow, string? timeZone) =>
        TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utcNow, DateTimeKind.Utc), Zone(timeZone));

    /// <summary>The user's "today": the date of Today's article and of its <c>DailyPicks</c> row.</summary>
    public static DateOnly LocalDate(DateTime utcNow, string? timeZone) => DateOnly.FromDateTime(LocalNow(utcNow, timeZone));

    /// <summary>
    /// The pick for <paramref name="date"/> is due from 30 minutes before the reminder until that day ends. A reminder in
    /// the first half hour after midnight is therefore picked late on the evening before.
    /// </summary>
    public static bool IsPickDue(DateTime localNow, TimeOnly reminder, DateOnly date) =>
        localNow >= date.ToDateTime(reminder) - PickLead && localNow < date.AddDays(1).ToDateTime(TimeOnly.MinValue);

    /// <summary>Today's push is due from the reminder time until <see cref="LateWindow"/> later (and never after midnight).</summary>
    public static bool IsPushDue(DateTime localNow, TimeOnly reminder)
    {
        var at = DateOnly.FromDateTime(localNow).ToDateTime(reminder);
        return localNow >= at && localNow <= at + LateWindow;
    }

    /// <summary>
    /// <see cref="IsPickDue"/> as reminder-time ranges, so the job can query them per time zone: today's picks for every
    /// reminder up to now + 30 minutes, and tomorrow's for reminders just after midnight once that passes midnight.
    /// </summary>
    public static IReadOnlyList<ReminderRange> PickRanges(DateTime localNow)
    {
        var today = DateOnly.FromDateTime(localNow);
        var limit = localNow.TimeOfDay + PickLead;
        if (limit < OneDay) return [new ReminderRange(today, TimeOnly.MinValue, TimeOnly.FromTimeSpan(limit))];

        return
        [
            new ReminderRange(today, TimeOnly.MinValue, TimeOnly.MaxValue),
            new ReminderRange(today.AddDays(1), TimeOnly.MinValue, TimeOnly.FromTimeSpan(limit - OneDay)),
        ];
    }

    /// <summary><see cref="IsPushDue"/> as a reminder-time range for today.</summary>
    public static ReminderRange PushRange(DateTime localNow)
    {
        var now = localNow.TimeOfDay;
        var from = now - LateWindow;
        return new ReminderRange(
            DateOnly.FromDateTime(localNow),
            from < TimeSpan.Zero ? TimeOnly.MinValue : TimeOnly.FromTimeSpan(from),
            TimeOnly.FromTimeSpan(now));
    }

    /// <summary>How long FCM should keep the push for an offline device: until the user's day ends (at least 15 minutes).</summary>
    public static TimeSpan TimeToLive(DateTime localNow)
    {
        var left = DateOnly.FromDateTime(localNow).AddDays(1).ToDateTime(TimeOnly.MinValue) - localNow;
        return left < TimeSpan.FromMinutes(15) ? TimeSpan.FromMinutes(15) : left;
    }
}

/// <summary>Reminder times from <paramref name="From"/> to <paramref name="To"/> (both inclusive) whose pick or push for <paramref name="Date"/> is due.</summary>
public readonly record struct ReminderRange(DateOnly Date, TimeOnly From, TimeOnly To)
{
    public bool Contains(TimeOnly reminder) => reminder >= From && reminder <= To;
}

/// <summary>
/// Quiet hours (F17, SPEC §21.1, default 23:00–07:00): pushes that are not security alerts wait until they end. The
/// window may span midnight; <paramref name="End"/> is exclusive.
/// </summary>
public readonly record struct QuietHours(TimeOnly Start, TimeOnly End)
{
    public bool Contains(TimeOnly time) => Start != End && time.IsBetween(Start, End);
}
