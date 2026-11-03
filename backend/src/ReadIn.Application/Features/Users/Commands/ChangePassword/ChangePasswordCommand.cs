using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.ChangePassword;

/// <summary>Settings → Account (SPEC F18). Every other session is signed out; this device gets a fresh session.</summary>
[Authenticated]
public sealed record ChangePasswordCommand(string CurrentPassword, string NewPassword) : ICommand<Result<AuthSessionDto>>;

internal sealed class ChangePasswordCommandValidator : AbstractValidator<ChangePasswordCommand>
{
    public ChangePasswordCommandValidator()
    {
        RuleFor(c => c.CurrentPassword).NotEmpty().MaximumLength(PasswordRules.MaxLength);
        RuleFor(c => c.NewPassword).Password(_ => null);
    }
}
