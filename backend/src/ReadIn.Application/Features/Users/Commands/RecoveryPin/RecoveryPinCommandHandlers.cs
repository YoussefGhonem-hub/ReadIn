using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.RecoveryPin;

internal sealed class SetRecoveryPinCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IRecoveryPinHasher pins,
    IOptions<RecoveryOptions> recovery,
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

        var pin = RecoveryPinRules.Normalize(command.Pin);
        var violations = RecoveryPinRules.Check(pin, recovery.Value.PinLength, user.PhoneNumber, password: null);
        if (violations.Count > 0) return ValidationErrors.For(nameof(command.Pin), violations);

        user.SetRecoveryPin(pins.Hash(userId, pin), clock.GetUtcNow().UtcDateTime);
        audit.Record(AuditActions.RecoveryPinSet, userId);
        await db.SaveChangesAsync(cancellationToken);
        await access.InvalidateAsync(userId, cancellationToken);
        return await meReader.ReadAsync(userId, cancellationToken);
    }
}

internal sealed class ChangeRecoveryPinCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IRecoveryPinHasher pins,
    IOptions<RecoveryOptions> recovery,
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

        var pin = RecoveryPinRules.Normalize(command.NewPin);
        var violations = RecoveryPinRules.Check(pin, recovery.Value.PinLength, user.PhoneNumber, command.CurrentPassword);
        if (violations.Count > 0) return ValidationErrors.For(nameof(command.NewPin), violations);

        user.RecordSuccessfulSignIn();
        user.ChangeRecoveryPin(pins.Hash(userId, pin), clock.GetUtcNow().UtcDateTime);
        audit.Record(AuditActions.RecoveryPinChanged, userId);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
