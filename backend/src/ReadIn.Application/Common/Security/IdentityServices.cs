using ReadIn.Application.Common.Interfaces;
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
