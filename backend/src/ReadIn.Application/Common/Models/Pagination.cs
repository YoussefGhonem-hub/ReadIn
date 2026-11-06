using System.Globalization;
using System.Text;

namespace ReadIn.Application.Common.Models;

/// <summary>Cursor page for feeds (SPEC §17.1).</summary>
public sealed record CursorPage<T>(IReadOnlyList<T> Items, string? NextCursor);

/// <summary>Offset page for admin tables (SPEC §17.1).</summary>
public sealed record PagedList<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount)
{
    public int TotalPages => PageSize == 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
}

/// <summary>Opaque keyset cursor over (timestamp DESC, id DESC).</summary>
public readonly record struct TimeCursor(DateTime Timestamp, Guid Id)
{
    public string Encode() => CursorText.Encode($"{Timestamp.Ticks.ToString(CultureInfo.InvariantCulture)}:{Id:N}");

    public static TimeCursor? Decode(string? cursor)
    {
        if (CursorText.Decode(cursor) is not { Length: 2 } parts) return null;
        try
        {
            return new TimeCursor(
                new DateTime(long.Parse(parts[0], CultureInfo.InvariantCulture), DateTimeKind.Utc),
                Guid.ParseExact(parts[1], "N"));
        }
        catch (Exception e) when (e is FormatException or OverflowException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}

/// <summary>
/// Opaque keyset cursor over (tier ASC, timestamp DESC, id DESC): a feed made of tiers, each newest first (For you:
/// your interests, then everything else). Tier 0 encodes exactly like <see cref="TimeCursor"/>, so either one decodes.
/// </summary>
public readonly record struct TieredTimeCursor(int Tier, DateTime Timestamp, Guid Id)
{
    public string Encode() => Tier == 0
        ? new TimeCursor(Timestamp, Id).Encode()
        : CursorText.Encode($"{Tier.ToString(CultureInfo.InvariantCulture)}:{Timestamp.Ticks.ToString(CultureInfo.InvariantCulture)}:{Id:N}");

    public static TieredTimeCursor? Decode(string? cursor)
    {
        if (TimeCursor.Decode(cursor) is { } plain) return new TieredTimeCursor(0, plain.Timestamp, plain.Id);
        if (CursorText.Decode(cursor) is not { Length: 3 } parts) return null;
        try
        {
            var tier = int.Parse(parts[0], NumberStyles.None, CultureInfo.InvariantCulture);
            return new TieredTimeCursor(
                tier,
                new DateTime(long.Parse(parts[1], CultureInfo.InvariantCulture), DateTimeKind.Utc),
                Guid.ParseExact(parts[2], "N"));
        }
        catch (Exception e) when (e is FormatException or OverflowException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}

/// <summary>
/// Opaque keyset cursor over a ranked feed made of tiers (For you, ADR 0020): (tier ASC, ranked time DESC, timestamp
/// DESC, id DESC), all ranked against <see cref="Snapshot"/>, the time the first page was served. Every page of one scroll
/// ranks against the same snapshot, so the ranks don't move while the user pages. Starts with <c>r</c>, so it never
/// decodes as a <see cref="TimeCursor"/> or <see cref="TieredTimeCursor"/>, and they never decode as this one.
/// </summary>
/// <param name="RankedAt">The last card's rank: an effective time (its publish time plus its boosts).</param>
/// <param name="Timestamp">The last card's publish time, the first tie-break.</param>
public readonly record struct RankedCursor(int Tier, DateTime Snapshot, DateTime RankedAt, DateTime Timestamp, Guid Id)
{
    private const string Prefix = "r";

    public string Encode() => CursorText.Encode(string.Join(':',
        Prefix,
        Tier.ToString(CultureInfo.InvariantCulture),
        Snapshot.Ticks.ToString(CultureInfo.InvariantCulture),
        RankedAt.Ticks.ToString(CultureInfo.InvariantCulture),
        Timestamp.Ticks.ToString(CultureInfo.InvariantCulture),
        Id.ToString("N")));

    public static RankedCursor? Decode(string? cursor)
    {
        if (CursorText.Decode(cursor) is not [Prefix, var tier, var snapshot, var rankedAt, var timestamp, var id]) return null;
        try
        {
            return new RankedCursor(
                int.Parse(tier, NumberStyles.None, CultureInfo.InvariantCulture),
                Utc(snapshot),
                Utc(rankedAt),
                Utc(timestamp),
                Guid.ParseExact(id, "N"));
        }
        catch (Exception e) when (e is FormatException or OverflowException or ArgumentOutOfRangeException)
        {
            return null;
        }

        static DateTime Utc(string ticks) => new(long.Parse(ticks, NumberStyles.None, CultureInfo.InvariantCulture), DateTimeKind.Utc);
    }
}

/// <summary>
/// Opaque cursor over a ranked list (search, F16): the position of the next item. A ranked list has no stable key to
/// seek from, so the cursor counts; a cursor that doesn't decode is the first page.
/// </summary>
public readonly record struct OffsetCursor(int Offset)
{
    private const string Prefix = "o";

    public string Encode() => CursorText.Encode($"{Prefix}:{Offset.ToString(CultureInfo.InvariantCulture)}");

    public static int Decode(string? cursor) =>
        CursorText.Decode(cursor) is [Prefix, var offset]
        && int.TryParse(offset, NumberStyles.None, CultureInfo.InvariantCulture, out var value)
            ? value
            : 0;
}

/// <summary>URL-safe base64 of <c>:</c>-separated parts, for the opaque cursors.</summary>
internal static class CursorText
{
    public static string Encode(string text) =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes(text)).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    public static string[]? Decode(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor)) return null;
        try
        {
            var base64 = cursor.Replace('-', '+').Replace('_', '/');
            base64 = base64.PadRight(base64.Length + (4 - base64.Length % 4) % 4, '=');
            return Encoding.UTF8.GetString(Convert.FromBase64String(base64)).Split(':');
        }
        catch (FormatException)
        {
            return null;
        }
    }
}
