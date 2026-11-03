using System.Text.Json;
using System.Text.RegularExpressions;
using ReadIn.Application.Common.Content;
using ReadIn.Domain.Common;
using ReadIn.Infrastructure.Content;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace ReadIn.ContentStudio.Validation;

public sealed record ValidationRequest(
    string? Slug = null,
    string? Field = null,
    bool Plan = false,
    bool Links = true,
    bool Compile = true);

/// <summary>
/// <c>validate</c> (SPEC §19.3): per-article rules (<see cref="ArticleRules"/>), duplicate titles, compile checks
/// (<see cref="CodeChecks"/>) and the link checker. <c>--plan</c> checks the plan in taxonomy.yaml instead.
/// </summary>
public sealed partial class ContentValidator(ContentRepository content, IRDocProcessor rdoc)
{
    /// <summary>Two titles (or misconceptions) sharing this share of their meaningful words are near-duplicates.</summary>
    private const double SimilarityLimit = 0.6;

    private static readonly HashSet<string> StopWords =
    [
        "a", "an", "the", "is", "are", "isn", "t", "not", "and", "or", "of", "in", "on", "to", "for", "with", "your", "you",
        "what", "why", "how", "when", "it", "its", "does", "doesn", "do", "don", "really", "actually", "happens", "vs",
        "versus", "about", "without", "myths", "myth", "explained", "right", "wrong", "way", "s", "from", "into", "than",
    ];

    public string RepoRoot => Path.GetDirectoryName(content.Root)!;

    public async Task<(List<Finding> Findings, ValidationStats Stats)> ValidateAsync(ValidationRequest request, CancellationToken ct)
    {
        var findings = new List<Finding>();
        var stats = new ValidationStats();
        var taxonomy = await content.ReadTaxonomyAsync(ct);

        if (request.Plan)
        {
            findings.AddRange(CheckPlan(taxonomy));
            if (request.Links)
                await CheckLinksAsync(taxonomy.PlannedArticles.SelectMany(p => p.PlannedSources.Select(u => (p.Slug, u))), findings, stats, ct);
            return (findings, stats);
        }

        var plan = taxonomy.PlannedArticles.GroupBy(p => p.Slug).ToDictionary(g => g.Key, g => g.First());
        var glossary = await LoadGlossaryAsync(findings, ct);
        var all = new List<(string Folder, ArticleMeta Meta)>();
        foreach (var folder in content.ArticleFolders())
        {
            try
            {
                all.Add((folder, await content.ReadMetaAsync(folder, ct)));
            }
            catch (JsonException ex)
            {
                findings.Add(new(Path.GetFileName(folder), Severity.Error, "meta", ex.Message));
            }
        }

        foreach (var dup in all.GroupBy(a => a.Meta.Slug).Where(g => g.Count() > 1))
            findings.Add(new(dup.Key, Severity.Error, "slug", $"Slug used by {dup.Count()} folders."));
        findings.AddRange(CheckSimilarTitles(all.Select(a => (a.Meta.Slug, a.Meta.Translations.GetValueOrDefault("en")?.Title ?? "")), "title", Severity.Error));

        var selected = all.Where(a =>
            (request.Slug is null || a.Meta.Slug == request.Slug) &&
            (request.Field is null || a.Meta.Field == request.Field)).ToList();

        var checkers = CodeChecks.Checkers(Path.Combine(RepoRoot, "tools"));
        var snippets = new List<Snippet>();
        foreach (var (folder, meta) in selected)
        {
            stats.Articles++;
            var article = await LoadAsync(folder, meta, plan.GetValueOrDefault(meta.Slug), findings, ct);
            if (article is null) continue;
            foreach (var (language, processed) in article.Processed)
                stats.Lengths.Add((meta.Slug, language, processed.Content.WordCount, processed.Content.ReadingTimeMinutes));

            foreach (var (severity, check, message) in ArticleRules.Check(article, glossary))
                findings.Add(new(meta.Slug, severity, check, message));

            if (article.Documents.TryGetValue("en", out var en))
            {
                var extracted = CodeChecks.Extract(meta.Slug, en, meta.Code, checkers).ToList();
                findings.AddRange(CheckSkipReasons(meta, extracted));
                snippets.AddRange(extracted);
            }
        }

        if (request.Compile) await CompileAsync(snippets, checkers, findings, stats, ct);
        if (request.Links)
            await CheckLinksAsync(selected.SelectMany(a => a.Meta.Sources.Select(s => (a.Meta.Slug, s.Url))), findings, stats, ct);

        return (findings, stats);
    }

