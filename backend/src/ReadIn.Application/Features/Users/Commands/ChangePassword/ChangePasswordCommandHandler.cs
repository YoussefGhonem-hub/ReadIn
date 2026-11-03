using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;

namespace ReadIn.Application.Features.Users.Commands.ChangePassword;

internal sealed class ChangePasswordCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IPasswordHasher passwords,
    PasswordConfirmation confirmation,
    SessionIssuer sessions,
    AuditTrail audit)
    : ICommandHandler<ChangePasswordCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(ChangePasswordCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        if (await confirmation.ConfirmAsync(user, command.CurrentPassword, cancellationToken) is { } error) return error;

        var violations = PasswordRules.Check(command.NewPassword, user.PhoneNumber);
        if (violations.Count > 0) return ValidationErrors.For(nameof(command.NewPassword), violations);

        user.RecordSuccessfulSignIn();
        user.ChangePassword(passwords.Hash(command.NewPassword));
        await sessions.RevokeAllAsync(userId, cancellationToken);
        audit.Record(AuditActions.PasswordChanged, userId);
        return await sessions.StartAsync(user, cancellationToken);
    }
}
