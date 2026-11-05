using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Mutes.Commands.ShowLess;

internal sealed class ShowLessCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<ShowLessCommand, Result>
{
    public async ValueTask<Result> Handle(ShowLessCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        // An article you can open (as GET /articles/{slug}): a hidden one only for its author and moderators.
        var article = await db.Articles.AsNoTracking()
            .VisibleTo(currentUser)
            .Where(a => a.Id == command.ArticleId)
            .Select(a => new { a.AuthorId })
            .FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        if (article.AuthorId == userId) return MuteErrors.OwnArticle;

        if (await IsMarkedAsync(userId, command.ArticleId, cancellationToken)) return Result.Success();

        db.ArticleFeedback.Add(new ArticleFeedback(userId, command.ArticleId, ArticleFeedbackType.ShowLess, clock.GetUtcNow().UtcDateTime));
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // Marked by a concurrent request (unique index): the outcome is the same.
            db.ClearChangeTracker();
            if (!await IsMarkedAsync(userId, command.ArticleId, cancellationToken)) throw;
        }

        return Result.Success();
    }

    private Task<bool> IsMarkedAsync(Guid userId, Guid articleId, CancellationToken ct) =>
        db.ArticleFeedback.AsNoTracking().AnyAsync(f => f.UserId == userId && f.ArticleId == articleId, ct);
}
