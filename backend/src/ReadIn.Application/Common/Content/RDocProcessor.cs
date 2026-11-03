using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using System.Text.Unicode;
using Json.Schema;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Content;

public sealed record RDocHeading(string BlockId, int Level, string Text);

public sealed record ProcessedRDoc(
    ArticleContent Content,
    string Language,
    IReadOnlyList<RDocHeading> Headings,
    IReadOnlyList<string> TermIds,
    IReadOnlyList<string> CodeLanguages,
    int CodeLines);

public interface IRDocProcessor
{
    /// <summary>
    /// Sanitizes, validates and analyses an RDoc document (SPEC §13.5). The returned JSON is the only
    /// form of the content that may be stored.
    /// </summary>
    Result<ProcessedRDoc> Process(JsonElement document, string? expectedLanguage = null, string? title = null);
}

public static class RDocErrors
{
    public static readonly Error LanguageMismatch =
        Error.Validation("article.content_language_mismatch", "The RDoc language does not match the requested article language.");

    public static Error Invalid(IReadOnlyDictionary<string, string[]> details) =>
        ArticleErrors.InvalidContent with { Details = details };
}

internal sealed partial class RDocProcessor : IRDocProcessor
{
    private const int ArabicWordsPerMinute = 180;
    private const int EnglishWordsPerMinute = 230;
    private const double SecondsPerCodeLine = 4;

    private static readonly Lazy<JsonSchema> Schema = new(LoadSchema);

    /// <summary>String properties that hold human text or code and must be sanitized.</summary>
    private static readonly HashSet<string> TextProperties = ["text", "title", "caption", "alt", "cite", "code", "label", "filename"];

    private static readonly HashSet<string> YouTubeHosts = ["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be", "www.youtube-nocookie.com"];
    private static readonly HashSet<string> GistHosts = ["gist.github.com"];

    public Result<ProcessedRDoc> Process(JsonElement document, string? expectedLanguage = null, string? title = null)
    {
        if (document.ValueKind != JsonValueKind.Object)
            return RDocErrors.Invalid(new Dictionary<string, string[]> { ["content"] = ["RDoc must be a JSON object."] });

        var node = JsonNode.Parse(document.GetRawText())!;
        Sanitize(node, parentKey: null);
        var sanitized = JsonSerializer.SerializeToElement(node);

        var evaluation = Schema.Value.Evaluate(sanitized, new EvaluationOptions { OutputFormat = OutputFormat.List });
        if (!evaluation.IsValid) return RDocErrors.Invalid(CollectSchemaErrors(evaluation));

        var embedErrors = CheckEmbeds(sanitized);
        if (embedErrors.Count > 0) return RDocErrors.Invalid(embedErrors);

        var language = sanitized.GetProperty("language").GetString()!;
        if (expectedLanguage is not null && language != expectedLanguage) return RDocErrors.LanguageMismatch;

        return Analyse(sanitized, node.ToJsonString(StorageJson), language, title);
    }

    /// <summary>Stores Arabic as-is instead of \uXXXX escapes (~6× smaller); HTML-sensitive characters stay escaped.</summary>
    private static readonly JsonSerializerOptions StorageJson = new() { Encoder = JavaScriptEncoder.Create(UnicodeRanges.All) };

    // ── Sanitization ────────────────────────────────────────────

    private static void Sanitize(JsonNode? node, string? parentKey)
    {
        switch (node)
        {
            case JsonObject obj:
                foreach (var (key, value) in obj.ToList())
                {
                    if (value is JsonValue v && v.TryGetValue<string>(out var s) && TextProperties.Contains(key))
                        obj[key] = CleanText(s, isCode: key == "code");
                    else
                        Sanitize(value, key);
                }
                break;
            case JsonArray array:
                foreach (var item in array) Sanitize(item, parentKey);
                break;
        }
    }

    /// <summary>
    /// Removes bidi embedding/override/isolate controls (renderers own isolation; in code they enable
    /// "Trojan Source" attacks) and C0 control characters other than tab/newline.
    /// </summary>
    internal static string CleanText(string value, bool isCode)
    {
        var sb = new StringBuilder(value.Length);
        foreach (var ch in value)
        {
            if (ch is >= '‪' and <= '‮' or >= '⁦' and <= '⁩') continue;
            if (char.IsControl(ch) && ch is not '\n' && !(isCode && ch is '\t')) continue;
            sb.Append(ch);
        }
        return sb.ToString();
    }

