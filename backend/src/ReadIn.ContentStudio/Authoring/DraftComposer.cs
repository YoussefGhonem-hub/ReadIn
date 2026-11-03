using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using ReadIn.Domain.Common;

namespace ReadIn.ContentStudio.Authoring;

/// <summary>
/// <c>compose</c>: turns the drafts of an article folder (<c>en.md</c>, <c>ar-EG.md</c>) into <c>en.json</c> /
/// <c>ar-EG.json</c>. The JSON is written one block per line so a git diff shows which block changed.
/// </summary>
public static class DraftComposer
{
    private static readonly JsonSerializerOptions Compact = new() { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };

    public static async Task<List<string>> ComposeAsync(string folder, CancellationToken ct)
    {
        var errors = new List<string>();
        foreach (var language in ArticleLanguages.All)
        {
            var draft = Path.Combine(folder, $"{language}.md");
            if (!File.Exists(draft)) continue;

            var (document, problems) = RDocMarkdown.Convert(await File.ReadAllTextAsync(draft, ct), language);
            if (document is null)
            {
                errors.AddRange(problems.Select(p => $"{language}.md:{p.Line}: {p.Message}"));
                continue;
            }
            await File.WriteAllTextAsync(Path.Combine(folder, $"{language}.json"), Format(document), new UTF8Encoding(false), ct);
        }
        return errors;
    }

    public static string Format(JsonObject document)
    {
        var sb = new StringBuilder();
        sb.Append("{\n");
        sb.Append($"  \"version\": {document["version"]!.ToJsonString(Compact)},\n");
        sb.Append($"  \"language\": {document["language"]!.ToJsonString(Compact)},\n");
        sb.Append("  \"blocks\": [\n");
        var blocks = document["blocks"]!.AsArray();
        for (var i = 0; i < blocks.Count; i++)
        {
            sb.Append("    ").Append(blocks[i]!.ToJsonString(Compact));
            sb.Append(i < blocks.Count - 1 ? ",\n" : "\n");
        }
        sb.Append("  ]\n}\n");
        return sb.ToString();
    }
}
