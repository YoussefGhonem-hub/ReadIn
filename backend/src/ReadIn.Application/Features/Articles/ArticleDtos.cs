using System.Text.Json;
using System.Text.Json.Serialization;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Articles;

public sealed record AuthorDto(Guid Id, string DisplayName, string Username, string? AvatarUrl, bool IsVerified);

/// <summary>Reactions per type (SPEC F10); the same shape as <c>/live/articles/{id}/reactions</c> (F27).</summary>
public sealed record ReactionCountsDto(int Insightful, int Love, int Fire, int MindBlown)
{
    public static readonly ReactionCountsDto None = new(0, 0, 0, 0);

    public int Total() => Insightful + Love + Fire + MindBlown;
}

public sealed record FieldRefDto(Guid Id, string Slug, string Name, string NameAr, string NameEn);

public sealed record SourceDto(string Title, string Url);

public sealed record ReviewerDto(string DisplayName, string Username);

public record ArticleCardDto
{
    public Guid Id { get; init; }
    public string Slug { get; init; } = default!;

    /// <summary>The language actually served (requested language, or the source language as fallback).</summary>
    public string Language { get; init; } = default!;

    public string Title { get; init; } = default!;
    public string? Subtitle { get; init; }
    public string? CoverUrl { get; init; }
    public FieldRefDto Field { get; init; } = default!;
    public AuthorDto Author { get; init; } = default!;
    public int ReadingTimeMinutes { get; init; }
    public bool IsReviewed { get; init; }
    public bool IsAiAssisted { get; init; }
    public string? VersionBadge { get; init; }
    public DateTime? PublishedAt { get; init; }

    /// <summary>All reactions; always the sum of <see cref="Reactions"/>.</summary>
    public int ReactionCount { get; init; }

    public ReactionCountsDto Reactions { get; init; } = ReactionCountsDto.None;
    public int CommentCount { get; init; }
    public int SaveCount { get; init; }

    /// <summary>The viewer's reaction; null for guests. Loaded after the projection by <see cref="ArticleViewerStateReader"/>.</summary>
    public ReactionType? MyReaction { get; init; }

    /// <summary>The viewer saved it; false for guests.</summary>
    public bool IsSaved { get; init; }

    /// <summary>1–10 images or one PDF (ADR 0011). Loaded after the projection by <see cref="ArticleAttachmentsReader"/>.</summary>
    public ArticleAttachmentsDto? Attachments { get; init; }
}

public sealed record ImageAttachmentDto(
    Guid AssetId,
    int Order,
    string? Caption,
    string AltText,
    int Width,
    int Height,
    string? BlurHash,
    IReadOnlyList<Uploads.MediaVariantDto> Variants);

public sealed record DocumentAttachmentDto(
    Guid AssetId,
    string Title,
    int PageCount,
    bool AllowDownload,
    bool CanDownload,
    string DownloadUrl,
    IReadOnlyList<Uploads.MediaPageDto> Pages);

/// <summary><see cref="Kind"/> is <c>images</c> or <c>document</c>; never both.</summary>
public sealed record ArticleAttachmentsDto(string Kind, IReadOnlyList<ImageAttachmentDto> Images, DocumentAttachmentDto? Document)
{
    public const string ImagesKind = "images";
    public const string DocumentKind = "document";
}

public sealed record ArticleDetailsDto : ArticleCardDto
{
    public IReadOnlyList<string> AvailableLanguages { get; init; } = [];
    public string? Summary { get; init; }

    /// <summary>RDoc document (shared/rdoc/rdoc.schema.json).</summary>
    public JsonElement Content { get; init; }

    public FieldRefDto? Topic { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = [];
    public IReadOnlyList<SourceDto> Sources { get; init; } = [];
    public ReviewerDto? ReviewedBy { get; init; }
    public DateTime? LastReviewedAt { get; init; }
    public int ReadCount { get; init; }

    /// <summary>The viewer follows the author; false for guests and on your own articles.</summary>
    public bool IsFollowingAuthor { get; init; }

    /// <summary>The viewer's collections that hold this article; empty for guests and unsaved articles.</summary>
    public IReadOnlyList<Guid> CollectionIds { get; init; } = [];

    /// <summary>The viewer's reading progress, so the reader can resume (F04); null for guests and unopened articles.</summary>
    public MyProgressDto? MyProgress { get; init; }

    /// <summary>Raw RDoc from the projection; parsed into <see cref="Content"/> by the handler.</summary>
    [JsonIgnore]
    public string ContentJson { get; init; } = default!;
}

/// <summary>
/// Where the viewer left an article: <see cref="LastPosition"/> is what the reader sent (the scroll position as a
/// fraction, e.g. "0.4523") and <see cref="Language"/> the version it was measured on.
/// </summary>
public sealed record MyProgressDto(string Language, int Percent, string? LastPosition, DateTime? CompletedAt);
