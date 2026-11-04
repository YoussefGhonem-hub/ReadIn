using System.Text.Json;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace ReadIn.Infrastructure.Content;

public sealed class ContentOptions
{
    public const string Section = "Content";

    /// <summary>Path to the repo's <c>content/</c> folder. Empty = search upwards from the app's content root.</summary>
    public string? RootPath { get; set; }
}

/// <summary>Reads git-versioned content (SPEC §5, §19.5): taxonomy.yaml and content/articles/**.</summary>
public sealed class ContentRepository(IOptions<ContentOptions> options, IHostEnvironment environment)
{
    private static readonly IDeserializer Yaml = new DeserializerBuilder()
        .WithNamingConvention(CamelCaseNamingConvention.Instance)
        .IgnoreUnmatchedProperties()
        .Build();

    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    private readonly Lazy<string> _root = new(() => ResolveRoot(options.Value.RootPath, environment.ContentRootPath));

    public string Root => _root.Value;

    public string TaxonomyPath => Path.Combine(Root, "taxonomy.yaml");

    public async Task<TaxonomyFile> ReadTaxonomyAsync(CancellationToken ct) =>
        Yaml.Deserialize<TaxonomyFile>(await File.ReadAllTextAsync(TaxonomyPath, ct));

    /// <summary>All article folders: content/articles/{field}/{topic}/{slug}/ containing meta.json.</summary>
    public IEnumerable<string> ArticleFolders()
    {
        var articles = Path.Combine(Root, "articles");
        return Directory.Exists(articles)
            ? Directory.EnumerateFiles(articles, "meta.json", SearchOption.AllDirectories).Select(Path.GetDirectoryName).OfType<string>().Order()
            : [];
    }

    public async Task<ArticleMeta> ReadMetaAsync(string folder, CancellationToken ct)
    {
        await using var stream = File.OpenRead(Path.Combine(folder, "meta.json"));
        return await JsonSerializer.DeserializeAsync<ArticleMeta>(stream, Json, ct)
            ?? throw new InvalidDataException($"Empty meta.json in {folder}");
    }

    /// <summary>Raw RDoc for one language, or null when that version doesn't exist.</summary>
    public async Task<JsonDocument?> ReadRDocAsync(string folder, string language, CancellationToken ct)
    {
        var path = Path.Combine(folder, $"{language}.json");
        if (!File.Exists(path)) return null;
        await using var stream = File.OpenRead(path);
        return await JsonDocument.ParseAsync(stream, cancellationToken: ct);
    }

    /// <summary>content/glossary/*.yaml: one file per writing group, term ids unique across files (SPEC F21).</summary>
    public IEnumerable<string> GlossaryFiles()
    {
        var glossary = Path.Combine(Root, "glossary");
        return Directory.Exists(glossary) ? Directory.EnumerateFiles(glossary, "*.yaml").Order(StringComparer.Ordinal) : [];
    }

    public async Task<GlossaryFile> ReadGlossaryAsync(string file, CancellationToken ct) =>
        Yaml.Deserialize<GlossaryFile>(await File.ReadAllTextAsync(file, ct)) ?? new GlossaryFile();

    public async Task<string> HashFilesAsync(IEnumerable<string> files, CancellationToken ct)
    {
        var parts = new List<string>();
        foreach (var file in files.Order(StringComparer.Ordinal))
            parts.Add($"{Path.GetRelativePath(Root, file)}:{await File.ReadAllTextAsync(file, ct)}");
        return Persistence.Seeding.SeedChecksum.Of([.. parts]);
    }

    private static string ResolveRoot(string? configured, string contentRoot)
    {
        if (!string.IsNullOrWhiteSpace(configured))
        {
            var full = Path.GetFullPath(configured, contentRoot);
            return File.Exists(Path.Combine(full, "taxonomy.yaml"))
                ? full
                : throw new DirectoryNotFoundException($"Content:RootPath '{full}' has no taxonomy.yaml.");
        }

        for (var dir = new DirectoryInfo(contentRoot); dir is not null; dir = dir.Parent)
        {
            var candidate = Path.Combine(dir.FullName, "content");
            if (File.Exists(Path.Combine(candidate, "taxonomy.yaml"))) return candidate;
        }
        throw new DirectoryNotFoundException("Could not find the content/ folder. Set Content:RootPath.");
    }
}

public sealed class TaxonomyFile
{
    public int Version { get; set; }
    public List<FieldEntry> Fields { get; set; } = [];
    public List<LearningPathEntry> LearningPaths { get; set; } = [];

