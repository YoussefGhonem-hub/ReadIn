using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.CreateCollection;

internal sealed class CreateCollectionCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, ContentFilter.ContentScreening screening, TimeProvider clock)
    : ICommandHandler<CreateCollectionCommand, Result<CollectionDto>>
{
    public async ValueTask<Result<CollectionDto>> Handle(CreateCollectionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var name = command.Name.Trim();
        // F37: a block-level term refuses the name; collections are private, so a flag reports nothing.
        var screened = await screening.ScreenAsync([new ContentFilter.ScreenedField("name", name)], cancellationToken);
        if (screened.IsFailure) return screened.Error;

        var existing = await db.Collections.CountAsync(c => c.UserId == userId, cancellationToken);
        var created = Collection.Create(userId, name, existing, clock.GetUtcNow().UtcDateTime);
        if (created.IsFailure) return created.Error;
        if (await db.IsCollectionNameTakenAsync(userId, name, exceptId: null, cancellationToken)) return CollectionErrors.NameTaken;

        db.Collections.Add(created.Value);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // Created concurrently with the same name (unique index).
            if (await db.IsCollectionNameTakenAsync(userId, name, exceptId: null, cancellationToken)) return CollectionErrors.NameTaken;
            throw;
        }

        return await db.Collections.AsNoTracking().Where(c => c.Id == created.Value.Id).ToDtos(db).FirstAsync(cancellationToken);
    }
}
