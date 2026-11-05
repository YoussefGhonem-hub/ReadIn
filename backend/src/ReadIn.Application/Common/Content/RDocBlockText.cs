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
            var text = block.TryGetProperty("content", out var content) ? Inline(content) : string.Empty;
            return new RDocTextBlock(id, type, text, [new RDocTextUnit(0, text.Length)]);
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
            return new RDocTextBlock(id, type, sb.ToString(), units);
        }

        return new RDocTextBlock(id, type, null, []);
    }

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
