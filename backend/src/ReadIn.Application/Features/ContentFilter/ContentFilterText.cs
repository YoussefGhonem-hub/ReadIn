using System.Globalization;
using System.Text;

namespace ReadIn.Application.Features.ContentFilter;

/// <summary>
/// The text rules of the content filter (SPEC F37, contract "Legal & content filter" decision 8): one normalization for the
/// text and the listed terms, words with their inner separators removed, runs of single letters joined, repeated letters
/// collapsed, Arabic clitics stripped (prefixes, pronoun suffixes, a ta marbuta written ت) and a leetspeak form of Latin
/// words. Pure, so the matcher can be tested with any word list.
/// </summary>
public static class ContentFilterText
{
    /// <summary>A stripped candidate keeps at least this many letters; shorter terms only match a bare word.</summary>
    public const int MinStrippedLength = 3;

    /// <summary>Characters inside a word that are dropped (the word goes on): <c>. - _ * | ~</c>.</summary>
    private static readonly HashSet<char> InnerSeparators = ['.', '-', '_', '*', '|', '~'];

    /// <summary>Stacked Arabic prefixes, longest first: an optional و/ف, an optional ب/ك/ل, an optional ال (ل + ال = لل).</summary>
    public static readonly IReadOnlyList<string> ArabicPrefixes = BuildPrefixes();

    /// <summary>Arabic pronoun suffixes, longest first (after normalization ة is ه, so ه also covers a final ta marbuta).</summary>
    public static readonly IReadOnlyList<string> ArabicSuffixes =
        [.. new[] { "كما", "هما", "كم", "كن", "ها", "هم", "هن", "ني", "نا", "ك", "ه", "ي" }.OrderByDescending(s => s.Length)];

    /// <summary>
    /// SPEC §22 (diacritics and tatweel removed, <c>أ إ آ ٱ → ا</c>, <c>ى → ي</c>, <c>ة → ه</c>), lower case, Arabic-Indic and
    /// Persian digits as 0–9, invisible format characters (zero-width, BiDi marks) removed, whitespace runs as one space.
    /// </summary>
    public static string Normalize(string? text)
    {
        if (string.IsNullOrEmpty(text)) return string.Empty;
        var sb = new StringBuilder(text.Length);
        var pendingSpace = false;
        foreach (var raw in text)
        {
            if (char.IsWhiteSpace(raw))
            {
                pendingSpace = sb.Length > 0;
                continue;
            }
            if (IsDropped(raw)) continue;
            if (pendingSpace)
            {
                sb.Append(' ');
                pendingSpace = false;
            }
            sb.Append(Map(raw));
        }
        return sb.ToString();
    }

    /// <summary>A listed term in the form it is compared in: normalized, inner separators removed, words single-spaced.</summary>
    public static string NormalizeTerm(string? term) =>
        string.Join(' ', Words(Normalize(term)).Select(w => w.Joined).Where(w => w.Length > 0));

    /// <summary>Letters repeated in a row become one (<c>كلمممه</c> → <c>كلمه</c>, <c>shiiit</c> → <c>shit</c>).</summary>
    public static string Collapse(string word)
    {
        if (word.Length < 2) return word;
        var sb = new StringBuilder(word.Length);
        foreach (var ch in word)
            if (sb.Length == 0 || sb[^1] != ch || !char.IsLetter(ch)) sb.Append(ch);
        return sb.ToString();
    }

    /// <summary>A word of the text: its letters with the inner separators removed, and its parts between those separators.</summary>
    public sealed record Word(string Joined, IReadOnlyList<string> Parts);

    /// <summary>
    /// The words of a normalized text: runs of letters and digits (and <c>@ $</c>, for leetspeak), where an inner separator
    /// (<c>. - _ * | ~</c>) is dropped without ending the word. Anything else ends a word.
    /// </summary>
    public static IReadOnlyList<Word> Words(string normalized)
    {
        var words = new List<Word>();
        var joined = new StringBuilder();
        var part = new StringBuilder();
        var parts = new List<string>();

        void End()
        {
            if (part.Length > 0) parts.Add(part.ToString());
            // A leading @ is a mention's, not part of the word.
            var text = joined.ToString().TrimStart('@');
            if (text.Length > 0) words.Add(new Word(text, [.. parts.Select(p => p.TrimStart('@')).Where(p => p.Length > 0)]));
            joined.Clear();
            part.Clear();
            parts.Clear();
        }

        foreach (var ch in normalized)
        {
            if (char.IsLetterOrDigit(ch) || ch is '@' or '$')
            {
                joined.Append(ch);
                part.Append(ch);
            }
            else if (InnerSeparators.Contains(ch) && joined.Length > 0)
            {
                if (part.Length > 0) parts.Add(part.ToString());
                part.Clear();
            }
            else
            {
                End();
            }
        }
        End();
        return words;
    }

