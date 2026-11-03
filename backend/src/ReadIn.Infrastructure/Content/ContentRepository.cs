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
    public List<PlannedArticleEntry> PlannedArticles { get; set; } = [];
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
    public string Topic { get; set; } = default!;
    public string Level { get; set; } = "beginner";
    public string? Version { get; set; }
    public PathRef? Path { get; set; }
    public List<string> Sources { get; set; } = [];
}

public sealed class PathRef
{
    public string Slug { get; set; } = default!;
    public int Order { get; set; }
}

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

    public bool IsPublishable => Status is "approved" or "published";
    public bool IsReviewable => Status is "auto-checked";
}

public sealed record TranslationMeta(string Title, string? Subtitle);

public sealed record SourceEntry(string Title, string Url);
