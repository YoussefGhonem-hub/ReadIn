using System.Text.Json;
using SkiaSharp;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// Sizes a table for the page before Chromium sees it (SPEC F33: "Full content width with wrapping text"; No-bug rules 1
/// and 3). Text in a cell wraps at spaces only, so a number, a Latin word or an Arabic word never splits. Every cell's
/// words are measured with the fonts the PDF uses, and the columns get fixed widths from those measures, much like the
/// browser's own automatic layout but known in advance, so a table can never be wider than the page. A table whose widest
/// words don't fit side by side at <see cref="BaseFontSize"/> gets a smaller font, down to <see cref="MinFontSize"/>
/// (paper can't scroll). Only a token longer than <see cref="LongToken"/> characters (a URL, an identifier) may break
/// inside its cell, and, in a table too wide even at the smallest font, a word wider than its column.
/// </summary>
internal static class PdfTableLayout
{
    /// <summary>The table's font size in article.css, in pt.</summary>
    public const double BaseFontSize = 10;

    /// <summary>The smallest font a wide table shrinks to, in pt.</summary>
    public const double MinFontSize = 6.5;

    /// <summary>A token longer than this (a URL, an identifier) may break inside its cell; shorter words never do.</summary>
    public const int LongToken = 24;

    /// <summary>The content width of an A4 page with 18 mm side margins (article.css <c>@page</c>), in pt.</summary>
    public const double ContentWidth = (210 - 2 * 18) * 72 / 25.4;

    /// <summary>The cells' inline padding (article.css <c>th, td</c>: 0.57em on each side).</summary>
    private const double PaddingEm = 2 * 0.57;

    /// <summary>A cell's 0.5 pt border, counted once per column.</summary>
    private const double BorderPt = 0.5;

    /// <summary><c>code.inline</c>: 0.86em, with 1 mm of padding on each side.</summary>
    private const double InlineCodeEm = 0.86;
    private const double InlineCodePaddingPt = 2 * 72 / 25.4;

    /// <summary>The narrowest a column gets (a column of long tokens only), in em.</summary>
    private const double MinColumnEm = 2;

    /// <summary>
    /// The measures are a little generous: they have no kerning and no Arabic joining, and the browser rounds; a word
    /// measured too narrow would split.
    /// </summary>
    private const double Safety = 1.06;

    /// <summary>The size the fonts are measured at (em = width / size).</summary>
    private const float MeasureSize = 100;

    private static readonly Lazy<SKTypeface> PlexRegular = Typeface("IBMPlexSans-Regular.ttf");
    private static readonly Lazy<SKTypeface> PlexSemiBold = Typeface("IBMPlexSans-SemiBold.ttf");
    private static readonly Lazy<SKTypeface> PlexBold = Typeface("IBMPlexSans-Bold.ttf");
    private static readonly Lazy<SKTypeface> ArabicRegular = Typeface("IBMPlexSansArabic-Regular.ttf");
    private static readonly Lazy<SKTypeface> ArabicSemiBold = Typeface("IBMPlexSansArabic-SemiBold.ttf");
    private static readonly Lazy<SKTypeface> ArabicBold = Typeface("IBMPlexSansArabic-Bold.ttf");
    private static readonly Lazy<SKTypeface> Mono = Typeface("JetBrainsMono-Regular.ttf");

    /// <param name="FontSize">The table's font size in pt; <see cref="BaseFontSize"/> unless the table is too wide.</param>
    /// <param name="ColumnPercents">Each column's share of the table width, in logical order (they add up to 100 at most).</param>
    public sealed record Layout(double FontSize, IReadOnlyList<double> ColumnPercents);

