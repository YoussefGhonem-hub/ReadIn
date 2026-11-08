using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Comments.Commands;

/// <summary>POST /articles/{id}/comments (SPEC F11).</summary>
[RequirePermission(Permissions.Comments.Create)]
public sealed record PostCommentCommand(Guid ArticleId, string? Body) : ICommand<Result<CommentDto>>;

/// <summary>POST /comments/{id}/replies: replying to a reply joins its thread (one level of replies).</summary>
[RequirePermission(Permissions.Comments.Create)]
public sealed record PostReplyCommand(Guid CommentId, string? Body) : ICommand<Result<CommentDto>>;

/// <summary>PATCH /comments/{id}: the author edits the text; the comment shows "edited".</summary>
[Authenticated]
public sealed record EditCommentCommand(Guid CommentId, string? Body) : ICommand<Result<CommentDto>>;

/// <summary>DELETE /comments/{id}: the author deletes (soft); a thread with replies keeps a placeholder.</summary>
[Authenticated]
public sealed record DeleteCommentCommand(Guid CommentId) : ICommand<Result>;

/// <summary>PUT (like) / DELETE (unlike) /comments/{id}/like, idempotent (SPEC §17.1).</summary>
[RequirePermission(Permissions.Reactions.Create)]
public sealed record SetCommentLikeCommand(Guid CommentId, bool Liked) : ICommand<Result<CommentLikeDto>>;

/// <summary>POST (pin) / DELETE (unpin) /comments/{id}/pin: the article's author pins one top-level comment.</summary>
[Authenticated]
public sealed record SetCommentPinCommand(Guid CommentId, bool Pinned) : ICommand<Result<CommentDto>>;

internal sealed class PostCommentCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, CommentPosting posting, CommentReader reader, CommentGuard guard, TimeProvider clock)
    : ICommandHandler<PostCommentCommand, Result<CommentDto>>
{
    public async ValueTask<Result<CommentDto>> Handle(PostCommentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var article = await db.Articles.VisibleTo(currentUser).Where(a => a.Id == command.ArticleId)
            .Select(a => new { a.AuthorId }).FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        // F36: never on the article of someone you are blocked with.
        if (await guard.BlockedAsync(userId, article.AuthorId, ArticleErrors.NotFound, cancellationToken) is { } blocked) return blocked;

        var prepared = await posting.PrepareAsync(command.Body, userId, cancellationToken);
        if (prepared.IsFailure) return prepared.Error;
        // F37: the content filter and the spam limit, then the per-article limits.
        var screened = await guard.ScreenNewAsync(userId, prepared.Value.Body, cancellationToken);
        if (screened.IsFailure) return screened.Error;
        var limits = await posting.CheckLimitsAsync(userId, command.ArticleId, prepared.Value.Body, cancellationToken);
        if (limits.IsFailure) return limits.Error;

        var comment = Comment.Post(command.ArticleId, userId, prepared.Value.Body, prepared.Value.MentionedUserIds, clock.GetUtcNow().UtcDateTime);
        db.Comments.Add(comment);
        await guard.FlagAsync(comment.Id, screened.Value, cancellationToken);
        await db.SaveChangesAsync(cancellationToken);

        return (await reader.LoadOneAsync(comment.Id, cancellationToken))!;
    }
}

internal sealed class PostReplyCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, CommentPosting posting, CommentReader reader, CommentGuard guard, TimeProvider clock)
    : ICommandHandler<PostReplyCommand, Result<CommentDto>>
{
    public async ValueTask<Result<CommentDto>> Handle(PostReplyCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var target = await db.Comments.IgnoreQueryFilters().FirstOrDefaultAsync(c => c.Id == command.CommentId, cancellationToken);
        if (target is null) return CommentErrors.NotFound;
        var article = await db.Articles.VisibleTo(currentUser).Where(a => a.Id == target.ArticleId)
            .Select(a => new { a.AuthorId }).FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        // F36: never under the comment, or on the article, of someone you are blocked with.
        if (await guard.BlockedAsync(userId, target.AuthorId, CommentErrors.NotFound, cancellationToken) is { } blockedAuthor) return blockedAuthor;
        if (await guard.BlockedAsync(userId, article.AuthorId, ArticleErrors.NotFound, cancellationToken) is { } blockedWriter) return blockedWriter;

        var prepared = await posting.PrepareAsync(command.Body, userId, cancellationToken);
        if (prepared.IsFailure) return prepared.Error;
        // F37: the content filter and the spam limit, then the per-article limits.
        var screened = await guard.ScreenNewAsync(userId, prepared.Value.Body, cancellationToken);
        if (screened.IsFailure) return screened.Error;
        var limits = await posting.CheckLimitsAsync(userId, target.ArticleId, prepared.Value.Body, cancellationToken);
        if (limits.IsFailure) return limits.Error;

        var reply = Comment.Reply(target, userId, prepared.Value.Body, prepared.Value.MentionedUserIds, clock.GetUtcNow().UtcDateTime);
        if (reply.IsFailure) return reply.Error;

        db.Comments.Add(reply.Value);
        await guard.FlagAsync(reply.Value.Id, screened.Value, cancellationToken);
        await db.SaveChangesAsync(cancellationToken);
        await posting.RecountRepliesAsync(reply.Value.ParentId!.Value, cancellationToken);

        return (await reader.LoadOneAsync(reply.Value.Id, cancellationToken))!;
    }
}

