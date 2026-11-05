using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.WriterCategories;

/// <summary>
/// The category-name rules of SPEC F31, as <c>docs/api/contract-v1.md</c> ("Writer categories", Names) states them:
/// <see cref="Clean"/>, <see cref="IsValid"/>, <see cref="Normalize"/> (tag rule 3) and <see cref="SlugBase"/> (tag rule 4).
/// </summary>
public static partial class WriterCategoryNames
{
    private const char Tatweel = 'ـ';
    private const string FallbackSlug = "category";

    /// <summary>A raw name longer than this is never looked at (<c>category.name_invalid</c>).</summary>
    public const int MaxRawLength = 200;

    /// <summary>
    /// Like tag rule 1 without dropping a leading <c>#</c>: removes invisible format (Unicode Cf) and control characters,
    /// trims, turns every run of whitespace into one space and writes Arabic-Indic digits as 0–9.
    /// </summary>
    public static string Clean(string? raw)
    {
        if (string.IsNullOrEmpty(raw) || raw.Length > MaxRawLength) return string.Empty;

        var text = new StringBuilder(raw.Length);
        var space = false;
        foreach (var ch in raw)
        {
            if (char.IsWhiteSpace(ch))
            {
                space = text.Length > 0;
                continue;
            }
            if (CharUnicodeInfo.GetUnicodeCategory(ch) is UnicodeCategory.Format or UnicodeCategory.Control) continue;
            if (space) text.Append(' ');
            space = false;
            text.Append(ch switch
            {
                >= '٠' and <= '٩' => (char)('0' + (ch - '٠')),
                >= '۰' and <= '۹' => (char)('0' + (ch - '۰')),
                _ => ch,
            });
        }
        return text.ToString();
    }

    /// <summary>A <see cref="Clean"/>ed name: 1–40 characters (UTF-16 code units) with at least one letter (not tatweel) or digit.</summary>
    public static bool IsValid(string cleaned)
    {
        if (cleaned.Length is 0 or > WriterCategory.MaxNameLength) return false;
        foreach (var rune in cleaned.EnumerateRunes())
        {
            switch (Rune.GetUnicodeCategory(rune))
            {
                case UnicodeCategory.UppercaseLetter or UnicodeCategory.LowercaseLetter or UnicodeCategory.TitlecaseLetter
                    or UnicodeCategory.ModifierLetter or UnicodeCategory.OtherLetter when rune.Value != Tatweel:
                case UnicodeCategory.DecimalDigitNumber:
                    return true;
            }
        }
        return false;
    }

    /// <summary>The key two names of one writer share when they are the same category (tag rule 3).</summary>
    public static string Normalize(string cleaned) => TagNames.Normalize(cleaned);

    /// <summary>The slug a new category starts from (tag rule 4). Never empty and never starts with <c>_</c>.</summary>
    public static string SlugBase(string name) => TagNames.SlugText(name) is { Length: > 0 } slug ? slug : FallbackSlug;

    /// <summary>
    /// The neutral name a moderator's clear gives a category: <c>قسم {n}</c> for a writer whose UI language is Arabic,
    /// <c>Category {n}</c> otherwise.
    /// </summary>
    public static string Placeholder(string? uiLanguage, int number) =>
        string.Equals(uiLanguage, "en", StringComparison.OrdinalIgnoreCase)
            ? $"Category {number.ToString(CultureInfo.InvariantCulture)}"
            : $"قسم {number.ToString(CultureInfo.InvariantCulture)}";

    /// <summary>A name a moderator's clear could have given (<c>قسم 3</c>, <c>Category 3</c>): clearing it again changes nothing.</summary>
    public static bool IsPlaceholder(string name) => PlaceholderPattern().IsMatch(name);

    [GeneratedRegex(@"^(قسم|Category) [0-9]+$", RegexOptions.CultureInvariant)]
    private static partial Regex PlaceholderPattern();
}
