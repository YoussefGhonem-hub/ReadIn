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
    public string Encode() =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes($"{Timestamp.Ticks.ToString(CultureInfo.InvariantCulture)}:{Id:N}"))
            .TrimEnd('=').Replace('+', '-').Replace('/', '_');

    public static TimeCursor? Decode(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor)) return null;
        try
        {
            var base64 = cursor.Replace('-', '+').Replace('_', '/');
            base64 = base64.PadRight(base64.Length + (4 - base64.Length % 4) % 4, '=');
            var parts = Encoding.UTF8.GetString(Convert.FromBase64String(base64)).Split(':');
            if (parts.Length != 2) return null;
            return new TimeCursor(
                new DateTime(long.Parse(parts[0], CultureInfo.InvariantCulture), DateTimeKind.Utc),
                Guid.ParseExact(parts[1], "N"));
        }
        catch (FormatException)
        {
            return null;
        }
    }
}
