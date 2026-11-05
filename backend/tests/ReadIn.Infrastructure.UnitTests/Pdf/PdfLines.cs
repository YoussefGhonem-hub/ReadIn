using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using ReadIn.Infrastructure.Pdf;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// Reads a printed PDF back as lines of glyphs (PdfPig), to check what readers see: text in the right order, on which
/// page, inside the margins. A glyph's text is its ToUnicode value, so Arabic comes back as presentation forms (the
/// shaped, connected letters); <see cref="Normalize"/> folds them to plain letters for comparisons.
/// </summary>
internal static partial class PdfLines
{
    public const double PageWidth = 595.28;
    public const double PageHeight = 841.89;
    public const double SideMargin = 18 / 25.4 * 72;
    public const double TopMargin = 16 / 25.4 * 72;
    public const double BottomMargin = 22 / 25.4 * 72;

    public sealed record Line(int Page, double Baseline, IReadOnlyList<Letter> Letters)
    {
        /// <summary>The glyphs left to right (how an LTR line reads).</summary>
        public string LeftToRight => Normalize(string.Concat(Letters.OrderBy(l => l.StartBaseLine.X).Select(l => l.Value)));

        /// <summary>The glyphs right to left (how an RTL line reads; Latin and digit runs come out reversed).</summary>
        public string RightToLeft => Normalize(string.Concat(Letters.OrderByDescending(l => l.StartBaseLine.X).Select(l => l.Value)));

        /// <summary>An LTR line in reading order: left to right, with each run of Arabic glyphs read right to left.</summary>
        public string LtrReadingOrder
        {
            get
            {
                var text = new StringBuilder();
                var arabic = new List<string>();
                foreach (var letter in Letters.OrderBy(l => l.StartBaseLine.X))
                {
                    if (IsArabic(letter.Value)) { arabic.Add(letter.Value); continue; }
                    Flush();
                    text.Append(letter.Value);
                }
                Flush();
                return Normalize(text.ToString());

                void Flush()
                {
                    for (var i = arabic.Count - 1; i >= 0; i--) text.Append(arabic[i]);
                    arabic.Clear();
                }
            }
        }

        /// <summary>Share of the Arabic glyphs that are joining forms (initial, medial, final): unshaped text has none.</summary>
        public double JoinedShare
        {
            get
            {
                var arabic = Letters.Where(l => IsArabic(l.Value)).ToList();
                if (arabic.Count == 0) return 0;
                return arabic.Count(l => l.Value.Any(c => c is >= 'ﭐ' and <= '﷿' or >= 'ﹰ' and <= 'ﻼ')) / (double)arabic.Count;
            }
        }
    }

    public static IReadOnlyList<Line> Lines(PdfDocument pdf) =>
        [.. pdf.GetPages().SelectMany(page => page.Letters
            .Where(l => !string.IsNullOrWhiteSpace(l.Value))
            .GroupBy(l => Math.Round(l.StartBaseLine.Y))
            .OrderByDescending(g => g.Key)
            .Select(g => new Line(page.Number, g.Key, [.. g])))];

    /// <summary>The first page with a line that reads <paramref name="text"/> (LTR or RTL), or 0.</summary>
    public static int PageOf(IReadOnlyList<Line> lines, string text)
    {
        var needle = Normalize(text);
        return lines.FirstOrDefault(l => l.LeftToRight.Contains(needle, StringComparison.Ordinal)
                                          || l.RightToLeft.Contains(needle, StringComparison.Ordinal)
                                          || l.LtrReadingOrder.Contains(needle, StringComparison.Ordinal))?.Page ?? 0;
    }

    public static IEnumerable<int> PagesOf(IReadOnlyList<Line> lines, string text)
    {
        var needle = Normalize(text);
        return lines.Where(l => l.LeftToRight.Contains(needle, StringComparison.Ordinal) || l.RightToLeft.Contains(needle, StringComparison.Ordinal))
            .Select(l => l.Page).Distinct();
    }

    /// <summary>
    /// What an RTL line containing <paramref name="logical"/> reads right to left, by the §14.2 rules the PDF follows:
    /// isolated Latin runs and numbers show left to right (so they come out reversed), brackets in Arabic text are
    /// mirrored, everything else keeps its order.
    /// </summary>
    public static string ExpectedRightToLeft(string logical)
    {
        var text = new StringBuilder();
        foreach (var segment in BidiText.Segment(logical, BidiText.Rtl))
        {
            if (segment.Isolate)
            {
                text.Append(Reverse(segment.Text));
                continue;
            }
            var mirrored = new string([.. segment.Text.Select(c => c switch
            {
                '(' => ')', ')' => '(', '[' => ']', ']' => '[', '{' => '}', '}' => '{', '<' => '>', '>' => '<', _ => c,
            })]);
            text.Append(Number().Replace(mirrored, m => Reverse(m.Value)));
        }
        return Normalize(text.ToString());
    }

    /// <summary>Compatibility-folded (presentation forms → letters), without whitespace and Arabic marks.</summary>
    public static string Normalize(string text)
    {
        var folded = text.Normalize(NormalizationForm.FormKC);
        var result = new StringBuilder(folded.Length);
        foreach (var c in folded)
        {
            if (char.IsWhiteSpace(c)) continue;
            var category = CharUnicodeInfo.GetUnicodeCategory(c);
            if (category is UnicodeCategory.NonSpacingMark or UnicodeCategory.EnclosingMark or UnicodeCategory.Format) continue;
            result.Append(c);
        }
        return result.ToString();
    }

    public static bool IsArabic(string value) =>
        value.Any(c => c is >= '؀' and <= 'ۿ' or >= 'ݐ' and <= 'ݿ' or >= 'ﭐ' and <= '﷿' or >= 'ﹰ' and <= 'ﻼ');

    private static string Reverse(string value)
    {
        var chars = value.ToCharArray();
        Array.Reverse(chars);
        return new string(chars);
    }

    [GeneratedRegex(@"[0-9]+(?:[.,:/\-][0-9]+)*%?")]
    private static partial Regex Number();
}
