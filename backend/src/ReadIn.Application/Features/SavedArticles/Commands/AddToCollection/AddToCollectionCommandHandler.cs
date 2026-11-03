using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.AddToCollection;

internal sealed class AddToCollectionCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<AddToCollectionCommand, Result>
{
    public async ValueTask<Result> Handle(AddToCollectionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var collection = await db.FindOwnCollectionAsync(command.CollectionId, userId, command.ArticleId, cancellationToken);
        if (collection is null) return CollectionErrors.NotFound;
        if (!await db.Articles.Visible().AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var now = clock.GetUtcNow().UtcDateTime;
        var wasSaved = await IsSavedAsync(userId, command.ArticleId, cancellationToken);
        if (!wasSaved) db.SavedArticles.Add(SavedArticle.Create(userId, command.ArticleId, now));
        var added = collection.AddArticle(command.ArticleId, now);
        if (wasSaved && !added) return Result.Success();

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // The same request ran twice at once: fine when the other one did the work.
            var inCollection = await db.CollectionItems.AsNoTracking()
                .AnyAsync(i => i.CollectionId == collection.Id && i.ArticleId == command.ArticleId, cancellationToken);
            if (!inCollection || !await IsSavedAsync(userId, command.ArticleId, cancellationToken)) throw;
        }

        return Result.Success();
    }

    private Task<bool> IsSavedAsync(Guid userId, Guid articleId, CancellationToken ct) =>
        db.SavedArticles.AsNoTracking().AnyAsync(s => s.UserId == userId && s.ArticleId == articleId, ct);
}
