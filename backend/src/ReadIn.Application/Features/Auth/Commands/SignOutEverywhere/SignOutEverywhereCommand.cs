using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;

namespace ReadIn.Application.Features.Auth.Commands.SignOutEverywhere;

/// <summary>Sign out of all devices (SPEC F01): every other session ends, and this device gets a fresh one.</summary>
[Authenticated]
public sealed record SignOutEverywhereCommand : ICommand<Result<AuthSessionDto>>;

internal sealed class SignOutEverywhereCommandHandler(IAppDbContext db, ICurrentUser currentUser, SessionIssuer sessions, AuditTrail audit)
    : ICommandHandler<SignOutEverywhereCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(SignOutEverywhereCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        user.RotateSecurityStamp();
        await sessions.RevokeAllAsync(userId, cancellationToken);
        audit.Record(AuditActions.SignedOutEverywhere, userId);
        return await sessions.StartAsync(user, cancellationToken);
    }
}
