using System.Text;
using System.Text.Json;

namespace ReadIn.ContentStudio.Validation;

/// <summary>A run of human-readable text inside a block (inline code excluded), for language and BiDi lint.</summary>
public sealed record TextRun(string BlockId, string Text);

public sealed record BlockView(JsonElement Element, string Id, string Type)
{
    public string? Dir => Element.TryGetProperty("dir", out var d) ? d.GetString() : null;
}

/// <summary>Read-only helpers over a sanitized RDoc document.</summary>
public static class RDocWalker
{
    public static List<BlockView> Blocks(JsonElement document) =>
        [.. document.GetProperty("blocks").EnumerateArray()
            .Select(b => new BlockView(b, b.GetProperty("id").GetString()!, b.GetProperty("type").GetString()!))];

    /// <summary>Every inline array of a block (paragraph content, list items, table cells, step contents…).</summary>
    public static IEnumerable<JsonElement> InlineArrays(BlockView block)
    {
        var e = block.Element;
        switch (block.Type)
        {
            case "paragraph" or "heading" or "quote" or "callout" or "summary":
                yield return e.GetProperty("content");
                break;
            case "bulletList" or "orderedList":
                foreach (var item in e.GetProperty("items").EnumerateArray()) yield return item;
                break;
            case "steps":
                foreach (var step in e.GetProperty("items").EnumerateArray()) yield return step.GetProperty("content");
                break;
            case "table":
                foreach (var cell in e.GetProperty("header").EnumerateArray()) yield return cell;
                foreach (var row in e.GetProperty("rows").EnumerateArray())
                    foreach (var cell in row.EnumerateArray()) yield return cell;
                break;
        }
    }

    /// <summary>Plain strings that are not inline arrays: callout and step titles, image alt and caption, quote cite.</summary>
    public static IEnumerable<string> PlainStrings(BlockView block)
    {
        var e = block.Element;
        foreach (var key in new[] { "title", "alt", "caption", "cite" })
            if (e.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.String) yield return value.GetString()!;
        if (block.Type == "steps")
            foreach (var step in e.GetProperty("items").EnumerateArray()) yield return step.GetProperty("title").GetString()!;
    }

    /// <summary>Human text of a block: plain strings plus inline text that is not marked as code.</summary>
    public static IEnumerable<TextRun> TextRuns(BlockView block)
    {
        foreach (var s in PlainStrings(block)) yield return new TextRun(block.Id, s);
        foreach (var inlines in InlineArrays(block))
        {
            var sb = new StringBuilder();
            foreach (var node in inlines.EnumerateArray())
            {
                var type = node.GetProperty("type").GetString();
                if (type is "text" && !IsCode(node)) sb.Append(node.GetProperty("text").GetString());
                else if (type is "term" or "mention") sb.Append(node.GetProperty("text").GetString());
                else sb.Append(' '); // code or a hard break separates runs
            }
            if (sb.Length > 0) yield return new TextRun(block.Id, sb.ToString());
        }
    }

    public static IEnumerable<JsonElement> InlineNodes(BlockView block) =>
        InlineArrays(block).SelectMany(a => a.EnumerateArray());

    public static bool IsCode(JsonElement inline) =>
        inline.TryGetProperty("marks", out var marks) && marks.EnumerateArray().Any(m => m.GetProperty("type").GetString() == "code");

    /// <summary>Text used for a block's automatic direction: like the renderers, inline code doesn't count.</summary>
    public static string DirectionText(BlockView block) => string.Concat(TextRuns(block).Select(r => r.Text));
}
