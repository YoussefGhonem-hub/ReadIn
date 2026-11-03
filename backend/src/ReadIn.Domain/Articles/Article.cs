using ReadIn.Domain.Common;
using ReadIn.Domain.Media;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Domain.Articles;

public enum ArticleStatus
{
    Draft = 0,
    Submitted = 1,
    InReview = 2,
    ChangesRequested = 3,
    Approved = 4,
    Scheduled = 5,
    Published = 6,
    Archived = 7,
}

public enum ReviewStatus
{
    None = 0,
    Pending = 1,
    Approved = 2,
    ChangesRequested = 3,
}

/// <summary>
/// Article aggregate (SPEC §6.6, F06). Lifecycle and review are two axes: a non-sensitive article may be
/// published without review (no "Reviewed" badge) and reviewed later; sensitive fields require approval first.
/// </summary>
public sealed class Article : AggregateRoot, IAuditable, ISoftDeletable, IHasRowVersion
{
    public const int MaxTags = 5;
    public const int MaxImageAttachments = 10;
    public const int MaxCaptionLength = 5000;
    public const int MaxAltTextLength = 5000;

    /// <summary>Word-count change ratio above which an edit resets the "Reviewed" badge (SPEC §10.2).</summary>
    public const double SignificantChangeRatio = 0.15;

    private readonly List<ArticleTranslation> _translations = [];
    private readonly List<ArticleTag> _tags = [];
    private readonly List<ArticleSource> _sources = [];
    private readonly List<ArticleRevision> _revisions = [];
    private readonly List<ArticleAttachment> _attachments = [];

    private Article() { } // EF

    public Guid AuthorId { get; private set; }
    public Guid FieldId { get; private set; }
    public Guid? TopicId { get; private set; }
    public string Slug { get; private set; } = default!;
    public ArticleStatus Status { get; private set; }
    public ReviewStatus ReviewStatus { get; private set; }
    public string SourceLanguage { get; private set; } = default!;
    public string? CoverUrl { get; private set; }
    public bool IsAiAssisted { get; private set; }
    public string? VersionBadge { get; private set; }
    public DateTime? LastReviewedAt { get; private set; }

    /// <summary>When the content pipeline last validated this article (SPEC §19.3); Today's article falls back to these (F07).</summary>
    public DateTime? AutoCheckedAt { get; private set; }
    public Guid? ReviewedById { get; private set; }
    public DateTime? PublishedAt { get; private set; }
    public DateTime? ScheduledAt { get; private set; }
    public double QualityScore { get; private set; }

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
    public Users.User Author { get; private set; } = default!;
    public Field Field { get; private set; } = default!;
    public Topic? Topic { get; private set; }
    public Users.User? ReviewedBy { get; private set; }

