using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Follows.Commands.FollowInterest;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Follows.Commands.UnfollowInterest;

internal sealed class UnfollowInterestCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UnfollowInterestCommand, Result<InterestsDto>>
{
    public async ValueTask<Result<InterestsDto>> Handle(UnfollowInterestCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.Interests).FirstAsync(u => u.Id == userId, cancellationToken);

        var result = command.Target == InterestTarget.Field
            ? user.UnfollowField(command.TargetId)
            : user.UnfollowTopic(command.TargetId);
        if (result.IsFailure) return result.Error;

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            // Removed by a concurrent request: answer with what is stored.
            return await Interests.ReadAsync(db, userId, cancellationToken);
        }
        return Interests.Of(user);
    }
}
