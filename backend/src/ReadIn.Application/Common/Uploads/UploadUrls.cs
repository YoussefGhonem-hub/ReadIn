using System.Diagnostics.CodeAnalysis;
using System.Text.Json;
using System.Text.Json.Nodes;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Common.Uploads;

/// <summary>
/// Converts between what is stored (relative upload paths, <c>rdoc-asset://uploads/…</c> in RDoc) and what clients
/// get (absolute URLs from <see cref="IFileStorage.GetPublicUrl"/>), so the public domain lives only in configuration.
/// External URLs (e.g. a Google profile photo) pass through unchanged.
/// </summary>
public static class UploadUrls
{
    /// <summary>Scheme of RDoc image sources that live in our storage (shared/rdoc/rdoc.schema.json).</summary>
    public const string AssetScheme = "rdoc-asset://";

    private static readonly string[] ImageSourceKeys = ["src", "darkSrc"];

    /// <summary>Stored value → value served to clients.</summary>
    public static string? ToPublicUrl(this IFileStorage storage, string? stored) =>
        UploadPath.TryParse(stored, out var path) ? storage.GetPublicUrl(path.Value) : stored;

    /// <summary>Client value → value to store: our own upload URLs become relative paths.</summary>
    public static string? ToStoredValue(this IFileStorage storage, string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        return storage.TryGetUploadPath(value, out var path) ? path.Value : value.Trim();
    }

    /// <summary>True when <paramref name="value"/> is a relative upload path or the public URL of one of our uploads.</summary>
    public static bool TryGetUploadPath(this IFileStorage storage, string? value, [NotNullWhen(true)] out UploadPath? path)
    {
        if (UploadPath.TryParse(value, out path)) return true;

        // Uri.TryCreate also accepts "/x" as a file URI on Unix, so require http(s) explicitly.
        if (value is not null
            && Uri.TryCreate(value.Trim(), UriKind.Absolute, out var uri)
            && uri.Scheme is "http" or "https"
            && UploadPath.TryParse(uri.AbsolutePath, out path)
            && string.Equals(storage.GetPublicUrl(path.Value), value.Trim(), StringComparison.OrdinalIgnoreCase))
            return true;

        path = null;
        return false;
    }

    /// <summary>RDoc as served: <c>rdoc-asset://uploads/…</c> image sources become absolute URLs.</summary>
    public static JsonElement ToPublicContent(this IFileStorage storage, string contentJson)
    {
        if (!contentJson.Contains(AssetScheme + "uploads/", StringComparison.Ordinal))
        {
            using var document = JsonDocument.Parse(contentJson);
            return document.RootElement.Clone();
        }

        var root = JsonNode.Parse(contentJson);
        RewriteImageSources(root, src =>
            src.StartsWith(AssetScheme, StringComparison.Ordinal) && UploadPath.TryParse("/" + src[AssetScheme.Length..], out var path)
                ? storage.GetPublicUrl(path.Value)
                : src);
        return JsonSerializer.SerializeToElement(root);
    }

    /// <summary>RDoc as stored: image sources that are our own upload URLs become <c>rdoc-asset://uploads/…</c>.</summary>
    public static JsonElement ToStoredContent(this IFileStorage storage, JsonElement content)
    {
        if (content.ValueKind != JsonValueKind.Object) return content;

        var root = JsonNode.Parse(content.GetRawText());
        var changed = RewriteImageSources(root, src =>
            !src.StartsWith(AssetScheme, StringComparison.Ordinal) && storage.TryGetUploadPath(src, out var path)
                ? AssetScheme + path.Value[1..]
                : src);
        return changed ? JsonSerializer.SerializeToElement(root) : content;
    }

    private static bool RewriteImageSources(JsonNode? node, Func<string, string> rewrite)
    {
        var changed = false;
        switch (node)
        {
            case JsonObject block:
                if (block["type"] is JsonValue type && type.TryGetValue<string>(out var kind) && kind == "image")
                {
                    foreach (var key in ImageSourceKeys)
                    {
                        if (block[key] is not JsonValue value || !value.TryGetValue<string>(out var src)) continue;
                        var rewritten = rewrite(src);
                        if (rewritten == src) continue;
                        block[key] = rewritten;
                        changed = true;
                    }
                }
                foreach (var (_, child) in block) changed |= RewriteImageSources(child, rewrite);
                break;

            case JsonArray items:
                foreach (var child in items) changed |= RewriteImageSources(child, rewrite);
                break;
        }
        return changed;
    }
}