    private async Task<ArticleUnderTest?> LoadAsync(string folder, ArticleMeta meta, PlannedArticleEntry? plan, List<Finding> findings, CancellationToken ct)
    {
        var documents = new Dictionary<string, JsonElement>();
        var processed = new Dictionary<string, ProcessedRDoc>();
        foreach (var language in ArticleLanguages.All)
        {
            JsonDocument? document;
            try
            {
                document = await content.ReadRDocAsync(folder, language, ct);
            }
            catch (JsonException ex)
            {
                findings.Add(new(meta.Slug, Severity.Error, "json", $"{language}.json: {ex.Message}"));
                continue;
            }
            if (document is null)
            {
                findings.Add(new(meta.Slug, Severity.Error, "files", $"{language}.json is missing."));
                continue;
            }

            using (document)
            {
                var result = rdoc.Process(document.RootElement, language, meta.Translations.GetValueOrDefault(language)?.Title);
                if (result.IsFailure)
                {
                    var details = result.Error.Details?.Select(d => $"{d.Key}: {string.Join(", ", d.Value)}") ?? [result.Error.Description];
                    foreach (var detail in details) findings.Add(new(meta.Slug, Severity.Error, "schema", $"{language}: {detail}"));
                    continue;
                }
                // The stored form is the sanitized JSON, so rules run on exactly what readers will get.
                using var stored = JsonDocument.Parse(result.Value.Content.Json);
                documents[language] = stored.RootElement.Clone();
                processed[language] = result.Value;
            }
        }
        return documents.Count > 0 ? new ArticleUnderTest(folder, meta, plan, documents, processed) : null;
    }

    private static IEnumerable<Finding> CheckSkipReasons(ArticleMeta meta, List<Snippet> snippets)
    {
        var skip = meta.Code?.Skip ?? [];
        foreach (var s in snippets.Where(s => !s.Compile && string.IsNullOrWhiteSpace(skip.GetValueOrDefault(s.Key))))
            yield return new(meta.Slug, Severity.Error, "compile", $"{s.Key} has \"compile\": false but no reason in meta.json code.skip.");
        foreach (var key in skip.Keys.Where(k => !snippets.Any(s => s.Key == k && !s.Compile)))
            yield return new(meta.Slug, Severity.Error, "compile", $"code.skip names '{key}', which is not a snippet marked \"compile\": false.");
    }

    private static async Task CompileAsync(List<Snippet> snippets, List<ISnippetChecker> checkers, List<Finding> findings, ValidationStats stats, CancellationToken ct)
    {
        var byChecker = new Dictionary<ISnippetChecker, List<Snippet>>();
        foreach (var s in snippets)
        {
            var checker = checkers.FirstOrDefault(c => c.Handles(s.Lang));
            if (checker is null)
            {
                stats.Skipped.Add((s.Slug, s.Key, s.Lang, $"no checker for '{s.Lang}'"));
                continue;
            }
            if (!s.Compile)
            {
                stats.Skipped.Add((s.Slug, s.Key, s.Lang, "compile: false"));
                continue;
            }
            if (!byChecker.TryGetValue(checker, out var list)) byChecker[checker] = list = [];
            list.Add(s);
        }

        foreach (var (checker, list) in byChecker)
        {
            var run = await checker.CheckAsync(list, ct);
            if (run.Toolchain is not null)
                findings.Add(new("(toolchain)", Severity.Error, "compile", $"{checker.Id}: {run.Toolchain} {list.Count} snippet(s) were NOT checked."));
            stats.Compiled[checker.Id] = run.Checked;
            foreach (var e in run.Errors)
                findings.Add(new(e.Snippet.Slug, Severity.Error, "compile", $"{e.Snippet.Key} ({e.Snippet.Lang}): {e.Message}"));
        }
    }

