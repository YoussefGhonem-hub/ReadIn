using ReadIn.Application.Features.Feed.DailyArticle;

namespace ReadIn.Application.UnitTests.Feed;

/// <summary>Time-zone math of the daily article (SPEC F07, §21.1): local dates, DST, midnight and the late window.</summary>
public sealed class DailyScheduleTests
{
    private static DateTime Utc(int month, int day, int hour, int minute, int year = 2026) =>
        new(year, month, day, hour, minute, 0, DateTimeKind.Utc);

    private static DateTime Local(int month, int day, int hour, int minute, int year = 2026) =>
        new(year, month, day, hour, minute, 0, DateTimeKind.Unspecified);

    private static TimeOnly At(int hour, int minute) => new(hour, minute);

    [Theory]
    // 2026-11-03 22:30 UTC is already the 4th east of UTC+1:30 and still the 3rd west of it.
    [InlineData("Africa/Cairo", "2026-11-04 00:30")] // UTC+2 (Egypt's summer time ended in October)
    [InlineData("Asia/Tokyo", "2026-11-04 07:30")] // UTC+9
    [InlineData("Pacific/Kiritimati", "2026-11-04 12:30")] // UTC+14, the first to start a day
    [InlineData("Asia/Kolkata", "2026-11-04 04:00")] // UTC+5:30
    [InlineData("Europe/London", "2026-11-03 22:30")] // UTC+0 in winter
    [InlineData("America/Los_Angeles", "2026-11-03 14:30")] // UTC-8 (DST ended on Nov 1)
    [InlineData("Pacific/Pago_Pago", "2026-11-03 11:30")] // UTC-11, the last to end a day
    public void Users_ahead_of_and_behind_utc_get_their_own_local_time_and_date(string zone, string expected)
    {
        var utcNow = Utc(11, 3, 22, 30);

        DailySchedule.LocalNow(utcNow, zone).ToString("yyyy-MM-dd HH:mm", System.Globalization.CultureInfo.InvariantCulture)
            .Should().Be(expected);
        DailySchedule.LocalDate(utcNow, zone).Should().Be(DateOnly.Parse(expected[..10], System.Globalization.CultureInfo.InvariantCulture));
    }

    [Theory]
    [InlineData("Mars/Olympus_Mons")]
    [InlineData("")]
    [InlineData(null)]
    public void Unknown_time_zones_fall_back_to_utc(string? zone) =>
        DailySchedule.LocalDate(Utc(11, 3, 23, 59), zone).Should().Be(new DateOnly(2026, 11, 3));

    [Fact]
    public void The_date_rolls_over_at_local_midnight_not_utc_midnight()
    {
        // Tokyo, reminder 08:00: the pick for Nov 4 is made at 07:30 local, which is still Nov 3 in UTC.
        var localNow = DailySchedule.LocalNow(Utc(11, 3, 22, 30), "Asia/Tokyo");

        DailySchedule.IsPickDue(localNow, At(8, 0), new DateOnly(2026, 11, 4)).Should().BeTrue();
        DailySchedule.IsPushDue(localNow, At(8, 0)).Should().BeFalse("the push waits for 08:00");
        DailySchedule.IsPushDue(DailySchedule.LocalNow(Utc(11, 3, 23, 0), "Asia/Tokyo"), At(8, 0)).Should().BeTrue();

        // Los Angeles, same instant: it is 14:30 on Nov 3, so the reminder of Nov 3 is long gone.
        var behind = DailySchedule.LocalNow(Utc(11, 3, 22, 30), "America/Los_Angeles");
        DailySchedule.IsPickDue(behind, At(8, 0), new DateOnly(2026, 11, 3)).Should().BeTrue("a late pick is still made for today");
        DailySchedule.IsPushDue(behind, At(8, 0)).Should().BeFalse("6.5 hours late is past the late window");
    }

    [Fact]
    public void The_pick_is_made_30_minutes_before_the_reminder()
    {
        var today = new DateOnly(2026, 11, 3);

        DailySchedule.IsPickDue(Local(11, 3, 7, 29), At(8, 0), today).Should().BeFalse();
        DailySchedule.IsPickDue(Local(11, 3, 7, 30), At(8, 0), today).Should().BeTrue();
        DailySchedule.IsPickDue(Local(11, 3, 23, 59), At(8, 0), today).Should().BeTrue("missed runs still make the day's pick");
    }

    [Fact]
    public void The_push_goes_out_at_the_reminder_and_at_most_two_hours_late()
    {
        DailySchedule.IsPushDue(Local(11, 3, 7, 59), At(8, 0)).Should().BeFalse();
        DailySchedule.IsPushDue(Local(11, 3, 8, 0), At(8, 0)).Should().BeTrue();
        DailySchedule.IsPushDue(Local(11, 3, 10, 0), At(8, 0)).Should().BeTrue("a run missed by the job's downtime catches up");
        DailySchedule.IsPushDue(Local(11, 3, 10, 1), At(8, 0)).Should().BeFalse("hours late is worse than no push; the hero card stays");
    }

