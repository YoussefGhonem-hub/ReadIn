using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Uploads;

public static class UploadErrors
{
    public static readonly Error PurposeInvalid = Error.Validation("upload.purpose_invalid", "Purpose must be avatar, cover or article-image.");
    public static readonly Error Empty = Error.Validation("upload.empty", "The file is empty.");
    public static readonly Error TooLarge = Error.Validation("upload.too_large", "Images must be 5 MB or smaller.");
    public static readonly Error UnsupportedType = Error.Validation("upload.unsupported_type", "Only JPEG, PNG and WebP images are allowed.");
    public static readonly Error DimensionsTooLarge = Error.Validation("upload.dimensions_too_large", "Images must be at most 8000 × 8000 pixels.");
    public static readonly Error InvalidImage = Error.Validation("upload.invalid_image", "The file is not a readable image.");
}
