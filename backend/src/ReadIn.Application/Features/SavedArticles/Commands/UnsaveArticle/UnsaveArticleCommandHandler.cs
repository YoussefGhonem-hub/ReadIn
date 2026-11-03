using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.UnsaveArticle;

internal sealed class UnsaveArticleCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UnsaveArticleCommand, Result<SaveStateDto>>
{
    public async ValueTask<Result<SaveStateDto>> Handle(UnsaveArticleCommand command, CancellationToken cancellationToken)
    {
        if (!await db.Articles.Visible().AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var userId = currentUser.RequireUserId();
        var articleId = command.ArticleId;
        var saved = await db.SavedArticles.FirstOrDefaultAsync(s => s.UserId == userId && s.ArticleId == articleId, cancellationToken);
        var collections = await db.Collections
            .Include(c => c.Items.Where(i => i.ArticleId == articleId))
            .Where(c => c.UserId == userId && c.Items.Any(i => i.ArticleId == articleId))
            .ToListAsync(cancellationToken);

        if (saved is null && collections.Count == 0) return await db.StateAsync(userId, articleId, cancellationToken);

        // One transaction: the save and every collection entry go together.
        if (saved is not null)
        {
            saved.Remove();
            db.SavedArticles.Remove(saved);
        }
        foreach (var collection in collections) collection.RemoveArticle(articleId);

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            // Unsaved by a concurrent request: the outcome is the same.
        }

        return await db.StateAsync(userId, articleId, cancellationToken);
    }
}
