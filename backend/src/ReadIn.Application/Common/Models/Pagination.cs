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
