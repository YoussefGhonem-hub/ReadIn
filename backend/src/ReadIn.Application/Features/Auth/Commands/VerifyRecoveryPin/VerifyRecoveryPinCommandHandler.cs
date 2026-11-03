using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Commands.VerifyRecoveryPin;

/// <summary>
/// Recovery (SPEC §9.5): one generic error for a wrong number or PIN, 5 attempts an hour per number, 5 wrong PINs lock
/// recovery for an hour, and the third lockout within 7 days disables it until an Admin reset.
/// </summary>
internal sealed class VerifyRecoveryPinCommandHandler(
    IAppDbContext db,
    IRecoveryPinHasher pins,
    IClientInfo client,
    AuditTrail audit,
    TimeProvider clock)
    : ICommandHandler<VerifyRecoveryPinCommand, Result<PasswordResetTokenDto>>
{
    private const int AttemptsPerHour = 5;

    public async ValueTask<Result<PasswordResetTokenDto>> Handle(VerifyRecoveryPinCommand command, CancellationToken cancellationToken)
    {
        var pin = RecoveryPinRules.Normalize(command.Pin);
        if (!PhoneNumberRules.TryNormalize(command.PhoneNumber, out var phone))
        {
            pins.VerifyAgainstDummy(pin);
            return CredentialErrors.RecoveryInvalid;
        }

        var now = clock.GetUtcNow().UtcDateTime;
        var phoneHash = pins.HashPhoneNumber(phone);
        var since = now.AddHours(-1);
        if (await db.RecoveryAttempts.CountAsync(a => a.PhoneNumberHash == phoneHash && a.CreatedAt > since, cancellationToken) >= AttemptsPerHour)
            return CredentialErrors.TooManyAttempts;

        var user = await db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone, cancellationToken);
        if (user is null || !user.CanSignIn || !user.HasRecoveryPin)
        {
            pins.VerifyAgainstDummy(pin);
            return await FailAsync(user?.Id, phoneHash, now, CredentialErrors.RecoveryInvalid, cancellationToken);
        }

        if (user.RecoveryDisabled) return await FailAsync(user.Id, phoneHash, now, CredentialErrors.RecoveryDisabled, cancellationToken);
        if (user.IsRecoveryLockedAt(now)) return await FailAsync(user.Id, phoneHash, now, CredentialErrors.RecoveryLocked, cancellationToken);

        if (!pins.Verify(user.Id, user.RecoveryPinHash!, pin))
        {
            if (!user.RecordFailedRecovery(now))
                return await FailAsync(user.Id, phoneHash, now, CredentialErrors.RecoveryInvalid, cancellationToken);

            audit.Record(AuditActions.RecoveryLockedOut, user.Id);
            var error = user.RecoveryDisabled ? CredentialErrors.RecoveryDisabled : CredentialErrors.RecoveryLocked;
            return await FailAsync(user.Id, phoneHash, now, error, cancellationToken);
        }

        user.RecordSuccessfulRecovery();
        var (token, hash) = SecretTokens.Create();
        var reset = PasswordResetToken.Issue(user.Id, hash, now, client.IpAddress);
        db.PasswordResetTokens.Add(reset);
        db.RecoveryAttempts.Add(RecoveryAttempt.Record(user.Id, phoneHash, client.IpAddress, succeeded: true, now));
        await db.SaveChangesAsync(cancellationToken);

        return new PasswordResetTokenDto(token, reset.ExpiresAt);
    }

    private async Task<Result<PasswordResetTokenDto>> FailAsync(Guid? userId, string phoneHash, DateTime now, Error error, CancellationToken ct)
    {
        db.RecoveryAttempts.Add(RecoveryAttempt.Record(userId, phoneHash, client.IpAddress, succeeded: false, now));
        await db.SaveChangesAsync(ct);
        return error;
    }
}
