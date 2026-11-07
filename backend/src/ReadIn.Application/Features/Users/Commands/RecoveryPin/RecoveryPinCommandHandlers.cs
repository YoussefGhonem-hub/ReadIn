using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.RecoveryPin;

/// <remarks>The validator has already checked the PIN: digits only, <c>Recovery:PinLength</c> of them.</remarks>
internal sealed class SetRecoveryPinCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IRecoveryPinHasher pins,
    IUserAccessService access,
    AuditTrail audit,
    MeReader meReader,
    TimeProvider clock)
    : ICommandHandler<SetRecoveryPinCommand, Result<MeDto>>
{
    public async ValueTask<Result<MeDto>> Handle(SetRecoveryPinCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);
        if (user.HasRecoveryPin && !user.MustSetRecoveryPin) return CredentialErrors.PinAlreadySet;

        user.SetRecoveryPin(pins.Hash(userId, RecoveryPinRules.Normalize(command.Pin)), clock.GetUtcNow().UtcDateTime);
        audit.Record(AuditActions.RecoveryPinSet, userId);
        await db.SaveChangesAsync(cancellationToken);
        await access.InvalidateAsync(userId, cancellationToken);
        return await meReader.ReadAsync(userId, cancellationToken);
    }
}

/// <remarks>The validator has already checked the new PIN: digits only, <c>Recovery:PinLength</c> of them.</remarks>
internal sealed class ChangeRecoveryPinCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IRecoveryPinHasher pins,
    PasswordConfirmation confirmation,
    AuditTrail audit,
    TimeProvider clock)
    : ICommandHandler<ChangeRecoveryPinCommand, Result>
{
    public async ValueTask<Result> Handle(ChangeRecoveryPinCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        if (await confirmation.ConfirmAsync(user, command.CurrentPassword, cancellationToken) is { } error) return error;

        user.RecordSuccessfulSignIn();
        user.ChangeRecoveryPin(pins.Hash(userId, RecoveryPinRules.Normalize(command.NewPin)), clock.GetUtcNow().UtcDateTime);
        audit.Record(AuditActions.RecoveryPinChanged, userId);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