    /// <summary>The font size and the column widths of an RDoc <c>table</c> block.</summary>
    public static Layout For(JsonElement block, bool arabicArticle)
    {
        var rows = new List<(JsonElement[] Cells, bool Header)>();
        if (block.TryGetProperty("header", out var header) && header.ValueKind == JsonValueKind.Array)
            rows.Add(([.. header.EnumerateArray()], true));
        if (block.TryGetProperty("rows", out var body) && body.ValueKind == JsonValueKind.Array)
        {
            foreach (var row in body.EnumerateArray().Where(r => r.ValueKind == JsonValueKind.Array))
                rows.Add(([.. row.EnumerateArray()], false));
        }

        var columns = rows.Count == 0 ? 0 : rows.Max(r => r.Cells.Length);
        if (columns == 0) return new Layout(BaseFontSize, []);

        using var measurer = new Measurer(arabicArticle);
        var measures = Enumerable.Range(0, columns).Select(_ => new Column()).ToArray();
        foreach (var (cells, isHeader) in rows)
        {
            for (var c = 0; c < cells.Length; c++)
                measurer.Cell(cells[c], isHeader, measures[c]);
        }

        var available = ContentWidth - (columns + 1) * BorderPt;
        var size = FontSizeFor(measures, available);
        var min = measures.Select(m => m.Min(size)).ToArray();
        var max = measures.Select(m => Math.Max(m.Max(size), m.Min(size))).ToArray();
        var widths = Distribute(min, max, available);
        var total = widths.Sum();
        // Rounded down, so the columns never add up to more than the table (it would grow past the margin).
        var percents = widths.Select(w => Math.Floor(w / total * 10_000) / 100).ToArray();
        return new Layout(size, percents);
    }

    /// <summary>The largest size, from the base size down to the smallest, at which the widest words fit side by side.</summary>
    private static double FontSizeFor(Column[] columns, double available)
    {
        double Need(double size) => columns.Sum(c => c.Min(size));

        if (Need(BaseFontSize) <= available) return BaseFontSize;
        if (Need(MinFontSize) > available) return MinFontSize;

        var (low, high) = (MinFontSize, BaseFontSize);
        for (var i = 0; i < 16; i++)
        {
            var middle = (low + high) / 2;
            if (Need(middle) <= available) low = middle;
            else high = middle;
        }
        // Rounded down to a tenth of a point, as written into the page.
        return Math.Floor(low * 10) / 10;
    }

    /// <summary>
    /// Column widths for the available width, like CSS automatic table layout: every column gets at least its widest
    /// word; the rest goes by how much more each column's longest line wants. When even the widest words don't fit, by
    /// their share of them.
    /// </summary>
    private static double[] Distribute(double[] min, double[] max, double available)
    {
        var minTotal = min.Sum();
        var maxTotal = max.Sum();
        if (maxTotal <= available) return [.. max.Select(m => m / maxTotal * available)];
        if (minTotal > available) return [.. min.Select(m => m / minTotal * available)];

        var room = available - minTotal;
        var wants = maxTotal - minTotal;
        return [.. min.Select((m, i) => m + room * (max[i] - m) / wants)];
    }

    private static Lazy<SKTypeface> Typeface(string file) => new(() =>
    {
        using var data = SKData.CreateCopy(ArticlePdfAssets.Read(file));
        return SKTypeface.FromData(data) ?? throw new InvalidOperationException($"The PDF font {file} can't be read.");
    });

    /// <summary>A width as <c>Em × font size + Pt</c> (padding in mm doesn't grow with the font).</summary>
    private readonly record struct Width(double Em, double Pt)
    {
        public double At(double size) => Em * size + Pt;

        public static Width operator +(Width a, Width b) => new(a.Em + b.Em, a.Pt + b.Pt);
    }

    /// <summary>One column's candidates: its words that may not split, and its cells' lines.</summary>
    private sealed class Column
    {
        private static readonly Width Padding = new(PaddingEm, BorderPt);

        public List<Width> Words { get; } = [new(MinColumnEm, 0)];
        public List<Width> Lines { get; } = [];

        public double Min(double size) => Words.Max(w => w.At(size)) * Safety + Padding.At(size);

        public double Max(double size) => Lines.Count == 0 ? Min(size) : Lines.Max(w => w.At(size)) * Safety + Padding.At(size);
    }

    private enum Face
    {
        Regular,
        SemiBold,
        Bold,
        Code,
    }

    /// <summary>Measures cell text with the page's fonts (font-family order of article.css).</summary>
    private sealed class Measurer(bool arabicArticle) : IDisposable
    {
        private readonly Dictionary<SKTypeface, SKFont> _fonts = [];

        // The state of the cell being measured.
        private Column _column = null!;
        private Width _word;
        private int _wordLength;
        private Width _line;

