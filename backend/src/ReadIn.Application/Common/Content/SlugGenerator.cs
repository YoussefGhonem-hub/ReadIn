using System.Text;

namespace ReadIn.Application.Common.Content;

public static class SlugGenerator
{
    public const int MaxLength = 80;

    /// <summary>
    /// Builds an ASCII slug from a (preferably English) title. Returns an empty string when the title
    /// has no Latin letters or digits, so callers can fall back to another source.
    /// </summary>
    public static string FromTitle(string? title)
    {
        if (string.IsNullOrWhiteSpace(title)) return string.Empty;

        var sb = new StringBuilder(title.Length);
        var dash = false;
        foreach (var ch in title.ToLowerInvariant())
        {
            if (char.IsAsciiLetterOrDigit(ch))
            {
                if (dash && sb.Length > 0) sb.Append('-');
                sb.Append(ch);
                dash = false;
            }
            else if (ch is '#' && sb.Length > 0 && sb[^1] == 'c')
            {
                sb.Append("sharp"); // "C#" → "csharp"
            }
            else
            {
                dash = true;
            }
        }

        var slug = sb.ToString();
        if (slug.Length <= MaxLength) return slug;

        var cut = slug.LastIndexOf('-', MaxLength);
        return cut > 20 ? slug[..cut] : slug[..MaxLength];
    }
}