    private static Dictionary<string, string[]> CheckEmbeds(JsonElement document)
    {
        var errors = new Dictionary<string, string[]>();
        var index = 0;
        foreach (var block in document.GetProperty("blocks").EnumerateArray())
        {
            if (block.GetProperty("type").GetString() == "embed")
            {
                var provider = block.GetProperty("provider").GetString();
                var url = block.GetProperty("url").GetString();
                var allowed = Uri.TryCreate(url, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps && provider switch
                {
                    "youtube" => YouTubeHosts.Contains(uri.Host),
                    "github-gist" => GistHosts.Contains(uri.Host),
                    _ => false,
                };
                if (!allowed) errors[$"content.blocks[{index}].url"] = ["rdoc.embed_not_allowed"];
            }
            index++;
        }
        return errors;
    }

    private static Dictionary<string, string[]> CollectSchemaErrors(EvaluationResults evaluation)
    {
        var errors = new Dictionary<string, List<string>>();
        foreach (var detail in evaluation.Details ?? [])
        {
            if (detail.IsValid || detail.Errors is null) continue;
            var location = "content" + detail.InstanceLocation;
            if (!errors.TryGetValue(location, out var list)) errors[location] = list = [];
            list.AddRange(detail.Errors.Values);
        }

        if (errors.Count == 0) errors["content"] = ["The document does not match the RDoc schema."];
        return errors.Take(20).ToDictionary(e => e.Key, e => e.Value.Distinct().Take(5).ToArray());
    }

    // ── Analysis ────────────────────────────────────────────────

    private static ProcessedRDoc Analyse(JsonElement document, string json, string language, string? title)
    {
        var text = new StringBuilder();
        var headings = new List<RDocHeading>();
        var terms = new HashSet<string>(StringComparer.Ordinal);
        var codeLanguages = new HashSet<string>(StringComparer.Ordinal);
        string? summary = null;
        var codeLines = 0;

        foreach (var block in document.GetProperty("blocks").EnumerateArray())
        {
            var type = block.GetProperty("type").GetString();
            switch (type)
            {
                case "paragraph" or "quote" or "callout" or "summary" or "heading":
                    if (block.TryGetProperty("title", out var calloutTitle)) AppendBlock(text, calloutTitle.GetString());
                    var inline = InlineText(block.GetProperty("content"), terms);
                    AppendBlock(text, inline);
                    if (type == "heading")
                        headings.Add(new RDocHeading(block.GetProperty("id").GetString()!, block.GetProperty("level").GetInt32(), inline));
                    if (type == "summary") summary ??= inline;
                    break;

                case "bulletList" or "orderedList":
                    foreach (var item in block.GetProperty("items").EnumerateArray()) AppendBlock(text, InlineText(item, terms));
                    break;

                case "steps":
                    foreach (var step in block.GetProperty("items").EnumerateArray())
                    {
                        AppendBlock(text, step.GetProperty("title").GetString());
                        AppendBlock(text, InlineText(step.GetProperty("content"), terms));
                    }
                    break;

                case "table":
                    foreach (var cell in block.GetProperty("header").EnumerateArray()) AppendBlock(text, InlineText(cell, terms));
                    foreach (var row in block.GetProperty("rows").EnumerateArray())
                        foreach (var cell in row.EnumerateArray()) AppendBlock(text, InlineText(cell, terms));
                    break;

                case "image":
                    if (block.TryGetProperty("caption", out var caption)) AppendBlock(text, caption.GetString());
                    break;

                case "code":
                    codeLanguages.Add(block.GetProperty("lang").GetString()!);
                    codeLines += CountLines(block.GetProperty("code").GetString());
                    break;

                case "codeTabs":
                    var first = true;
                    foreach (var tab in block.GetProperty("tabs").EnumerateArray())
                    {
                        codeLanguages.Add(tab.GetProperty("lang").GetString()!);
                        // Readers read one tab, so only the first counts toward reading time.
                        if (first) codeLines += CountLines(tab.GetProperty("code").GetString());
                        first = false;
                    }
                    break;
            }
        }

        var plainText = text.ToString().Trim();
        var words = WordRegex().Count(plainText);
        var wpm = language == ArticleLanguages.EgyptianArabic ? ArabicWordsPerMinute : EnglishWordsPerMinute;
        var minutes = words / (double)wpm + codeLines * SecondsPerCodeLine / 60;
        var readingTime = Math.Max(1, (int)Math.Ceiling(minutes));

        var searchText = ArabicNormalizer.Normalize(string.IsNullOrWhiteSpace(title) ? plainText : $"{title}\n{plainText}");

        return new ProcessedRDoc(
            new ArticleContent(json, plainText, searchText, summary, readingTime, words),
            language,
            headings,
            [.. terms],
            [.. codeLanguages],
            codeLines);
    }

    private static string InlineText(JsonElement inlines, HashSet<string> terms)
    {
        var sb = new StringBuilder();
        foreach (var node in inlines.EnumerateArray())
        {
            switch (node.GetProperty("type").GetString())
            {
                case "text" or "mention":
                    sb.Append(node.GetProperty("text").GetString());
                    break;
                case "term":
                    terms.Add(node.GetProperty("termId").GetString()!);
                    sb.Append(node.GetProperty("text").GetString());
                    break;
                case "hardBreak":
                    sb.Append('\n');
                    break;
            }
        }
        return sb.ToString();
    }

    private static void AppendBlock(StringBuilder sb, string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return;
        if (sb.Length > 0) sb.Append("\n\n");
        sb.Append(value.Trim());
    }

    private static int CountLines(string? code) =>
        string.IsNullOrEmpty(code) ? 0 : code.Split('\n').Count(l => !string.IsNullOrWhiteSpace(l));

    private static JsonSchema LoadSchema()
    {
        using var stream = typeof(RDocProcessor).Assembly.GetManifestResourceStream("ReadIn.rdoc.schema.json")
            ?? throw new InvalidOperationException("Embedded RDoc schema not found.");
        using var reader = new StreamReader(stream);
        return JsonSchema.FromText(reader.ReadToEnd());
    }

    [GeneratedRegex(@"\S+")]
    private static partial Regex WordRegex();
}
