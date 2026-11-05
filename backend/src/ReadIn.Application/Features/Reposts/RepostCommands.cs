using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Reposts;

/// <summary>
/// PUT /articles/{id}/repost (SPEC F29): repost an article you can open to your followers. Idempotent: a second repost
/// changes nothing and keeps the first time. Never your own article (<c>repost.own_article</c>).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Reposts.Create)]
public sealed record RepostArticleCommand(Guid ArticleId) : ICommand<Result<RepostStateDto>>;

/// <summary>DELETE /articles/{id}/repost (SPEC F29): undo your repost. Idempotent; on your own article it answers "not reposted".</summary>
[Authenticated]
[RequirePermission(Permissions.Reposts.Create)]
public sealed record UndoRepostCommand(Guid ArticleId) : ICommand<Result<RepostStateDto>>;

internal sealed class RepostArticleCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<RepostArticleCommand, Result<RepostStateDto>>
{
    public async ValueTask<Result<RepostStateDto>> Handle(RepostArticleCommand command, CancellationToken cancellationToken)
    {
        // The reader's rules: a hidden article is only there for its author and moderators (F22).
        var article = await db.Articles.AsNoTracking().VisibleTo(currentUser)
            .Where(a => a.Id == command.ArticleId)
            .Select(a => new { a.AuthorId })
            .FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;

        var userId = currentUser.RequireUserId();
        if (article.AuthorId == userId) return RepostErrors.OwnArticle;

        if (!await db.Reposts.AnyAsync(r => r.UserId == userId && r.ArticleId == command.ArticleId, cancellationToken))
        {
            db.Reposts.Add(Repost.Create(userId, command.ArticleId, clock.GetUtcNow().UtcDateTime));
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                // Two reposts at once (a double tap): the unique index kept the one that committed first.
                if (!await RepostStates.ExistsAsync(db, userId, command.ArticleId, cancellationToken)) throw;
            }
        }

        return await RepostStates.ReadAsync(db, userId, command.ArticleId, cancellationToken);
    }
}

internal sealed class UndoRepostCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UndoRepostCommand, Result<RepostStateDto>>
{
    public async ValueTask<Result<RepostStateDto>> Handle(UndoRepostCommand command, CancellationToken cancellationToken)
    {
        if (!await db.Articles.VisibleTo(currentUser).AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var userId = currentUser.RequireUserId();
        var repost = await db.Reposts.FirstOrDefaultAsync(r => r.UserId == userId && r.ArticleId == command.ArticleId, cancellationToken);
        if (repost is not null)
        {
            repost.Remove();
            db.Reposts.Remove(repost);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateConcurrencyException)
            {
                // Undone by a concurrent request: the outcome is the same.
            }
        }

        return await RepostStates.ReadAsync(db, userId, command.ArticleId, cancellationToken);
    }
}

internal static class RepostStates
{
    public static Task<bool> ExistsAsync(IAppDbContext db, Guid userId, Guid articleId, CancellationToken ct) =>
        db.Reposts.AsNoTracking().AnyAsync(r => r.UserId == userId && r.ArticleId == articleId, ct);

    /// <summary>Counted from the rows right after the change; the article's denormalized count follows through the outbox.</summary>
    public static async Task<RepostStateDto> ReadAsync(IAppDbContext db, Guid userId, Guid articleId, CancellationToken ct) => new(
        await db.Reposts.AsNoTracking().CountAsync(r => r.ArticleId == articleId, ct),
        await ExistsAsync(db, userId, articleId, ct));
}
