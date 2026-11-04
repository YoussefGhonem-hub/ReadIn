using System.Text.Json;
using System.Text.Json.Nodes;

namespace ReadIn.Application.Common.Content;

/// <summary>
/// The <c>mention</c> inline nodes of an RDoc document (SPEC §13.3): <c>{ "type": "mention", "userId", "text" }</c>. Readers
/// link a mention by its text (<c>@username</c>), so what goes live is checked and rewritten here (SPEC F05, F18).
/// </summary>
public static class RDocMentions
{
    private const string MentionType = "mention";

    /// <summary>The user ids the document mentions, distinct, in document order. Ids that aren't GUIDs are skipped.</summary>
    public static IReadOnlyList<Guid> UserIds(JsonElement document)
    {
        var ids = new List<Guid>();
        if (document.ValueKind is JsonValueKind.Object or JsonValueKind.Array) Collect(JsonNode.Parse(document.GetRawText()), ids);
        return [.. ids.Distinct()];
    }

    /// <summary>
    /// The document with every mention checked against <paramref name="allowed"/> (user id → current @username): an allowed
    /// user keeps the mention, with its text set to <c>"@" + username</c> so it can't point at someone else or go stale; any
    /// other mention (not allowed, unknown, deleted or suspended) becomes a plain <c>text</c> node with the same text.
    /// A document without mentions comes back unchanged.
    /// </summary>
    public static JsonElement Apply(JsonElement document, IReadOnlyDictionary<Guid, string> allowed)
    {
        if (document.ValueKind is not (JsonValueKind.Object or JsonValueKind.Array)) return document;

        var root = JsonNode.Parse(document.GetRawText());
        return Rewrite(root, allowed) ? JsonSerializer.SerializeToElement(root) : document;
    }

    private static void Collect(JsonNode? node, List<Guid> ids)
    {
        switch (node)
        {
            case JsonObject obj:
                if (IsMention(obj) && UserIdOf(obj) is { } id) ids.Add(id);
                foreach (var (_, value) in obj) Collect(value, ids);
                break;
            case JsonArray array:
                foreach (var item in array) Collect(item, ids);
                break;
        }
    }

    /// <returns>true when a mention was found (and rewritten).</returns>
    private static bool Rewrite(JsonNode? node, IReadOnlyDictionary<Guid, string> allowed)
    {
        var changed = false;
        switch (node)
        {
            case JsonObject obj:
                foreach (var (_, value) in obj.ToList()) changed |= Rewrite(value, allowed);
                break;
            case JsonArray array:
                for (var i = 0; i < array.Count; i++)
                {
                    // Inline nodes live in arrays (a block's content, list items, table cells).
                    if (array[i] is JsonObject inline && IsMention(inline) && TextOf(inline) is { } text)
                    {
                        array[i] = UserIdOf(inline) is { } id && allowed.TryGetValue(id, out var username)
                            ? new JsonObject { ["type"] = MentionType, ["userId"] = id.ToString(), ["text"] = "@" + username }
                            : new JsonObject { ["type"] = "text", ["text"] = text };
                        changed = true;
                    }
                    else
                    {
                        changed |= Rewrite(array[i], allowed);
                    }
                }
                break;
        }
        return changed;
    }

    private static bool IsMention(JsonObject obj) =>
        obj["type"] is JsonValue type && type.TryGetValue<string>(out var value) && value == MentionType;

    private static Guid? UserIdOf(JsonObject mention) =>
        mention["userId"] is JsonValue value && value.TryGetValue<string>(out var text) && Guid.TryParse(text, out var id) ? id : null;

    private static string? TextOf(JsonObject mention) =>
        mention["text"] is JsonValue value && value.TryGetValue<string>(out var text) && text.Length > 0 ? text : null;
}
