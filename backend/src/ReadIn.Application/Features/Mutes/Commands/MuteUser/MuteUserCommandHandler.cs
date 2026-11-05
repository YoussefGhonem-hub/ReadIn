using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Mutes.Commands.MuteUser;

internal sealed class MuteUserCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<MuteUserCommand, Result<UserMuteStateDto>>
{
    public async ValueTask<Result<UserMuteStateDto>> Handle(MuteUserCommand command, CancellationToken cancellationToken)
    {
        var muterId = currentUser.RequireUserId();
        var userId = command.UserId;
        var target = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.IsSystemAccount })
            .FirstOrDefaultAsync(cancellationToken);
        if (target is null) return UserErrors.NotFound;
        if (userId == muterId) return MuteErrors.Self;
        if (target.IsSystemAccount) return MuteErrors.SystemAccount;

        // Under the muter's row lock, so the 500 limit holds for concurrent mutes and a repeat never races the unique index.
        var outcome = await db.LockedForUserAsync<Result<bool>>(muterId, async ct =>
        {
            if (!await db.UserMutes.AnyAsync(m => m.MuterId == muterId && m.MutedUserId == userId, ct))
            {
                if (await db.UserMutes.CountAsync(m => m.MuterId == muterId, ct) >= MuteErrors.MaxMutedUsers) return MuteErrors.Limit;

                var mute = UserMute.Create(muterId, userId, clock.GetUtcNow().UtcDateTime);
                if (mute.IsFailure) return mute.Error;
                db.UserMutes.Add(mute.Value);
                await db.SaveChangesAsync(ct);
            }

            // A mute ends your follow (SPEC F28); a repeated mute has nothing left to end.
            return await db.UserFollows.Where(f => f.FollowerId == muterId && f.FolloweeId == userId).ExecuteDeleteAsync(ct) > 0;
        }, cancellationToken);
        if (outcome.IsFailure) return outcome.Error;

        return await db.UserMuteStateAsync(muterId, userId, followRemoved: outcome.Value, cancellationToken);
    }
}
