using System.Globalization;
using System.Text;
using ReadIn.Application.Common.Content;

namespace ReadIn.Application.Features.Tags;

/// <summary>
/// The tag-name rules of SPEC F32, as <c>docs/api/contract-v1.md</c> ("Tag names") states them for the clients:
/// <see cref="Clean"/> (rule 1), <see cref="IsValidNew"/> (rule 2), <see cref="Normalize"/> (rule 3) and
/// <see cref="SlugBase"/> (rule 4).
/// </summary>
public static class TagNames
{
    public const int MinLength = 2;
    public const int MaxLength = 30;

    /// <summary>A raw name longer than this is never looked at (<c>tag.invalid</c>).</summary>
    public const int MaxRawLength = 200;

    /// <summary>At most this many names in one editor document, repeats included (more is <c>article.too_many_tags</c>).</summary>
    public const int MaxRawCount = 50;

    /// <summary>New tags one writer may create in <see cref="NewTagWindow"/> (<c>tag.limit</c>).</summary>
    public const int MaxNewPerWindow = 20;

    public static readonly TimeSpan NewTagWindow = TimeSpan.FromHours(24);

    /// <summary>A user-created tag without published articles for this long is deleted by the daily job.</summary>
    public static readonly TimeSpan EmptyRetention = TimeSpan.FromDays(30);

    private const int MaxSlugBaseLength = 80;
    private const string FallbackSlug = "tag";
    private const char Tatweel = 'ـ';

