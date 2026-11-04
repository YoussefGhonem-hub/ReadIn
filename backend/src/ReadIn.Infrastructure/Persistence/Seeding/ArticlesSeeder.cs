using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #6 (all environments, Production included): imports git-versioned articles (SPEC §19.2 step 6) under the
/// official "ReadIn" account. Status-aware: <c>approved</c>/<c>published</c> → published with the AI-assisted label;
/// <c>auto-checked</c> → kept as a draft of the official account; <c>generated</c>/<c>failed</c> → skipped.
/// <list type="bullet">
/// <item>Upsert by slug, and versioned per article: a <see cref="SeedHistory"/> row (<c>article:{slug}</c>) holds the
/// checksum of its files, so only changed articles are re-imported.</item>
/// <item><c>cover.webp</c> goes through the image pipeline (400/800/1200 + BlurHash, ADR 0011).</item>
/// <item>New articles get staggered publish dates over the last ~120 days (plan order, interleaved across learning
/// paths), so the feed isn't 300 articles published in the same second.</item>
/// <item><c>reviewStatus</c> and <c>reviewer</c> in meta.json are ignored: there is no review (ADR 0015).</item>
/// <item>An article of the official account whose folder was removed is archived.</item>
/// </list>
/// </summary>
internal sealed partial class ArticlesSeeder(
    AppDbContext db,
    ContentRepository content,
    IRDocProcessor rdoc,
    IImageProcessor images,
    IFileStorage storage,
    UploadCleanup uploads,
    TimeProvider clock,
    ILogger<ArticlesSeeder> logger) : ISeeder
{
    private const int StaggerDays = 120;
    private const int CoverWidth = 1200;

    public string Name => "articles";
    public int Order => 6;
    public int Version => 2;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        Task.FromResult(SeedChecksum.Of([.. content.ArticleFolders().Select(FolderChecksum), Version.ToString()]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var fields = await db.Fields.Include(f => f.Topics).ToDictionaryAsync(f => f.Slug, cancellationToken);
        var schedule = await PublishScheduleAsync(cancellationToken);
        var history = await db.SeedHistory.Where(h => h.Name.StartsWith(HistoryPrefix))
            .ToDictionaryAsync(h => h.Name, cancellationToken);
        var complete = true;
        var slugs = new HashSet<string>();

        foreach (var folder in content.ArticleFolders())
        {
            var meta = await content.ReadMetaAsync(folder, cancellationToken);
            slugs.Add(meta.Slug);
            if (!meta.IsPublishable && !meta.IsReviewable) continue;

            var checksum = FolderChecksum(folder);
            var entry = history.GetValueOrDefault(HistoryPrefix + meta.Slug);
            if (entry is not null && entry.Version == Version && entry.Checksum == checksum) continue;

            var result = await ImportAsync(folder, meta, fields, schedule, cancellationToken);
            if (result.IsFailure)
            {
                LogImportFailed(logger, meta.Slug, result.Error.Code, FormatDetails(result.Error));
                db.ChangeTracker.Clear();
                complete = false;
                continue;
            }

            if (entry is null)
            {
                entry = new SeedHistory(HistoryPrefix + meta.Slug);
                db.SeedHistory.Add(entry);
                history[entry.Name] = entry;
            }
            entry.Record(Version, checksum, Now);
            await db.SaveChangesAsync(cancellationToken);
            if (result.Value is { } replacedCover) await uploads.ReleaseAsync(replacedCover, cancellationToken);
        }

        await ArchiveRemovedAsync(slugs, cancellationToken);
        return complete;
    }

    private const string HistoryPrefix = "article:";

    /// <returns>The previous cover path when the cover was replaced (released after saving), else null.</returns>
    private async Task<Result<string?>> ImportAsync(
        string folder, ArticleMeta meta, Dictionary<string, Field> fields, IReadOnlyDictionary<string, DateTime> schedule, CancellationToken ct)
    {
        if (!fields.TryGetValue(meta.Field, out var field))
            return Error.Validation("seed.field_not_found", $"Unknown field '{meta.Field}'.");
        var topic = meta.Topic is null ? null : field.Topics.FirstOrDefault(t => t.Slug == meta.Topic);

        var article = await db.Articles
            .Include(a => a.Translations)
            .Include(a => a.Sources)
            .Include(a => a.Tags)
            .FirstOrDefaultAsync(a => a.Slug == meta.Slug, ct);
        if (article is null)
        {
            article = Article.CreateDraft(SystemUsers.EditorialId, field.Id, topic?.Id, meta.Slug);
            db.Articles.Add(article);
        }

        // Source language first so it becomes the source translation.
        var languages = ArticleLanguages.All.OrderByDescending(l => l == meta.SourceLanguage);
        foreach (var language in languages)
        {
            using var document = await content.ReadRDocAsync(folder, language, ct);
            if (document is null) continue;
            if (!meta.Translations.TryGetValue(language, out var titles))
                return Error.Validation("seed.title_missing", $"meta.json has no title for '{language}'.");

            var processed = rdoc.Process(document.RootElement, language, titles.Title);
            if (processed.IsFailure) return processed.Error;

            var existing = article.Translations.FirstOrDefault(t => t.Language == language);
            var applied = existing is null
                ? article.AddTranslation(language, titles.Title, titles.Subtitle, processed.Value.Content)
                : existing.ContentJson == processed.Value.Content.Json && existing.Title == titles.Title && existing.Subtitle == titles.Subtitle
                    ? Result.Success()
                    : article.UpdateTranslation(language, titles.Title, titles.Subtitle, processed.Value.Content, Now);
            if (applied.IsFailure) return applied.Error;
        }

        var cover = await ImportCoverAsync(folder, article.CoverUrl, ct);
        if (cover.IsFailure) return cover.Error;
        var previousCover = article.CoverUrl;
        article.SetMetadata(cover.Value ?? previousCover, meta.VersionBadge, meta.IsAiAssisted);
        article.SetSources(meta.Sources.Select(s => (s.Title, s.Url)));
        var tagged = article.SetTags(await UpsertTagsAsync(meta.Tags, ct));
        if (tagged.IsFailure) return tagged.Error;

        if (meta.IsPublishable && !article.IsPublished)
        {
            // Staggered dates are in the past; a date in the future publishes now (there is no scheduling, ADR 0015).
            var publishAt = meta.PublishAt ?? meta.ReviewedAt ?? schedule.GetValueOrDefault(meta.Slug, Now);
            var published = article.Publish(field, publishAt < Now ? publishAt : Now);
            if (published.IsFailure) return published.Error;
        }

        // Pipeline content passed every automatic check before it could be committed (CI runs `validate --all`).
        if (meta.LastReviewedAt is { } checkedAt) article.MarkAutoChecked(checkedAt);

        return cover.Value is not null && previousCover != cover.Value ? previousCover : null;
    }

    /// <returns>The new cover path, or null when there is no cover or it is unchanged.</returns>
    private async Task<Result<string?>> ImportCoverAsync(string folder, string? current, CancellationToken ct)
    {
        var path = Path.Combine(folder, "cover.webp");
        if (!File.Exists(path)) return (string?)null;

        var bytes = await File.ReadAllBytesAsync(path, ct);
        if (SeedImages.IsStored(current, bytes)) return (string?)null;

        var asset = await SeedImages.ImportAsync(images, storage, db, SystemUsers.EditorialId, UploadPurpose.Cover, bytes, Now, ct);
        return asset.IsFailure ? asset.Error : SeedImages.Pick(asset.Value, CoverWidth);
    }

    /// <summary>
    /// First-publish dates for planned articles: the plan is interleaved across learning paths (every path's 1st
    /// article, then every 2nd…), spread evenly over the last <see cref="StaggerDays"/> days, oldest first, with a
    /// stable per-slug time of day. Only used the first time an article is published in an environment.
    /// </summary>
    private async Task<IReadOnlyDictionary<string, DateTime>> PublishScheduleAsync(CancellationToken ct)
    {
        var plan = (await content.ReadTaxonomyAsync(ct)).PlannedArticles;
        var ordered = plan
            .GroupBy(p => p.LearningPath)
            .SelectMany(path => path.OrderBy(p => p.Order).Select((p, i) => (p.Slug, Round: i, Path: path.Key)))
            .OrderBy(x => x.Round).ThenBy(x => x.Path, StringComparer.Ordinal)
            .Select(x => x.Slug)
            .ToList();

        var start = Now.Date.AddDays(-StaggerDays);
        var schedule = new Dictionary<string, DateTime>();
        for (var i = 0; i < ordered.Count; i++)
        {
            var day = ordered.Count == 1 ? 0 : (int)Math.Round(i * (StaggerDays - 1) / (double)(ordered.Count - 1));
            var minutes = BitConverter.ToUInt16(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(ordered[i])), 0) % (14 * 60);
            schedule[ordered[i]] = start.AddDays(day).AddHours(7).AddMinutes(minutes); // 07:00–21:00 UTC
        }
        return schedule;
    }

    /// <summary>Articles of the official account whose content folder was removed are archived, never deleted.</summary>
    private async Task ArchiveRemovedAsync(HashSet<string> slugs, CancellationToken ct)
    {
        var removed = await db.Articles
            .Where(a => a.AuthorId == SystemUsers.EditorialId && a.Status != ArticleStatus.Archived && !slugs.Contains(a.Slug))
            .ToListAsync(ct);
        foreach (var article in removed)
        {
            article.Archive();
            LogArchived(logger, article.Slug);
        }
        if (removed.Count > 0) await db.SaveChangesAsync(ct);
    }

    private async Task<List<Guid>> UpsertTagsAsync(IEnumerable<string> names, CancellationToken ct)
    {
        var ids = new List<Guid>();
        foreach (var name in names.Distinct())
        {
            var slug = Tag.ToSlug(name);
            var tag = db.Tags.Local.FirstOrDefault(t => t.Slug == slug)
                ?? await db.Tags.FirstOrDefaultAsync(t => t.Slug == slug, ct);
            if (tag is null)
            {
                tag = new Tag(slug, name);
                db.Tags.Add(tag);
            }
            ids.Add(tag.Id);
        }
        return ids;
    }

    /// <summary>Checksum of an article folder's committed files (drafts and other files don't count).</summary>
    private string FolderChecksum(string folder) =>
        SeedChecksum.Of([.. new[] { "meta.json", "en.json", "ar-EG.json", "cover.webp" }
            .Select(name => Path.Combine(folder, name))
            .Where(File.Exists)
            .Select(path => $"{Path.GetRelativePath(content.Root, path)}:{Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(path)))}")]);

    private DateTime Now => clock.GetUtcNow().UtcDateTime;

    private static string FormatDetails(Error error) =>
        error.Details is null ? error.Description : string.Join("; ", error.Details.Select(d => $"{d.Key}: {string.Join(", ", d.Value)}"));

    [LoggerMessage(Level = LogLevel.Error, Message = "Article '{Slug}' was not imported: {Code} — {Details}")]
    private static partial void LogImportFailed(ILogger logger, string slug, string code, string details);


    [LoggerMessage(Level = LogLevel.Information, Message = "Article '{Slug}' has no content folder any more; archived")]
    private static partial void LogArchived(ILogger logger, string slug);
}
