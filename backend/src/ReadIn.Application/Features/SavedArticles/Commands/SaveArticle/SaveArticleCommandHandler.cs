using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles.Commands.SaveArticle;

internal sealed class SaveArticleCommandHandler(IAppDbContext db, ICurrentUser currentUser, BlockRelations blocks, TimeProvider clock)
    : ICommandHandler<SaveArticleCommand, Result<SaveStateDto>>
{
    public async ValueTask<Result<SaveStateDto>> Handle(SaveArticleCommand command, CancellationToken cancellationToken)
    {
        // F36: the blocker gets 403 block.blocked, the blocked person the same not-found as a deleted article.
        if (await blocks.ArticleErrorAsync(currentUser, command.ArticleId, cancellationToken) is { } blocked) return blocked;
        if (!await db.Articles.VisibleTo(currentUser).AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var userId = currentUser.RequireUserId();
        if (!await IsSavedAsync(userId, command.ArticleId, cancellationToken))
        {
            db.SavedArticles.Add(SavedArticle.Create(userId, command.ArticleId, clock.GetUtcNow().UtcDateTime));
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                // Saved by a concurrent request (unique index): the outcome is the same.
                if (!await IsSavedAsync(userId, command.ArticleId, cancellationToken)) throw;
            }
        }

        return await db.StateAsync(userId, command.ArticleId, cancellationToken);
    }

    private Task<bool> IsSavedAsync(Guid userId, Guid articleId, CancellationToken ct) =>
        db.SavedArticles.AsNoTracking().AnyAsync(s => s.UserId == userId && s.ArticleId == articleId, ct);
}
