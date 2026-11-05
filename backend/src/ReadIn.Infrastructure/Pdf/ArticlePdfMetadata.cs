using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Core;
using UglyToad.PdfPig.Tokens;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// Finishes the document information of an article PDF (SPEC F33, No-bug rule 6). Chromium writes the title (from
/// <c>&lt;title&gt;</c>), the language (<c>/Lang</c>, from <c>&lt;html lang&gt;</c>), the tags and the bookmarks, but
/// no author, and it names a bookmark after its heading's text in visual order (so <c>جدول فيه 12 عمود</c> comes out
/// scrambled). Both are fixed with a standard PDF incremental update: the printed bytes stay as they are, and a new Info
/// dictionary, the bookmark items with their headings' text in reading order, a cross-reference section and a trailer
/// are appended.
/// </summary>
internal static partial class ArticlePdfMetadata
{
    public const string Creator = "ReadIn";

    /// <param name="headings">The H2/H3 texts in document order; used only when they match Chromium's bookmarks one to one.</param>
    public static byte[] Apply(byte[] pdf, string title, string author, IReadOnlyList<string> headings)
    {
        var tailLength = Math.Min(pdf.Length, 4096);
        var tail = Encoding.Latin1.GetString(pdf, pdf.Length - tailLength, tailLength);
        var startXref = tail.LastIndexOf("startxref", StringComparison.Ordinal);
        var trailerStart = tail.LastIndexOf("trailer", StringComparison.Ordinal);
        if (startXref < 0 || trailerStart < 0 || trailerStart > startXref)
            throw new InvalidOperationException("The printed PDF has no classic trailer to update.");

        var trailer = tail[trailerStart..startXref];
        var previousXref = long.Parse(Number().Match(tail, startXref + "startxref".Length).Value, CultureInfo.InvariantCulture);
        var size = int.Parse(SizeEntry().Match(trailer).Groups[1].Value, CultureInfo.InvariantCulture);
        var root = RootEntry().Match(trailer).Groups[1].Value;
        var infoMatch = InfoEntry().Match(trailer);
        var info = infoMatch.Success ? int.Parse(infoMatch.Groups[1].Value, CultureInfo.InvariantCulture) : size++;

        string producer;
        string? created;
        List<(IndirectReference Reference, DictionaryToken Item)> bookmarks;
        using (var document = PdfDocument.Open(pdf))
        {
            producer = document.Information.Producer ?? "Skia/PDF";
            created = document.Information.CreationDate;
            bookmarks = Bookmarks(document);
        }

        var objects = new List<(int Number, int Generation, string Body)>();

        var dictionary = new StringBuilder()
            .Append("<< /Title ").Append(TextString(title))
            .Append(" /Author ").Append(TextString(author))
            .Append(" /Creator ").Append(TextString(Creator))
            .Append(" /Producer ").Append(TextString(producer));
        if (created is { Length: > 0 }) dictionary.Append(" /CreationDate ").Append(Literal(created)).Append(" /ModDate ").Append(Literal(created));
        objects.Add((info, 0, dictionary.Append(" >>").ToString()));

        if (bookmarks.Count == headings.Count)
        {
            for (var i = 0; i < bookmarks.Count; i++)
            {
                var (reference, item) = bookmarks[i];
                var entries = item.Data.Where(p => p.Key != NameToken.Title.Data)
                    .Select(p => "/" + EscapeName(p.Key) + " " + Serialize(p.Value))
                    .Prepend("/Title " + TextString(headings[i]));
                objects.Add(((int)reference.ObjectNumber, reference.Generation, "<< " + string.Join(' ', entries) + " >>"));
            }
        }

        using var output = new MemoryStream(pdf.Length + 4096);
        output.Write(pdf);
        if (pdf[^1] != (byte)'\n') output.WriteByte((byte)'\n');

        var offsets = new List<(int Number, int Generation, long Offset)>();
        foreach (var (number, generation, body) in objects)
        {
            offsets.Add((number, generation, output.Position));
            Write(output, string.Create(CultureInfo.InvariantCulture, $"{number} {generation} obj\n{body}\nendobj\n"));
        }

        var xrefOffset = output.Position;
        var xref = new StringBuilder("xref\n0 1\n0000000000 65535 f \n");
        foreach (var (number, generation, offset) in offsets.OrderBy(o => o.Number))
            xref.Append(CultureInfo.InvariantCulture, $"{number} 1\n{offset:D10} {generation:D5} n \n");
        xref.Append(CultureInfo.InvariantCulture,
            $"trailer\n<< /Size {size} /Root {root} R /Info {info} 0 R /Prev {previousXref} >>\nstartxref\n{xrefOffset}\n%%EOF\n");
        Write(output, xref.ToString());
        return output.ToArray();
    }

