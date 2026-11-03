namespace ReadIn.Application.Features.Uploads;

/// <summary>One stored size. <see cref="Path"/> is what the database keeps; <see cref="Url"/> is for display only.</summary>
public sealed record UploadedImageVariantDto(int Size, string Path, string Url, int Width, int Height);

/// <summary>
/// Result of POST /uploads. The top-level <see cref="Path"/>/<see cref="Url"/>/<see cref="Width"/>/<see cref="Height"/>
/// describe the largest size: send <see cref="Path"/> as <c>avatarUrl</c> / <c>coverUrl</c>, or
/// <c>"rdoc-asset:/" + Path</c> as an RDoc image <c>src</c>.
/// </summary>
public sealed record UploadedImageDto(
    string Purpose,
    string Path,
    string Url,
    int Width,
    int Height,
    IReadOnlyList<UploadedImageVariantDto> Variants);
