using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.CompleteProfile;

/// <summary>After sign up (SPEC §9.2): display name, unique @username and an optional avatar from <c>POST /uploads/images</c>.</summary>
[Authenticated]
public sealed record CompleteProfileCommand(string DisplayName, string Username, string? AvatarUrl = null) : ICommand<Result<MeDto>>;

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
    }
}
