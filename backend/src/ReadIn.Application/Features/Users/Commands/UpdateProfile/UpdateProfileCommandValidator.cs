using FluentValidation;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.UpdateProfile;

internal sealed class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
{
    public UpdateProfileCommandValidator(IFileStorage storage)
    {
        RuleFor(c => c.DisplayName).NotEmpty().Length(2, 60);
        RuleFor(c => c.Username)
            .Must(User.IsValidUsername)
            .WithErrorCode("user.username_invalid");
        RuleFor(c => c.Bio).MaximumLength(300);
        // An uploaded avatar (relative path or its public URL), or any external https image (e.g. the sign-in provider's photo).
        RuleFor(c => c.Avatar!.Url)
            .Must(url => storage.TryGetUploadPath(url, out var path) ? path.Purpose == UploadPurpose.Avatar : BeHttpsUrl(url!))
            .When(c => c.Avatar?.Url is not null)
            .WithErrorCode("validation.url")
            .OverridePropertyName("avatarUrl");
        RuleFor(c => c.Links!.GitHub).Must(BeHttpsUrl!).When(c => c.Links?.GitHub is not null).WithErrorCode("validation.url");
        RuleFor(c => c.Links!.LinkedIn).Must(BeHttpsUrl!).When(c => c.Links?.LinkedIn is not null).WithErrorCode("validation.url");
        RuleFor(c => c.Links!.Website).Must(BeHttpsUrl!).When(c => c.Links?.Website is not null).WithErrorCode("validation.url");
    }

    private static bool BeHttpsUrl(string value) =>
        value.Length <= 2048 && Uri.TryCreate(value, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps;
}
