using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.CompleteProfile;

/// <summary>
/// After sign up (SPEC §9.2): display name, unique @username, an optional avatar from <c>POST /uploads/images</c> and an
/// optional title (F14; <see cref="Headline"/> null keeps the current one).
/// </summary>
[Authenticated]
public sealed record CompleteProfileCommand(string DisplayName, string Username, string? AvatarUrl = null, HeadlineChange? Headline = null)
    : ICommand<Result<MeDto>>;

internal sealed class CompleteProfileCommandValidator : AbstractValidator<CompleteProfileCommand>
{
    public CompleteProfileCommandValidator(IFileStorage storage)
    {
        RuleFor(c => c.DisplayName).NotEmpty().Length(2, 60);
        RuleFor(c => c.Username).Must(User.IsValidUsername).WithErrorCode("user.username_invalid");
        RuleFor(c => c.AvatarUrl)
            .Must(url => storage.TryGetUploadPath(url, out var path) && path.Purpose == UploadPurpose.Avatar)
            .When(c => c.AvatarUrl is not null)
            .WithErrorCode("validation.url");
        RuleFor(c => c.Headline).Custom((change, context) => UpdateProfile.UpdateProfileCommandValidator.AddHeadlineFailures(change, context));
    }
}
