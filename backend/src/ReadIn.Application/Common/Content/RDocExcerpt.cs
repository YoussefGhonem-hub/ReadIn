using System.Text;
using System.Text.Json;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Common.Content;

/// <summary>The feed card's text (SPEC F34) and whether the article holds more than it.</summary>
public sealed record RDocExcerptResult(string Text, bool HasMore);

/// <summary>
/// Builds the feed card's excerpt (SPEC F34, §13.5) from a stored or processed RDoc document: plain text taken in
/// document order from the summary, paragraphs, lists, steps, quotes and callouts (one line per block, list item and
/// step), with glossary terms and mentions as their text. Headings, code, tables, images and embeds are skipped, and make
/// <see cref="RDocExcerptResult.HasMore"/> true, as do a quote's cite and text cut at
/// <see cref="ArticleTranslation.ExcerptMaxLength"/> characters (at a word, with no "…": clients add it). Never throws:
/// a document it can't read gives an empty excerpt with more to read.
/// </summary>
public static class RDocExcerpt
{
    public static RDocExcerptResult From(JsonElement document)
    {
        if (document.ValueKind != JsonValueKind.Object
            || !document.TryGetProperty("blocks", out var blocks)
            || blocks.ValueKind != JsonValueKind.Array)
            return new RDocExcerptResult("", HasMore: true);

        var lines = new List<string>();
        var skipped = false;
        foreach (var block in blocks.EnumerateArray())
        {
            switch (StringOf(block, "type"))
            {
                case "paragraph" or "summary":
                    AddLine(lines, InlineText(block, "content"));
                    break;

                case "quote":
                    AddLine(lines, InlineText(block, "content"));
                    if (!string.IsNullOrWhiteSpace(StringOf(block, "cite"))) skipped = true;
                    break;

                case "callout":
                    AddLine(lines, StringOf(block, "title"));
                    AddLine(lines, InlineText(block, "content"));
                    break;

                case "bulletList" or "orderedList":
                    foreach (var item in ArrayOf(block, "items")) AddLine(lines, Inlines(item));
                    break;

                case "steps":
                    foreach (var step in ArrayOf(block, "items"))
                    {
                        AddLine(lines, StringOf(step, "title"));
                        AddLine(lines, InlineText(step, "content"));
                    }
                    break;

                case "divider":
                    break;

                default: // heading, code, codeTabs, table, image, embed, and anything newer
                    skipped = true;
                    break;
            }
        }

        var text = string.Join('\n', lines);
        if (text.Length <= ArticleTranslation.ExcerptMaxLength) return new RDocExcerptResult(text, skipped);
        return new RDocExcerptResult(CutAtWord(text, ArticleTranslation.ExcerptMaxLength), HasMore: true);
    }

    /// <summary>The longest start of <paramref name="text"/> up to <paramref name="max"/> characters that ends at a word.</summary>
    internal static string CutAtWord(string text, int max)
    {
        if (text.Length <= max) return text;

        var end = max;
        if (!char.IsWhiteSpace(text[end]))
        {
            var space = end - 1;
            while (space > 0 && !char.IsWhiteSpace(text[space])) space--;
            // One word longer than the whole excerpt (a long URL): cut inside it, never inside a surrogate pair.
            if (space > 0) end = space;
            else if (char.IsHighSurrogate(text[end - 1])) end--;
        }
        return text[..end].TrimEnd();
    }

    private static void AddLine(List<string> lines, string? value)
    {
        var line = Normalize(value);
        if (line.Length > 0) lines.Add(line);
    }

    /// <summary>Collapses runs of spaces and tabs to one space and blank lines to one line break.</summary>
    private static string Normalize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return "";

        var sb = new StringBuilder(value.Length);
        var pendingSpace = false;
        var pendingBreak = false;
        foreach (var ch in value.Trim())
        {
            if (ch is '\n' or '\r') { pendingBreak = true; continue; }
            if (char.IsWhiteSpace(ch)) { pendingSpace = true; continue; }

            if (pendingBreak) sb.Append('\n');
            else if (pendingSpace) sb.Append(' ');
            pendingSpace = pendingBreak = false;
            sb.Append(ch);
        }
        return sb.ToString();
    }

    private static string InlineText(JsonElement owner, string property) =>
        owner.ValueKind == JsonValueKind.Object && owner.TryGetProperty(property, out var inlines) ? Inlines(inlines) : "";

    private static string Inlines(JsonElement inlines)
    {
        if (inlines.ValueKind != JsonValueKind.Array) return "";

        var sb = new StringBuilder();
        foreach (var node in inlines.EnumerateArray())
        {
            switch (StringOf(node, "type"))
            {
                case "text" or "term" or "mention":
                    sb.Append(StringOf(node, "text"));
                    break;
                case "hardBreak":
                    sb.Append('\n');
                    break;
            }
        }
        return sb.ToString();
    }

    private static string? StringOf(JsonElement owner, string property) =>
        owner.ValueKind == JsonValueKind.Object && owner.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static IEnumerable<JsonElement> ArrayOf(JsonElement owner, string property) =>
        owner.ValueKind == JsonValueKind.Object && owner.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.Array
            ? value.EnumerateArray()
            : [];
}
