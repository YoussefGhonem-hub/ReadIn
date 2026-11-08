using FluentValidation;
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
/// PUT /articles/{id}/repost (SPEC F29): repost an article you can open to your followers, optionally with your thoughts
/// (<see cref="Caption"/>). Idempotent: when you already reposted it, only the caption can change, and the repost keeps
/// its first time, its count and its one notification. A null caption means none on a new repost and "unchanged" on an
/// existing one; a string sets it, and a blank one clears it. Never your own article (<c>repost.own_article</c>).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Reposts.Create)]
public sealed record RepostArticleCommand(Guid ArticleId, string? Caption = null) : ICommand<Result<RepostStateDto>>;

/// <summary>DELETE /articles/{id}/repost (SPEC F29): undo your repost, caption and all. Idempotent; on your own article it answers "not reposted".</summary>
[Authenticated]
[RequirePermission(Permissions.Reposts.Create)]
public sealed record UndoRepostCommand(Guid ArticleId) : ICommand<Result<RepostStateDto>>;

/// <summary>At most 500 characters after trimming: <c>caption: ["repost.caption_too_long"]</c>.</summary>
internal sealed class RepostArticleCommandValidator : AbstractValidator<RepostArticleCommand>
{
    public RepostArticleCommandValidator() =>
        RuleFor(c => c.Caption).Must(Repost.CaptionFits).WithErrorCode(RepostErrors.CaptionTooLongCode);
}

internal sealed class RepostArticleCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, Blocks.BlockRelations blocks, ContentFilter.ContentScreening screening, TimeProvider clock)
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
        // F36: never the article of someone you are blocked with (they see a plain 404; the blocker 403 block.blocked).
        if (await blocks.ErrorForAsync(userId, article.AuthorId, ArticleErrors.NotFound, cancellationToken) is { } blocked) return blocked;
        // F37: the caption is public text: the content filter, spam signs included.
        var screened = await screening.ScreenAsync([new ContentFilter.ScreenedField("caption", command.Caption, SpamSignals: true)], cancellationToken);
        if (screened.IsFailure) return screened.Error;

        var existing = await db.Reposts.FirstOrDefaultAsync(r => r.UserId == userId && r.ArticleId == command.ArticleId, cancellationToken);
        if (existing is not null)
        {
            await screening.FlagAsync(Domain.Moderation.ReportTargetType.Repost, existing.Id, screened.Value, cancellationToken);
            var edited = await EditCaptionAsync(existing, command.Caption, cancellationToken);
            if (edited.IsFailure) return edited.Error;
        }
        else
        {
            var created = Repost.Create(userId, command.ArticleId, command.Caption, clock.GetUtcNow().UtcDateTime);
            if (created.IsFailure) return created.Error;

            db.Reposts.Add(created.Value);
            await screening.FlagAsync(Domain.Moderation.ReportTargetType.Repost, created.Value.Id, screened.Value, cancellationToken);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                // Two reposts at once (a double tap): the unique index kept the one that committed first. It is now an
                // existing repost, so this request's caption, if it has one, is set on it.
                db.ClearChangeTracker();
                var winner = await db.Reposts.FirstOrDefaultAsync(r => r.UserId == userId && r.ArticleId == command.ArticleId, cancellationToken);
                if (winner is null) throw;
                var edited = await EditCaptionAsync(winner, command.Caption, cancellationToken);
                if (edited.IsFailure) return edited.Error;
            }
        }

        return await RepostStates.ReadAsync(db, userId, command.ArticleId, cancellationToken);
    }

    /// <summary>
    /// The caption of a repost that already exists: a null caption leaves it as it is. No event is raised, so the count
    /// doesn't move and the author hears nothing new.
    /// </summary>
    private async Task<Result> EditCaptionAsync(Repost repost, string? caption, CancellationToken cancellationToken)
    {
        if (caption is null) return Result.Success();

        var result = repost.SetCaption(caption);
        if (result.IsFailure) return result;
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            // Undone by a concurrent request: the state read next says so.
        }
        return Result.Success();
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
    /// <summary>
    /// Counted from the rows right after the change; the article's denormalized count follows through the outbox. The
    /// caption is the user's repost's, null when it has none or there is no repost.
    /// </summary>
    public static async Task<RepostStateDto> ReadAsync(IAppDbContext db, Guid userId, Guid articleId, CancellationToken ct)
    {
        var count = await db.Reposts.AsNoTracking().CountAsync(r => r.ArticleId == articleId, ct);
        var mine = await db.Reposts.AsNoTracking()
            .Where(r => r.UserId == userId && r.ArticleId == articleId)
            .Select(r => new { r.Caption })
            .FirstOrDefaultAsync(ct);
        return new RepostStateDto(count, mine is not null, mine?.Caption);
    }
}
