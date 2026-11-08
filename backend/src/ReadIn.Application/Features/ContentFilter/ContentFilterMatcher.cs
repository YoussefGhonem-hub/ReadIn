using System.Text.RegularExpressions;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.ContentFilter;

/// <summary>A term the matcher compares: its normalized form, list language and level.</summary>
public sealed record FilterTerm(string Normalized, string Language, ContentFilterLevel Level);

/// <summary>What the filter found in a text: the strongest level (null = nothing) and the matched terms (for staff only).</summary>
public sealed record ContentCheck(ContentFilterLevel? Level, IReadOnlyList<string> Matches)
{
    public static readonly ContentCheck Clean = new(null, []);

    public bool IsBlocked => Level == ContentFilterLevel.Block;
    public bool IsFlagged => Level == ContentFilterLevel.Flag;
}

/// <summary>
/// The content filter's matcher (SPEC F37, contract decision 8): whole words only, never substrings. Each word of the text
/// gives candidates (itself and its parts, joined runs of single letters, the Arabic clitic-stripped forms, the leetspeak
/// form of a Latin word for the English lists), each also compared collapsed. A term of 2 letters or fewer matches only a
/// bare word. Multi-word terms match the same words in a row.
/// </summary>
public sealed class ContentFilterMatcher
{
    private readonly Dictionary<string, FilterTerm> _exact = new(StringComparer.Ordinal);
    private readonly Dictionary<string, FilterTerm> _collapsed = new(StringComparer.Ordinal);
    private readonly Dictionary<string, FilterTerm> _phrases = new(StringComparer.Ordinal);
    private readonly int _longestPhrase;

    public ContentFilterMatcher(IEnumerable<FilterTerm> terms)
    {
        foreach (var term in terms)
        {
            if (term.Normalized.Length == 0) continue;
            if (term.Normalized.Contains(' '))
            {
                Keep(_phrases, term.Normalized, term);
                Keep(_phrases, string.Join(' ', term.Normalized.Split(' ').Select(ContentFilterText.Collapse)), term);
                _longestPhrase = Math.Max(_longestPhrase, term.Normalized.Count(c => c == ' ') + 1);
                continue;
            }
            Keep(_exact, term.Normalized, term);
            Keep(_collapsed, ContentFilterText.Collapse(term.Normalized), term);
        }
    }

    public static readonly ContentFilterMatcher Empty = new([]);

    public int TermCount => _exact.Count + _phrases.Count;

    /// <summary>The terms the text holds; <see cref="ContentCheck.Level"/> is the strongest of them.</summary>
    public ContentCheck Check(string? text)
    {
        if (string.IsNullOrWhiteSpace(text) || (_exact.Count == 0 && _phrases.Count == 0)) return ContentCheck.Clean;
        var words = ContentFilterText.Words(ContentFilterText.Normalize(text));
        var found = new Dictionary<string, FilterTerm>(StringComparer.Ordinal);

        foreach (var word in words)
        {
            Bare(word.Joined, found);
            foreach (var part in word.Parts) Bare(part, found);
            foreach (var stripped in ContentFilterText.StrippedCandidates(word.Joined)) Stripped(stripped, found);
            foreach (var leet in ContentFilterText.LeetCandidates(word.Joined)) English(leet, found);
        }

        // "ك ل م ة", "k a l m a": a run of single letters split by spaces or punctuation is one candidate too.
        var run = new List<string>();
        foreach (var word in words.Append(null))
        {
            if (word is not null && ContentFilterText.LetterCount(word.Joined) == 1 && word.Joined.Length == 1)
            {
                run.Add(word.Joined);
                continue;
            }
            if (run.Count >= 2)
            {
                var joined = string.Concat(run);
                Bare(joined, found);
                foreach (var stripped in ContentFilterText.StrippedCandidates(joined)) Stripped(stripped, found);
            }
            run.Clear();
        }

        if (_phrases.Count > 0 && words.Count > 1)
        {
            var forms = words.Select(w => w.Joined).ToList();
            for (var size = 2; size <= Math.Min(_longestPhrase, forms.Count); size++)
            {
                for (var i = 0; i + size <= forms.Count; i++)
                {
                    var phrase = string.Join(' ', forms.Skip(i).Take(size));
                    if (_phrases.TryGetValue(phrase, out var term)
                        || _phrases.TryGetValue(string.Join(' ', forms.Skip(i).Take(size).Select(ContentFilterText.Collapse)), out term))
                        found[term.Normalized] = term;
                }
            }
        }

        if (found.Count == 0) return ContentCheck.Clean;
        var level = found.Values.Any(t => t.Level == ContentFilterLevel.Block) ? ContentFilterLevel.Block : ContentFilterLevel.Flag;
        return new ContentCheck(level, [.. found.Keys.Order(StringComparer.Ordinal)]);
    }

