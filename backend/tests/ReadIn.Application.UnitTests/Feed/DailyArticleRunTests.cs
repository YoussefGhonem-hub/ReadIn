using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Domain.Common;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.UnitTests.Feed;

/// <summary>
/// Idempotency of the daily-article job: runs it the way Hangfire does (every 5 minutes, sometimes twice, sometimes not
/// at all) against one user, selecting with the same reminder ranges and claiming the push on the same
/// <see cref="DailyPick"/> as <see cref="DailyArticleDelivery"/>. Every local day must get exactly one pick and one push.
/// </summary>
public sealed class DailyArticleRunTests
{
    /// <summary>One user's picks by local date, and the pushes "sent" (local date → local time it went out).</summary>
    private sealed class FakeUser(string zone, TimeOnly reminder)
    {
        public Dictionary<DateOnly, DailyPick> Picks { get; } = [];
        public List<(DateOnly Date, DateTime LocalSentAt)> Pushes { get; } = [];

        /// <summary>One run at <paramref name="utcNow"/>, as <see cref="DailyArticleDelivery.RunAsync"/> selects users.</summary>
        public void Run(DateTime utcNow)
        {
            var localNow = DailySchedule.LocalNow(utcNow, zone);
            foreach (var range in DailySchedule.PickRanges(localNow))
            {
                if (range.Contains(reminder) && !Picks.ContainsKey(range.Date))
                    Picks[range.Date] = new DailyPick(Guid.Empty, range.Date, Guid.NewGuid());
            }

            var push = DailySchedule.PushRange(localNow);
            if (push.Contains(reminder) && Picks.TryGetValue(push.Date, out var pick) && pick.MarkNotified(utcNow))
                Pushes.Add((push.Date, localNow));
        }
    }

    private static IEnumerable<DateTime> EveryFiveMinutes(DateTime fromUtc, TimeSpan length)
    {
        for (var t = fromUtc; t < fromUtc + length; t = t.AddMinutes(5)) yield return t;
    }

    [Theory]
    [InlineData("Africa/Cairo", 8, 0)]
    [InlineData("Asia/Tokyo", 7, 45)]
    [InlineData("America/Los_Angeles", 21, 0)]
    [InlineData("Pacific/Kiritimati", 0, 10)] // UTC+14 and just after midnight: picked the evening before
    [InlineData("Pacific/Pago_Pago", 23, 55)] // UTC-11 and just before midnight
    public void Every_day_gets_one_pick_and_one_push_even_when_runs_repeat(string zone, int hour, int minute)
    {
        var reminder = new TimeOnly(hour, minute);
        var user = new FakeUser(zone, reminder);
        var start = new DateTime(2026, 11, 2, 0, 0, 0, DateTimeKind.Utc);
        var firstDay = DailySchedule.LocalDate(start, zone);

        foreach (var utcNow in EveryFiveMinutes(start, TimeSpan.FromDays(4)))
        {
            user.Run(utcNow);
            user.Run(utcNow); // a retried or overlapping run changes nothing
        }

        var days = user.Pushes.Select(p => p.Date).ToList();
        days.Should().OnlyHaveUniqueItems("a day's push is sent once");
        days.Should().HaveCountGreaterThanOrEqualTo(3);
        days.Should().OnlyContain(d => user.Picks.ContainsKey(d));
        // The first day may start inside the late window (a catch-up push); every later one goes out on time.
        user.Pushes.Where(p => p.Date > firstDay).Should().OnlyContain(p => p.LocalSentAt >= p.Date.ToDateTime(reminder)
            && p.LocalSentAt < p.Date.ToDateTime(reminder).AddMinutes(5), "it goes out on the first run at or after the reminder");
        var lastDay = DailySchedule.LocalDate(start.AddDays(4), zone);
        user.Picks.Keys.Where(d => d > firstDay && d < lastDay).Should().OnlyContain(d => days.Contains(d), "every full day has a pick and a push");
    }

    [Fact]
    public void Missed_runs_catch_up_within_the_late_window_and_never_send_twice()
    {
        var user = new FakeUser("Africa/Cairo", new TimeOnly(8, 0));
        var day = new DateOnly(2026, 11, 3);

        // The server is down from 07:00 to 09:15 Cairo time (05:00–07:15 UTC): no pick at 07:30, no push at 08:00.
        foreach (var utcNow in EveryFiveMinutes(new DateTime(2026, 11, 3, 0, 0, 0, DateTimeKind.Utc), TimeSpan.FromHours(12))
                     .Where(t => t < new DateTime(2026, 11, 3, 5, 0, 0, DateTimeKind.Utc) || t >= new DateTime(2026, 11, 3, 7, 15, 0, DateTimeKind.Utc)))
        {
            user.Run(utcNow);
        }

        user.Picks.Should().ContainKey(day);
        user.Pushes.Should().ContainSingle().Which.Should().Be((day, new DateTime(2026, 11, 3, 9, 15, 0)));
    }

