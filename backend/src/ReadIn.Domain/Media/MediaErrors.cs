using ReadIn.Domain.Common;

namespace ReadIn.Domain.Media;

public static class MediaErrors
{
    public static readonly Error FileRequired = Error.Validation("media.file_required", "Choose a file to upload.");
    public static readonly Error TooLarge = Error.Validation("media.too_large", "The file is too large.");
    public static readonly Error UnsupportedType = Error.Validation("media.unsupported_type", "This file type is not supported.");
    public static readonly Error DimensionsTooLarge = Error.Validation("media.dimensions_too_large", "The image is larger than 8000×8000 pixels.");
    public static readonly Error ImageCorrupted = Error.Validation("media.image_corrupted", "The image could not be read.");
    public static readonly Error PdfEncrypted = Error.Validation("media.pdf_encrypted", "This file is password-protected. Upload it without a password.");
    public static readonly Error PdfCorrupted = Error.Validation("media.pdf_corrupted", "The PDF file is damaged and could not be read.");
    public static readonly Error PdfTooManyPages = Error.Validation("media.pdf_too_many_pages", "A PDF can have at most 100 pages.");
    public static readonly Error QuotaDaily = Error.Conflict("media.quota_daily", "You reached today's upload limit. Try again tomorrow.");
    public static readonly Error QuotaStorage = Error.Conflict("media.quota_storage", "You used all your storage space. Delete some uploads first.");
    public static readonly Error NotFound = Error.NotFound("media.not_found", "File not found.");
    public static readonly Error InUse = Error.Conflict("media.in_use", "Remove this file from its post before deleting it.");
    public static readonly Error DownloadNotAllowed = Error.Forbidden("media.download_not_allowed", "The author did not allow downloading this file.");

    /// <summary>Failure reasons stored on the asset when background processing fails.</summary>
    public const string ProcessingFailed = "media.processing_failed";

    public const string ProcessingTimeout = "media.processing_timeout";
}

public static class AttachmentErrors
{
    public static readonly Error MixedKinds = Error.Validation("attachments.mixed_kinds", "A post can have images or one PDF, not both.");
    public static readonly Error TooManyImages = Error.Validation("attachments.too_many_images", "A post can have at most 10 images.");
    public static readonly Error SingleDocument = Error.Validation("attachments.single_document", "A post can have only one PDF.");
    public static readonly Error AltTextRequired = Error.Validation("attachments.alt_text_required", "Every image needs alt text.");
    public static readonly Error AltTextTooLong = Error.Validation("attachments.alt_text_too_long", "Alt text can be at most 5000 characters.");
    public static readonly Error CaptionTooLong = Error.Validation("attachments.caption_too_long", "A caption can be at most 5000 characters.");
    public static readonly Error TitleRequired = Error.Validation("attachments.title_required", "The document needs a title.");
    public static readonly Error TitleTooLong = Error.Validation("attachments.title_too_long", "The document title can be at most 5000 characters.");
    public static readonly Error AssetNotFound = Error.Validation("attachments.asset_not_found", "One of the files was not found.");
    public static readonly Error AssetNotReady = Error.Conflict("attachments.asset_not_ready", "Wait until every file has finished processing.");
    public static readonly Error DuplicateAsset = Error.Validation("attachments.duplicate_asset", "The same file was added twice.");
}