    /// <summary>A whole word as written: every term, short ones included.</summary>
    private void Bare(string candidate, Dictionary<string, FilterTerm> found)
    {
        if (_exact.TryGetValue(candidate, out var term) || _collapsed.TryGetValue(ContentFilterText.Collapse(candidate), out term))
            found[term.Normalized] = term;
    }

    /// <summary>A clitic-stripped form: only terms of 3 letters or more.</summary>
    private void Stripped(string candidate, Dictionary<string, FilterTerm> found)
    {
        if (ContentFilterText.LetterCount(candidate) < ContentFilterText.MinStrippedLength) return;
        if ((_exact.TryGetValue(candidate, out var term) || _collapsed.TryGetValue(ContentFilterText.Collapse(candidate), out term))
            && ContentFilterText.LetterCount(term.Normalized) >= ContentFilterText.MinStrippedLength)
            found[term.Normalized] = term;
    }

    /// <summary>A leetspeak form: only the English lists' terms, so Franco-Arabic spellings keep matching as written.</summary>
    private void English(string candidate, Dictionary<string, FilterTerm> found)
    {
        if ((_exact.TryGetValue(candidate, out var term) || _collapsed.TryGetValue(ContentFilterText.Collapse(candidate), out term))
            && term.Language == "en")
            found[term.Normalized] = term;
    }

    /// <summary>A block term wins over a flag term with the same form.</summary>
    private static void Keep(Dictionary<string, FilterTerm> map, string key, FilterTerm term)
    {
        if (!map.TryGetValue(key, out var existing) || (existing.Level == ContentFilterLevel.Flag && term.Level == ContentFilterLevel.Block))
            map[key] = term;
    }
}

/// <summary>
/// Signs of spam (SPEC F37 flag level, contract decision 7): 3 or more links, the same link twice, or a phone number
/// (9+ digits in a row once spaces, dashes, dots and brackets between them are removed, Arabic-Indic digits included).
/// </summary>
public static partial class SpamSignals
{
    public const string Links = "[links]";
    public const string RepeatedLink = "[repeated link]";
    public const string PhoneNumber = "[phone number]";

    public static IReadOnlyList<string> Check(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return [];
        var signals = new List<string>();
        var links = LinkPattern().Matches(text).Select(m => m.Value.TrimEnd('.', ',', ')', '!', '?').ToLowerInvariant()).ToList();
        if (links.Count >= 3) signals.Add(Links);
        if (links.Count != links.Distinct(StringComparer.Ordinal).Count()) signals.Add(RepeatedLink);

        var digits = ContentFilterText.Normalize(text);
        foreach (Match match in PhonePattern().Matches(digits))
        {
            if (match.Value.Count(char.IsAsciiDigit) >= 9)
            {
                signals.Add(PhoneNumber);
                break;
            }
        }
        return signals;
    }

    [GeneratedRegex(@"(?:https?://|www\.)[^\s<>""]+", RegexOptions.IgnoreCase)]
    private static partial Regex LinkPattern();

    [GeneratedRegex(@"\+?\d[\d\s\-.()]{7,}\d")]
    private static partial Regex PhonePattern();
}
