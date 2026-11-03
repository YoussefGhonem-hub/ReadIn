using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.RegisterDevice;

internal sealed class RegisterDeviceCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<RegisterDeviceCommand, Result>
{
    public async ValueTask<Result> Handle(RegisterDeviceCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.Devices).FirstAsync(u => u.Id == userId, cancellationToken);

        user.RegisterDevice(command.Token, command.Platform, clock.GetUtcNow().UtcDateTime);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