    /// <summary>The bookmark items in document order (depth first, like the headings).</summary>
    private static List<(IndirectReference, DictionaryToken)> Bookmarks(PdfDocument document)
    {
        var items = new List<(IndirectReference, DictionaryToken)>();
        if (Reference(document.Structure.Catalog.CatalogDictionary, NameToken.Outlines) is not { } outlinesReference) return items;
        if (Resolve(document, outlinesReference) is not { } outlines) return items;

        Walk(outlines, 0);
        return items;

        void Walk(DictionaryToken parent, int depth)
        {
            if (depth > 10) return;
            var next = Reference(parent, NameToken.First);
            var seen = new HashSet<IndirectReference>();
            while (next is not null && seen.Add(next.Data) && Resolve(document, next) is { } item)
            {
                items.Add((next.Data, item));
                Walk(item, depth + 1);
                next = Reference(item, NameToken.Next);
            }
        }
    }

    private static IndirectReferenceToken? Reference(DictionaryToken dictionary, NameToken key) =>
        dictionary.TryGet(key, out var token) ? token as IndirectReferenceToken : null;

    private static DictionaryToken? Resolve(PdfDocument document, IndirectReferenceToken reference) =>
        document.Structure.GetObject(reference.Data).Data as DictionaryToken;

    private static string Serialize(IToken token) => token switch
    {
        NameToken name => "/" + EscapeName(name.Data),
        NumericToken number => number.Data.ToString(CultureInfo.InvariantCulture),
        IndirectReferenceToken reference => string.Create(CultureInfo.InvariantCulture, $"{reference.Data.ObjectNumber} {reference.Data.Generation} R"),
        BooleanToken boolean => boolean.Data ? "true" : "false",
        NullToken => "null",
        HexToken hex => TextString(hex.Data),
        StringToken text => TextString(text.Data),
        ArrayToken array => "[" + string.Join(' ', array.Data.Select(Serialize)) + "]",
        DictionaryToken dictionary => "<< " + string.Join(' ', dictionary.Data.Select(p => "/" + EscapeName(p.Key) + " " + Serialize(p.Value))) + " >>",
        _ => throw new InvalidOperationException($"A bookmark holds a {token.GetType().Name}, which can't be rewritten."),
    };

    private static string EscapeName(string name)
    {
        var escaped = new StringBuilder(name.Length);
        foreach (var b in Encoding.UTF8.GetBytes(name))
        {
            if (b is > 0x21 and < 0x7F && "#()<>[]{}/%".IndexOf((char)b, StringComparison.Ordinal) < 0) escaped.Append((char)b);
            else escaped.Append(CultureInfo.InvariantCulture, $"#{b:X2}");
        }
        return escaped.ToString();
    }

    /// <summary>A PDF text string in UTF-16BE with its byte order mark, as hex: any language, no escaping.</summary>
    private static string TextString(string value) => "<FEFF" + Convert.ToHexString(Encoding.BigEndianUnicode.GetBytes(value)) + ">";

    private static string Literal(string value) =>
        "(" + value.Replace("\\", "\\\\", StringComparison.Ordinal).Replace("(", "\\(", StringComparison.Ordinal).Replace(")", "\\)", StringComparison.Ordinal) + ")";

    private static void Write(Stream stream, string text) => stream.Write(Encoding.Latin1.GetBytes(text));

    [GeneratedRegex(@"\d+")]
    private static partial Regex Number();

    [GeneratedRegex(@"/Size\s+(\d+)")]
    private static partial Regex SizeEntry();

    [GeneratedRegex(@"/Root\s+(\d+\s+\d+)\s+R")]
    private static partial Regex RootEntry();

    [GeneratedRegex(@"/Info\s+(\d+)\s+\d+\s+R")]
    private static partial Regex InfoEntry();
}
