using System.Text.Json;
using FluentValidation;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>
/// The shape of an editor document (F05). Lenient about unfinished work (empty titles, missing field, alt text): that is
/// what the live checks report. Only a malformed or oversized document is rejected.
/// </summary>
internal sealed class ArticleDraftDocumentValidator : AbstractValidator<ArticleDraftDocument>
{
    public const int MaxTitleLength = 150;
    public const int MaxSubtitleLength = 250;
    public const int MaxBlocks = 2000;
    public const int MaxContentChars = 500_000;
    public const int MaxSources = 30;
    public const int MaxTagLength = 40;

    public ArticleDraftDocumentValidator(IFileStorage storage)
    {
        RuleFor(d => d.SourceLanguage).Must(ArticleLanguages.IsValid).WithErrorCode(ArticleErrors.InvalidLanguage.Code);
        RuleFor(d => d.Translations)
            .Must(t => t is { Count: >= 1 and <= 2 } && t.Select(x => x.Language).Distinct().Count() == t.Count)
            .WithErrorCode(ArticleErrors.TranslationExists.Code);
        RuleFor(d => d).Must(d => d.Translations.Any(t => t.Language == d.SourceLanguage))
            .OverridePropertyName("sourceLanguage").WithErrorCode(ArticleErrors.TranslationNotFound.Code);
        RuleForEach(d => d.Translations).ChildRules(translation =>
        {
            translation.RuleFor(t => t.Language).Must(ArticleLanguages.IsValid).WithErrorCode(ArticleErrors.InvalidLanguage.Code);
            translation.RuleFor(t => t.Title).NotNull().MaximumLength(MaxTitleLength);
            translation.RuleFor(t => t.Subtitle).MaximumLength(MaxSubtitleLength);
            translation.RuleFor(t => t).Must(t => IsRDocShape(t.Content, t.Language))
                .OverridePropertyName("content").WithErrorCode(ArticleErrors.InvalidContent.Code);
        });

        RuleFor(d => d.Tags).Must(t => t.Count <= Article.MaxTags).WithErrorCode(ArticleErrors.TooManyTags.Code);
        RuleForEach(d => d.Tags).NotEmpty().MaximumLength(MaxTagLength);

        RuleFor(d => d.Sources).Must(s => s.Count <= MaxSources).WithErrorCode("validation.max_length");
        RuleForEach(d => d.Sources).ChildRules(source =>
        {
            source.RuleFor(s => s.Title).NotEmpty().MaximumLength(200);
            source.RuleFor(s => s.Url).Must(IsHttpUrl).WithErrorCode("validation.url");
        });

        // An uploaded cover (relative path or its public URL), or an external http(s) image.
        RuleFor(d => d.CoverUrl)
            .Must(u => string.IsNullOrWhiteSpace(u) || (storage.TryGetUploadPath(u, out var path) ? path.Purpose == UploadPurpose.Cover : IsHttpUrl(u)))
            .WithErrorCode("validation.url");
        RuleFor(d => d.VersionBadge).MaximumLength(30);

        RuleFor(d => d.Attachments)
            .Must(a => a.Count <= Article.MaxImageAttachments && a.Select(x => x.MediaAssetId).Distinct().Count() == a.Count)
            .WithErrorCode("attachments.too_many_images");
        RuleForEach(d => d.Attachments).ChildRules(attachment =>
        {
            attachment.RuleFor(a => a.MediaAssetId).NotEmpty();
            attachment.RuleFor(a => a.Caption).MaximumLength(Article.MaxCaptionLength).WithErrorCode("attachments.caption_too_long");
            attachment.RuleFor(a => a.AltText).MaximumLength(Article.MaxAltTextLength).WithErrorCode("attachments.alt_text_too_long");
            attachment.RuleFor(a => a.Title).MaximumLength(5000).Must(t => t is null || !t.Contains('\n'))
                .WithErrorCode("attachments.title_too_long");
        });
    }

    /// <summary>An RDoc object in <paramref name="language"/> with a block array; the schema itself is checked by the live checks.</summary>
    private static bool IsRDocShape(JsonElement content, string language) =>
        content.ValueKind == JsonValueKind.Object
        && content.GetRawText().Length <= MaxContentChars
        && content.TryGetProperty("language", out var lang) && lang.ValueKind == JsonValueKind.String && lang.GetString() == language
        && content.TryGetProperty("blocks", out var blocks) && blocks.ValueKind == JsonValueKind.Array && blocks.GetArrayLength() <= MaxBlocks;

    private static bool IsHttpUrl(string? url) =>
        url is { Length: <= 2048 } && Uri.TryCreate(url, UriKind.Absolute, out var uri) && uri.Scheme is "http" or "https";
}

internal sealed class CreateArticleDraftCommandValidator : AbstractValidator<CreateArticleDraftCommand>
{
    public CreateArticleDraftCommandValidator(IFileStorage storage) =>
        RuleFor(c => c.Document).NotNull().SetValidator(new ArticleDraftDocumentValidator(storage));
}

internal sealed class SaveArticleDraftCommandValidator : AbstractValidator<SaveArticleDraftCommand>
{
    public SaveArticleDraftCommandValidator(IFileStorage storage)
    {
        RuleFor(c => c.BaseVersion).GreaterThanOrEqualTo(0);
        RuleFor(c => c.Document).NotNull().SetValidator(new ArticleDraftDocumentValidator(storage));
    }
}
