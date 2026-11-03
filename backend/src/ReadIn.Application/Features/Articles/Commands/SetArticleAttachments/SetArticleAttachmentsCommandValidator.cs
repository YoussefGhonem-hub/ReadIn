using FluentValidation;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Articles.Commands.SetArticleAttachments;

internal sealed class SetArticleAttachmentsCommandValidator : AbstractValidator<SetArticleAttachmentsCommand>
{
    public SetArticleAttachmentsCommandValidator()
    {
        RuleFor(c => c.Items).NotNull();
        RuleFor(c => c.Items.Count).LessThanOrEqualTo(Article.MaxImageAttachments)
            .OverridePropertyName("items").WithErrorCode(AttachmentErrors.TooManyImages.Code);
        RuleForEach(c => c.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.MediaAssetId).NotEmpty();
            item.RuleFor(i => i.Order).GreaterThanOrEqualTo(0);
            item.RuleFor(i => i.Caption).MaximumLength(Article.MaxCaptionLength).WithErrorCode(AttachmentErrors.CaptionTooLong.Code);
            item.RuleFor(i => i.AltText).MaximumLength(Article.MaxAltTextLength).WithErrorCode(AttachmentErrors.AltTextTooLong.Code);
            item.RuleFor(i => i.Title).MaximumLength(MediaAsset.MaxTitleLength).WithErrorCode(AttachmentErrors.TitleTooLong.Code);
        });
    }
}
