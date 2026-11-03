using ReadIn.Domain.Common;

namespace ReadIn.Domain.Media;

public enum MediaKind
{
    Image = 0,
    Document = 1,
}

/// <summary>What an upload is for. It decides the variant widths and the storage folder (ADR 0011).</summary>
public enum MediaPurpose
{
    Image = 0,
    Avatar = 1,
    Cover = 2,
    Document = 3,
}

public enum MediaStatus
{
    Uploading = 0,
    Processing = 1,
    Ready = 2,
    Failed = 3,
}

/// <summary>One responsive WebP rendition of an image. <see cref="Path"/> is relative to the uploads root.</summary>
public sealed record MediaVariant(int Width, int Height, string Path, long Bytes);

/// <summary>
/// An uploaded image or PDF document and everything generated from it (SPEC §16, ADR 0011). Images are processed in
/// the request and arrive <see cref="MediaStatus.Ready"/>; documents are rendered by a background job, page 1 first.
/// </summary>
public sealed class MediaAsset : AggregateRoot, IAuditable
{
    public const int MaxTitleLength = 5000;

    private readonly List<MediaAssetPage> _pages = [];
    private List<MediaVariant> _variants = [];

    private MediaAsset() { } // EF

    public Guid OwnerId { get; private set; }
    public MediaKind Kind { get; private set; }
    public MediaPurpose Purpose { get; private set; }
    public MediaStatus Status { get; private set; }

    /// <summary>Stable error code (e.g. <c>media.processing_timeout</c>) when <see cref="Status"/> is Failed.</summary>
    public string? FailureReason { get; private set; }

    /// <summary>Documents: the original PDF. Images: the largest variant (the raw upload is never kept, it may carry EXIF/GPS).</summary>
    public string? OriginalPath { get; private set; }

    public long OriginalSizeBytes { get; private set; }

    /// <summary>Bytes this asset occupies in storage (original PDF + variants + pages); counted against the owner's quota.</summary>
    public long StoredBytes { get; private set; }

    public int? Width { get; private set; }
    public int? Height { get; private set; }
    public string? BlurHash { get; private set; }

    public IReadOnlyList<MediaVariant> Variants
    {
        get => _variants.AsReadOnly();
        private set => _variants = [.. value];
    }

    public int? PageCount { get; private set; }
    public string? Title { get; private set; }
    public bool AllowDownload { get; private set; }

    /// <summary>Text extracted from a PDF so documents are searchable (SPEC §22).</summary>
    public string? ExtractedText { get; private set; }

