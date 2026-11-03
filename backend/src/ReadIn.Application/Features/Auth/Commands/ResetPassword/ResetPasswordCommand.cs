using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.ResetPassword;

/// <summary>Forgot password, step 2 (SPEC §9.2): the reset token + a new password. Every session is signed out.</summary>
public sealed record ResetPasswordCommand(string ResetToken, string NewPassword) : ICommand<Result>;

internal sealed class ResetPasswordCommandValidator : AbstractValidator<ResetPasswordCommand>
{
    public ResetPasswordCommandValidator()
    {
        RuleFor(c => c.ResetToken).NotEmpty().MaximumLength(100);
        // The rule that needs the account's number runs in the handler.
        RuleFor(c => c.NewPassword).Password(_ => null);
    }
}
