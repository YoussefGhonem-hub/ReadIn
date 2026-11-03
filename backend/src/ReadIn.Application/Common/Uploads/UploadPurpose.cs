using ReadIn.Domain.Media;

namespace ReadIn.Application.Common.Uploads;

/// <summary>
/// What an image is uploaded for: its API name, its folder under <c>/uploads</c> and its responsive width buckets
/// (SPEC §24, ADR 0010, buckets from ADR 0011). Every variant becomes one WebP file named by its real width
/// (<c>{id}_{width}.webp</c>). Images are never upscaled: see <see cref="WidthsFor"/>.
/// </summary>
public sealed class UploadPurpose
{
    /// <summary>Square, center-cropped.</summary>
    public static readonly UploadPurpose Avatar = new("avatar", "avatars", [64, 128, 256, 512], square: true, MediaPurpose.Avatar);

    /// <summary>Article cover.</summary>
    public static readonly UploadPurpose Cover = new("cover", "covers", [400, 800, 1200], square: false, MediaPurpose.Cover);

    /// <summary>Post/article images: attachments and image blocks inside RDoc content.</summary>
    public static readonly UploadPurpose ArticleImage = new("image", "images", [320, 640, 1080, 1600], square: false, MediaPurpose.Image);

    public static IReadOnlyList<UploadPurpose> All { get; } = [Avatar, Cover, ArticleImage];

    /// <summary>Earlier name of <see cref="ArticleImage"/>, still accepted by the API.</summary>
    private const string LegacyArticleImageName = "article-image";

    private UploadPurpose(string name, string folder, int[] sizes, bool square, MediaPurpose mediaPurpose)
    {
        Name = name;
        Folder = folder;
        Sizes = sizes;
        Square = square;
        MediaPurpose = mediaPurpose;
    }

    /// <summary>Value of the <c>purpose</c> form field.</summary>
    public string Name { get; }

    /// <summary>Folder under <c>/uploads</c>.</summary>
    public string Folder { get; }

    /// <summary>Width buckets, smallest first: the side of a square image, otherwise the width.</summary>
    public IReadOnlyList<int> Sizes { get; }

    public bool Square { get; }

    public MediaPurpose MediaPurpose { get; }

    /// <summary>
    /// The variant widths for an image whose bucketed side is <paramref name="measure"/> px: every bucket up to it, plus
    /// <paramref name="measure"/> itself when it falls below the largest bucket. A 1000 px photo gets 320, 640 and 1000;
    /// a 200 px one gets 200 only. Never upscales, never stores two files of the same width.
    /// </summary>
    public IReadOnlyList<int> WidthsFor(int measure)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(measure);
        var widths = Sizes.Where(size => size <= measure).ToList();
        if (measure < Sizes[^1] && !widths.Contains(measure)) widths.Add(measure);
        return widths;
    }

    public static UploadPurpose? FromName(string? name) =>
        name == LegacyArticleImageName ? ArticleImage : All.FirstOrDefault(p => p.Name == name);

    public static UploadPurpose? FromFolder(string? folder) => All.FirstOrDefault(p => p.Folder == folder);

    public override string ToString() => Name;
}

public static class UploadLimits
{
    /// <summary>Raw image upload limit (ADR 0011). Clients compress before uploading, so real uploads are far smaller.</summary>
    public const long MaxBytes = 10 * 1024 * 1024;

    /// <summary>Raw PDF upload limit (ADR 0011).</summary>
    public const long MaxDocumentBytes = 20 * 1024 * 1024;

    /// <summary>Larger images are rejected before their pixels are decoded (decompression-bomb protection).</summary>
    public const int MaxDimension = 8000;

    /// <summary>Unreferenced uploads younger than this are kept, so a client can still attach them.</summary>
    public static readonly TimeSpan OrphanGracePeriod = TimeSpan.FromHours(24);
}
