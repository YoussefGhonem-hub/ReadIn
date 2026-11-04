using ReadIn.Domain.Common;

namespace ReadIn.Domain.Articles;

/// <summary>
/// Processed RDoc content: the validated + sanitized JSON and everything derived from it (SPEC §13.5).
/// Produced by the application's RDoc processor, never built from raw client input.
/// </summary>
/// <param name="Excerpt">The feed card's text (SPEC F34): plain text, at most <see cref="ArticleTranslation.ExcerptMaxLength"/>
/// characters cut at a word; empty when the article has no text the excerpt takes.</param>
/// <param name="ExcerptHasMore">The article holds more than <paramref name="Excerpt"/>: cut text, later blocks, or blocks
/// the excerpt skips.</param>
public sealed record ArticleContent(
    string Json,
    string PlainText,
    string SearchText,
    string? Summary,
    int ReadingTimeMinutes,
    int WordCount,
    string Excerpt,
    bool ExcerptHasMore);

public sealed class ArticleTranslation
{
    public const int ExcerptMaxLength = 400;

    private ArticleTranslation() { } // EF

    internal ArticleTranslation(Guid articleId, string language, string title, string? subtitle, ArticleContent content, bool isSource)
    {
        ArticleId = articleId;
        Language = language;
        Title = title;
        Subtitle = subtitle;
        IsSource = isSource;
        Apply(content);
    }

    public Guid Id { get; private set; }
    public Guid ArticleId { get; private set; }
    public string Language { get; private set; } = default!;
    public string Title { get; private set; } = default!;
    public string? Subtitle { get; private set; }
    public string? Summary { get; private set; }
    public string ContentJson { get; private set; } = default!;
    public string PlainText { get; private set; } = default!;
    public string SearchText { get; private set; } = default!;
    public int ReadingTimeMinutes { get; private set; }
    public int WordCount { get; private set; }

    /// <summary>The feed card's text (SPEC F34); null only on a version published before excerpts existed, until the backfill.</summary>
    public string? Excerpt { get; private set; }

    /// <summary>The version holds more than <see cref="Excerpt"/>: cut text, later blocks, or blocks the excerpt skips.</summary>
    public bool ExcerptHasMore { get; private set; }

    public bool IsSource { get; private set; }
    public DateTime? UpdatedAt { get; private set; }

    internal void MarkSource(bool isSource) => IsSource = isSource;

    internal void Update(string title, string? subtitle, ArticleContent content, DateTime now)
    {
        Title = title;
        Subtitle = subtitle;
        UpdatedAt = now;
        Apply(content);
    }

    private void Apply(ArticleContent content)
    {
        ContentJson = content.Json;
        PlainText = content.PlainText;
        SearchText = content.SearchText;
        Summary = content.Summary;
        ReadingTimeMinutes = content.ReadingTimeMinutes;
        WordCount = content.WordCount;
        Excerpt = content.Excerpt;
        ExcerptHasMore = content.ExcerptHasMore;
    }
}

public sealed class ArticleTag
{
    private ArticleTag() { } // EF

    internal ArticleTag(Guid articleId, Guid tagId)
    {
        ArticleId = articleId;
        TagId = tagId;
    }

    public Guid ArticleId { get; private set; }
    public Guid TagId { get; private set; }
    public Taxonomy.Tag Tag { get; private set; } = default!;
}

public sealed class ArticleSource
{
    private ArticleSource() { } // EF

    internal ArticleSource(Guid articleId, string title, string url, int sortOrder)
    {
        ArticleId = articleId;
        Title = title;
        Url = url;
        SortOrder = sortOrder;
    }

    public Guid Id { get; private set; }
    public Guid ArticleId { get; private set; }
    public string Title { get; private set; } = default!;
    public string Url { get; private set; } = default!;
    public int SortOrder { get; private set; }
    public DateTime? LastCheckedAt { get; private set; }
    public bool? IsAlive { get; private set; }

    public void RecordCheck(bool isAlive, DateTime checkedAt)
    {
        IsAlive = isAlive;
        LastCheckedAt = checkedAt;
    }
}

/// <summary>One language version for <see cref="Article.ReplaceTranslations"/>: processed content only (SPEC §13.5).</summary>
public sealed record TranslationVersion(string Language, string Title, string? Subtitle, ArticleContent Content);

