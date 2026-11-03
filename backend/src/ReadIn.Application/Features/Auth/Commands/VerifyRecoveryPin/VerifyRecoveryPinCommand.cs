using FluentValidation;
using Mediator;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.VerifyRecoveryPin;

/// <summary>Forgot password, step 1 (SPEC §9.2): phone + recovery PIN → a 10-minute reset token.</summary>
public sealed record VerifyRecoveryPinCommand(string PhoneNumber, string Pin) : ICommand<Result<PasswordResetTokenDto>>;

internal sealed class VerifyRecoveryPinCommandValidator : AbstractValidator<VerifyRecoveryPinCommand>
{
    public VerifyRecoveryPinCommandValidator()
    {
        RuleFor(c => c.PhoneNumber).NotEmpty().MaximumLength(32);
        RuleFor(c => c.Pin).NotEmpty().MaximumLength(12);
    }
}
