using ReadIn.Application.Features.Admin;

namespace ReadIn.Application.UnitTests.Admin;

/// <summary>
/// F23 dashboard periods (contract decision 4): calendar days in Admin:TimeZone, and the previous period moved back by the
/// period's length in days, so "today" compares with yesterday up to the same time of day. A day that starts with a
/// daylight-saving jump starts at its first valid minute.
/// </summary>
public sealed class AdminWindowsTests
{
    /// <summary>Egypt's rule since 2023 (UTC+2, +1 from the last Friday of April to the last Thursday of October), built here
    /// so the test doesn't depend on the machine's time zone data.</summary>
    private static readonly TimeZoneInfo Cairo = TimeZoneInfo.CreateCustomTimeZone(
        "Test/Cairo", TimeSpan.FromHours(2), "Test Cairo", "EET", "EEST",
        [
            TimeZoneInfo.AdjustmentRule.CreateAdjustmentRule(
                new DateTime(2023, 1, 1), new DateTime(2030, 12, 31), TimeSpan.FromHours(1),
                TimeZoneInfo.TransitionTime.CreateFloatingDateRule(new DateTime(1, 1, 1, 0, 0, 0), 4, 5, DayOfWeek.Friday),
                TimeZoneInfo.TransitionTime.CreateFloatingDateRule(new DateTime(1, 1, 1, 0, 0, 0), 10, 5, DayOfWeek.Friday)),
        ]);

    private static DateTime Utc(int month, int day, int hour, int minute = 0) => new(2026, month, day, hour, minute, 0, DateTimeKind.Utc);

    private static DateOnly Date(int month, int day) => new(2026, month, day);

    [Fact]
    public void Today_runs_from_local_midnight_to_now_and_compares_with_yesterday_up_to_the_same_time()
    {
        var now = Utc(1, 15, 10); // 12:00 in Cairo (UTC+2 in winter)

        var window = AdminWindows.For(AdminPeriods.Today, now, Cairo);

        window.Should().Be(new AdminWindow(
            Utc(1, 14, 22), now, Date(1, 15), Date(1, 15),
            Utc(1, 13, 22), Utc(1, 14, 10), Date(1, 14), Date(1, 14)));
    }

    [Fact]
    public void Today_is_the_local_day_even_when_utc_is_still_on_the_day_before()
    {
        var window = AdminWindows.For(AdminPeriods.Today, Utc(1, 15, 23), Cairo); // 01:00 on the 16th in Cairo

        (window.FromUtc, window.FromDate, window.ToDate).Should().Be((Utc(1, 15, 22), Date(1, 16), Date(1, 16)));
    }

    [Fact]
    public void Yesterday_is_all_of_yesterday_and_its_previous_period_the_day_before()
    {
        var window = AdminWindows.For(AdminPeriods.Yesterday, Utc(1, 15, 10), Cairo);

        window.Should().Be(new AdminWindow(
            Utc(1, 13, 22), Utc(1, 14, 22), Date(1, 14), Date(1, 14),
            Utc(1, 12, 22), Utc(1, 13, 22), Date(1, 13), Date(1, 13)));
    }

    [Theory]
    [InlineData(AdminPeriods.Last7Days, 7)]
    [InlineData(AdminPeriods.Last30Days, 30)]
    public void The_last_n_days_include_today_and_compare_with_the_n_days_before(string period, int days)
    {
        var now = Utc(1, 31, 10); // 12:00 in Cairo on the 31st
        var today = Date(1, 31);

        var window = AdminWindows.For(period, now, Cairo);

        window.FromDate.Should().Be(today.AddDays(-(days - 1)));
        window.ToDate.Should().Be(today);
        window.FromUtc.Should().Be(new DateTime(today.AddDays(-(days - 1)), TimeOnly.MinValue, DateTimeKind.Utc).AddHours(-2));
        window.ToUtc.Should().Be(now);
        window.PreviousFromDate.Should().Be(today.AddDays(-(2 * days - 1)));
        window.PreviousToDate.Should().Be(today.AddDays(-days));
        window.PreviousFromUtc.Should().Be(window.FromUtc.AddDays(-days));
        window.PreviousToUtc.Should().Be(now.AddDays(-days));
    }

    [Fact]
    public void A_day_that_starts_with_the_spring_jump_starts_at_its_first_valid_minute()
    {
        // 24 April 2026, a Friday: at 00:00 the clocks go to 01:00 (UTC+3). It is 13:00 there.
        var now = Utc(4, 24, 10);

        var window = AdminWindows.For(AdminPeriods.Today, now, Cairo);

        // 01:00 UTC+3 = 22:00 UTC, the same instant as the midnight that didn't happen.
        window.FromUtc.Should().Be(Utc(4, 23, 22));
        window.FromDate.Should().Be(Date(4, 24));
        // Yesterday was still UTC+2: midnight 22:00 UTC, and 13:00 local = 11:00 UTC, one hour longer than today's window.
        window.PreviousFromUtc.Should().Be(Utc(4, 22, 22));
        window.PreviousToUtc.Should().Be(Utc(4, 23, 11));
    }

    [Fact]
    public void Seven_days_across_the_spring_jump_start_at_the_local_midnight_before_it()
    {
        var window = AdminWindows.For(AdminPeriods.Last7Days, Utc(4, 27, 12), Cairo); // 15:00 UTC+3 on Monday 27 April

        window.FromDate.Should().Be(Date(4, 21));
        window.FromUtc.Should().Be(Utc(4, 20, 22)); // 21 April 00:00 at UTC+2
        window.PreviousToUtc.Should().Be(Utc(4, 20, 13)); // 20 April 15:00 at UTC+2
    }

    [Fact]
    public void An_unknown_period_is_today() =>
        AdminWindows.For("whatever", Utc(1, 15, 10), Cairo).Should().Be(AdminWindows.For(AdminPeriods.Today, Utc(1, 15, 10), Cairo));

    [Theory]
    [InlineData("today", true)]
    [InlineData("yesterday", true)]
    [InlineData("7d", true)]
    [InlineData("30d", true)]
    [InlineData("week", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void Known_periods(string? period, bool known) => AdminPeriods.IsKnown(period).Should().Be(known);

    [Fact]
    public void An_unknown_time_zone_falls_back_to_utc() => AdminClock.ResolveZone("Mars/Olympus").Should().Be(TimeZoneInfo.Utc);
}
