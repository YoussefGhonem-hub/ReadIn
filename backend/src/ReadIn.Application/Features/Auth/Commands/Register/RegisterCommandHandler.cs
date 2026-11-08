using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Commands.Register;

internal sealed class RegisterCommandHandler(
    IAppDbContext db,
    IPasswordHasher passwords,
    IRecoveryPinHasher pins,
    SessionIssuer sessions,
    AuditTrail audit,
    Legal.TermsOfUse terms,
    TimeProvider clock)
    : ICommandHandler<RegisterCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(RegisterCommand command, CancellationToken cancellationToken)
    {
        // The terms box (SPEC F37) before anything else: nothing is created without it.
        var accepted = Legal.TermsOfUse.Require(command.AcceptTerms);
        if (accepted.IsFailure) return accepted.Error;
        if (!PhoneNumberRules.TryNormalize(command.PhoneNumber, out var phone)) return CredentialErrors.InvalidCredentials;
        // Soft-deleted accounts keep their number until they are anonymized (SPEC F01).
        if (await IsTakenAsync(phone, cancellationToken)) return CredentialErrors.PhoneTaken;

        var user = User.Register(
            phone,
            passwords.Hash(command.Password),
            await NewAccounts.PlaceholderUsernameAsync(db, cancellationToken),
            RoleIds.Member,
            command.UiLanguage,
            NewAccounts.ValidTimeZoneOrNull(command.TimeZone));
        db.Users.Add(user); // assigns the id that the PIN hash is bound to
        user.SetRecoveryPin(pins.Hash(user.Id, RecoveryPinRules.Normalize(command.RecoveryPin)), clock.GetUtcNow().UtcDateTime);
        audit.Record(AuditActions.SignUp, user.Id);
        user.AcceptTerms(terms.CurrentVersion, clock.GetUtcNow().UtcDateTime);
        audit.Record(AuditActions.TermsAccepted, user.Id, AuditTargets.User, user.Id, terms.CurrentVersion);

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