/// <summary>
/// The editor's working copy (F05): the whole editor document as JSON, saved by autosave. <see cref="Version"/> guards
/// against two devices overwriting each other; <see cref="HasChanges"/> says a published article has unpublished edits.
/// </summary>
public sealed class ArticleDraft
{
    private ArticleDraft() { } // EF

    internal ArticleDraft(Guid articleId, string documentJson, DateTime now)
    {
        ArticleId = articleId;
        DocumentJson = documentJson;
        Version = 1;
        SavedAt = now;
    }

    public Guid ArticleId { get; private set; }
    public string DocumentJson { get; private set; } = default!;
    public int Version { get; private set; }
    public bool HasChanges { get; internal set; }
    public DateTime SavedAt { get; private set; }

    internal void Replace(string documentJson, bool hasChanges, DateTime now)
    {
        DocumentJson = documentJson;
        HasChanges = hasChanges;
        Version++;
        SavedAt = now;
    }

    internal void Publish(string documentJson, DateTime now)
    {
        DocumentJson = documentJson;
        HasChanges = false;
        SavedAt = now;
    }
}

/// <summary>A published version of an article (F05 revision history): the editor document as it went live.</summary>
public sealed class ArticleRevision
{
    private ArticleRevision() { } // EF

    public ArticleRevision(Guid articleId, int number, string title, IEnumerable<string> languages, string documentJson, Guid? editorId, DateTime now)
    {
        ArticleId = articleId;
        RevisionNumber = number;
        Title = title;
        Languages = string.Join(',', languages);
        DocumentJson = documentJson;
        CreatedBy = editorId;
        CreatedAt = now;
    }

    public Guid Id { get; private set; }
    public Guid ArticleId { get; private set; }
    public int RevisionNumber { get; private set; }

    /// <summary>The source-language title at that time, for the history list.</summary>
    public string Title { get; private set; } = default!;

    /// <summary>Comma-separated languages of the version, source first.</summary>
    public string Languages { get; private set; } = default!;
    public string DocumentJson { get; private set; } = default!;
    /// <summary>The editor; null once that account was deleted (SPEC F01), the revision itself stays with the article.</summary>
    public Guid? CreatedBy { get; private set; }
    public DateTime CreatedAt { get; private set; }
}

/// <summary>A media asset shown with the article: one of 1–10 images, or its single PDF document (ADR 0011).</summary>
public sealed class ArticleAttachment
{
    private ArticleAttachment() { } // EF

    internal ArticleAttachment(Guid articleId, Guid mediaAssetId, int order, string? caption, string? altText)
    {
        ArticleId = articleId;
        MediaAssetId = mediaAssetId;
        Order = order;
        Caption = caption;
        AltText = altText;
    }

    public Guid ArticleId { get; private set; }
    public Guid MediaAssetId { get; private set; }
    public int Order { get; private set; }
    public string? Caption { get; private set; }

    /// <summary>Required for images; documents are labelled by their title.</summary>
    public string? AltText { get; private set; }

    public Media.MediaAsset MediaAsset { get; private set; } = default!;
}

/// <summary>What <see cref="Article.SetAttachments"/> needs to know about each requested asset.</summary>
public sealed record AttachmentCandidate(
    Guid MediaAssetId,
    Media.MediaKind Kind,
    Media.MediaStatus Status,
    Guid? OwnerId,
    int Order,
    string? Caption,
    string? AltText);

/// <summary>Reactions on one article per type (SPEC F10).</summary>
public sealed record ReactionCounts(int Insightful, int Love, int Fire, int MindBlown)
{
    public static readonly ReactionCounts None = new(0, 0, 0, 0);

    public int Total => Insightful + Love + Fire + MindBlown;
}

public sealed record ArticlePublishedDomainEvent(Guid ArticleId, Guid? AuthorId, Guid FieldId, string Slug) : DomainEvent;

/// <summary>
/// A publish or "Update" put live a version that @mentions <paramref name="MentionedUserIds"/> (any language version; never
/// the author). Source of the article <c>mention</c> notifications (SPEC F17), each user told once per article.
/// </summary>
public sealed record ArticleMentionsDomainEvent(Guid ArticleId, Guid AuthorId, IReadOnlyList<Guid> MentionedUserIds) : DomainEvent;
