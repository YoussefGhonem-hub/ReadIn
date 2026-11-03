using ReadIn.Domain.Reading;

namespace ReadIn.Domain.UnitTests.Reading;

public sealed class ReadingClockTests
{
    [Fact]
    public void A_late_evening_in_Cairo_is_already_the_next_day()
    {
        // 22:30 UTC on 2 Nov is 00:30 on 3 Nov in Cairo (UTC+2 after the October DST change).
        ReadingClock.LocalDate(new DateTime(2026, 11, 2, 22, 30, 0, DateTimeKind.Utc), "Africa/Cairo")
            .Should().Be(new DateOnly(2026, 11, 3));
    }

    [Fact]
    public void The_same_instant_is_a_different_date_east_and_west()
    {
        var instant = new DateTime(2026, 11, 3, 12, 0, 0, DateTimeKind.Utc);

        ReadingClock.LocalDate(instant, "Pacific/Kiritimati").Should().Be(new DateOnly(2026, 11, 4)); // UTC+14
        ReadingClock.LocalDate(instant, "Pacific/Pago_Pago").Should().Be(new DateOnly(2026, 11, 3)); // UTC−11
    }

    [Theory]
    [InlineData("2026-03-08T06:59:00Z", "2026-03-08")] // 01:59 EST, just before the clocks go forward
    [InlineData("2026-03-08T07:00:00Z", "2026-03-08")] // 03:00 EDT
    [InlineData("2026-03-09T03:59:00Z", "2026-03-08")] // 23:59 EDT
    [InlineData("2026-03-09T04:00:00Z", "2026-03-09")] // midnight EDT
    public void Daylight_saving_changes_dont_move_the_date(string utc, string expected)
    {
        var instant = DateTime.Parse(utc, null, System.Globalization.DateTimeStyles.AdjustToUniversal);

        ReadingClock.LocalDate(instant, "America/New_York").Should().Be(DateOnly.Parse(expected));
    }

    [Fact]
    public void An_unknown_time_zone_falls_back_to_utc()
    {
        ReadingClock.LocalDate(new DateTime(2026, 11, 2, 23, 0, 0, DateTimeKind.Utc), "Mars/Olympus_Mons")
            .Should().Be(new DateOnly(2026, 11, 2));
    }
}
