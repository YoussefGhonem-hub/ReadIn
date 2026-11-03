using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Interfaces;

/// <summary>One encoded size of an uploaded image. <see cref="Size"/> is the size bucket used in the file name.</summary>
public sealed record ProcessedImage(int Size, int Width, int Height, byte[] Content);

/// <summary>
/// Decodes an uploaded image and re-encodes it as WebP in every size of its <see cref="UploadPurpose"/> (SPEC §24):
/// EXIF orientation applied, all metadata dropped, never upscaled. Rejects images larger than
/// <see cref="UploadLimits.MaxDimension"/> before decoding their pixels.
/// </summary>
public interface IImageProcessor
{
    /// <param name="format">The format detected from the magic bytes; the decoder must agree with it.</param>
    /// <returns>One image per size bucket, smallest first.</returns>
    Result<IReadOnlyList<ProcessedImage>> Process(Stream content, ImageFormat format, UploadPurpose purpose);
}
