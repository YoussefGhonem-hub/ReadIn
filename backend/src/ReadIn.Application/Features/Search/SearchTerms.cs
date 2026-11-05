using System.Text;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Search;

/// <summary>
/// The search query <c>q</c> as both engines use it (contract-v1 "Search"): cleaned like a tag name (F32 rule 1), one
/// leading <c>@</c> dropped, normalized like <c>SearchText</c> (SPEC §22) and split into words. Nothing in it is ever
/// query syntax: the full-text condition quotes every word, and LIKE patterns escape <c>% _ [ \</c>.
/// </summary>
public sealed class SearchTerms
{
    /// <summary>The escape character of every LIKE pattern built here.</summary>
    public const string LikeEscape = "\\";

    /// <summary>A raw <c>q</c> longer than this is refused before it is cleaned.</summary>
    private const int MaxRawLength = 1000;

    private const string ArabicArticle = "ال";

    /// <summary>Quotes, brackets and sentence punctuation around a word (and a full stop after it) are not part of it (<c>"docker",</c> → <c>docker</c>).</summary>
    private static readonly char[] WrappingPunctuation =
        ['"', '\'', '`', '(', ')', '[', ']', '{', '}', '<', '>', ',', ';', ':', '!', '?', '«', '»', '“', '”', '„', '‘', '’', '،', '؛', '؟'];

    private SearchTerms(string cleaned, string phrase, IReadOnlyList<string> words)
    {
        Cleaned = cleaned;
        Phrase = phrase;
        Words = words;
        Slug = TagNames.SlugText(cleaned);
        Handle = words.Count == 1 && IsHandlePrefix(phrase) ? phrase : null;
    }

    /// <summary><c>q</c> cleaned (case and letter forms kept), 1–100 characters.</summary>
    public string Cleaned { get; }

    /// <summary>The whole cleaned <c>q</c>, normalized: for "exact name" and "one phrase" checks.</summary>
    public string Phrase { get; }

    /// <summary>The normalized words that must all be found: those with a letter or digit, at most <see cref="SearchLimits.MaxWords"/>.</summary>
    public IReadOnlyList<string> Words { get; }

    /// <summary><c>q</c> made into a slug (F32 rule 4, <c>C#</c> → <c>csharp</c>); empty when it gives none.</summary>
    public string Slug { get; }

    /// <summary>The one word of <c>q</c> when it can begin a @username (lower case), else null.</summary>
    public string? Handle { get; }

    public static Result<SearchTerms> Parse(string? q)
    {
        if (q is null || q.Length > MaxRawLength) return SearchErrors.QueryInvalid;

        var cleaned = TagNames.Clean(q);
        if (cleaned.StartsWith('@')) cleaned = cleaned[1..].TrimStart();
        if (cleaned.Length is 0 or > SearchLimits.MaxQueryLength) return SearchErrors.QueryInvalid;

        var phrase = ArabicNormalizer.Normalize(cleaned);
        var words = phrase
            .Split(' ', StringSplitOptions.RemoveEmptyEntries)
            .Select(word => word.Trim(WrappingPunctuation).TrimEnd('.'))
            .Where(HasLetterOrDigit)
            .Distinct(StringComparer.Ordinal)
            .Take(SearchLimits.MaxWords)
            .ToList();
        if (words.Count == 0) return SearchErrors.QueryInvalid;

        return new SearchTerms(cleaned, phrase, words);
    }

    /// <summary>
    /// The full-text search condition: every word as a quoted prefix term, joined by AND. An Arabic word that doesn't
    /// start with <c>ال</c> also matches with it (<c>("ذكاء*" OR "الذكاء*")</c>). Quotes and asterisks are dropped from the
    /// words, so nothing a user types can end a term, add an operator or a wildcard.
    /// </summary>
    public string FullTextCondition()
    {
        var condition = new StringBuilder();
        foreach (var word in Words)
        {
            var term = word.Replace("\"", string.Empty, StringComparison.Ordinal).Replace("*", string.Empty, StringComparison.Ordinal);
            if (term.Length == 0) continue;
            if (condition.Length > 0) condition.Append(" AND ");
            if (IsArabicLetter(term[0]) && !term.StartsWith(ArabicArticle, StringComparison.Ordinal))
                condition.Append("(\"").Append(term).Append("*\" OR \"").Append(ArabicArticle).Append(term).Append("*\")");
            else
                condition.Append('"').Append(term).Append("*\"");
        }
        return condition.ToString();
    }

    /// <summary>A LIKE pattern that finds <paramref name="text"/> anywhere (<c>%text%</c>, escaped).</summary>
    public static string ContainsPattern(string text) => $"%{EscapeLike(text)}%";

