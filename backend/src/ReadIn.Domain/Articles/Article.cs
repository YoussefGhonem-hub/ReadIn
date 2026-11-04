using ReadIn.Domain.Common;
using ReadIn.Domain.Media;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Domain.Articles;

/// <summary>Draft → Published → Archived (SPEC F06); stored by name.</summary>
public enum ArticleStatus
{
    Draft,
    Published,
    Archived,
}

/// <summary>
/// Article aggregate (SPEC §6.6, F06). Anyone may publish in any field; there is no review (ADR 0015). The editor (F05)
/// works on a private <see cref="ArticleDraft"/>: readers only ever see the published translations, which a publish
/// replaces with the working copy.
/// </summary>
public sealed class Article : AggregateRoot, IAuditable, ISoftDeletable, IHasRowVersion
{
    public const int MaxTags = 5;
    public const int MaxImageAttachments = 10;
    public const int MaxCaptionLength = 5000;
    public const int MaxAltTextLength = 5000;

    private readonly List<ArticleTranslation> _translations = [];
    private readonly List<ArticleTag> _tags = [];
    private readonly List<ArticleSource> _sources = [];
    private readonly List<ArticleAttachment> _attachments = [];

    private Article() { } // EF

    /// <summary>Null once the author deleted their account: published articles stay, shown as by a deleted user (SPEC §9.6).</summary>
    public Guid? AuthorId { get; private set; }
    public Guid FieldId { get; private set; }
    public Guid? TopicId { get; private set; }
    public string Slug { get; private set; } = default!;
    public ArticleStatus Status { get; private set; }
    public string SourceLanguage { get; private set; } = default!;
    public string? CoverUrl { get; private set; }
    public bool IsAiAssisted { get; private set; }
    public string? VersionBadge { get; private set; }

    /// <summary>When the content pipeline last validated this article (SPEC §19.3).</summary>
    public DateTime? AutoCheckedAt { get; private set; }
    public DateTime? PublishedAt { get; private set; }

    /// <summary>Ranks articles for Today's article (F07, ADR 0015); recomputed by the quality job.</summary>
    public double QualityScore { get; private set; }

    /// <summary>
    /// Hidden by a moderator (SPEC F22): gone from every list, feed and count; only its author and moderators still open
    /// it. No foreign key, like <c>Comments.HiddenById</c>.
    /// </summary>
    public DateTime? HiddenAt { get; private set; }
    public Guid? HiddenById { get; private set; }

    // Denormalized counters (SPEC §16.1), recomputed from SQL by the outbox handlers after each change (F27).

    /// <summary>All reactions: always the sum of the four per-type counts below.</summary>
    public int ReactionCount { get; private set; }
    public int InsightfulCount { get; private set; }
    public int LoveCount { get; private set; }
    public int FireCount { get; private set; }
    public int MindBlownCount { get; private set; }
    public int CommentCount { get; private set; }
    public int SaveCount { get; private set; }
    public int ReadCount { get; private set; }

    // Read-side navigations for query projections only; domain behavior never uses them.
    public Users.User? Author { get; private set; }
    public Field Field { get; private set; } = default!;
    public Topic? Topic { get; private set; }

    public IReadOnlyCollection<ArticleTranslation> Translations => _translations.AsReadOnly();
    public IReadOnlyCollection<ArticleTag> Tags => _tags.AsReadOnly();
    public IReadOnlyCollection<ArticleSource> Sources => _sources.AsReadOnly();
    public IReadOnlyCollection<ArticleAttachment> Attachments => _attachments.AsReadOnly();

