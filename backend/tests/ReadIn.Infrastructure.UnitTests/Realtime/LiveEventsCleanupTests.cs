using ReadIn.Infrastructure.Realtime;

namespace ReadIn.Infrastructure.UnitTests.Realtime;

public sealed class LiveEventsCleanupTests
{
    private static readonly DateTime Now = new(2026, 11, 3, 18, 0, 0, DateTimeKind.Utc);

    /// <summary>A push id created at <paramref name="at"/>; the random tail keeps ids made in the same ms distinct.</summary>
    private static string PushId(DateTime at, int tail = 0) => PushIds.Prefix(at) + tail.ToString("D12");

    [Fact]
    public void Push_ids_carry_their_creation_time()
    {
        var at = new DateTime(2026, 11, 3, 17, 59, 30, 123, DateTimeKind.Utc);

        PushIds.CreatedAt(PushId(at)).Should().Be(at);
        PushIds.CreatedAt("not!a!push!id").Should().BeNull();
        PushIds.CreatedAt("short").Should().BeNull();
    }

    [Fact]
    public void Push_ids_sort_in_creation_order()
    {
        var earlier = PushId(Now.AddHours(-5));
        var later = PushId(Now.AddMinutes(-1));

        string.CompareOrdinal(earlier, later).Should().BeNegative();
    }

    [Fact]
    public void Events_older_than_24_hours_go()
    {
        var old = PushId(Now.AddHours(-25));
        var recent = PushId(Now.AddHours(-23));

        LiveEventsCleanupJob.Expired([recent, old], Now).Should().Equal(old);
    }

    [Fact]
    public void At_most_100_events_stay_per_article()
    {
        var keys = Enumerable.Range(0, 130).Select(i => PushId(Now.AddMinutes(-130 + i), i)).ToList();

        var expired = LiveEventsCleanupJob.Expired(keys, Now);

        expired.Should().HaveCount(30).And.Equal(keys.Take(30), "the oldest go first");
    }

    [Fact]
    public void Keys_that_are_not_push_ids_go()
    {
        LiveEventsCleanupJob.Expired(["garbage", PushId(Now)], Now).Should().Equal("garbage");
    }
}