    /// <summary>
    /// The LIKE patterns that find <paramref name="word"/> at the start of a word of <c>' ' + column</c>: after a space,
    /// and for an Arabic word also after <c>ال</c>. <paramref name="separator"/> is the character before the word.
    /// </summary>
    public static (string Plain, string WithArticle) WordStartPatterns(string word, char separator = ' ')
    {
        var escaped = EscapeLike(word);
        var sep = EscapeLike(separator.ToString());
        return ($"%{sep}{escaped}%", $"%{sep}{ArabicArticle}{escaped}%");
    }

    /// <summary>Whether <paramref name="normalizedText"/> holds every word at the start of one of its words (the in-memory twin of the LIKE patterns).</summary>
    public bool AllWordsStartWordsIn(string? normalizedText, string separators = " ")
    {
        if (string.IsNullOrEmpty(normalizedText)) return false;
        return Words.All(word => StartsAWord(normalizedText, word, separators)
            || (IsArabicLetter(word[0]) && StartsAWord(normalizedText, ArabicArticle + word, separators)));
    }

    /// <summary>Whether <paramref name="normalizedText"/> holds every word anywhere (the title check of <c>matchedIn</c> on the LIKE fallback).</summary>
    public bool AllWordsIn(string? normalizedText) =>
        !string.IsNullOrEmpty(normalizedText) && Words.All(word => normalizedText.Contains(word, StringComparison.Ordinal));

    /// <summary>
    /// Whether <paramref name="normalizedText"/> holds every word where the full-text engine finds it (the title check of
    /// <c>matchedIn</c> on that engine): at the start of a word, which starts after anything that isn't a letter or digit
    /// (<c>net</c> is in <c>asp.net</c>, not in <c>internet</c>); an Arabic word also behind the prefixes the Arabic word
    /// breaker takes off (<c>ال</c>, <c>و</c> / <c>ف</c>, <c>ب</c> / <c>ك</c> / <c>ل</c>, <c>لل</c>: <c>ذكاء</c> is in <c>بالذكاء</c>).
    /// </summary>
    public bool AllWordsAtWordStartsIn(string? normalizedText) =>
        !string.IsNullOrEmpty(normalizedText) && Words.All(word => AtAWordStart(normalizedText, word));

    /// <summary>Escapes the LIKE wildcards and the escape character itself.</summary>
    public static string EscapeLike(string text)
    {
        var escaped = new StringBuilder(text.Length + 4);
        foreach (var ch in text)
        {
            if (ch is '\\' or '%' or '_' or '[') escaped.Append('\\');
            escaped.Append(ch);
        }
        return escaped.ToString();
    }

    private static bool StartsAWord(string text, string word, string separators)
    {
        for (var at = text.IndexOf(word, StringComparison.Ordinal); at >= 0; at = text.IndexOf(word, at + 1, StringComparison.Ordinal))
        {
            if (at == 0 || separators.Contains(text[at - 1], StringComparison.Ordinal)) return true;
        }
        return false;
    }

    private static bool AtAWordStart(string text, string word)
    {
        for (var at = text.IndexOf(word, StringComparison.Ordinal); at >= 0; at = text.IndexOf(word, at + 1, StringComparison.Ordinal))
        {
            var start = at;
            while (start > 0 && char.IsLetterOrDigit(text[start - 1])) start--;
            if (start == at || (IsArabicLetter(word[0]) && IsArabicPrefix(text.AsSpan(start, at - start)))) return true;
        }
        return false;
    }

    /// <summary>What the Arabic word breaker takes off before a word: <c>و</c> or <c>ف</c>, then <c>ب</c>, <c>ك</c> or <c>ل</c>, then <c>ال</c>; or <c>لل</c>.</summary>
    private static bool IsArabicPrefix(ReadOnlySpan<char> prefix)
    {
        if (prefix.Length > 0 && prefix[0] is 'و' or 'ف') prefix = prefix[1..];
        if (prefix.SequenceEqual("لل")) return true;
        if (prefix.Length > 0 && prefix[0] is 'ب' or 'ك' or 'ل') prefix = prefix[1..];
        return prefix.IsEmpty || prefix.SequenceEqual(ArabicArticle);
    }

    /// <summary>The start of a @username: lower-case letters, digits and "_" (usernames are 3–30 of them).</summary>
    private static bool IsHandlePrefix(string text) =>
        text.Length <= 30 && text.All(ch => ch is (>= 'a' and <= 'z') or (>= '0' and <= '9') or '_');

    private static bool HasLetterOrDigit(string word) => word.Any(char.IsLetterOrDigit);

    private static bool IsArabicLetter(char ch) => ch is >= 'ء' and <= 'ي';
}
