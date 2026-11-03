using FluentValidation;
using Mediator;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.RecoveryPin;

/// <summary>
/// The mandatory "set recovery PIN" screen (SPEC §9.2), for accounts that have no PIN or were reset by an Admin.
/// Accounts that already have one change it with <see cref="ChangeRecoveryPinCommand"/>.
/// </summary>
[Authenticated]
public sealed record SetRecoveryPinCommand(string Pin) : ICommand<Result<MeDto>>;

/// <summary>"تغيير الـ PIN" (SPEC F18): current password + new PIN.</summary>
[Authenticated]
public sealed record ChangeRecoveryPinCommand(string CurrentPassword, string NewPin) : ICommand<Result>;

internal sealed class SetRecoveryPinCommandValidator : AbstractValidator<SetRecoveryPinCommand>
{
    public SetRecoveryPinCommandValidator(IOptions<RecoveryOptions> recovery)
    {
        // The rule that needs the account's number runs in the handler.
        RuleFor(c => c.Pin).RecoveryPin(recovery.Value.PinLength, _ => null, _ => null);
    }
}

internal sealed class ChangeRecoveryPinCommandValidator : AbstractValidator<ChangeRecoveryPinCommand>
{
    public ChangeRecoveryPinCommandValidator(IOptions<RecoveryOptions> recovery)
    {
        RuleFor(c => c.CurrentPassword).NotEmpty().MaximumLength(PasswordRules.MaxLength);
        RuleFor(c => c.NewPin).RecoveryPin(recovery.Value.PinLength, _ => null, c => c.CurrentPassword);
    }
}
