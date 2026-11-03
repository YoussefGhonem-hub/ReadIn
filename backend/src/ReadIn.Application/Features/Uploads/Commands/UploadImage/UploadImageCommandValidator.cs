using FluentValidation;
using ReadIn.Application.Common.Uploads;

namespace ReadIn.Application.Features.Uploads.Commands.UploadImage;

internal sealed class UploadImageCommandValidator : AbstractValidator<UploadImageCommand>
{
    public UploadImageCommandValidator()
    {
        RuleFor(c => c.Purpose).Must(p => UploadPurpose.FromName(p) is not null).WithErrorCode(UploadErrors.PurposeInvalid.Code);
        RuleFor(c => c.Length).GreaterThan(0).WithErrorCode(UploadErrors.Empty.Code)
            .LessThanOrEqualTo(UploadLimits.MaxBytes).WithErrorCode(UploadErrors.TooLarge.Code)
            .OverridePropertyName("file");
    }
}