internal sealed class EditCommentCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, CommentPosting posting, CommentReader reader, CommentGuard guard, TimeProvider clock)
    : ICommandHandler<EditCommentCommand, Result<CommentDto>>
{
    public async ValueTask<Result<CommentDto>> Handle(EditCommentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var comment = await db.Comments.Include(c => c.Mentions).FirstOrDefaultAsync(c => c.Id == command.CommentId, cancellationToken);
        if (comment is null) return CommentErrors.NotFound;

        var prepared = await posting.PrepareAsync(command.Body, userId, cancellationToken);
        if (prepared.IsFailure) return prepared.Error;
        // F37: an edit is filtered like a new comment (no spam limit: it adds nothing).
        var screened = await guard.ScreenAsync(prepared.Value.Body, cancellationToken);
        if (screened.IsFailure) return screened.Error;

        var edited = comment.Edit(userId, prepared.Value.Body, prepared.Value.MentionedUserIds, clock.GetUtcNow().UtcDateTime);
        if (edited.IsFailure) return edited.Error;
        await guard.FlagAsync(comment.Id, screened.Value, cancellationToken);
        await db.SaveChangesAsync(cancellationToken);

        return (await reader.LoadOneAsync(comment.Id, cancellationToken))!;
    }
}

internal sealed class DeleteCommentCommandHandler(IAppDbContext db, ICurrentUser currentUser, CommentPosting posting, TimeProvider clock)
    : ICommandHandler<DeleteCommentCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteCommentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var comment = await db.Comments.FirstOrDefaultAsync(c => c.Id == command.CommentId, cancellationToken);
        if (comment is null) return Result.Success(); // already deleted: DELETE is idempotent

        var deleted = comment.Delete(userId, clock.GetUtcNow().UtcDateTime);
        if (deleted.IsFailure) return deleted;
        await db.SaveChangesAsync(cancellationToken);

        if (comment.ParentId is { } parentId) await posting.RecountRepliesAsync(parentId, cancellationToken);
        return Result.Success();
    }
}

internal sealed class SetCommentLikeCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, CommentPosting posting, Blocks.BlockRelations blocks, TimeProvider clock)
    : ICommandHandler<SetCommentLikeCommand, Result<CommentLikeDto>>
{
    public async ValueTask<Result<CommentLikeDto>> Handle(SetCommentLikeCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var comment = await db.Comments.AsNoTracking().FirstOrDefaultAsync(c => c.Id == command.CommentId, cancellationToken);
        if (comment is null) return CommentErrors.NotFound;
        // F36: no like on the comment (or under the article) of someone you are blocked with.
        if (await blocks.ErrorForAsync(userId, comment.AuthorId, CommentErrors.NotFound, cancellationToken) is { } blockedAuthor) return blockedAuthor;
        if (await blocks.ArticleErrorAsync(currentUser, comment.ArticleId, cancellationToken) is { } blockedArticle) return blockedArticle;
        if (!comment.IsVisible) return CommentErrors.NotAvailable;
        if (!await db.Articles.VisibleTo(currentUser).AnyAsync(a => a.Id == comment.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var existing = await db.CommentLikes.FirstOrDefaultAsync(l => l.CommentId == comment.Id && l.UserId == userId, cancellationToken);
        var changed = false;
        if (command.Liked && existing is null)
        {
            db.CommentLikes.Add(CommentLike.Create(comment, userId, clock.GetUtcNow().UtcDateTime));
            changed = true;
        }
        else if (!command.Liked && existing is not null)
        {
            existing.Remove(comment);
            db.CommentLikes.Remove(existing);
            changed = true;
        }

        if (changed)
        {
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException) when (command.Liked)
            {
                // A parallel request liked it first (unique CommentId + UserId): the outcome is the same.
            }
            await posting.RecountLikesAsync(comment.Id, cancellationToken);
        }

        var likes = await db.Comments.AsNoTracking().Where(c => c.Id == comment.Id).Select(c => c.LikeCount).FirstAsync(cancellationToken);
        return new CommentLikeDto(likes, command.Liked);
    }
}

internal sealed class SetCommentPinCommandHandler(IAppDbContext db, ICurrentUser currentUser, CommentReader reader, TimeProvider clock)
    : ICommandHandler<SetCommentPinCommand, Result<CommentDto>>
{
    public async ValueTask<Result<CommentDto>> Handle(SetCommentPinCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var comment = await db.Comments.FirstOrDefaultAsync(c => c.Id == command.CommentId, cancellationToken);
        if (comment is null) return CommentErrors.NotFound;

        var authorId = await db.Articles.VisibleTo(currentUser).Where(a => a.Id == comment.ArticleId).Select(a => (Guid?)a.AuthorId).FirstOrDefaultAsync(cancellationToken);
        if (authorId is null) return ArticleErrors.NotFound;
        if (authorId != userId) return CommentErrors.PinNotArticleAuthor;

        if (!command.Pinned)
        {
            comment.Unpin();
            await db.SaveChangesAsync(cancellationToken);
            return (await reader.LoadOneAsync(comment.Id, cancellationToken))!;
        }

        if (comment.IsPinned) return (await reader.LoadOneAsync(comment.Id, cancellationToken))!;

        // One pinned comment per article (filtered unique index): unpin the current one first, in its own save.
        var current = await db.Comments.FirstOrDefaultAsync(c => c.ArticleId == comment.ArticleId && c.IsPinned && c.Id != comment.Id, cancellationToken);
        if (current is not null)
        {
            current.Unpin();
            await db.SaveChangesAsync(cancellationToken);
        }

        var pinned = comment.Pin(clock.GetUtcNow().UtcDateTime);
        if (pinned.IsFailure) return pinned.Error;
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            return CommentErrors.PinConflict; // another comment was pinned at the same moment
        }
        return (await reader.LoadOneAsync(comment.Id, cancellationToken))!;
    }
}
