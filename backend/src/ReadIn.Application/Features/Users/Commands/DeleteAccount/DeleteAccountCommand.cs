using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;

namespace ReadIn.Application.Features.Users.Commands.DeleteAccount;

/// <summary>
/// Delete account (SPEC F01): requires the password. The account is soft-deleted and signed out everywhere at once; its
/// personal data is removed after 30 days, and its articles and comments stay as "Deleted user".
/// </summary>
[Authenticated]
public sealed record DeleteAccountCommand(string Password) : ICommand<Result>;

internal sealed class DeleteAccountCommandValidator : AbstractValidator<DeleteAccountCommand>
{
    public DeleteAccountCommandValidator() => RuleFor(c => c.Password).NotEmpty().MaximumLength(PasswordRules.MaxLength);
}

internal sealed class DeleteAccountCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    PasswordConfirmation confirmation,
    SessionIssuer sessions,
    IUserAccessService access,
    AuditTrail audit)
    : ICommandHandler<DeleteAccountCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteAccountCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.Devices).FirstAsync(u => u.Id == userId, cancellationToken);

        if (await confirmation.ConfirmAsync(user, command.Password, cancellationToken) is { } error) return error;

        foreach (var token in user.Devices.Select(d => d.Token).ToList()) user.UnregisterDevice(token); // no more pushes
        user.RotateSecurityStamp();
        await sessions.RevokeAllAsync(userId, cancellationToken);
        db.Users.Remove(user); // soft delete (SPEC §16.1)
        audit.Record(AuditActions.AccountDeleted, userId);
        await db.SaveChangesAsync(cancellationToken);
        await access.InvalidateAsync(userId, cancellationToken);
        return Result.Success();
    }
}
