using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Common.Uploads;

/// <summary>Image upload errors. They share the <c>media.*</c> codes of <see cref="MediaErrors"/> (ADR 0011).</summary>
public static class UploadErrors
{
    public static readonly Error PurposeInvalid = Error.Validation("media.purpose_invalid", "Purpose must be image, avatar or cover.");
    public static readonly Error Empty = MediaErrors.FileRequired;
    public static readonly Error TooLarge = MediaErrors.TooLarge;
    public static readonly Error UnsupportedType = MediaErrors.UnsupportedType;
    public static readonly Error DimensionsTooLarge = MediaErrors.DimensionsTooLarge;
    public static readonly Error InvalidImage = MediaErrors.ImageCorrupted;
}
