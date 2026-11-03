using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.AddPhoneSignIn;

/// <summary>
/// Settings → Account for a Google/Apple account (SPEC F18): add phone + password + recovery PIN, confirmed with a fresh
/// token of a linked identity. Other sessions are signed out and this one gets fresh tokens, like a password change.
/// </summary>
[Authenticated]
public sealed record AddPhoneSignInCommand(string PhoneNumber, string Password, string RecoveryPin, ExternalCredentialDto External)
    : ICommand<Result<AuthSessionDto>>;

internal sealed class AddPhoneSignInCommandValidator : AbstractValidator<AddPhoneSignInCommand>
{
    public AddPhoneSignInCommandValidator(IOptions<RecoveryOptions> recovery)
    {
        RuleFor(c => c.PhoneNumber).PhoneNumber();
        RuleFor(c => c.Password).Password(c => c.PhoneNumber);
        RuleFor(c => c.RecoveryPin).RecoveryPin(recovery.Value.PinLength, c => c.PhoneNumber, c => c.Password);
        RuleFor(c => c.External).NotNull().SetValidator(new ExternalCredentialValidator());
    }
}

internal sealed class AddPhoneSignInCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IdentityConfirmation confirmation,
    IPasswordHasher passwords,
    IRecoveryPinHasher pins,
    SessionIssuer sessions,
    AuditTrail audit,
    TimeProvider clock)
    : ICommandHandler<AddPhoneSignInCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(AddPhoneSignInCommand command, CancellationToken cancellationToken)
    {
        if (!PhoneNumberRules.TryNormalize(command.PhoneNumber, out var phone))
            return Error.Validation(CredentialValidators.PhoneInvalid, "The phone number is not valid.");

        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.ExternalLogins).FirstAsync(u => u.Id == userId, cancellationToken);
        if (user.HasPassword) return CredentialErrors.PhoneSignInExists;

        if (await confirmation.ConfirmAsync(user, password: null, command.External, cancellationToken) is { } error) return error;

        if (await IsTakenAsync(phone, cancellationToken)) return CredentialErrors.PhoneTaken;

        var added = user.AddPhoneSignIn(phone, passwords.Hash(command.Password));
        if (added.IsFailure) return added.Error;
        user.SetRecoveryPin(pins.Hash(userId, RecoveryPinRules.Normalize(command.RecoveryPin)), clock.GetUtcNow().UtcDateTime);
        await sessions.RevokeAllAsync(userId, cancellationToken);
        audit.Record(AuditActions.PhoneSignInAdded, userId);

        try
        {
            return await sessions.StartAsync(user, cancellationToken);
        }
        catch (DbUpdateException)
        {
            if (await IsTakenAsync(phone, cancellationToken)) return CredentialErrors.PhoneTaken; // signed up concurrently
            throw;
        }
    }

    private Task<bool> IsTakenAsync(string phone, CancellationToken ct) =>
        db.Users.IgnoreQueryFilters().AsNoTracking().AnyAsync(u => u.PhoneNumber == phone, ct);
}
