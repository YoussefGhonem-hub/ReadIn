using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.ChangePhoneNumber;

internal sealed class ChangePhoneNumberCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    PasswordConfirmation confirmation,
    SessionIssuer sessions,
    AuditTrail audit)
    : ICommandHandler<ChangePhoneNumberCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(ChangePhoneNumberCommand command, CancellationToken cancellationToken)
    {
        if (!PhoneNumberRules.TryNormalize(command.NewPhoneNumber, out var phone))
            return Error.Validation(CredentialValidators.PhoneInvalid, "The phone number is not valid.");

        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);
        if (user.PhoneNumber == phone) return CredentialErrors.PhoneUnchanged;

        if (await confirmation.ConfirmAsync(user, command.CurrentPassword, cancellationToken) is { } error) return error;

        if (await db.Users.IgnoreQueryFilters().AnyAsync(u => u.PhoneNumber == phone, cancellationToken))
            return CredentialErrors.PhoneTaken;

        user.RecordSuccessfulSignIn();
        user.ChangePhoneNumber(phone);
        await sessions.RevokeAllAsync(userId, cancellationToken);
        audit.Record(AuditActions.PhoneNumberChanged, userId);
        return await sessions.StartAsync(user, cancellationToken);
    }
}
