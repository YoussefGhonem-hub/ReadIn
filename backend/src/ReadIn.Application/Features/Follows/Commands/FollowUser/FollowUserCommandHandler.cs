using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Follows.Commands.FollowUser;

internal sealed class FollowUserCommandHandler(IAppDbContext db, ICurrentUser currentUser, BlockRelations blocks, TimeProvider clock)
    : ICommandHandler<FollowUserCommand, Result<FollowStateDto>>
{
    public async ValueTask<Result<FollowStateDto>> Handle(FollowUserCommand command, CancellationToken cancellationToken)
    {
        var followerId = currentUser.RequireUserId();
        var followeeId = command.UserId;
        if (!await db.Users.AnyAsync(u => u.Id == followeeId, cancellationToken)) return UserErrors.NotFound;
        // F36: neither of two people blocked with each other follows the other: the blocker gets 403 block.blocked, the
        // blocked person the same not-found as a deleted account.
        if (await blocks.ErrorForAsync(followerId, followeeId, UserErrors.NotFound, cancellationToken) is { } blocked) return blocked;

        var followed = await FollowAsync(db, followerId, followeeId, clock.GetUtcNow().UtcDateTime, cancellationToken);
        if (followed.IsFailure) return followed.Error;

        return await db.FollowStateAsync(followerId, followeeId, cancellationToken);
    }

    /// <summary>
    /// Follows <paramref name="followeeId"/> (idempotent) and ends a mute of them: following and muting never hold at once
    /// (SPEC F28). Also the Undo of a mute that ended a follow (<c>DELETE /users/{id}/mute?restoreFollow=true</c>).
    /// </summary>
    internal static async Task<Result> FollowAsync(IAppDbContext db, Guid followerId, Guid followeeId, DateTime now, CancellationToken ct)
    {
        if (!await IsFollowingAsync(db, followerId, followeeId, ct))
        {
            var follow = UserFollow.Create(followerId, followeeId, now);
            if (follow.IsFailure) return follow.Error;

            db.UserFollows.Add(follow.Value);
            try
            {
                await db.SaveChangesAsync(ct);
            }
            catch (DbUpdateException)
            {
                // Followed by a concurrent request (unique index): the outcome is the same.
                if (!await IsFollowingAsync(db, followerId, followeeId, ct)) throw;
            }
        }

        await db.UserMutes.Where(m => m.MuterId == followerId && m.MutedUserId == followeeId).ExecuteDeleteAsync(ct);
        return Result.Success();
    }

    private static Task<bool> IsFollowingAsync(IAppDbContext db, Guid followerId, Guid followeeId, CancellationToken ct) =>
        db.UserFollows.AsNoTracking().AnyAsync(f => f.FollowerId == followerId && f.FolloweeId == followeeId, ct);
}
