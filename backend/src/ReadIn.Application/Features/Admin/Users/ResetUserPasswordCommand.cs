using System.Security.Cryptography;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Admin.Users;

/// <summary>Shown once to the admin, who passes it to the user through support. The user must change it on sign in.</summary>
public sealed record TemporaryPasswordDto(string TemporaryPassword);

/// <summary>
/// "Forgot the PIN too" → support → Admin reset (SPEC §9.5): temporary password + <c>MustChangePassword</c>, PIN cleared
/// + <c>MustSetRecoveryPin</c>, recovery re-enabled, every session revoked, audit log entry.
/// </summary>
[RequirePermission(Permissions.Users.ResetPassword)]
public sealed record ResetUserPasswordCommand(Guid UserId) : ICommand<Result<TemporaryPasswordDto>>;

internal sealed class ResetUserPasswordCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IPasswordHasher passwords,
    SessionIssuer sessions,
    IUserAccessService access,
    AuditTrail audit)
    : ICommandHandler<ResetUserPasswordCommand, Result<TemporaryPasswordDto>>
{
    // No look-alike characters (0/O, 1/l/I), so it can be read out over the phone.
    private const string Letters = "abcdefghjkmnpqrstuvwxyz";
    private const string Digits = "23456789";

    public async ValueTask<Result<TemporaryPasswordDto>> Handle(ResetUserPasswordCommand command, CancellationToken cancellationToken)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == command.UserId, cancellationToken);
        if (user is null || !user.CanSignInWithPassword) return UserErrors.NotFound;
        // Taking over an account that can do more than you would be a way around the permissions: only a SuperAdmin
        // resets a SuperAdmin. Today only the SuperAdmin holds users.reset_password; this keeps a staff role safe later.
        var target = await access.GetAsync(user.Id, cancellationToken);
        if (target is not null && !target.Permissions.All(currentUser.Permissions.Contains)) return AuthErrors.Forbidden;

        var temporary = NewTemporaryPassword();
        user.ResetByAdmin(passwords.Hash(temporary));
        await sessions.RevokeAllAsync(user.Id, cancellationToken);
        audit.Record(AuditActions.AdminPasswordReset, user.Id);
        await db.SaveChangesAsync(cancellationToken);
        await access.InvalidateAsync(user.Id, cancellationToken);
        return new TemporaryPasswordDto(temporary);
    }

    /// <summary>12 characters, letters and digits, so it passes the password rules.</summary>
    private static string NewTemporaryPassword()
    {
        var chars = RandomNumberGenerator.GetString(Letters + Digits, 10) + RandomNumberGenerator.GetString(Letters, 1) + RandomNumberGenerator.GetString(Digits, 1);
        return new string(RandomNumberGenerator.GetItems<char>(chars, chars.Length));
    }
}
