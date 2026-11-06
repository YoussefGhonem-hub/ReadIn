using System.Text;
using System.Text.Json;

namespace ReadIn.Application.Common.Content;

/// <summary>A piece of a block's plain text a highlight stays inside: the whole block, or one list item. End exclusive.</summary>
public sealed record RDocTextUnit(int Start, int End);

/// <summary>
/// One block as highlights see it (SPEC F30). <see cref="Text"/> is the block's plain text, or null for a block that
/// can't be highlighted (code, code tabs, table, steps, image, divider, embed).
/// </summary>
public sealed record RDocTextBlock(string Id, string Type, string? Text, IReadOnlyList<RDocTextUnit> Units)
{
    public bool IsHighlightable => Text is not null;

    /// <summary>
    /// <c>rtl</c> or <c>ltr</c>: the direction the reader gives the block (SPEC §14.2 rule 1, the web's
    /// <c>resolveBlockDir</c>, the PDF's <c>BidiText.ResolveBlockDir</c>): its explicit <c>dir</c>, else its first strong
    /// character, with inline code skipped and a callout's title first. Null when it has neither (the article's language
    /// decides), and for a block that can't be highlighted. A quote card takes it (SPEC F24).
    /// </summary>
    public string? Dir { get; init; }
}

/// <summary>
/// The plain text of RDoc blocks that highlight offsets count in (SPEC F30, contract "Highlights (F30)", the fixtures in
/// <c>shared/rdoc/highlight-fixtures.json</c>): inline nodes in order, where text, term and mention give their text and a
/// hard break gives "\n"; marks add nothing. A list's items are joined by one "\n" and each item is a unit of its own.
/// A callout's title and a quote's cite are not part of it. Nothing is trimmed or normalized: offsets are UTF-16 code
/// units of exactly this string.
/// </summary>
public static class RDocBlockText
{
    private static readonly HashSet<string> SingleUnitTypes = ["paragraph", "heading", "quote", "callout", "summary"];
    private static readonly HashSet<string> ListTypes = ["bulletList", "orderedList"];

    /// <summary>Every block of the document, in order. A document that doesn't parse has no blocks.</summary>
    public static IReadOnlyList<RDocTextBlock> Blocks(string contentJson)
    {
        try
        {
            using var document = JsonDocument.Parse(contentJson);
            return Blocks(document.RootElement);
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static IReadOnlyList<RDocTextBlock> Blocks(JsonElement document)
    {
        if (document.ValueKind != JsonValueKind.Object || !document.TryGetProperty("blocks", out var blocks) || blocks.ValueKind != JsonValueKind.Array)
            return [];

        var result = new List<RDocTextBlock>();
        foreach (var block in blocks.EnumerateArray())
        {
            if (block.ValueKind != JsonValueKind.Object) continue;
            var id = Str(block, "id");
            var type = Str(block, "type");
            if (id is null || type is null) continue;
            result.Add(Read(id, type, block));
        }
        return result;
    }

    private static RDocTextBlock Read(string id, string type, JsonElement block)
    {
        if (SingleUnitTypes.Contains(type))
        {
            var hasContent = block.TryGetProperty("content", out var content);
            var text = hasContent ? Inline(content) : string.Empty;
            var title = type == "callout" && Str(block, "title") is { Length: > 0 } calloutTitle ? calloutTitle + " " : string.Empty;
            return new RDocTextBlock(id, type, text, [new RDocTextUnit(0, text.Length)])
            {
                Dir = BlockDir(block, title + (hasContent ? DirText(content) : string.Empty)),
            };
        }

        if (ListTypes.Contains(type) && block.TryGetProperty("items", out var items) && items.ValueKind == JsonValueKind.Array)
        {
            var sb = new StringBuilder();
            var units = new List<RDocTextUnit>();
            foreach (var item in items.EnumerateArray())
            {
                if (units.Count > 0) sb.Append('\n');
                var start = sb.Length;
                sb.Append(Inline(item));
                units.Add(new RDocTextUnit(start, sb.Length));
            }
            return new RDocTextBlock(id, type, sb.ToString(), units)
            {
                Dir = BlockDir(block, string.Join(' ', items.EnumerateArray().Select(DirText))),
            };
        }

        return new RDocTextBlock(id, type, null, []);
    }

    /// <summary>An explicit <c>rtl</c>/<c>ltr</c> wins; <c>auto</c> (the default) follows the first strong character.</summary>
    private static string? BlockDir(JsonElement block, string dirText) =>
        Str(block, "dir") is TextDirection.Rtl or TextDirection.Ltr ? Str(block, "dir") : TextDirection.FirstStrong(dirText);

    /// <summary>
    /// The text a block's direction is resolved from (the web's <c>inlineText</c>): text without the code mark, terms and
    /// mentions; any other node is a line break. Inline code is skipped so a leading <c>AddScoped</c> doesn't flip an Arabic block.
    /// </summary>
    private static string DirText(JsonElement nodes)
    {
        if (nodes.ValueKind != JsonValueKind.Array) return string.Empty;
        var sb = new StringBuilder();
        foreach (var node in nodes.EnumerateArray())
        {
            switch (node.ValueKind == JsonValueKind.Object ? Str(node, "type") : null)
            {
                case "text" when !HasCodeMark(node):
                case "term" or "mention":
                    sb.Append(Str(node, "text"));
                    break;
                case "text":
                    break;
                default:
                    sb.Append('\n');
                    break;
            }
        }
        return sb.ToString();
    }

    private static bool HasCodeMark(JsonElement node) =>
        node.TryGetProperty("marks", out var marks) && marks.ValueKind == JsonValueKind.Array
        && marks.EnumerateArray().Any(m => m.ValueKind == JsonValueKind.Object && Str(m, "type") == "code");

    private static string Inline(JsonElement nodes)
    {
        if (nodes.ValueKind != JsonValueKind.Array) return string.Empty;
        var sb = new StringBuilder();
        foreach (var node in nodes.EnumerateArray())
        {
            switch (node.ValueKind == JsonValueKind.Object ? Str(node, "type") : null)
            {
                case "text" or "term" or "mention":
                    sb.Append(Str(node, "text"));
                    break;
                case "hardBreak":
                    sb.Append('\n');
                    break;
            }
        }
        return sb.ToString();
    }

    private static string? Str(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;
}
