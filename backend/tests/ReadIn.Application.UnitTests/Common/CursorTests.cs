using ReadIn.Application.Common.Models;

namespace ReadIn.Application.UnitTests.Common;

/// <summary>The opaque keyset cursors (SPEC §17.1); the tiered one pages For you across its groups (F03).</summary>
public sealed class CursorTests
{
    private static readonly DateTime At = new(2026, 11, 4, 9, 30, 15, 123, DateTimeKind.Utc);
    private static readonly Guid Id = Guid.Parse("0195f3a0-0000-7000-8000-0000000000aa");

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    public void A_tiered_cursor_round_trips(int tier) =>
        TieredTimeCursor.Decode(new TieredTimeCursor(tier, At, Id).Encode()).Should().Be(new TieredTimeCursor(tier, At, Id));

    [Fact]
    public void Tier_zero_is_a_plain_time_cursor_both_ways()
    {
        new TieredTimeCursor(0, At, Id).Encode().Should().Be(new TimeCursor(At, Id).Encode());
        TieredTimeCursor.Decode(new TimeCursor(At, Id).Encode()).Should().Be(new TieredTimeCursor(0, At, Id));
        TimeCursor.Decode(new TieredTimeCursor(1, At, Id).Encode()).Should().BeNull("a plain cursor can't say which tier it is in");
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("not a cursor!")]
    [InlineData("LTE6MToy")] // "-1:1:2"
    [InlineData("OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTowMTk1ZjNhMDAwMDA3MDAwODAwMDAwMDAwMDAwMDBhYQ")] // ticks past long.MaxValue
    [InlineData("OTAwMDAwMDAwMDAwMDAwMDAwMDowMTk1ZjNhMDAwMDA3MDAwODAwMDAwMDAwMDAwMDBhYQ")] // ticks past DateTime.MaxValue
    [InlineData("MTo5MDAwMDAwMDAwMDAwMDAwMDAwOjAxOTVmM2EwMDAwMDcwMDA4MDAwMDAwMDAwMDAwMGFh")] // the same in tier 1
    public void Anything_else_is_no_cursor(string? cursor)
    {
        TieredTimeCursor.Decode(cursor).Should().BeNull();
        TimeCursor.Decode(cursor).Should().BeNull();
    }
}
