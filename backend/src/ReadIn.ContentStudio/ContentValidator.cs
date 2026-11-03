using System.Text.Json;
using ReadIn.Application.Common.Content;
using ReadIn.Domain.Common;
using ReadIn.Infrastructure.Content;

namespace ReadIn.ContentStudio;

public enum Severity { Error, Warning }

public sealed record Finding(string Slug, Severity Severity, string Check, string Message);

/// <summary>
/// Automatic checks from SPEC §19.3 that run offline: schema, en/ar-EG structure parity, sources,
/// quality and freshness. Code compilation and live link checks are separate (network/toolchains).
/// </summary>
public sealed class ContentValidator(ContentRepository content, IRDocProcessor rdoc)
{
    private const int MinWords = 800;
    private const int MaxWords = 2000;
    private const int MinMinutes = 4;
    private const int MaxMinutes = 10;

    /// <summary>Fields whose articles must carry a version badge (e.g. ".NET 10").</summary>
    private static readonly HashSet<string> VersionedFields = ["dotnet", "frontend", "mobile", "claude-ai-tools", "databases", "devops-cloud"];

    private static readonly HashSet<string> StructuralBlocks = ["heading", "code", "codeTabs", "table", "steps", "callout", "image"];

    public async Task<IReadOnlyList<Finding>> ValidateAsync(string? onlySlug, CancellationToken ct)
    {
        var findings = new List<Finding>();
        foreach (var folder in content.ArticleFolders())
        {
            ArticleMeta meta;
            try
            {
                meta = await content.ReadMetaAsync(folder, ct);
            }
            catch (JsonException ex)
            {
                findings.Add(new(Path.GetFileName(folder), Severity.Error, "meta", ex.Message));
                continue;
            }

            if (onlySlug is not null && meta.Slug != onlySlug) continue;
            findings.AddRange(await ValidateArticleAsync(folder, meta, ct));
        }
        return findings;
    }

    private async Task<List<Finding>> ValidateArticleAsync(string folder, ArticleMeta meta, CancellationToken ct)
    {
        var findings = new List<Finding>();
        void Add(Severity s, string check, string message) => findings.Add(new(meta.Slug, s, check, message));

        if (Path.GetFileName(folder) != meta.Slug) Add(Severity.Error, "meta", "Folder name must equal the slug.");
        if (meta.Sources.Count == 0) Add(Severity.Error, "sources", "At least one source is required.");
        foreach (var source in meta.Sources.Where(s => !Uri.TryCreate(s.Url, UriKind.Absolute, out var u) || u.Scheme != Uri.UriSchemeHttps))
            Add(Severity.Error, "sources", $"Source URL must be https: {source.Url}");
        if (VersionedFields.Contains(meta.Field) && string.IsNullOrWhiteSpace(meta.VersionBadge))
            Add(Severity.Warning, "freshness", "Versioned technology without a version badge.");

        var documents = new Dictionary<string, JsonElement>();
        foreach (var language in ArticleLanguages.All)
        {
            using var document = await content.ReadRDocAsync(folder, language, ct);
            if (document is null)
            {
                Add(Severity.Error, "files", $"{language}.json is missing.");
                continue;
            }
            if (!meta.Translations.TryGetValue(language, out var titles) || string.IsNullOrWhiteSpace(titles.Title))
                Add(Severity.Error, "meta", $"No title for {language}.");

            var processed = rdoc.Process(document.RootElement, language, meta.Translations.GetValueOrDefault(language)?.Title);
            if (processed.IsFailure)
            {
                var details = processed.Error.Details?.Select(d => $"{d.Key}: {string.Join(", ", d.Value)}") ?? [processed.Error.Description];
                foreach (var detail in details) Add(Severity.Error, "schema", $"{language}: {detail}");
                continue;
            }

            documents[language] = document.RootElement.Clone();
            var c = processed.Value.Content;
            if (language == meta.SourceLanguage && (c.WordCount < MinWords || c.WordCount > MaxWords))
                Add(Severity.Warning, "quality", $"{language}: {c.WordCount} words (target {MinWords}–{MaxWords}).");
            if (c.ReadingTimeMinutes is < MinMinutes or > MaxMinutes)
                Add(Severity.Warning, "quality", $"{language}: reading time {c.ReadingTimeMinutes} min (target {MinMinutes}–{MaxMinutes}; outside it the article is never picked as Today's article).");
            if (!Blocks(document.RootElement).Any(b => b.Type is "callout" or "code" or "codeTabs" or "table"))
                Add(Severity.Error, "quality", $"{language}: needs at least one callout, code block or table.");
        }

        if (documents.TryGetValue("en", out var en) && documents.TryGetValue("ar-EG", out var ar))
            findings.AddRange(CheckParity(meta.Slug, en, ar));

        return findings;
    }

    /// <summary>Both versions must share sections, code blocks and structure (SPEC §19.3 "Structure parity").</summary>
    private static IEnumerable<Finding> CheckParity(string slug, JsonElement en, JsonElement ar)
    {
        var enBlocks = Blocks(en).Where(b => StructuralBlocks.Contains(b.Type)).ToList();
        var arBlocks = Blocks(ar).Where(b => StructuralBlocks.Contains(b.Type)).ToList();

        if (enBlocks.Count != arBlocks.Count)
        {
            yield return new(slug, Severity.Error, "parity", $"Structural block count differs: en={enBlocks.Count}, ar-EG={arBlocks.Count}.");
            yield break;
        }

        for (var i = 0; i < enBlocks.Count; i++)
        {
            var (e, a) = (enBlocks[i], arBlocks[i]);
            if (e.Type != a.Type || e.Id != a.Id)
                yield return new(slug, Severity.Error, "parity", $"Block #{i}: en has {e.Type}#{e.Id}, ar-EG has {a.Type}#{a.Id}.");
            else if (e.Type == "code" && e.Code != a.Code)
                yield return new(slug, Severity.Error, "parity", $"Code block '{e.Id}' differs between versions (code must be identical).");
        }
    }

    private sealed record BlockInfo(string Id, string Type, string? Code);

    private static IEnumerable<BlockInfo> Blocks(JsonElement document) =>
        document.GetProperty("blocks").EnumerateArray().Select(b => new BlockInfo(
            b.GetProperty("id").GetString()!,
            b.GetProperty("type").GetString()!,
            b.TryGetProperty("code", out var code) ? code.GetString() : null));
}