    public IReadOnlyCollection<ArticleTranslation> Translations => _translations.AsReadOnly();
    public IReadOnlyCollection<ArticleTag> Tags => _tags.AsReadOnly();
    public IReadOnlyCollection<ArticleSource> Sources => _sources.AsReadOnly();
    public IReadOnlyCollection<ArticleRevision> Revisions => _revisions.AsReadOnly();
    public IReadOnlyCollection<ArticleAttachment> Attachments => _attachments.AsReadOnly();

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }
    public bool IsDeleted { get; private set; }
    public DateTime? DeletedAt { get; private set; }
    public byte[] RowVersion { get; private set; } = [];

    public bool IsReviewed => ReviewStatus == ReviewStatus.Approved;
    public bool IsPublished => Status == ArticleStatus.Published;

    public static Article CreateDraft(Guid authorId, Guid fieldId, Guid? topicId, string slug, Guid? id = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(slug);
        return new Article
        {
            Id = id ?? Guid.Empty,
            AuthorId = authorId,
            FieldId = fieldId,
            TopicId = topicId,
            Slug = slug,
            Status = ArticleStatus.Draft,
            ReviewStatus = ReviewStatus.None,
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

    /// <summary>
    /// Updates a translation. Editing a published article stores a revision first and resets the
    /// "Reviewed" badge when the content changed significantly (SPEC §10.2).
    /// </summary>
    public Result UpdateTranslation(string language, string title, string? subtitle, ArticleContent content, Guid editorId, DateTime now)
    {
        var translation = _translations.FirstOrDefault(t => t.Language == language);
        if (translation is null) return ArticleErrors.TranslationNotFound;

        if (IsPublished)
        {
            _revisions.Add(new ArticleRevision(Id, translation, _revisions.Count + 1, editorId, now));

            if (IsReviewed && IsSignificantChange(translation.WordCount, content.WordCount))
            {
                ReviewStatus = ReviewStatus.None;
                ReviewedById = null;
            }
        }

        translation.Update(title.Trim(), subtitle?.Trim(), content, now);
        return Result.Success();
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
        if (items.Any(i => i.OwnerId != AuthorId)) return AttachmentErrors.AssetNotFound;
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

    public Result SubmitForReview()
    {
        if (Status is not (ArticleStatus.Draft or ArticleStatus.ChangesRequested or ArticleStatus.Published))
            return ArticleErrors.InvalidTransition(Status, ArticleStatus.Submitted);
        if (_translations.Count == 0) return ArticleErrors.NoContent;

        if (Status != ArticleStatus.Published) Status = ArticleStatus.Submitted;
        ReviewStatus = ReviewStatus.Pending;
        Raise(() => new ArticleSubmittedDomainEvent(Id, FieldId));
        return Result.Success();
    }

    public Result StartReview()
    {
        if (ReviewStatus != ReviewStatus.Pending) return ArticleErrors.NotPendingReview;
        if (Status == ArticleStatus.Submitted) Status = ArticleStatus.InReview;
        return Result.Success();
    }

    public Result Approve(Guid reviewerId, DateTime now)
    {
        if (ReviewStatus != ReviewStatus.Pending) return ArticleErrors.NotPendingReview;
        if (reviewerId == AuthorId) return ArticleErrors.CannotReviewOwnArticle;

        ReviewStatus = ReviewStatus.Approved;
        ReviewedById = reviewerId;
        LastReviewedAt = now;
        if (Status is ArticleStatus.Submitted or ArticleStatus.InReview) Status = ArticleStatus.Approved;
        Raise(() => new ArticleReviewedDomainEvent(Id, AuthorId, Approved: true));
        return Result.Success();
    }

    public Result RequestChanges(Guid reviewerId)
    {
        if (ReviewStatus != ReviewStatus.Pending) return ArticleErrors.NotPendingReview;
        if (reviewerId == AuthorId) return ArticleErrors.CannotReviewOwnArticle;

        ReviewStatus = ReviewStatus.ChangesRequested;
        if (Status is ArticleStatus.Submitted or ArticleStatus.InReview) Status = ArticleStatus.ChangesRequested;
        Raise(() => new ArticleReviewedDomainEvent(Id, AuthorId, Approved: false));
        return Result.Success();
    }

    public Result Publish(Field field, DateTime now)
    {
        var check = EnsureCanGoLive(field);
        if (check.IsFailure) return check;

        Status = ArticleStatus.Published;
        PublishedAt ??= now;
        ScheduledAt = null;
        Raise(() => new ArticlePublishedDomainEvent(Id, AuthorId, FieldId, Slug));
        return Result.Success();
    }

    public Result Schedule(Field field, DateTime publishAt, DateTime now)
    {
        if (publishAt <= now) return ArticleErrors.ScheduleInPast;
        var check = EnsureCanGoLive(field);
        if (check.IsFailure) return check;

        Status = ArticleStatus.Scheduled;
        ScheduledAt = publishAt;
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

    /// <summary>Used by the content importer: editorial content arrives already reviewed (SPEC §19.2).</summary>
    public void MarkReviewed(Guid reviewerId, DateTime reviewedAt)
    {
        ReviewStatus = ReviewStatus.Approved;
        ReviewedById = reviewerId;
        LastReviewedAt = reviewedAt;
        if (Status is ArticleStatus.Draft or ArticleStatus.Submitted or ArticleStatus.InReview) Status = ArticleStatus.Approved;
    }

    /// <summary>
    /// Content-pipeline articles passed every automatic check (SPEC §19.3) on <paramref name="checkedAt"/>, which also
    /// becomes the "Last reviewed" date until a human reviews them. It never sets a reviewer: no badge is faked.
    /// </summary>
    public void MarkAutoChecked(DateTime checkedAt)
    {
        AutoCheckedAt = checkedAt;
        if (ReviewStatus != ReviewStatus.Approved) LastReviewedAt = checkedAt;
    }

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

    private Result EnsureCanGoLive(Field field)
    {
        if (field.Id != FieldId) throw new ArgumentException("Field does not match the article.", nameof(field));
        if (Status is ArticleStatus.Archived) return ArticleErrors.InvalidTransition(Status, ArticleStatus.Published);
        if (_translations.Count == 0) return ArticleErrors.NoContent;
        if (field.RequiresSources && _sources.Count == 0) return ArticleErrors.SourcesRequired;
        if (field.IsSensitive && ReviewStatus != ReviewStatus.Approved) return ArticleErrors.ReviewRequired;
        return Result.Success();
    }

    private static bool IsSignificantChange(int oldWords, int newWords)
    {
        if (oldWords == 0) return newWords > 0;
        return Math.Abs(newWords - oldWords) / (double)oldWords > SignificantChangeRatio;
    }
}
