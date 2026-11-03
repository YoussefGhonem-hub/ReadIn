using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Commands.ResetPassword;

internal sealed class ResetPasswordCommandHandler(
    IAppDbContext db,
    IPasswordHasher passwords,
    IClientInfo client,
    IUserAccessService access,
    SessionIssuer sessions,
    AuditTrail audit,
    TimeProvider clock)
    : ICommandHandler<ResetPasswordCommand, Result>
{
    public async ValueTask<Result> Handle(ResetPasswordCommand command, CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var hash = SecretTokens.Hash(command.ResetToken);
        var token = await db.PasswordResetTokens.FirstOrDefaultAsync(t => t.TokenHash == hash, cancellationToken);
        if (token is null || !token.IsUsableAt(now, client.IpAddress)) return CredentialErrors.ResetTokenInvalid;

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == token.UserId, cancellationToken);
        if (user is null || !user.CanSignIn) return CredentialErrors.ResetTokenInvalid;

        var violations = PasswordRules.Check(command.NewPassword, user.PhoneNumber);
        if (violations.Count > 0) return ValidationErrors.For(nameof(command.NewPassword), violations);

        user.ResetPassword(passwords.Hash(command.NewPassword));
        token.MarkUsed(now);
        await sessions.RevokeAllAsync(user.Id, cancellationToken);
        audit.Record(AuditActions.PasswordReset, user.Id);
        await db.SaveChangesAsync(cancellationToken);
        await access.InvalidateAsync(user.Id, cancellationToken);
        return Result.Success();
    }
}
