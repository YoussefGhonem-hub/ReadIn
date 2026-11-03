using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads;

/// <summary>One responsive WebP rendition (absolute URL).</summary>
public sealed record MediaVariantDto(int Width, int Height, string Url, long Bytes);

/// <summary>A rendered PDF page: 400 px thumb + 1080 px view.</summary>
public sealed record MediaPageDto(int PageNo, int Width, int Height, string BlurHash, string ThumbUrl, string ViewUrl);

/// <summary>GET /uploads/{id}: an uploaded image or PDF and its processing state (ADR 0011).</summary>
public sealed record MediaAssetDto
{
    public Guid Id { get; init; }
    public MediaKind Kind { get; init; }
    public MediaPurpose Purpose { get; init; }
    public MediaStatus Status { get; init; }
    public string? FailureReason { get; init; }
    public int? Width { get; init; }
    public int? Height { get; init; }
    public string? BlurHash { get; init; }
    public long SizeBytes { get; init; }
    public IReadOnlyList<MediaVariantDto> Variants { get; init; } = [];
    public string? Title { get; init; }
    public int? PageCount { get; init; }
    public int PagesReady { get; init; }
    public IReadOnlyList<MediaPageDto> Pages { get; init; } = [];
    public bool AllowDownload { get; init; }
    public DateTime CreatedAt { get; init; }
}
