using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Interfaces;

/// <summary>One encoded width of an uploaded image. <see cref="Size"/> is the width used in the file name.</summary>
public sealed record ProcessedImage(int Size, int Width, int Height, byte[] Content);

/// <summary>
/// A processed upload: the upright size of the original (the square side for avatars), its BlurHash placeholder and
/// every variant, smallest first (ADR 0011).
/// </summary>
public sealed record ProcessedImageSet(int Width, int Height, string BlurHash, IReadOnlyList<ProcessedImage> Variants);

/// <summary>
/// Decodes an uploaded image and re-encodes it as WebP in the widths of its <see cref="UploadPurpose"/> (SPEC §24,
/// ADR 0011): EXIF orientation applied, converted to sRGB, all metadata dropped, never upscaled. Rejects images larger
/// than <see cref="UploadLimits.MaxDimension"/> before decoding their pixels.
/// </summary>
public interface IImageProcessor
{
    /// <param name="format">The format detected from the magic bytes; the decoder must agree with it.</param>
    Result<ProcessedImageSet> Process(Stream content, ImageFormat format, UploadPurpose purpose);
}