    [Fact]
    public void A_reminder_just_after_midnight_is_picked_the_evening_before()
    {
        var tomorrow = new DateOnly(2026, 11, 4);

        DailySchedule.IsPickDue(Local(11, 3, 23, 39), At(0, 10), tomorrow).Should().BeFalse();
        DailySchedule.IsPickDue(Local(11, 3, 23, 40), At(0, 10), tomorrow).Should().BeTrue();
        DailySchedule.IsPushDue(Local(11, 3, 23, 40), At(0, 10)).Should().BeFalse("that is yesterday's 00:10");
        DailySchedule.IsPushDue(Local(11, 4, 0, 10), At(0, 10)).Should().BeTrue();

        var ranges = DailySchedule.PickRanges(Local(11, 3, 23, 40));
        ranges.Should().HaveCount(2);
        ranges[1].Date.Should().Be(tomorrow);
        ranges[1].Contains(At(0, 10)).Should().BeTrue();
        ranges[1].Contains(At(0, 11)).Should().BeFalse();
    }

    [Fact]
    public void A_reminder_just_before_midnight_never_spills_into_the_next_day()
    {
        DailySchedule.IsPushDue(Local(11, 3, 23, 59), At(23, 50)).Should().BeTrue();
        DailySchedule.IsPushDue(Local(11, 4, 0, 30), At(23, 50)).Should().BeFalse("at 00:30 it is a new day with a new pick");
        DailySchedule.PushRange(Local(11, 4, 0, 30)).Should().Be(new ReminderRange(new DateOnly(2026, 11, 4), TimeOnly.MinValue, At(0, 30)));
    }

    [Fact]
    public void A_reminder_inside_the_skipped_dst_hour_fires_right_after_the_jump()
    {
        // New York, 2026-03-08: 02:00 EST jumps to 03:00 EDT, so 02:30 never happens.
        const string zone = "America/New_York";
        var before = DailySchedule.LocalNow(Utc(3, 8, 6, 59), zone);
        var after = DailySchedule.LocalNow(Utc(3, 8, 7, 0), zone);

        before.Should().Be(Local(3, 8, 1, 59));
        after.Should().Be(Local(3, 8, 3, 0));
        DailySchedule.IsPushDue(before, At(2, 30)).Should().BeFalse();
        DailySchedule.IsPushDue(after, At(2, 30)).Should().BeTrue();
        DailySchedule.IsPickDue(after, At(2, 30), new DateOnly(2026, 3, 8)).Should().BeTrue();
    }

    [Fact]
    public void A_reminder_inside_the_repeated_dst_hour_is_due_twice_so_the_pick_claims_it()
    {
        // New York, 2026-11-01: 02:00 EDT falls back to 01:00 EST, so 01:30 happens twice (05:30 and 06:30 UTC).
        const string zone = "America/New_York";
        var first = DailySchedule.LocalNow(Utc(11, 1, 5, 30), zone);
        var second = DailySchedule.LocalNow(Utc(11, 1, 6, 30), zone);

        first.Should().Be(second);
        DailySchedule.IsPushDue(first, At(1, 30)).Should().BeTrue();
        DailySchedule.LocalDate(Utc(11, 1, 6, 30), zone).Should().Be(new DateOnly(2026, 11, 1), "both are the same local day");
    }

    [Fact]
    public void The_query_ranges_select_exactly_the_reminders_that_are_due()
    {
        // The job queries reminder-time ranges per time zone; they must agree with the per-user rules at every minute.
        var today = new DateOnly(2026, 11, 3);
        var reminders = Enumerable.Range(0, 24 * 60).Select(m => TimeOnly.FromTimeSpan(TimeSpan.FromMinutes(m))).ToList();

        for (var minute = 0; minute < 24 * 60; minute += 7)
        {
            var localNow = today.ToDateTime(TimeOnly.MinValue).AddMinutes(minute).AddSeconds(minute % 60);
            var picks = DailySchedule.PickRanges(localNow);
            var push = DailySchedule.PushRange(localNow);

            foreach (var reminder in reminders)
            {
                foreach (var date in new[] { today, today.AddDays(1) })
                {
                    picks.Any(r => r.Date == date && r.Contains(reminder))
                        .Should().Be(DailySchedule.IsPickDue(localNow, reminder, date), $"pick of {date} at {localNow:HH:mm:ss} for {reminder}");
                }
                (push.Date == today && push.Contains(reminder))
                    .Should().Be(DailySchedule.IsPushDue(localNow, reminder), $"push at {localNow:HH:mm:ss} for {reminder}");
            }
        }
    }

    [Fact]
    public void A_push_lives_until_the_users_day_ends()
    {
        DailySchedule.TimeToLive(Local(11, 3, 8, 0)).Should().Be(TimeSpan.FromHours(16));
        DailySchedule.TimeToLive(Local(11, 3, 23, 55)).Should().Be(TimeSpan.FromMinutes(15), "never shorter than 15 minutes");
    }

    [Fact]
    public void Quiet_hours_may_span_midnight()
    {
        var night = new QuietHours(At(23, 0), At(7, 0));

        night.Contains(At(23, 0)).Should().BeTrue();
        night.Contains(At(2, 0)).Should().BeTrue();
        night.Contains(At(7, 0)).Should().BeFalse("the end is exclusive");
        night.Contains(At(12, 0)).Should().BeFalse();
        new QuietHours(At(8, 0), At(8, 0)).Contains(At(8, 0)).Should().BeFalse("an empty window silences nothing");
    }
}