    private async Task CheckLinksAsync(IEnumerable<(string Slug, string Url)> sources, List<Finding> findings, ValidationStats stats, CancellationToken ct)
    {
        var list = sources.ToList();
        using var checker = new LinkChecker(Path.Combine(content.Root, ".cache", "links.json"));
        var results = await checker.CheckAsync(list.Select(s => s.Url), ct);
        stats.LinksChecked = results.Count;
        stats.LinksFromCache = checker.FromCache;

        foreach (var (slug, url) in list)
        {
            var r = results[url];
            if (r.Ok) continue;
            var why = r.Error ?? $"HTTP {r.Status}";
            stats.LinkFailures.Add($"{slug}: {url} ({why})");
            findings.Add(new(slug, Severity.Error, "links", $"{url} → {why}"));
        }
    }

    // ── Plan (content/taxonomy.yaml) ────────────────────────────

    private static IEnumerable<Finding> CheckPlan(TaxonomyFile taxonomy)
    {
        const string plan = "(plan)";
        var fields = taxonomy.Fields.ToDictionary(f => f.Slug);
        var paths = taxonomy.LearningPaths.ToDictionary(p => p.Slug);

        foreach (var dup in taxonomy.PlannedArticles.GroupBy(p => p.Slug).Where(g => g.Count() > 1))
            yield return new(dup.Key, Severity.Error, "plan", $"Slug planned {dup.Count()} times.");
        foreach (var dup in taxonomy.LearningPaths.GroupBy(p => p.Slug).Where(g => g.Count() > 1))
            yield return new(plan, Severity.Error, "plan", $"Learning path '{dup.Key}' defined {dup.Count()} times.");

        foreach (var p in taxonomy.PlannedArticles)
        {
            if (!SlugPattern().IsMatch(p.Slug) || p.Slug.Length > 60)
                yield return new(p.Slug, Severity.Error, "plan", "Slug must be kebab-case English, ≤ 60 characters.");
            if (!fields.TryGetValue(p.Field, out var field))
                yield return new(p.Slug, Severity.Error, "plan", $"Unknown field '{p.Field}'.");
            else if (field.Topics.All(t => t.Slug != p.Topic))
                yield return new(p.Slug, Severity.Error, "plan", $"Topic '{p.Topic}' is not a topic of '{p.Field}'.");
            if (!paths.ContainsKey(p.LearningPath))
                yield return new(p.Slug, Severity.Error, "plan", $"Unknown learning path '{p.LearningPath}'.");
            if (p.Level is not ("beginner" or "intermediate" or "advanced"))
                yield return new(p.Slug, Severity.Error, "plan", $"Level '{p.Level}' must be beginner, intermediate or advanced.");
            if (string.IsNullOrWhiteSpace(p.TitleEn) || p.TitleEn.Length > 100)
                yield return new(p.Slug, Severity.Error, "plan", "titleEn is required (≤ 100 characters).");
            if (string.IsNullOrWhiteSpace(p.TitleAr) || p.TitleAr.Length > 100 || !p.TitleAr.Any(c => c is >= '؀' and <= 'ۿ'))
                yield return new(p.Slug, Severity.Error, "plan", "titleAr is required, in Arabic (≤ 100 characters).");
            if (string.IsNullOrWhiteSpace(p.Misconception) || p.Misconception.Contains('\n'))
                yield return new(p.Slug, Severity.Error, "plan", "misconception must be one line.");
            if (p.PlannedSources.Count is < ArticleRules.MinSources or > ArticleRules.MaxSources)
                yield return new(p.Slug, Severity.Error, "plan", $"{p.PlannedSources.Count} planned sources (need 2–5).");
            foreach (var url in p.PlannedSources.Where(u => !u.StartsWith("https://", StringComparison.Ordinal)))
                yield return new(p.Slug, Severity.Error, "plan", $"Source must be https: {url}");
        }

        foreach (var path in taxonomy.PlannedArticles.GroupBy(p => p.LearningPath))
        {
            var orders = path.Select(p => p.Order).Order().ToList();
            if (!orders.SequenceEqual(Enumerable.Range(1, orders.Count)))
                yield return new(plan, Severity.Error, "plan", $"Path '{path.Key}' orders are {string.Join(',', orders)}; they must be 1..{orders.Count}.");
        }
        foreach (var path in taxonomy.LearningPaths.Where(p => taxonomy.PlannedArticles.All(a => a.LearningPath != p.Slug)))
            yield return new(plan, Severity.Warning, "plan", $"Learning path '{path.Slug}' has no articles.");

        foreach (var f in CheckSimilarTitles(taxonomy.PlannedArticles.Select(p => (p.Slug, p.TitleEn)), "title", Severity.Error)) yield return f;
        foreach (var f in CheckSimilarTitles(taxonomy.PlannedArticles.Select(p => (p.Slug, p.Misconception)), "misconception", Severity.Warning)) yield return f;
    }