    [Fact]
    public void A_push_missed_by_more_than_the_late_window_is_dropped_but_the_pick_is_made()
    {
        var user = new FakeUser("Africa/Cairo", new TimeOnly(8, 0));

        // Down from 07:00 to 10:30 Cairo time.
        foreach (var utcNow in EveryFiveMinutes(new DateTime(2026, 11, 3, 0, 0, 0, DateTimeKind.Utc), TimeSpan.FromHours(20))
                     .Where(t => t < new DateTime(2026, 11, 3, 5, 0, 0, DateTimeKind.Utc) || t >= new DateTime(2026, 11, 3, 8, 30, 0, DateTimeKind.Utc)))
        {
            user.Run(utcNow);
        }

        user.Picks.Should().ContainKey(new DateOnly(2026, 11, 3), "the hero card is still today's article");
        user.Pushes.Should().BeEmpty();
    }

    [Fact]
    public void The_repeated_dst_hour_sends_one_push()
    {
        // New York falls back on 2026-11-01: 01:30 happens at 05:30 and again at 06:30 UTC.
        var user = new FakeUser("America/New_York", new TimeOnly(1, 30));

        foreach (var utcNow in EveryFiveMinutes(new DateTime(2026, 10, 31, 12, 0, 0, DateTimeKind.Utc), TimeSpan.FromDays(2)))
            user.Run(utcNow);

        user.Pushes.Where(p => p.Date == new DateOnly(2026, 11, 1)).Should().ContainSingle();
    }

    [Fact]
    public void The_skipped_dst_hour_still_sends_the_push()
    {
        // New York springs forward on 2026-03-08: 02:30 never happens; the push goes out at 03:00.
        var user = new FakeUser("America/New_York", new TimeOnly(2, 30));

        foreach (var utcNow in EveryFiveMinutes(new DateTime(2026, 3, 7, 12, 0, 0, DateTimeKind.Utc), TimeSpan.FromDays(2)))
            user.Run(utcNow);

        user.Pushes.Should().Contain((new DateOnly(2026, 3, 8), new DateTime(2026, 3, 8, 3, 0, 0)));
        user.Pushes.Where(p => p.Date == new DateOnly(2026, 3, 8)).Should().ContainSingle();
    }

    [Fact]
    public void Moving_the_reminder_later_after_the_push_does_not_send_a_second_one()
    {
        var pick = new DailyPick(Guid.NewGuid(), new DateOnly(2026, 11, 3), Guid.NewGuid());
        var eight = new DateTime(2026, 11, 3, 6, 0, 0, DateTimeKind.Utc);

        pick.MarkNotified(eight).Should().BeTrue();
        // The user now picks 21:00: the push range matches again at 21:00, but the pick is already claimed.
        DailySchedule.IsPushDue(new DateTime(2026, 11, 3, 21, 0, 0), new TimeOnly(21, 0)).Should().BeTrue();
        pick.MarkNotified(eight.AddHours(13)).Should().BeFalse();
    }
}

public sealed class DailyArticlePushTests
{
    private static readonly Guid ArticleId = Guid.Parse("0a1b2c3d-0000-0000-0000-000000000001");

    [Theory]
    [InlineData(UiLanguages.Arabic, "مقال اليوم جاهز ☕")]
    [InlineData(UiLanguages.English, "Today's article is ready ☕")]
    public void The_title_is_in_the_ui_language_and_the_body_is_the_article_title(string ui, string title)
    {
        var push = DailyArticlePush.Create(["t1", "t2"], ui, ArticleId, "rag-vs-fine-tuning", "RAG ولا Fine-tuning؟", "ar-EG", TimeSpan.FromHours(3));

        push.Title.Should().Be(title);
        push.Body.Should().Be("RAG ولا Fine-tuning؟");
        push.Tokens.Should().Equal("t1", "t2");
        push.CollapseKey.Should().Be("daily_article");
        push.TimeToLive.Should().Be(TimeSpan.FromHours(3));
    }

    [Fact]
    public void The_payload_opens_the_reader_on_every_client()
    {
        var push = DailyArticlePush.Create(["t1"], UiLanguages.Arabic, ArticleId, "rag-vs-fine-tuning", "RAG", ArticleLanguages.English, TimeSpan.FromHours(1));

        push.Data.Should().BeEquivalentTo(new Dictionary<string, string>
        {
            ["type"] = "daily_article",
            ["articleId"] = ArticleId.ToString(),
            ["slug"] = "rag-vs-fine-tuning",
            ["link"] = "readin://a/rag-vs-fine-tuning",
            ["lang"] = "en",
        });
    }
}
