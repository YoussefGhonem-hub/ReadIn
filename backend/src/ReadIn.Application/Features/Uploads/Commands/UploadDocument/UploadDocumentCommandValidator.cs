using FluentValidation;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Commands.UploadDocument;

internal sealed class UploadDocumentCommandValidator : AbstractValidator<UploadDocumentCommand>
{
    public UploadDocumentCommandValidator()
    {
        RuleFor(c => c.Title).MaximumLength(MediaAsset.MaxTitleLength).WithErrorCode("attachments.title_too_long");
        RuleFor(c => c.FileName).MaximumLength(255);
    }
}
