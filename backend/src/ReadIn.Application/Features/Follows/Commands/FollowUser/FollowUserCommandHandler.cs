using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Follows.Commands.FollowUser;

internal sealed class FollowUserCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<FollowUserCommand, Result<FollowStateDto>>
{
    public async ValueTask<Result<FollowStateDto>> Handle(FollowUserCommand command, CancellationToken cancellationToken)
    {
        var followerId = currentUser.RequireUserId();
        var followeeId = command.UserId;
        if (!await db.Users.AnyAsync(u => u.Id == followeeId, cancellationToken)) return UserErrors.NotFound;

        if (!await IsFollowingAsync(followerId, followeeId, cancellationToken))
        {
            var follow = UserFollow.Create(followerId, followeeId, clock.GetUtcNow().UtcDateTime);
            if (follow.IsFailure) return follow.Error;

            db.UserFollows.Add(follow.Value);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                // Followed by a concurrent request (unique index): the outcome is the same.
                if (!await IsFollowingAsync(followerId, followeeId, cancellationToken)) throw;
            }
        }

        return await db.FollowStateAsync(followerId, followeeId, cancellationToken);
    }

    private Task<bool> IsFollowingAsync(Guid followerId, Guid followeeId, CancellationToken ct) =>
        db.UserFollows.AsNoTracking().AnyAsync(f => f.FollowerId == followerId && f.FolloweeId == followeeId, ct);
}
