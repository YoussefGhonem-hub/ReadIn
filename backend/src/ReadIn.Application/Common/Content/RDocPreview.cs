using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace ReadIn.Application.Common.Content;

/// <summary>The first blocks of an article as an RDoc document, and whether they are all of it.</summary>
public sealed record RDocPreviewResult(string Json, bool IsComplete);

/// <summary>
/// What a feed card's "Read more" shows (SPEC F34): the article's first whole blocks, in order, until about
/// <see cref="WordBudget"/> words of text. A block is never cut, so the block that reaches the budget is kept whole, and
/// there is always at least one. A preview that stops before the end never ends on a heading or a divider (they belong to
/// what follows).
/// </summary>
public static partial class RDocPreview
{
    public const int WordBudget = 300;

    /// <summary>Text properties whose words count: inline text (terms and mentions too), titles, cites, captions and code.</summary>
    private static readonly HashSet<string> TextKeys = ["text", "title", "cite", "caption", "code"];

    /// <param name="contentJson">A stored, already validated RDoc document.</param>
    public static RDocPreviewResult Take(string contentJson, int wordBudget = WordBudget)
    {
        var document = JsonNode.Parse(contentJson)!.AsObject();
        if (document["blocks"] is not JsonArray blocks) return new RDocPreviewResult(contentJson, IsComplete: true);

        var count = 0;
        var words = 0;
        while (count < blocks.Count && words < wordBudget) words += Words(blocks[count++]);

        if (count < blocks.Count)
            while (count > 1 && Type(blocks[count - 1]) is "heading" or "divider") count--;

        if (count == blocks.Count) return new RDocPreviewResult(contentJson, IsComplete: true);

        while (blocks.Count > count) blocks.RemoveAt(blocks.Count - 1);
        return new RDocPreviewResult(document.ToJsonString(), IsComplete: false);
    }

    /// <summary>The words a reader reads in a block; a code-tabs block counts its first tab, as reading time does.</summary>
    internal static int Words(JsonNode? block)
    {
        if (Type(block) == "codeTabs")
            return block!["tabs"] is JsonArray { Count: > 0 } tabs && tabs[0] is JsonObject first ? CountWords(first["code"]) : 0;

        var total = 0;
        Walk(block, null, ref total);
        return total;
    }

    private static void Walk(JsonNode? node, string? key, ref int total)
    {
        switch (node)
        {
            case JsonObject obj:
                foreach (var (name, value) in obj) Walk(value, name, ref total);
                break;
            case JsonArray array:
                foreach (var item in array) Walk(item, key, ref total);
                break;
            case JsonValue when key is not null && TextKeys.Contains(key):
                total += CountWords(node);
                break;
        }
    }

    private static int CountWords(JsonNode? node) =>
        node is JsonValue value && value.TryGetValue<string>(out var text) ? WordRegex().Count(text) : 0;

    private static string? Type(JsonNode? block) =>
        block is JsonObject obj && obj["type"] is JsonValue value && value.TryGetValue<string>(out var type) ? type : null;

    [GeneratedRegex(@"\S+")]
    private static partial Regex WordRegex();
}
