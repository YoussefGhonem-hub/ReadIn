using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Common.Security;

/// <summary>Adds an <see cref="AuditLog"/> row, saved with the handler's unit of work (SPEC §9.5).</summary>
internal sealed class AuditTrail(IAppDbContext db, ICurrentUser currentUser, IClientInfo client, TimeProvider clock)
{
    public void Record(string action, Guid? userId) =>
        db.AuditLogs.Add(AuditLog.Record(action, currentUser.UserId, userId, client.IpAddress, clock.GetUtcNow().UtcDateTime));
}

/// <summary>
/// Sensitive account changes ask for the current password (SPEC F18). Wrong answers count toward the same 15-minute
/// lockout as sign in, so these endpoints can't be used to guess it.
/// </summary>
internal sealed class PasswordConfirmation(IAppDbContext db, IPasswordHasher passwords, TimeProvider clock)
{
    public async Task<Error?> ConfirmAsync(User user, string? password, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        if (user.IsLockedOutAt(now)) return CredentialErrors.LockedOut;

        if (user.PasswordHash is not null && !string.IsNullOrEmpty(password) &&
            passwords.Verify(user.PasswordHash, password) != PasswordCheck.Failed)
            return null;

        var locked = user.RecordFailedSignIn(now);
        await db.SaveChangesAsync(ct);
        return locked ? CredentialErrors.LockedOut : CredentialErrors.WrongPassword;
    }
}

/// <summary>
/// "Confirm it's you" for sensitive changes (SPEC F18): the current password, or a fresh Google/Apple token of an
/// identity linked to the account (the only option for accounts without a password). Needs
/// <see cref="User.ExternalLogins"/> loaded.
/// </summary>
internal sealed class IdentityConfirmation(PasswordConfirmation passwords, IExternalIdentityVerifier externalIdentities)
{
    public async Task<Error?> ConfirmAsync(User user, string? password, ExternalCredentialDto? external, CancellationToken ct)
    {
        var confirmed = await ConfirmWithIdentityAsync(user, password, external, ct);
        return confirmed.IsFailure ? confirmed.Error : null;
    }

    /// <summary>Like <see cref="ConfirmAsync"/>, and returns the Google/Apple identity it was confirmed with (null for the password).</summary>
    public async Task<Result<ExternalIdentity?>> ConfirmWithIdentityAsync(
        User user, string? password, ExternalCredentialDto? external, CancellationToken ct)
    {
        if (!string.IsNullOrEmpty(password))
        {
            if (await passwords.ConfirmAsync(user, password, ct) is { } error) return error;
            return Result.Success<ExternalIdentity?>(null);
        }
        if (external is null) return CredentialErrors.ConfirmationRequired;

        var identity = await externalIdentities.VerifyAsync(external.Provider, external.IdToken, external.Nonce, ct);
        if (identity.IsFailure) return identity.Error;
        if (user.FindExternalLogin(identity.Value.Provider)?.Subject != identity.Value.Subject) return CredentialErrors.ExternalMismatch;
        return identity.Value;
    }
}

/// <summary>
/// Phone + password check shared by sign in and "link my phone account" (SPEC §9.2, §9.5): one generic error for a wrong
/// number or password, the same timing for unknown numbers, 5 attempts a minute per number, and 5 wrong passwords lock the
/// account for 15 minutes. Changes on success are saved by the caller's session.
/// </summary>
internal sealed class PasswordSignIn(IAppDbContext db, IPasswordHasher passwords, IAttemptThrottle throttle, TimeProvider clock)
{
    public async Task<Result<User>> AuthenticateAsync(string phoneNumber, string password, CancellationToken ct)
    {
        if (!PhoneNumberRules.TryNormalize(phoneNumber, out var phone))
        {
            passwords.VerifyAgainstDummy(password);
            return CredentialErrors.InvalidCredentials;
        }

        if (!throttle.TryAcquire($"sign-in:{phone}", limit: 5, TimeSpan.FromMinutes(1))) return CredentialErrors.TooManyAttempts;

        var user = await db.Users.Include(u => u.ExternalLogins).FirstOrDefaultAsync(u => u.PhoneNumber == phone, ct);
        if (user is null || !user.CanSignInWithPassword)
        {
            passwords.VerifyAgainstDummy(password);
            return CredentialErrors.InvalidCredentials;
        }

        var now = clock.GetUtcNow().UtcDateTime;
        if (user.IsLockedOutAt(now)) return CredentialErrors.LockedOut;

        var check = passwords.Verify(user.PasswordHash!, password);
        if (check == PasswordCheck.Failed)
        {
            var locked = user.RecordFailedSignIn(now);
            await db.SaveChangesAsync(ct);
            return locked ? CredentialErrors.LockedOut : CredentialErrors.InvalidCredentials;
        }

        if (user.IsSuspendedAt(now)) return UserErrors.Suspended;

        user.RecordSuccessfulSignIn();
        if (check == PasswordCheck.SuccessRehashNeeded) user.UpgradePasswordHash(passwords.Hash(password));
        return user;
    }
}