    /// <summary>Keyword similarity (Jaccard over meaningful words) between every pair.</summary>
    private static IEnumerable<Finding> CheckSimilarTitles(IEnumerable<(string Slug, string Text)> items, string what, Severity severity)
    {
        var words = items.Select(i => (i.Slug, i.Text, Words: Keywords(i.Text))).Where(i => i.Words.Count > 0).ToList();
        for (var i = 0; i < words.Count; i++)
        {
            for (var j = i + 1; j < words.Count; j++)
            {
                var a = words[i].Words;
                var b = words[j].Words;
                var similarity = a.Intersect(b).Count() / (double)a.Union(b).Count();
                if (similarity >= SimilarityLimit)
                    yield return new(words[j].Slug, severity, "duplicates",
                        $"{what} overlaps '{words[i].Slug}' ({similarity:P0}): \"{words[j].Text}\" vs \"{words[i].Text}\".");
            }
        }
    }

    private static HashSet<string> Keywords(string text) =>
        [.. WordPattern().Matches(text.ToLowerInvariant()).Select(m => m.Value.Trim('.')).Where(w => w.Length > 0 && !StopWords.Contains(w))];

    /// <summary>Term ids from content/glossary/*.yaml (one file per field, so writers of different fields never collide).</summary>
    private async Task<IReadOnlySet<string>> LoadGlossaryAsync(List<Finding> findings, CancellationToken ct)
    {
        var folder = Path.Combine(content.Root, "glossary");
        var ids = new HashSet<string>();
        if (!Directory.Exists(folder)) return ids;

        var yaml = new DeserializerBuilder().WithNamingConvention(CamelCaseNamingConvention.Instance).IgnoreUnmatchedProperties().Build();
        foreach (var file in Directory.EnumerateFiles(folder, "*.yaml").Order(StringComparer.Ordinal))
        {
            var name = $"glossary/{Path.GetFileName(file)}";
            GlossaryFile parsed;
            try
            {
                parsed = yaml.Deserialize<GlossaryFile>(await File.ReadAllTextAsync(file, ct)) ?? new();
            }
            catch (YamlDotNet.Core.YamlException ex)
            {
                findings.Add(new(name, Severity.Error, "glossary", ex.Message));
                continue;
            }
            foreach (var term in parsed.Terms)
            {
                if (string.IsNullOrWhiteSpace(term.Id) || !SlugPattern().IsMatch(term.Id))
                    findings.Add(new(name, Severity.Error, "glossary", $"Term id '{term.Id}' must be kebab-case."));
                else if (!ids.Add(term.Id))
                    findings.Add(new(name, Severity.Error, "glossary", $"Term '{term.Id}' is defined more than once."));
                if (string.IsNullOrWhiteSpace(term.Term) || string.IsNullOrWhiteSpace(term.DefinitionEn) || string.IsNullOrWhiteSpace(term.DefinitionAr))
                    findings.Add(new(name, Severity.Error, "glossary", $"Term '{term.Id}' needs term, definitionEn and definitionAr."));
            }
        }
        return ids;
    }

    private sealed class GlossaryFile
    {
        public List<GlossaryTerm> Terms { get; set; } = [];
    }

    private sealed class GlossaryTerm
    {
        public string Id { get; set; } = default!;
        public string? Term { get; set; }
        public string? DefinitionEn { get; set; }
        public string? DefinitionAr { get; set; }
    }

    [GeneratedRegex(@"^[a-z0-9]+(-[a-z0-9]+)*$")]
    private static partial Regex SlugPattern();

    [GeneratedRegex(@"[a-z0-9#+.]+")]
    private static partial Regex WordPattern();
}