    public IReadOnlyCollection<MediaAssetPage> Pages => _pages.AsReadOnly();

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }

    public bool IsReady => Status == MediaStatus.Ready;

    public static MediaAsset StartImage(Guid ownerId, MediaPurpose purpose, long originalSizeBytes)
    {
        if (purpose == MediaPurpose.Document) throw new ArgumentException("Images cannot have the document purpose.", nameof(purpose));
        return new MediaAsset
        {
            OwnerId = ownerId,
            Kind = MediaKind.Image,
            Purpose = purpose,
            Status = MediaStatus.Uploading,
            OriginalSizeBytes = originalSizeBytes,
        };
    }

    public static MediaAsset StartDocument(Guid ownerId, string title, bool allowDownload, long originalSizeBytes, int pageCount)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(pageCount);
        return new MediaAsset
        {
            OwnerId = ownerId,
            Kind = MediaKind.Document,
            Purpose = MediaPurpose.Document,
            Status = MediaStatus.Uploading,
            OriginalSizeBytes = originalSizeBytes,
            PageCount = pageCount,
            Title = NormalizeTitle(title),
            AllowDownload = allowDownload,
        };
    }

    /// <summary>Records the processed image. Variants are ordered by width; the largest one stands in for the original.</summary>
    public void CompleteImage(int width, int height, string blurHash, IReadOnlyCollection<MediaVariant> variants)
    {
        EnsureKind(MediaKind.Image);
        if (variants.Count == 0) throw new ArgumentException("An image needs at least one variant.", nameof(variants));

        Width = width;
        Height = height;
        BlurHash = blurHash;
        Variants = [.. variants.OrderBy(v => v.Width)];
        OriginalPath = _variants[^1].Path;
        StoredBytes = _variants.Sum(v => v.Bytes);
        Status = MediaStatus.Ready;
        FailureReason = null;
    }

    /// <summary>The original PDF is stored; its pages are rendered in the background.</summary>
    public void StartProcessing(string originalPath)
    {
        EnsureKind(MediaKind.Document);
        OriginalPath = originalPath;
        StoredBytes = OriginalSizeBytes + _pages.Sum(p => p.Bytes);
        Status = MediaStatus.Processing;
    }

    /// <summary>Adds (or replaces, on a retried job) a rendered page. Page 1 also sets the asset's size and placeholder.</summary>
    public void AddPage(int pageNo, string thumbPath, string viewPath, int width, int height, string blurHash, long bytes)
    {
        EnsureKind(MediaKind.Document);
        if (pageNo < 1 || pageNo > PageCount) throw new ArgumentOutOfRangeException(nameof(pageNo));

        _pages.RemoveAll(p => p.PageNo == pageNo);
        _pages.Add(new MediaAssetPage(Id, pageNo, thumbPath, viewPath, width, height, blurHash, bytes));
        if (pageNo == 1)
        {
            Width = width;
            Height = height;
            BlurHash = blurHash;
        }
        StoredBytes = OriginalSizeBytes + _pages.Sum(p => p.Bytes);
    }

    public void CompleteDocument(string? extractedText)
    {
        EnsureKind(MediaKind.Document);
        if (_pages.Count != PageCount) throw new InvalidOperationException($"Only {_pages.Count} of {PageCount} pages were rendered.");

        ExtractedText = string.IsNullOrWhiteSpace(extractedText) ? null : extractedText;
        Status = MediaStatus.Ready;
        FailureReason = null;
    }

    public void Fail(string reason)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(reason);
        Status = MediaStatus.Failed;
        FailureReason = reason;
    }

    public Result UpdateDocumentSettings(string? title, bool allowDownload)
    {
        if (Kind != MediaKind.Document) return Result.Success();
        if (string.IsNullOrWhiteSpace(title)) return AttachmentErrors.TitleRequired;
        if (title.Trim().Length > MaxTitleLength) return AttachmentErrors.TitleTooLong;

        Title = NormalizeTitle(title);
        AllowDownload = allowDownload;
        return Result.Success();
    }

    /// <summary>Every stored file of this asset, relative to the uploads root (used for deletion and orphan cleanup).</summary>
    public IEnumerable<string> StoredPaths()
    {
        if (OriginalPath is not null) yield return OriginalPath;
        foreach (var variant in _variants.Where(v => v.Path != OriginalPath)) yield return variant.Path;
        foreach (var page in _pages)
        {
            yield return page.ThumbPath;
            yield return page.ViewPath;
        }
    }

    private static string NormalizeTitle(string title)
    {
        var trimmed = title.Trim();
        return trimmed.Length <= MaxTitleLength ? trimmed : trimmed[..MaxTitleLength].TrimEnd();
    }

    private void EnsureKind(MediaKind kind)
    {
        if (Kind != kind) throw new InvalidOperationException($"This operation needs a {kind} asset, not {Kind}.");
    }
}

/// <summary>A rendered PDF page: a 400 px thumb and a 1080 px view, both WebP.</summary>
public sealed class MediaAssetPage
{
    private MediaAssetPage() { } // EF

    internal MediaAssetPage(Guid assetId, int pageNo, string thumbPath, string viewPath, int width, int height, string blurHash, long bytes)
    {
        AssetId = assetId;
        PageNo = pageNo;
        ThumbPath = thumbPath;
        ViewPath = viewPath;
        Width = width;
        Height = height;
        BlurHash = blurHash;
        Bytes = bytes;
    }

    public Guid AssetId { get; private set; }
    public int PageNo { get; private set; }
    public string ThumbPath { get; private set; } = default!;
    public string ViewPath { get; private set; } = default!;

    /// <summary>Size of the view rendition.</summary>
    public int Width { get; private set; }

    public int Height { get; private set; }
    public string BlurHash { get; private set; } = default!;

    /// <summary>Thumb + view bytes.</summary>
    public long Bytes { get; private set; }
}
