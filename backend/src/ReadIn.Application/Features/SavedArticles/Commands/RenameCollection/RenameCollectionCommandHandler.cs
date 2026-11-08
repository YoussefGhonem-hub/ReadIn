using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.RenameCollection;

internal sealed class RenameCollectionCommandHandler(IAppDbContext db, ICurrentUser currentUser, ContentFilter.ContentScreening screening)
    : ICommandHandler<RenameCollectionCommand, Result<CollectionDto>>
{
    public async ValueTask<Result<CollectionDto>> Handle(RenameCollectionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var name = command.Name.Trim();
        // F37: a block-level term refuses the name; collections are private, so a flag reports nothing.
        var screened = await screening.ScreenAsync([new ContentFilter.ScreenedField("name", name)], cancellationToken);
        if (screened.IsFailure) return screened.Error;

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
