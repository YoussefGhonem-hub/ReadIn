using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.RenameCollection;

internal sealed class RenameCollectionCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<RenameCollectionCommand, Result<CollectionDto>>
{
    public async ValueTask<Result<CollectionDto>> Handle(RenameCollectionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var name = command.Name.Trim();

        var collection = await db.Collections.FirstOrDefaultAsync(c => c.Id == command.CollectionId && c.UserId == userId, cancellationToken);
        if (collection is null) return CollectionErrors.NotFound;
        if (await db.IsCollectionNameTakenAsync(userId, name, collection.Id, cancellationToken)) return CollectionErrors.NameTaken;

        collection.Rename(name);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            if (await db.IsCollectionNameTakenAsync(userId, name, collection.Id, cancellationToken)) return CollectionErrors.NameTaken;
            throw;
        }

        return await db.Collections.AsNoTracking().Where(c => c.Id == collection.Id).ToDtos(db).FirstAsync(cancellationToken);
    }
}
