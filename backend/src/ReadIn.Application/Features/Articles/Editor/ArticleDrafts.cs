using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Tags;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>What <see cref="ArticleDrafts.EvaluateAsync"/> found: the live checks and what publishing needs.</summary>
internal sealed record DraftEvaluation(
    IReadOnlyList<DraftProblemDto> Problems,
    IReadOnlyList<DraftReadingTimeDto> ReadingTime,
    Field? Field,
    IReadOnlyDictionary<Guid, MediaAsset> Assets);

/// <summary>
/// The editor's working copy (F05, ADR 0015): turning client documents into their stored form and back, building the
/// document of an article that has no working copy yet, and the live checks that decide whether it can be published.
/// Saving is lenient (an unfinished article is fine); publishing requires an empty problem list.
/// </summary>
internal sealed class ArticleDrafts(
    IAppDbContext db, IRDocProcessor rdoc, IFileStorage storage, Mapster.TypeAdapterConfig mapping, ArticleTagging tagging)
{
    public const int MinTitleLength = 5;

    /// <summary>RDoc blocks that count as content even without words.</summary>
    private static readonly HashSet<string> NonTextBlocks = ["code", "codeTabs", "image", "table", "embed"];

    /// <summary>A client document in stored form: trimmed text, upload URLs as relative paths (ADR 0010), source first.</summary>
    public ArticleDraftDocument ToStored(ArticleDraftDocument document) => document with
    {
        Translations = [.. document.Translations
            .OrderByDescending(t => t.Language == document.SourceLanguage)
            .Select(t => new DraftTranslation(t.Language, t.Title.Trim(), Blank(t.Subtitle), storage.ToStoredContent(t.Content)))],
        // Cleaned, with a repeat of the same tag dropped (SPEC F32); tags are created only when the article goes live.
        Tags = TagNames.Distinct(document.Tags ?? []),
        Sources = [.. document.Sources.Select(s => new SourceDto(s.Title.Trim(), s.Url.Trim()))],
        CoverUrl = storage.ToStoredValue(Blank(document.CoverUrl)),
        VersionBadge = Blank(document.VersionBadge),
        Attachments = [.. document.Attachments
            .OrderBy(a => a.Order)
            .Select((a, i) => a with { Order = i, Caption = Blank(a.Caption), AltText = Blank(a.AltText), Title = Blank(a.Title) })],
    };

    /// <summary>A stored document as clients get it: public URLs for the cover and the images in the content.</summary>
    public ArticleDraftDocument ToPublic(ArticleDraftDocument document) => document with
    {
        Translations = [.. document.Translations.Select(t => t with { Content = storage.ToPublicContent(t.Content.GetRawText()) })],
        CoverUrl = storage.ToPublicUrl(document.CoverUrl),
    };

    /// <summary>
    /// The document readers see now. Needs the article with its translations, tags (with the tag), sources and attachments
    /// (with the asset) loaded.
    /// </summary>
    public static ArticleDraftDocument FromLive(Article article) => new()
    {
        SourceLanguage = article.SourceLanguage ?? ArticleLanguages.EgyptianArabic,
        Translations = [.. article.Translations
            .OrderByDescending(t => t.IsSource)
            .Select(t => new DraftTranslation(t.Language, t.Title, t.Subtitle, JsonDocument.Parse(t.ContentJson).RootElement.Clone()))],
        FieldId = article.FieldId,
        TopicId = article.TopicId,
        Tags = [.. article.Tags.OrderBy(t => t.Position).ThenBy(t => t.TagId).Select(t => t.Tag.Name)], // hidden ones too (F32)
        Sources = [.. article.Sources.OrderBy(s => s.SortOrder).Select(s => new SourceDto(s.Title, s.Url))],
        CoverUrl = article.CoverUrl,
        VersionBadge = article.VersionBadge,
        IsAiAssisted = article.IsAiAssisted,
        Attachments = [.. article.Attachments.OrderBy(a => a.Order).Select(a => a.MediaAsset.Kind == MediaKind.Document
            ? new DraftAttachment(a.MediaAssetId, a.Order, null, null, a.MediaAsset.Title, a.MediaAsset.AllowDownload)
            : new DraftAttachment(a.MediaAssetId, a.Order, a.Caption, a.AltText, null, null))],
    };

    /// <summary>
    /// The working copy the editor shows: its draft, or, for a published article without unpublished changes (or an
    /// article created before the editor), what readers see.
    /// </summary>
    public static ArticleDraftDocument Current(Article article) =>
        article.Draft is { } draft && (draft.HasChanges || !article.IsPublished)
            ? ArticleDraftJson.Deserialize(draft.DocumentJson)
            : FromLive(article);

    /// <summary>Loads an article with everything <see cref="FromLive"/> and the editor need; null when missing.</summary>
    public Task<Article?> LoadAsync(Guid articleId, CancellationToken cancellationToken) => db.Articles
        .Include(a => a.Draft)
        .Include(a => a.Translations)
        .Include(a => a.Tags).ThenInclude(t => t.Tag)
        .Include(a => a.Sources)
        .Include(a => a.Attachments).ThenInclude(a => a.MediaAsset)
        .FirstOrDefaultAsync(a => a.Id == articleId, cancellationToken);

    /// <summary>A field that may be chosen, and the topic belongs to it (null topic is fine).</summary>
    public async Task<Result> CheckTaxonomyAsync(ArticleDraftDocument document, CancellationToken cancellationToken)
    {
        if (document.FieldId is not { } fieldId)
            return document.TopicId is null ? Result.Success() : EditorErrors.TopicNotInField;
        if (!await db.Fields.AnyAsync(f => f.Id == fieldId && f.IsEnabled, cancellationToken)) return EditorErrors.FieldNotFound;
        if (document.TopicId is { } topicId && !await db.Topics.AnyAsync(t => t.Id == topicId && t.FieldId == fieldId, cancellationToken))
            return EditorErrors.TopicNotInField;
        return Result.Success();
    }

    /// <summary>The live checks (SPEC F05) of a stored document owned by <paramref name="authorId"/>.</summary>
    public async Task<DraftEvaluation> EvaluateAsync(Guid articleId, Guid authorId, ArticleDraftDocument document, CancellationToken cancellationToken)
    {
        var problems = new List<DraftProblemDto>();
        var readingTime = new List<DraftReadingTimeDto>();

        var field = document.FieldId is { } fieldId
            ? await db.Fields.AsNoTracking().FirstOrDefaultAsync(f => f.Id == fieldId && f.IsEnabled, cancellationToken)
            : null;
        if (field is null) problems.Add(new DraftProblemDto(EditorErrors.Codes.FieldRequired));

        foreach (var translation in document.Translations)
        {
            var language = translation.Language;
            if (translation.Title.Length < MinTitleLength) problems.Add(new DraftProblemDto(EditorErrors.Codes.TitleLength, language));

            var missingAlt = ImageBlocksWithoutAlt(translation.Content);
            problems.AddRange(missingAlt.Select(id => new DraftProblemDto(EditorErrors.Codes.ImageAltRequired, language, id)));

            // Images without alt text are already reported; check everything else as if they had it.
            var processed = rdoc.Process(missingAlt.Count == 0 ? translation.Content : WithPlaceholderAlt(translation.Content), language, translation.Title);
            if (processed.IsFailure)
            {
                problems.Add(new DraftProblemDto(EditorErrors.Codes.ContentInvalid, language, FailingBlockId(translation.Content, language)));
                readingTime.Add(new DraftReadingTimeDto(language, 0, 0));
                continue;
            }

            var content = processed.Value.Content;
            readingTime.Add(new DraftReadingTimeDto(language, content.ReadingTimeMinutes, content.WordCount));
            // A post may be only its attachments (F26): text is required only without them.
            if (document.Attachments.Count == 0 && IsEmpty(translation.Content, content))
                problems.Add(new DraftProblemDto(EditorErrors.Codes.ContentEmpty, language));
        }

        if (field?.RequiresSources == true && document.Sources.Count == 0)
            problems.Add(new DraftProblemDto(ArticleErrors.SourcesRequired.Code));

        var assets = await CheckAttachmentsAsync(articleId, authorId, document.Attachments, problems, cancellationToken);
        problems.AddRange(await tagging.CheckAsync(articleId, authorId, document.Tags, cancellationToken));
        return new DraftEvaluation(problems, readingTime, field, assets);
    }

    public ArticleEditDto ToEditDto(Article article, ArticleDraftDocument document, DraftEvaluation evaluation) => new(
        article.Id,
        StatusName(article),
        article.PublishedAt is null ? null : article.Slug,
        article.PublishedAt,
        article.CurrentDraftVersion,
        article.Draft?.SavedAt ?? article.UpdatedAt ?? article.CreatedAt,
        article.IsPublished && article.Draft?.HasChanges == true,
        article.WriterCategoryId,
        ToPublic(document),
        [.. document.Attachments
            .Where(a => evaluation.Assets.ContainsKey(a.MediaAssetId))
            .Select(a => evaluation.Assets[a.MediaAssetId].ToDto(mapping, storage))],
        new DraftChecksDto(evaluation.ReadingTime, evaluation.Problems));

    /// <summary>"draft" until the first publish, then "published" (F05 has no other states).</summary>
    public static string StatusName(Article article) => article.PublishedAt is null ? "draft" : "published";

    /// <summary>
    /// Checks the attachments against their assets: ready, alt text or document title present, one kind, one PDF, not
    /// shown in another article. Missing assets count as not ready.
    /// </summary>
    private async Task<IReadOnlyDictionary<Guid, MediaAsset>> CheckAttachmentsAsync(
        Guid articleId, Guid authorId, IReadOnlyList<DraftAttachment> attachments, List<DraftProblemDto> problems, CancellationToken cancellationToken)
    {
        if (attachments.Count == 0) return new Dictionary<Guid, MediaAsset>();

        var ids = attachments.Select(a => a.MediaAssetId).Distinct().ToList();
        var assets = await db.MediaAssets.AsNoTracking().Include(m => m.Pages)
            .Where(m => ids.Contains(m.Id) && m.OwnerId == authorId)
            .ToDictionaryAsync(m => m.Id, cancellationToken);

        foreach (var attachment in attachments)
        {
            if (!assets.TryGetValue(attachment.MediaAssetId, out var asset) || asset.Status != MediaStatus.Ready)
                problems.Add(new DraftProblemDto(AttachmentErrors.AssetNotReady.Code, MediaAssetId: attachment.MediaAssetId));
            else if (asset.Kind == MediaKind.Image && string.IsNullOrWhiteSpace(attachment.AltText))
                problems.Add(new DraftProblemDto(AttachmentErrors.AltTextRequired.Code, MediaAssetId: attachment.MediaAssetId));
            else if (asset.Kind == MediaKind.Document && string.IsNullOrWhiteSpace(attachment.Title ?? asset.Title))
                problems.Add(new DraftProblemDto(AttachmentErrors.TitleRequired.Code, MediaAssetId: attachment.MediaAssetId));
        }

        var kinds = assets.Values.Select(a => a.Kind).Distinct().ToList();
        if (kinds.Count > 1) problems.Add(new DraftProblemDto(AttachmentErrors.MixedKinds.Code));
        else if (assets.Values.Count(a => a.Kind == MediaKind.Document) > 1) problems.Add(new DraftProblemDto(AttachmentErrors.SingleDocument.Code));

        // An asset shows in one post only (ADR 0011).
        var elsewhere = await db.ArticleAttachments
            .Where(a => ids.Contains(a.MediaAssetId) && a.ArticleId != articleId)
            .Select(a => a.MediaAssetId)
            .ToListAsync(cancellationToken);
        problems.AddRange(elsewhere.Distinct().Select(id => new DraftProblemDto(MediaErrors.InUse.Code, MediaAssetId: id)));

        return assets;
    }

    /// <summary>The attachments' assets as clients get them (a revision preview needs their variants and pages).</summary>
    public async Task<IReadOnlyList<MediaAssetDto>> MediaAsync(Guid authorId, IReadOnlyList<DraftAttachment> attachments, CancellationToken cancellationToken)
    {
        var ids = attachments.Select(a => a.MediaAssetId).Distinct().ToList();
        if (ids.Count == 0) return [];

        var assets = await db.MediaAssets.AsNoTracking().Include(m => m.Pages)
            .Where(m => ids.Contains(m.Id) && m.OwnerId == authorId)
            .ToDictionaryAsync(m => m.Id, cancellationToken);
        return [.. ids.Where(assets.ContainsKey).Select(id => assets[id].ToDto(mapping, storage))];
    }

    /// <summary>
    /// The id of the first block the RDoc schema rejects on its own, or null when the problem is the document itself. Schema
    /// errors can't say which block failed (alternatives of a valid block fail too), so each block is checked alone; this
    /// only runs for a draft that is already invalid.
    /// </summary>
    private string? FailingBlockId(JsonElement content, string language)
    {
        if (!content.TryGetProperty("blocks", out var blocks) || blocks.ValueKind != JsonValueKind.Array) return null;

        foreach (var block in blocks.EnumerateArray())
        {
            var single = JsonSerializer.SerializeToElement(new { version = 1, language, blocks = new[] { block } });
            if (rdoc.Process(single, language).IsSuccess) continue;
            return block.ValueKind == JsonValueKind.Object && block.TryGetProperty("id", out var id) && id.ValueKind == JsonValueKind.String
                ? id.GetString()
                : null;
        }
        return null;
    }

    private static List<string> ImageBlocksWithoutAlt(JsonElement content)
    {
        var ids = new List<string>();
        if (content.ValueKind != JsonValueKind.Object || !content.TryGetProperty("blocks", out var blocks) || blocks.ValueKind != JsonValueKind.Array)
            return ids;

        foreach (var block in blocks.EnumerateArray())
        {
            if (block.ValueKind != JsonValueKind.Object || !block.TryGetProperty("type", out var type) || type.GetString() != "image") continue;
            var hasAlt = block.TryGetProperty("alt", out var alt) && alt.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(alt.GetString());
            if (!hasAlt) ids.Add(block.TryGetProperty("id", out var id) && id.ValueKind == JsonValueKind.String ? id.GetString()! : string.Empty);
        }
        return ids;
    }

    private static JsonElement WithPlaceholderAlt(JsonElement content)
    {
        var node = JsonNode.Parse(content.GetRawText())!;
        foreach (var block in node["blocks"]!.AsArray().OfType<JsonObject>())
        {
            if (block["type"]?.GetValue<string>() == "image" && string.IsNullOrWhiteSpace(block["alt"]?.GetValue<string>()))
                block["alt"] = "-";
        }
        return JsonSerializer.SerializeToElement(node);
    }

    private static bool IsEmpty(JsonElement raw, ArticleContent processed)
    {
        if (processed.WordCount > 0) return false;
        return !raw.GetProperty("blocks").EnumerateArray()
            .Any(b => b.TryGetProperty("type", out var type) && NonTextBlocks.Contains(type.GetString() ?? string.Empty));
    }

    private static string? Blank(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
