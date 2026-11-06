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
        RankedCursor.Decode(cursor).Should().BeNull();
    }

    // ── The ranked For you cursor (ADR 0020) ──────────────────────

    private static readonly DateTime Snapshot = new(2026, 11, 6, 12, 0, 0, 456, DateTimeKind.Utc);

    [Theory]
    [InlineData(0)]
    [InlineData(2)]
    public void A_ranked_cursor_round_trips_with_its_snapshot(int tier)
    {
        var cursor = new RankedCursor(tier, Snapshot, At.AddSeconds(86_400 + 31_418), At, Id);

        var decoded = RankedCursor.Decode(cursor.Encode());

        decoded.Should().Be(cursor);
        decoded!.Value.Snapshot.Kind.Should().Be(DateTimeKind.Utc);
        decoded.Value.RankedAt.Kind.Should().Be(DateTimeKind.Utc);
    }

    [Fact]
    public void Ranked_and_older_cursors_never_decode_as_each_other()
    {
        var ranked = new RankedCursor(1, Snapshot, At.AddDays(1), At, Id).Encode();

        TieredTimeCursor.Decode(ranked).Should().BeNull("an old-style cursor would page newest first");
        TimeCursor.Decode(ranked).Should().BeNull();
        RankedCursor.Decode(new TieredTimeCursor(1, At, Id).Encode()).Should().BeNull("a cursor from before the ranking keeps its order");
        RankedCursor.Decode(new TimeCursor(At, Id).Encode()).Should().BeNull();
    }

    [Theory]
    [InlineData("r:1:2:3:4")]                                            // a part missing
    [InlineData("x:1:638_000:638_000:638_000:0195f3a0000070008000000000000aa")] // another prefix
    [InlineData("r:-1:1:1:1:0195f3a00000700080000000000000aa")]          // a negative tier
    [InlineData("r:0:99999999999999999999:1:1:0195f3a00000700080000000000000aa")] // ticks past long.MaxValue
    [InlineData("r:0:1:1:1:not-a-guid")]
    public void A_broken_ranked_cursor_is_no_cursor(string text) =>
        RankedCursor.Decode(Encode(text)).Should().BeNull();

    private static string Encode(string text) =>
        Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(text)).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