    /// <summary>The editorial plan (SPEC §19.1): every article the content pipeline writes, across all fields.</summary>
    public List<PlannedArticleEntry> PlannedArticles { get; set; } = [];
}

/// <summary>A curated, ordered series of articles (F09). Its articles name it in the plan and in meta.json.</summary>
public sealed class LearningPathEntry
{
    public string Slug { get; set; } = default!;
    public string Field { get; set; } = default!;
    public string TitleAr { get; set; } = default!;
    public string TitleEn { get; set; } = default!;
    public string? DescriptionAr { get; set; }
    public string? DescriptionEn { get; set; }
}

public sealed class FieldEntry
{
    public string Slug { get; set; } = default!;
    public string NameAr { get; set; } = default!;
    public string NameEn { get; set; } = default!;
    public string Icon { get; set; } = "book-open";
    public string Color { get; set; } = "primary";
    public bool Sensitive { get; set; }
    public bool RequiresSources { get; set; } = true;
    public bool Enabled { get; set; } = true;
    public int Target { get; set; }
    public List<TopicEntry> Topics { get; set; } = [];
}

public sealed class TopicEntry
{
    public string Slug { get; set; } = default!;
    public string NameAr { get; set; } = default!;
    public string NameEn { get; set; } = default!;
}

public sealed class PlannedArticleEntry
{
    public string Slug { get; set; } = default!;
    public string Field { get; set; } = default!;
    public string Topic { get; set; } = default!;
    public string TitleEn { get; set; } = default!;
    public string TitleAr { get; set; } = default!;

    /// <summary>The wrong belief the article corrects, in one line.</summary>
    public string Misconception { get; set; } = default!;

    public string Level { get; set; } = "beginner";
    public string LearningPath { get; set; } = default!;
    public int Order { get; set; }
    public string? VersionBadge { get; set; }
    public List<string> PlannedSources { get; set; } = [];
}

public sealed record PathRef(string Slug, int Order);

public sealed record ArticleMeta
{
    public string Slug { get; init; } = default!;
    public string Field { get; init; } = default!;
    public string? Topic { get; init; }

    /// <summary>generated | auto-checked | failed | approved | published (SPEC §19.2).</summary>
    public string Status { get; init; } = "generated";

    public string SourceLanguage { get; init; } = "en";

    /// <summary>Title/subtitle per language version; the RDoc files hold only the body (H1 is not a block).</summary>
    public Dictionary<string, TranslationMeta> Translations { get; init; } = [];

    public string? VersionBadge { get; init; }
    public bool IsAiAssisted { get; init; } = true;
    public string Level { get; init; } = "beginner";
    public List<string> Tags { get; init; } = [];
    public List<SourceEntry> Sources { get; init; } = [];
    public string? Reviewer { get; init; }
    public DateTime? ReviewedAt { get; init; }
    public DateTime? PublishAt { get; init; }

    /// <summary><c>pending</c> = published and waiting for a human reviewer; a "Reviewed by" badge is never faked.</summary>
    public string? ReviewStatus { get; init; }

    public PathRef? LearningPath { get; init; }

    /// <summary>When the content was generated or last re-verified by the pipeline (shown as "Last reviewed").</summary>
    public DateTime? LastReviewedAt { get; init; }

    public CodeMeta? Code { get; init; }

    public bool IsPublishable => Status is "approved" or "published";
    public bool IsReviewable => Status is "auto-checked";
}

public sealed record TranslationMeta(string Title, string? Subtitle);

/// <summary>
/// Compile-check settings (SPEC §19.3): hidden <c>stubs</c> per language that snippets compile against (e.g. a
/// <c>record Order</c> the article doesn't show), and <c>skip</c> reasons keyed by block id (<c>b7</c>) or tab
/// (<c>b7/1</c>) for snippets marked <c>"compile": false</c>.
/// </summary>
public sealed record CodeMeta
{
    public Dictionary<string, string> Stubs { get; init; } = [];
    public Dictionary<string, string> Skip { get; init; } = [];
}

public sealed record SourceEntry(string Title, string Url);

/// <summary>A content/glossary/*.yaml file: <c>terms: [{ id, term, definitionEn, definitionAr }]</c>.</summary>
public sealed class GlossaryFile
{
    public List<GlossaryEntry> Terms { get; set; } = [];
}

public sealed class GlossaryEntry
{
    public string Id { get; set; } = default!;
    public string Term { get; set; } = default!;
    public string DefinitionEn { get; set; } = default!;
    public string DefinitionAr { get; set; } = default!;
}
