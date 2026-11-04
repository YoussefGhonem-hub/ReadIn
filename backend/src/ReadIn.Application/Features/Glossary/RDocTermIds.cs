using System.Text.Json;

namespace ReadIn.Application.Features.Glossary;

/// <summary>Reads the glossary term ids that stored RDoc content uses (<c>{ "type": "term", "termId": … }</c> nodes).</summary>
public static class RDocTermIds
{
    /// <summary>Distinct term ids in document order; malformed JSON yields none.</summary>
    public static IReadOnlyList<string> Extract(string contentJson)
    {
        var ids = new List<string>();
        try
        {
            using var document = JsonDocument.Parse(contentJson);
            Collect(document.RootElement, ids);
        }
        catch (JsonException)
        {
            return [];
        }
        return ids;
    }

    private static void Collect(JsonElement element, List<string> ids)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Object:
                if (element.TryGetProperty("type", out var type) && type.ValueKind == JsonValueKind.String && type.ValueEquals("term")
                    && element.TryGetProperty("termId", out var termId) && termId.GetString() is { Length: > 0 } id
                    && !ids.Contains(id, StringComparer.Ordinal))
                {
                    ids.Add(id);
                }
                foreach (var property in element.EnumerateObject()) Collect(property.Value, ids);
                break;
            case JsonValueKind.Array:
                foreach (var item in element.EnumerateArray()) Collect(item, ids);
                break;
        }
    }
}
