using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.CreateCollection;

internal sealed class CreateCollectionCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<CreateCollectionCommand, Result<CollectionDto>>
{
    public async ValueTask<Result<CollectionDto>> Handle(CreateCollectionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var name = command.Name.Trim();

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
