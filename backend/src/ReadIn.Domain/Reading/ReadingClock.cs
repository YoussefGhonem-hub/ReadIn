namespace ReadIn.Domain.Reading;

/// <summary>
/// What "a day" means for streaks (ADR 0013): the calendar date in the user's profile time zone (<c>Users.TimeZone</c>,
/// an IANA id) at the moment the server records the reading. A date is fixed once recorded: changing the time zone
/// later never moves past reading days.
/// </summary>
public static class ReadingClock
{
    /// <summary>An unknown time zone id falls back to UTC, like the daily article pick (SPEC F07).</summary>
    public static DateOnly LocalDate(DateTime utcNow, string? timeZone)
    {
        var zone = timeZone is not null && TimeZoneInfo.TryFindSystemTimeZoneById(timeZone, out var tz) ? tz : TimeZoneInfo.Utc;
        return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utcNow, DateTimeKind.Utc), zone));
    }
}
