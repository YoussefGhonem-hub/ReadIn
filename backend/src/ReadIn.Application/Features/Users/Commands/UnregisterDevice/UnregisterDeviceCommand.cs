using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UnregisterDevice;

/// <summary><c>DELETE /me/devices/{token}</c>, called on sign out so the device stops getting pushes. Idempotent.</summary>
[Authenticated]
public sealed record UnregisterDeviceCommand(string Token) : ICommand<Result>;

internal sealed class UnregisterDeviceCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UnregisterDeviceCommand, Result>
{
    public async ValueTask<Result> Handle(UnregisterDeviceCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.Devices).FirstAsync(u => u.Id == userId, cancellationToken);

        if (user.UnregisterDevice(command.Token)) await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
