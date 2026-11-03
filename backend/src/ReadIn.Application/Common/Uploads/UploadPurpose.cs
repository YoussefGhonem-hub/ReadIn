namespace ReadIn.Application.Common.Uploads;

/// <summary>
/// What an image is uploaded for: its API name, its folder under <c>/uploads</c> and its size buckets (SPEC §24).
/// Every bucket becomes one WebP file (<c>{id}_{size}.webp</c>); images are never upscaled, so a bucket is a maximum.
/// </summary>
public sealed class UploadPurpose
{
    /// <summary>Square, center-cropped: 256 for lists, 512 for the profile page.</summary>
    public static readonly UploadPurpose Avatar = new("avatar", "avatars", [256, 512], square: true);

    /// <summary>Article cover, at most 1200 px wide.</summary>
    public static readonly UploadPurpose Cover = new("cover", "covers", [1200], square: false);

    /// <summary>Image block inside RDoc content, at most 1600 px wide.</summary>
    public static readonly UploadPurpose ArticleImage = new("article-image", "articles", [1600], square: false);

    public static IReadOnlyList<UploadPurpose> All { get; } = [Avatar, Cover, ArticleImage];

    private UploadPurpose(string name, string folder, int[] sizes, bool square)
    {
        Name = name;
        Folder = folder;
        Sizes = sizes;
        Square = square;
    }

    /// <summary>Value of the <c>purpose</c> form field.</summary>
    public string Name { get; }

    /// <summary>Folder under <c>/uploads</c>.</summary>
    public string Folder { get; }

    /// <summary>Size buckets, smallest first: the side of a square image, otherwise the maximum width.</summary>
    public IReadOnlyList<int> Sizes { get; }

    public bool Square { get; }

    public static UploadPurpose? FromName(string? name) => All.FirstOrDefault(p => p.Name == name);

    public static UploadPurpose? FromFolder(string? folder) => All.FirstOrDefault(p => p.Folder == folder);

    public override string ToString() => Name;
}

public static class UploadLimits
{
    public const long MaxBytes = 5 * 1024 * 1024;

    /// <summary>Larger images are rejected before their pixels are decoded (decompression-bomb protection).</summary>
    public const int MaxDimension = 8000;

    /// <summary>Unreferenced uploads younger than this are kept, so a client can still attach them.</summary>
    public static readonly TimeSpan OrphanGracePeriod = TimeSpan.FromHours(24);
}
