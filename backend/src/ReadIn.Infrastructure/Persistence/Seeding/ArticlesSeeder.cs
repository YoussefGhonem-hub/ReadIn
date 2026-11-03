using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Content;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #6 (all environments): imports git-versioned articles (SPEC §19.2 step 6). Status-aware:
/// <c>approved</c>/<c>published</c> → published under "ReadIn Editorial" with the AI-assisted label;
/// <c>auto-checked</c> → submitted to the reviewer queue; <c>generated</c>/<c>failed</c> → skipped.
/// </summary>
internal sealed partial class ArticlesSeeder(
    AppDbContext db,
    ContentRepository content,
    IRDocProcessor rdoc,
    TimeProvider clock,
    ILogger<ArticlesSeeder> logger) : ISeeder
{
    public string Name => "articles";
    public int Order => 6;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        content.HashFilesAsync(
            content.ArticleFolders().SelectMany(folder => Directory.EnumerateFiles(folder, "*.json")),
            cancellationToken);

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var fields = await db.Fields.Include(f => f.Topics).ToDictionaryAsync(f => f.Slug, cancellationToken);
        var complete = true;

        foreach (var folder in content.ArticleFolders())
        {
            var meta = await content.ReadMetaAsync(folder, cancellationToken);
            if (!meta.IsPublishable && !meta.IsReviewable) continue;

            var result = await ImportAsync(folder, meta, fields, cancellationToken);
            if (result.IsFailure)
            {
                LogImportFailed(logger, meta.Slug, result.Error.Code, FormatDetails(result.Error));
                db.ChangeTracker.Clear();
                complete = false;
                continue;
            }

            await db.SaveChangesAsync(cancellationToken);
        }

        return complete;
    }

    private async Task<Result> ImportAsync(string folder, ArticleMeta meta, Dictionary<string, Field> fields, CancellationToken ct)
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
                    : article.UpdateTranslation(language, titles.Title, titles.Subtitle, processed.Value.Content, SystemUsers.EditorialId, Now);
            if (applied.IsFailure) return applied;
        }

        article.SetMetadata(coverUrl: null, meta.VersionBadge, meta.IsAiAssisted);
        article.SetSources(meta.Sources.Select(s => (s.Title, s.Url)));
        var tags = await UpsertTagsAsync(meta.Tags, ct);
        var tagged = article.SetTags(tags);
        if (tagged.IsFailure) return tagged;

        return meta.IsPublishable ? await PublishAsync(article, field, meta, ct) : SubmitForReview(article);
    }

    private async Task<Result> PublishAsync(Article article, Field field, ArticleMeta meta, CancellationToken ct)
    {
        if (meta.Reviewer is not null && !article.IsReviewed)
        {
            var reviewerId = await db.Users.Where(u => u.Email == meta.Reviewer).Select(u => (Guid?)u.Id).FirstOrDefaultAsync(ct);
            if (reviewerId is { } id)
                article.MarkReviewed(id, meta.ReviewedAt ?? Now);
            else
                LogReviewerMissing(logger, meta.Slug, meta.Reviewer); // Never fake a "Reviewed by" badge.
        }

        if (article.IsPublished) return Result.Success();

        var publishAt = meta.PublishAt ?? meta.ReviewedAt ?? Now;
        return publishAt > Now ? article.Schedule(field, publishAt, Now) : article.Publish(field, publishAt);
    }

    private static Result SubmitForReview(Article article) =>
        article.Status is ArticleStatus.Draft or ArticleStatus.ChangesRequested ? article.SubmitForReview() : Result.Success();

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

    private DateTime Now => clock.GetUtcNow().UtcDateTime;

    private static string FormatDetails(Error error) =>
        error.Details is null ? error.Description : string.Join("; ", error.Details.Select(d => $"{d.Key}: {string.Join(", ", d.Value)}"));

    [LoggerMessage(Level = LogLevel.Error, Message = "Article '{Slug}' was not imported: {Code} — {Details}")]
    private static partial void LogImportFailed(ILogger logger, string slug, string code, string details);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Article '{Slug}': reviewer {Reviewer} does not exist here; imported without the Reviewed badge")]
    private static partial void LogReviewerMissing(ILogger logger, string slug, string reviewer);
}