        public void Cell(JsonElement cell, bool header, Column column)
        {
            _column = column;
            _word = default;
            _wordLength = 0;
            _line = default;
            if (cell.ValueKind == JsonValueKind.Array)
            {
                foreach (var node in cell.EnumerateArray())
                {
                    var type = node.ValueKind == JsonValueKind.Object && node.TryGetProperty("type", out var t) ? t.GetString() : null;
                    switch (type)
                    {
                        case "text":
                        {
                            var marks = node.TryGetProperty("marks", out var m) && m.ValueKind == JsonValueKind.Array
                                ? m.EnumerateArray().Select(x => x.TryGetProperty("type", out var mt) ? mt.GetString() : null).ToList()
                                : [];
                            var face = marks.Contains("code") ? Face.Code : marks.Contains("bold") ? Face.Bold : header ? Face.SemiBold : Face.Regular;
                            Text(Str(node, "text"), face);
                            break;
                        }
                        case "term" or "mention":
                            Text(Str(node, "text"), header ? Face.SemiBold : Face.Regular);
                            break;
                        case "hardBreak":
                            EndLine();
                            break;
                    }
                }
            }
            EndLine();
        }

        private void Text(string? text, Face face)
        {
            if (string.IsNullOrEmpty(text)) return;
            var code = face == Face.Code;
            if (code) Add(new Width(0, InlineCodePaddingPt), 0);

            var start = 0;
            for (var i = 0; i <= text.Length; i++)
            {
                var space = i < text.Length && char.IsWhiteSpace(text[i]);
                if (i < text.Length && !space) continue;
                if (i > start) Add(Measure(text[start..i], face), i - start);
                if (space)
                {
                    EndWord();
                    _line += Measure(" ", face);
                }
                start = i + 1;
            }
        }

        private void Add(Width width, int length)
        {
            _word += width;
            _wordLength += length;
            _line += width;
        }

        private void EndWord()
        {
            if (_wordLength is > 0 and <= LongToken) _column.Words.Add(_word);
            _word = default;
            _wordLength = 0;
        }

        private void EndLine()
        {
            EndWord();
            if (_line.Em > 0 || _line.Pt > 0) _column.Lines.Add(_line);
            _line = default;
        }

        /// <summary>The run's width, in runs of one font; a character none of them has counts a full em.</summary>
        private Width Measure(string run, Face face)
        {
            var scale = face == Face.Code ? InlineCodeEm : 1;
            double em = 0;
            var i = 0;
            while (i < run.Length)
            {
                var typeface = TypefaceOf(run, i, face);
                var start = i;
                while (i < run.Length && TypefaceOf(run, i, face) == typeface) i += char.IsSurrogatePair(run, i) ? 2 : 1;

                var piece = run[start..i];
                var font = Font(typeface);
                em += font.MeasureText(piece) / MeasureSize;
                em += font.GetGlyphs(piece).Count(g => g == 0);
            }
            return new Width(em * scale, 0);
        }

        private SKTypeface TypefaceOf(string run, int index, Face face)
        {
            var arabic = IsArabic(char.IsSurrogatePair(run, index) ? char.ConvertToUtf32(run, index) : run[index]);
            // article.css: code in JetBrains Mono, then Plex Arabic; Arabic articles in Plex Arabic (its Latin too);
            // English articles in Plex, Arabic letters in Plex Arabic.
            if (face == Face.Code) return arabic ? ArabicRegular.Value : Mono.Value;
            return (arabic || arabicArticle, face) switch
            {
                (true, Face.SemiBold) => ArabicSemiBold.Value,
                (true, Face.Bold) => ArabicBold.Value,
                (true, _) => ArabicRegular.Value,
                (false, Face.SemiBold) => PlexSemiBold.Value,
                (false, Face.Bold) => PlexBold.Value,
                _ => PlexRegular.Value,
            };
        }

        private SKFont Font(SKTypeface typeface)
        {
            if (_fonts.TryGetValue(typeface, out var font)) return font;
            font = new SKFont(typeface, MeasureSize) { Hinting = SKFontHinting.None, LinearMetrics = true, Subpixel = true };
            _fonts[typeface] = font;
            return font;
        }

        private static bool IsArabic(int cp) =>
            cp is >= 0x0600 and <= 0x06FF or >= 0x0750 and <= 0x077F or >= 0x08A0 and <= 0x08FF or >= 0xFB50 and <= 0xFDFF or >= 0xFE70 and <= 0xFEFF;

        private static string? Str(JsonElement node, string property) =>
            node.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;

        public void Dispose()
        {
            foreach (var font in _fonts.Values) font.Dispose();
        }
    }
}
