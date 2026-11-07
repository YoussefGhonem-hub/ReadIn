using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Follows.Commands.FollowInterest;

internal sealed class FollowInterestCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<FollowInterestCommand, Result<InterestsDto>>
{
    public async ValueTask<Result<InterestsDto>> Handle(FollowInterestCommand command, CancellationToken cancellationToken)
    {
        if (command.Target == InterestTarget.Field)
        {
            if (!await db.Fields.AnyAsync(f => f.Id == command.TargetId && f.IsEnabled, cancellationToken)) return TaxonomyErrors.FieldNotFound;
        }
        else if (!await db.Topics.AnyAsync(t => t.Id == command.TargetId && t.IsEnabled, cancellationToken))
        {
            return TaxonomyErrors.TopicNotFound;
        }

        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.Interests).FirstAsync(u => u.Id == userId, cancellationToken);
        if (command.Target == InterestTarget.Field) user.FollowField(command.TargetId);
        else user.FollowTopic(command.TargetId);

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // Followed by a concurrent request (unique index): answer with what is stored.
            return await Interests.ReadAsync(db, userId, cancellationToken);
        }
        return Interests.Of(user);
    }
}

internal static class Interests
{
    public static InterestsDto Of(User user) => new(
        [.. user.Interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value)],
        [.. user.Interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value)]);

    public static async Task<InterestsDto> ReadAsync(IAppDbContext db, Guid userId, CancellationToken ct)
    {
        var interests = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .SelectMany(u => u.Interests)
            .Select(i => new { i.FieldId, i.TopicId })
            .ToListAsync(ct);
        return new InterestsDto(
            [.. interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value)],
            [.. interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value)]);
    }
}
