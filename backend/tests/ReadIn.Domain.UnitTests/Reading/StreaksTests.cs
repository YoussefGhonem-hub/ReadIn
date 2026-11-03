using ReadIn.Domain.Reading;

namespace ReadIn.Domain.UnitTests.Reading;

public sealed class StreaksTests
{
    private static readonly DateOnly Today = new(2026, 11, 3);

    /// <summary>Read dates as days before <see cref="Today"/> (0 = today).</summary>
    private static DateOnly[] Ago(params int[] days) => [.. days.Select(d => Today.AddDays(-d))];

    private static DateOnly[] AgoRange(int from, int to) => Ago([.. Enumerable.Range(from, to - from + 1)]);

    [Fact]
    public void Nothing_read_is_no_streak()
    {
        var history = Streaks.Compute([]);

        history.Should().BeEquivalentTo(StreakHistory.Empty);
        Streaks.StatusOn(history, Today).Should().Be(new StreakStatus(0, 0, ReadToday: false, FreezeAvailable: true, FreezePending: false));
    }

    [Fact]
    public void Consecutive_days_add_up()
    {
        var history = Streaks.Compute(AgoRange(0, 4));

        history.Current.Should().Be(5);
        history.Longest.Should().Be(5);
        history.LastReadDate.Should().Be(Today);
        history.FreezeDays.Should().BeEmpty();
    }

    [Fact]
    public void Order_and_duplicates_of_the_dates_dont_matter()
    {
        var history = Streaks.Compute([Today, Today.AddDays(-2), Today, Today.AddDays(-1)]);

        history.Current.Should().Be(3);
    }

    [Fact]
    public void One_missed_day_is_covered_by_a_freeze_that_doesnt_count_as_a_read()
    {
        // Read 5..3 days ago, missed 2 days ago, read yesterday and today.
        var history = Streaks.Compute(Ago(5, 4, 3, 1, 0));

        history.Current.Should().Be(5);
        history.FreezeDays.Should().Equal(Today.AddDays(-2));
        history.LastFreezeDate.Should().Be(Today.AddDays(-2));
    }

    [Fact]
    public void Two_missed_days_in_a_row_end_the_streak()
    {
        var history = Streaks.Compute(Ago(6, 5, 4, 1, 0));

        history.Current.Should().Be(2);
        history.Longest.Should().Be(3);
        history.FreezeDays.Should().BeEmpty();
    }

    [Fact]
    public void Only_one_freeze_per_rolling_7_days()
    {
        // Missed 8 days ago (frozen) and 3 days ago: only 5 days apart, so the second miss ends the run.
        var history = Streaks.Compute(Ago(10, 9, 7, 6, 5, 4, 2, 1, 0));

        history.FreezeDays.Should().Equal(Today.AddDays(-8));
        history.Current.Should().Be(3);
        history.Longest.Should().Be(6);
    }

    [Fact]
    public void A_freeze_is_available_again_7_days_after_the_last_one()
    {
        // Misses 9 and 2 days ago: exactly 7 days apart, both are frozen.
        var history = Streaks.Compute(Ago(10, 8, 7, 6, 5, 4, 3, 1, 0));

        history.FreezeDays.Should().Equal(Today.AddDays(-9), Today.AddDays(-2));
        history.Current.Should().Be(9);
    }

    [Fact]
    public void The_longest_streak_survives_a_reset()
    {
        var history = Streaks.Compute([.. AgoRange(30, 50), .. AgoRange(0, 2)]);

        history.Current.Should().Be(3);
        history.Longest.Should().Be(21);
    }

    [Fact]
    public void Read_today_is_alive_and_marked_read()
    {
        var status = Streaks.StatusOn(Streaks.Compute(AgoRange(0, 2)), Today);

        status.Should().Be(new StreakStatus(3, 3, ReadToday: true, FreezeAvailable: true, FreezePending: false));
    }

    [Fact]
    public void Read_until_yesterday_is_still_alive_today()
    {
        var status = Streaks.StatusOn(Streaks.Compute(AgoRange(1, 4)), Today);

        status.Current.Should().Be(4);
        status.ReadToday.Should().BeFalse();
        status.FreezePending.Should().BeFalse();
    }

    [Fact]
    public void Missing_yesterday_leaves_a_pending_freeze()
    {
        var status = Streaks.StatusOn(Streaks.Compute(AgoRange(2, 5)), Today);

        status.Should().Be(new StreakStatus(4, 4, ReadToday: false, FreezeAvailable: false, FreezePending: true));
    }

    [Fact]
    public void Missing_yesterday_without_a_freeze_left_shows_zero()
    {
        // A freeze was used 4 days ago, so yesterday can't be covered.
        var status = Streaks.StatusOn(Streaks.Compute(Ago(6, 5, 3, 2)), Today);

        status.Current.Should().Be(0);
        status.Longest.Should().Be(4);
    }

    [Fact]
    public void Two_missed_days_show_zero()
    {
        var status = Streaks.StatusOn(Streaks.Compute(AgoRange(3, 10)), Today);

        status.Current.Should().Be(0);
        status.Longest.Should().Be(8);
    }

    [Fact]
    public void Reading_after_a_pending_freeze_uses_it()
    {
        var before = Streaks.StatusOn(Streaks.Compute(AgoRange(2, 5)), Today);
        var after = Streaks.Compute([.. AgoRange(2, 5), Today]);

        before.FreezePending.Should().BeTrue();
        after.Current.Should().Be(5);
        after.FreezeDays.Should().Equal(Today.AddDays(-1));
        Streaks.StatusOn(after, Today).FreezeAvailable.Should().BeFalse("the next freeze comes 7 days after this one");
    }

    [Theory]
    [InlineData(7, 7)]
    [InlineData(30, 30)]
    [InlineData(8, null)]
    [InlineData(1, null)]
    public void Milestones_are_reached_by_the_read_that_extends_the_streak(int length, int? milestone)
    {
        var history = Streaks.Compute(AgoRange(0, length - 1));

        Streaks.MilestoneReachedOn(history, Today).Should().Be(milestone);
    }

    [Fact]
    public void A_late_read_on_an_older_date_is_no_milestone()
    {
        var history = Streaks.Compute(AgoRange(0, 6));

        Streaks.MilestoneReachedOn(history, Today.AddDays(-3)).Should().BeNull();
    }
}
