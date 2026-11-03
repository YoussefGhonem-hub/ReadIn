using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.DeleteCollection;

internal sealed class DeleteCollectionCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<DeleteCollectionCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteCollectionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var collection = await db.Collections.FirstOrDefaultAsync(c => c.Id == command.CollectionId && c.UserId == userId, cancellationToken);
        if (collection is null) return CollectionErrors.NotFound;

        // The items go with it (cascade); the saved articles stay.
        db.Collections.Remove(collection);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
