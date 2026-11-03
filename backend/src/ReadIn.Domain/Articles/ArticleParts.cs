using ReadIn.Domain.Common;

namespace ReadIn.Domain.Articles;

/// <summary>
/// Processed RDoc content: the validated + sanitized JSON and everything derived from it (SPEC §13.5).
/// Produced by the application's RDoc processor, never built from raw client input.
/// </summary>
public sealed record ArticleContent(
    string Json,
    string PlainText,
    string SearchText,
    string? Summary,
    int ReadingTimeMinutes,
    int WordCount);

public sealed class ArticleTranslation
{
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
    public bool IsSource { get; private set; }
    public DateTime? UpdatedAt { get; private set; }

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

public sealed class ArticleRevision
{
    private ArticleRevision() { } // EF

    internal ArticleRevision(Guid articleId, ArticleTranslation snapshot, int number, Guid editorId, DateTime now)
    {
        ArticleId = articleId;
        Language = snapshot.Language;
        Title = snapshot.Title;
        Subtitle = snapshot.Subtitle;
        ContentJson = snapshot.ContentJson;
        RevisionNumber = number;
        CreatedBy = editorId;
        CreatedAt = now;
    }

    public Guid Id { get; private set; }
    public Guid ArticleId { get; private set; }
    public string Language { get; private set; } = default!;
    public string Title { get; private set; } = default!;
    public string? Subtitle { get; private set; }
    public string ContentJson { get; private set; } = default!;
    public int RevisionNumber { get; private set; }
    public Guid CreatedBy { get; private set; }
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
    Guid OwnerId,
    int Order,
    string? Caption,
    string? AltText);

public sealed record ArticlePublishedDomainEvent(Guid ArticleId, Guid AuthorId, Guid FieldId, string Slug) : DomainEvent;

public sealed record ArticleSubmittedDomainEvent(Guid ArticleId, Guid FieldId) : DomainEvent;

public sealed record ArticleReviewedDomainEvent(Guid ArticleId, Guid AuthorId, bool Approved) : DomainEvent;
