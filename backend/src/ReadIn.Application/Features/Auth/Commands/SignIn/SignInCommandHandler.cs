using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Commands.SignIn;

/// <summary>
/// Sign in (SPEC §9.2, §9.5): one generic error for a wrong number or password, the same timing for unknown numbers,
/// 5 attempts a minute per number, and 5 wrong passwords lock the account for 15 minutes.
/// </summary>
internal sealed class SignInCommandHandler(
    IAppDbContext db,
    IPasswordHasher passwords,
    IAttemptThrottle throttle,
    SessionIssuer sessions,
    TimeProvider clock)
    : ICommandHandler<SignInCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(SignInCommand command, CancellationToken cancellationToken)
    {
        if (!PhoneNumberRules.TryNormalize(command.PhoneNumber, out var phone))
        {
            passwords.VerifyAgainstDummy(command.Password);
            return CredentialErrors.InvalidCredentials;
        }

        if (!throttle.TryAcquire($"sign-in:{phone}", limit: 5, TimeSpan.FromMinutes(1))) return CredentialErrors.TooManyAttempts;

        var user = await db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone, cancellationToken);
        if (user is null || !user.CanSignIn)
        {
            passwords.VerifyAgainstDummy(command.Password);
            return CredentialErrors.InvalidCredentials;
        }

        var now = clock.GetUtcNow().UtcDateTime;
        if (user.IsLockedOutAt(now)) return CredentialErrors.LockedOut;

        var check = passwords.Verify(user.PasswordHash!, command.Password);
        if (check == PasswordCheck.Failed)
        {
            var locked = user.RecordFailedSignIn(now);
            await db.SaveChangesAsync(cancellationToken);
            return locked ? CredentialErrors.LockedOut : CredentialErrors.InvalidCredentials;
        }

        if (user.IsSuspendedAt(now)) return UserErrors.Suspended;

        user.RecordSuccessfulSignIn();
        if (check == PasswordCheck.SuccessRehashNeeded) user.UpgradePasswordHash(passwords.Hash(command.Password));
        return await sessions.StartAsync(user, cancellationToken);
    }
}