    /// <summary>Whether a word holds an Arabic letter (it then gets the affix candidates).</summary>
    public static bool IsArabic(string word) => word.Any(c => c is >= 'ء' and <= 'ي');

    /// <summary>Whether a word holds a Latin letter (it then gets a leetspeak candidate for the English lists).</summary>
    public static bool IsLatin(string word) => word.Any(c => c is >= 'a' and <= 'z');

    /// <summary>
    /// An Arabic word's candidates without its clitics: prefix-stripped, suffix-stripped and both, with a ta marbuta written
    /// ت before a suffix also tried as ه. Every candidate keeps at least <see cref="MinStrippedLength"/> letters. The bare
    /// word itself is not included.
    /// </summary>
    public static IReadOnlyList<string> StrippedCandidates(string word)
    {
        if (!IsArabic(word)) return [];
        var result = new HashSet<string>(StringComparer.Ordinal);

        var prefixStripped = new List<string> { word };
        foreach (var prefix in ArabicPrefixes)
        {
            if (word.Length > prefix.Length && word.StartsWith(prefix, StringComparison.Ordinal))
            {
                var stem = word[prefix.Length..];
                prefixStripped.Add(stem);
                Add(result, stem);
            }
        }

        foreach (var stem in prefixStripped)
        {
            foreach (var suffix in ArabicSuffixes)
            {
                if (stem.Length <= suffix.Length || !stem.EndsWith(suffix, StringComparison.Ordinal)) continue;
                var root = stem[..^suffix.Length];
                Add(result, root);
                // كلمتك → كلمت: the ta marbuta is written ت before a suffix; كلمه is the listed form after §22.
                if (root.EndsWith('ت')) Add(result, root[..^1] + "ه");
            }
        }
        result.Remove(word);
        return [.. result];
    }

    /// <summary>
    /// Leetspeak forms of a Latin word, for the English lists only: <c>0→o 3→e 4→a @→a $→s 5→s 7→t</c> and <c>1→i</c> or
    /// <c>1→l</c>. Empty when the word has nothing to replace.
    /// </summary>
    public static IReadOnlyList<string> LeetCandidates(string word)
    {
        if (!IsLatin(word) || !word.Any(c => c is '0' or '1' or '3' or '4' or '5' or '7' or '@' or '$')) return [];
        string Replace(char one) => new([.. word.Select(c => c switch
        {
            '0' => 'o',
            '1' => one,
            '3' => 'e',
            '4' => 'a',
            '@' => 'a',
            '$' => 's',
            '5' => 's',
            '7' => 't',
            _ => c,
        })]);
        return [.. new[] { Replace('i'), Replace('l') }.Distinct(StringComparer.Ordinal)];
    }

    private static void Add(HashSet<string> set, string candidate)
    {
        if (LetterCount(candidate) >= MinStrippedLength) set.Add(candidate);
    }

    public static int LetterCount(string text) => text.Count(char.IsLetter);

    private static IReadOnlyList<string> BuildPrefixes()
    {
        var set = new HashSet<string>(StringComparer.Ordinal);
        foreach (var conjunction in new[] { "", "و", "ف" })
        foreach (var preposition in new[] { "", "ب", "ك", "ل" })
        foreach (var article in new[] { "", "ال" })
        {
            var prefix = preposition == "ل" && article == "ال" ? conjunction + "لل" : conjunction + preposition + article;
            if (prefix.Length > 0) set.Add(prefix);
        }
        return [.. set.OrderByDescending(p => p.Length).ThenBy(p => p, StringComparer.Ordinal)];
    }

    /// <summary>Diacritics (and Quranic marks), tatweel and invisible format characters (zero-width, BiDi) are dropped.</summary>
    private static bool IsDropped(char ch) =>
        ch is >= 'ً' and <= 'ٟ' or 'ٰ' or >= 'ۖ' and <= 'ۭ' or 'ـ'
        || char.GetUnicodeCategory(ch) == UnicodeCategory.Format;

    private static char Map(char ch) => ch switch
    {
        'أ' or 'إ' or 'آ' or 'ٱ' => 'ا',
        'ى' => 'ي',
        'ة' => 'ه',
        >= '٠' and <= '٩' => (char)('0' + (ch - '٠')),
        >= '۰' and <= '۹' => (char)('0' + (ch - '۰')),
        _ => char.ToLowerInvariant(ch),
    };
}
