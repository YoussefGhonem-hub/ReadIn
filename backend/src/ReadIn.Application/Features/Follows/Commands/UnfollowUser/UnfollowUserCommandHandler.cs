using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Follows.Commands.UnfollowUser;

internal sealed class UnfollowUserCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UnfollowUserCommand, Result<FollowStateDto>>
{
    public async ValueTask<Result<FollowStateDto>> Handle(UnfollowUserCommand command, CancellationToken cancellationToken)
    {
        var followerId = currentUser.RequireUserId();
        var followeeId = command.UserId;
        if (!await db.Users.AnyAsync(u => u.Id == followeeId, cancellationToken)) return UserErrors.NotFound;
        if (followeeId == followerId) return FollowErrors.Self;

        var follow = await db.UserFollows.FirstOrDefaultAsync(f => f.FollowerId == followerId && f.FolloweeId == followeeId, cancellationToken);
        if (follow is not null)
        {
            db.UserFollows.Remove(follow);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateConcurrencyException)
            {
                // Unfollowed by a concurrent request: the outcome is the same.
            }
        }

        return await db.FollowStateAsync(followerId, followeeId, cancellationToken);
    }
}
