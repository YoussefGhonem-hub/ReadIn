using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Follows.Commands.FollowUser;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Mutes.Commands.UnmuteUser;

internal sealed class UnmuteUserCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<UnmuteUserCommand, Result<UserMuteStateDto>>
{
    public async ValueTask<Result<UserMuteStateDto>> Handle(UnmuteUserCommand command, CancellationToken cancellationToken)
    {
        var muterId = currentUser.RequireUserId();
        var userId = command.UserId;
        if (!await db.Users.AnyAsync(u => u.Id == userId, cancellationToken)) return UserErrors.NotFound;

        await db.UserMutes.Where(m => m.MuterId == muterId && m.MutedUserId == userId).ExecuteDeleteAsync(cancellationToken);

        // The toast's Undo: follow again as PUT /users/{id}/follow does (a same-day re-follow is no news, F17).
        if (command.RestoreFollow && userId != muterId)
        {
            var followed = await FollowUserCommandHandler.FollowAsync(db, muterId, userId, clock.GetUtcNow().UtcDateTime, cancellationToken);
            if (followed.IsFailure) return followed.Error;
        }

        return await db.UserMuteStateAsync(muterId, userId, followRemoved: false, cancellationToken);
    }
}
