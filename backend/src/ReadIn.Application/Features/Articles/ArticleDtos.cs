using System.Text.Json;
using System.Text.Json.Serialization;

namespace ReadIn.Application.Features.Articles;

public sealed record AuthorDto(Guid Id, string DisplayName, string Username, string? AvatarUrl, bool IsVerified);

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
    public int ReactionCount { get; init; }
    public int CommentCount { get; init; }

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
    public int SaveCount { get; init; }
    public int ReadCount { get; init; }

    /// <summary>Raw RDoc from the projection; parsed into <see cref="Content"/> by the handler.</summary>
    [JsonIgnore]
    public string ContentJson { get; init; } = default!;
}
