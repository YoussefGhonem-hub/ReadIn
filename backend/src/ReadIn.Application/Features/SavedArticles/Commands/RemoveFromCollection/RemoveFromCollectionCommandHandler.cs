using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.RemoveFromCollection;

internal sealed class RemoveFromCollectionCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<RemoveFromCollectionCommand, Result>
{
    public async ValueTask<Result> Handle(RemoveFromCollectionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var collection = await db.FindOwnCollectionAsync(command.CollectionId, userId, command.ArticleId, cancellationToken);
        if (collection is null) return CollectionErrors.NotFound;
        if (!await db.Articles.Visible().AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        if (!collection.RemoveArticle(command.ArticleId)) return Result.Success();
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            // Removed by a concurrent request: the outcome is the same.
        }
        return Result.Success();
    }
}