    /// <summary>
    /// Rule 1: drops invisible format characters (Unicode Cf), trims, drops leading <c>#</c>s and trims again, turns every
    /// run of whitespace into one space and writes Arabic-Indic digits as 0–9.
    /// </summary>
    public static string Clean(string? raw)
    {
        if (string.IsNullOrEmpty(raw)) return string.Empty;

        var visible = new StringBuilder(raw.Length);
        foreach (var ch in raw)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(ch) == UnicodeCategory.Format) continue;
            visible.Append(ch switch
            {
                >= '٠' and <= '٩' => (char)('0' + (ch - '٠')),
                >= '۰' and <= '۹' => (char)('0' + (ch - '۰')),
                _ => ch,
            });
        }

        var text = visible.ToString().Trim().TrimStart('#').Trim();
        var collapsed = new StringBuilder(text.Length);
        var space = false;
        foreach (var ch in text)
        {
            if (char.IsWhiteSpace(ch))
            {
                space = true;
                continue;
            }
            if (space) collapsed.Append(' ');
            space = false;
            collapsed.Append(ch);
        }
        return collapsed.ToString();
    }

    /// <summary>
    /// Rule 2, for a <see cref="Clean"/>ed name that would create a tag: 2–30 characters (UTF-16 code units), only letters,
    /// marks, digits, spaces and <c>- _ . + #</c>, and at least one letter (tatweel aside) or digit.
    /// </summary>
    public static bool IsValidNew(string cleaned)
    {
        if (cleaned.Length is < MinLength or > MaxLength) return false;

        var letterOrDigit = false;
        foreach (var rune in cleaned.EnumerateRunes())
        {
            switch (Rune.GetUnicodeCategory(rune))
            {
                case UnicodeCategory.UppercaseLetter or UnicodeCategory.LowercaseLetter or UnicodeCategory.TitlecaseLetter
                    or UnicodeCategory.ModifierLetter or UnicodeCategory.OtherLetter:
                    letterOrDigit |= rune.Value != Tatweel;
                    break;
                case UnicodeCategory.DecimalDigitNumber:
                    letterOrDigit = true;
                    break;
                case UnicodeCategory.NonSpacingMark or UnicodeCategory.SpacingCombiningMark or UnicodeCategory.EnclosingMark:
                    break;
                default:
                    if (rune.Value is not (' ' or '-' or '_' or '.' or '+' or '#')) return false;
                    break;
            }
        }
        return letterOrDigit;
    }

    /// <summary>Rule 3: the key two names share when they are one tag (lower case, SPEC §22 Arabic normalization).</summary>
    public static string Normalize(string cleaned) => ArabicNormalizer.Normalize(cleaned);

    /// <summary>
    /// The editor's list as stored: cleaned, empty names dropped, and a repeat of the same tag dropped (the first spelling
    /// stays).
    /// </summary>
    public static List<string> Distinct(IEnumerable<string?> names)
    {
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var kept = new List<string>();
        foreach (var name in names)
        {
            var cleaned = Clean(name);
            if (cleaned.Length == 0) continue;
            var key = Normalize(cleaned);
            if (key.Length > 0 && seen.Add(key)) kept.Add(cleaned);
        }
        return kept;
    }

    /// <summary>
    /// Rule 4: the slug a new tag starts from: lower case without Arabic diacritics or tatweel, <c>#</c> → <c>sharp</c>,
    /// <c>+</c> → <c>plus</c>, a leading <c>.</c> → <c>dot</c>, and every other run of characters that are not letters,
    /// marks or digits → one <c>-</c> (<c>C#</c> → <c>csharp</c>, <c>.NET</c> → <c>dotnet</c>, <c>ASP.NET Core</c> →
    /// <c>asp-net-core</c>). Never empty.
    /// </summary>
    public static string SlugBase(string name) => SlugText(name) is { Length: > 0 } slug ? slug : FallbackSlug;

    /// <summary><see cref="SlugBase"/> without the fallback: empty when <paramref name="name"/> gives no slug characters.</summary>
    public static string SlugText(string name)
    {
        var slug = new StringBuilder(name.Length + 8);
        var dash = false;

        void Append(string part)
        {
            if (dash && slug.Length > 0) slug.Append('-');
            slug.Append(part);
            dash = false;
        }

        foreach (var rune in name.ToLowerInvariant().EnumerateRunes())
        {
            if (rune.IsBmp && IsRemovedArabic((char)rune.Value)) continue;
            switch (rune.Value)
            {
                case '#':
                    Append("sharp");
                    continue;
                case '+':
                    Append("plus");
                    continue;
                case '.' when slug.Length == 0:
                    Append("dot");
                    continue;
            }

            if (Rune.IsLetterOrDigit(rune) || IsMark(rune))
            {
                if (dash && slug.Length > 0) slug.Append('-');
                slug.Append(rune.ToString());
                dash = false;
            }
            else
            {
                dash = true;
            }
        }

        var text = slug.ToString();
        if (text.Length > MaxSlugBaseLength)
        {
            var cut = text.LastIndexOf('-', MaxSlugBaseLength);
            text = cut > 20 ? text[..cut] : text[..MaxSlugBaseLength];
            if (char.IsHighSurrogate(text[^1])) text = text[..^1];
        }
        return text;
    }

    /// <summary><paramref name="slugBase"/>, or the first of <c>-2</c>, <c>-3</c>… after it that is not taken.</summary>
    public static string UniqueSlug(string slugBase, IReadOnlySet<string> taken)
    {
        if (!taken.Contains(slugBase)) return slugBase;
        for (var i = 2; ; i++)
        {
            var candidate = $"{slugBase}-{i.ToString(CultureInfo.InvariantCulture)}";
            if (!taken.Contains(candidate)) return candidate;
        }
    }

    private static bool IsMark(Rune rune) => Rune.GetUnicodeCategory(rune) is UnicodeCategory.NonSpacingMark
        or UnicodeCategory.SpacingCombiningMark or UnicodeCategory.EnclosingMark;

    /// <summary>Arabic diacritics, the superscript alef, Quranic marks and tatweel (as <see cref="ArabicNormalizer"/>).</summary>
    private static bool IsRemovedArabic(char ch) => ch is >= 'ً' and <= 'ٟ' or 'ٰ' or >= 'ۖ' and <= 'ۭ' or Tatweel;
}
