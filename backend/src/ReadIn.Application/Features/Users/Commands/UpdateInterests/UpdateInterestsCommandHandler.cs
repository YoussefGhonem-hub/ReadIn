using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdateInterests;

internal sealed class UpdateInterestsCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UpdateInterestsCommand, Result>
{
    private static readonly Error UnknownInterest =
        Error.Validation("user.interests.unknown", "One or more fields or topics do not exist.");

    public async ValueTask<Result> Handle(UpdateInterestsCommand command, CancellationToken cancellationToken)
    {
        var fieldIds = command.FieldIds.Distinct().ToList();
        var topicIds = command.TopicIds.Distinct().ToList();

        var knownFields = await db.Fields.CountAsync(f => fieldIds.Contains(f.Id) && f.IsEnabled, cancellationToken);
        var knownTopics = await db.Topics.CountAsync(t => topicIds.Contains(t.Id), cancellationToken);
        if (knownFields != fieldIds.Count || knownTopics != topicIds.Count) return UnknownInterest;

        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.Interests).FirstAsync(u => u.Id == userId, cancellationToken);

        var result = user.SetInterests(fieldIds, topicIds);
        if (result.IsFailure) return result;

        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