    /// <summary>The editor's working copy (F05); null until the article is first edited in the editor.</summary>
    public ArticleDraft? Draft { get; private set; }

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }
    public bool IsDeleted { get; private set; }
    public DateTime? DeletedAt { get; private set; }
    public byte[] RowVersion { get; private set; } = [];

    public bool IsPublished => Status == ArticleStatus.Published;
    public bool IsHidden => HiddenAt is not null;

    /// <param name="sourceLanguage">Set by the first <see cref="AddTranslation"/>; the editor passes it for a draft that has none yet.</param>
    public static Article CreateDraft(Guid authorId, Guid fieldId, Guid? topicId, string slug, Guid? id = null, string? sourceLanguage = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(slug);
        return new Article
        {
            Id = id ?? Guid.Empty,
            SourceLanguage = sourceLanguage!,
            AuthorId = authorId,
            FieldId = fieldId,
            TopicId = topicId,
            Slug = slug,
            Status = ArticleStatus.Draft,
        };
    }

    public Result AddTranslation(string language, string title, string? subtitle, ArticleContent content)
    {
        if (!ArticleLanguages.IsValid(language)) return ArticleErrors.InvalidLanguage;
        if (_translations.Any(t => t.Language == language)) return ArticleErrors.TranslationExists;

        var isSource = _translations.Count == 0;
        if (isSource) SourceLanguage = language;
        _translations.Add(new ArticleTranslation(Id, language, title.Trim(), subtitle?.Trim(), content, isSource));
        return Result.Success();
    }

    public Result UpdateTranslation(string language, string title, string? subtitle, ArticleContent content, DateTime now)
    {
        var translation = _translations.FirstOrDefault(t => t.Language == language);
        if (translation is null) return ArticleErrors.TranslationNotFound;

        translation.Update(title.Trim(), subtitle?.Trim(), content, now);
        return Result.Success();
    }

    /// <summary>
    /// Makes the published translations exactly <paramref name="versions"/> (one per language, 1–2): existing languages
    /// are updated, new ones added and missing ones removed; <paramref name="sourceLanguage"/> becomes the source.
    /// </summary>
    public Result ReplaceTranslations(string sourceLanguage, IReadOnlyList<TranslationVersion> versions, DateTime now)
    {
        if (versions.Count == 0) return ArticleErrors.NoContent;
        if (versions.Any(v => !ArticleLanguages.IsValid(v.Language)) || !ArticleLanguages.IsValid(sourceLanguage))
            return ArticleErrors.InvalidLanguage;
        if (versions.Select(v => v.Language).Distinct().Count() != versions.Count) return ArticleErrors.TranslationExists;
        if (versions.All(v => v.Language != sourceLanguage)) return ArticleErrors.TranslationNotFound;

        _translations.RemoveAll(t => versions.All(v => v.Language != t.Language));
        foreach (var version in versions)
        {
            var existing = _translations.FirstOrDefault(t => t.Language == version.Language);
            if (existing is null)
                _translations.Add(new ArticleTranslation(Id, version.Language, version.Title.Trim(), version.Subtitle?.Trim(), version.Content, false));
            else
                existing.Update(version.Title.Trim(), version.Subtitle?.Trim(), version.Content, now);
        }

        SourceLanguage = sourceLanguage;
        foreach (var translation in _translations) translation.MarkSource(translation.Language == sourceLanguage);
        return Result.Success();
    }

    /// <summary>Moves the article to another field and topic; the caller checks that the topic belongs to the field.</summary>
    public void SetTaxonomy(Guid fieldId, Guid? topicId)
    {
        FieldId = fieldId;
        TopicId = topicId;
    }

    /// <summary>The reader URL is fixed at the first publish (F05); until then the slug is a private placeholder.</summary>
    public void AssignSlug(string slug)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(slug);
        if (PublishedAt is not null) throw new InvalidOperationException("A published article keeps its slug.");
        Slug = slug;
    }

    public void SetMetadata(string? coverUrl, string? versionBadge, bool isAiAssisted)
    {
        CoverUrl = coverUrl;
        VersionBadge = string.IsNullOrWhiteSpace(versionBadge) ? null : versionBadge.Trim();
        IsAiAssisted = isAiAssisted;
    }

    public Result SetTags(IReadOnlyCollection<Guid> tagIds)
    {
        var distinct = tagIds.Distinct().ToList();
        if (distinct.Count > MaxTags) return ArticleErrors.TooManyTags;

        _tags.RemoveAll(t => !distinct.Contains(t.TagId));
        foreach (var tagId in distinct.Where(id => _tags.All(t => t.TagId != id)))
            _tags.Add(new ArticleTag(Id, tagId));
        return Result.Success();
    }

    public void SetSources(IEnumerable<(string Title, string Url)> sources)
    {
        _sources.Clear();
        var order = 0;
        foreach (var (title, url) in sources)
            _sources.Add(new ArticleSource(Id, title.Trim(), url.Trim(), order++));
    }

    /// <summary>
    /// Replaces the attachment set, like LinkedIn: either 1–10 images (each with alt text) or exactly one PDF, never
    /// both. Every asset must belong to the author and be ready. An empty list removes all attachments (ADR 0011).
    /// </summary>
    public Result SetAttachments(IReadOnlyList<AttachmentCandidate> items)
    {
        if (items.Select(i => i.MediaAssetId).Distinct().Count() != items.Count) return AttachmentErrors.DuplicateAsset;
        if (AuthorId is null || items.Any(i => i.OwnerId != AuthorId)) return AttachmentErrors.AssetNotFound;
        if (items.Select(i => i.Kind).Distinct().Count() > 1) return AttachmentErrors.MixedKinds;

        var documents = items.Count(i => i.Kind == MediaKind.Document);
        if (documents > 1) return AttachmentErrors.SingleDocument;
        if (items.Count > MaxImageAttachments) return AttachmentErrors.TooManyImages;

        foreach (var item in items.Where(i => i.Kind == MediaKind.Image))
        {
            if (string.IsNullOrWhiteSpace(item.AltText)) return AttachmentErrors.AltTextRequired;
            if (item.AltText.Trim().Length > MaxAltTextLength) return AttachmentErrors.AltTextTooLong;
        }
        if (items.Any(i => i.Caption?.Trim().Length > MaxCaptionLength)) return AttachmentErrors.CaptionTooLong;
        if (items.Any(i => i.Status != MediaStatus.Ready)) return AttachmentErrors.AssetNotReady;

        _attachments.Clear();
        var order = 0;
        foreach (var item in items.Select((item, index) => (item, index)).OrderBy(x => x.item.Order).ThenBy(x => x.index).Select(x => x.item))
        {
            var isImage = item.Kind == MediaKind.Image;
            _attachments.Add(new ArticleAttachment(
                Id,
                item.MediaAssetId,
                order++,
                isImage ? Clean(item.Caption) : null,
                isImage ? Clean(item.AltText) : null));
        }
        return Result.Success();

        static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    /// <summary>
    /// Makes the article live (SPEC F06): the first call publishes it, later calls are the editor's "Update" of a
    /// published article and keep its first publish date. Every field may publish directly (ADR 0015).
    /// </summary>
    public Result Publish(Field field, DateTime now)
    {
        var check = EnsureCanGoLive(field);
        if (check.IsFailure) return check;
        if (IsPublished) return Result.Success();

        Status = ArticleStatus.Published;
        PublishedAt ??= now;
        QualityScore = ArticleQuality.Score(ReactionCount, CommentCount, SaveCount, ReadCount, ReadCount, (now - PublishedAt.Value).TotalHours);
        Raise(() => new ArticlePublishedDomainEvent(Id, AuthorId, FieldId, Slug));
        return Result.Success();
    }

    public Result Archive()
    {
        if (Status == ArticleStatus.Archived) return Result.Success();
        Status = ArticleStatus.Archived;
        return Result.Success();
    }

    /// <summary>Soft-deletes the article and detaches its media; the caller deletes the detached assets (ADR 0011).</summary>
    public IReadOnlyList<Guid> SoftDelete(DateTime now)
    {
        IsDeleted = true;
        DeletedAt = now;
        var detached = _attachments.Select(a => a.MediaAssetId).ToList();
        _attachments.Clear();
        return detached;
    }

    /// <summary>A moderator hides the article (SPEC F22); idempotent. Moderators never delete articles: only authors do.</summary>
    public void Hide(Guid moderatorId, DateTime now)
    {
        if (IsHidden) return;
        HiddenAt = now;
        HiddenById = moderatorId;
    }

    public void Unhide()
    {
        HiddenAt = null;
        HiddenById = null;
    }

    /// <summary>Content-pipeline articles passed every automatic check (SPEC §19.3) on <paramref name="checkedAt"/>.</summary>
    public void MarkAutoChecked(DateTime checkedAt) => AutoCheckedAt = checkedAt;

    public void SetQualityScore(double score) => QualityScore = score;

    /// <summary>
    /// Sets the denormalized counters. The outbox handlers update them in SQL instead (one statement, no rowversion
    /// round trip); this keeps the same invariant for code that works on a loaded article.
    /// </summary>
    public void ApplyCounters(ReactionCounts reactions, int comments, int saves, int reads)
    {
        InsightfulCount = reactions.Insightful;
        LoveCount = reactions.Love;
        FireCount = reactions.Fire;
        MindBlownCount = reactions.MindBlown;
        ReactionCount = reactions.Total;
        CommentCount = comments;
        SaveCount = saves;
        ReadCount = reads;
    }

    /// <summary>
    /// Autosave (F05): replaces the working copy when <paramref name="baseVersion"/> is the version the editor last saw,
    /// so a second device never silently overwrites the first. A published article now has unpublished changes.
    /// </summary>
    public Result SaveDraft(string documentJson, int baseVersion, DateTime now)
    {
        if (CurrentDraftVersion != baseVersion) return ArticleErrors.DraftConflict;
        SetDraft(documentJson, hasChanges: IsPublished, now);
        return Result.Success();
    }

    /// <summary>"Discard changes": the working copy becomes <paramref name="liveDocumentJson"/>, the published version again.</summary>
    public Result DiscardDraft(string liveDocumentJson, int baseVersion, DateTime now)
    {
        if (!IsPublished) return ArticleErrors.NotPublished;
        if (CurrentDraftVersion != baseVersion) return ArticleErrors.DraftConflict;
        SetDraft(liveDocumentJson, hasChanges: false, now);
        return Result.Success();
    }

    /// <summary>Restoring a revision copies it into the working copy; readers see it only after the next publish.</summary>
    public Result RestoreDraft(string revisionDocumentJson, int baseVersion, DateTime now)
    {
        if (CurrentDraftVersion != baseVersion) return ArticleErrors.DraftConflict;
        SetDraft(revisionDocumentJson, hasChanges: IsPublished, now);
        return Result.Success();
    }

    /// <summary>After a publish the working copy is what readers see: no unpublished changes, same version.</summary>
    public void MarkDraftPublished(string publishedDocumentJson, DateTime now)
    {
        if (Draft is null) Draft = new ArticleDraft(Id, publishedDocumentJson, now);
        else Draft.Publish(publishedDocumentJson, now);
    }

    /// <summary>Deleting the article drops its working copy (F05).</summary>
    public void DeleteDraft() => Draft = null;

    /// <summary>0 while the article has no working copy yet (it was created outside the editor).</summary>
    public int CurrentDraftVersion => Draft?.Version ?? 0;

    private void SetDraft(string documentJson, bool hasChanges, DateTime now)
    {
        if (Draft is null) Draft = new ArticleDraft(Id, documentJson, now) { HasChanges = hasChanges };
        else Draft.Replace(documentJson, hasChanges, now);
    }

    private Result EnsureCanGoLive(Field field)
    {
        if (field.Id != FieldId) throw new ArgumentException("Field does not match the article.", nameof(field));
        if (Status is ArticleStatus.Archived) return ArticleErrors.InvalidTransition(Status, ArticleStatus.Published);
        if (_translations.Count == 0) return ArticleErrors.NoContent;
        if (field.RequiresSources && _sources.Count == 0) return ArticleErrors.SourcesRequired;
        return Result.Success();
    }
}
