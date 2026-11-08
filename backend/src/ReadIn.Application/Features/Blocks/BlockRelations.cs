using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Blocks;

/// <summary>How two people stand (SPEC F36): seen from the viewer.</summary>
public enum BlockDirection
{
    None,

    /// <summary>The viewer blocked the other person: they get <c>403 block.blocked</c> with an Unblock.</summary>
    YouBlocked,

    /// <summary>The other person blocked the viewer: everything of theirs looks deleted (a plain not-found).</summary>
    BlockedYou,

    /// <summary>Both blocked each other: the viewer's own block decides what they see (<see cref="YouBlocked"/>).</summary>
    Both,
}

/// <summary>Blocks as SQL subqueries (SPEC F36): every list leaves these people out, both ways.</summary>
public static class BlockQueries
{
    /// <summary>The people <paramref name="viewerId"/> is blocked with, either way (may repeat an id).</summary>
    public static IQueryable<Guid> BlockedWith(this IAppDbContext db, Guid viewerId) =>
        db.UserBlocks.Where(b => b.BlockerId == viewerId).Select(b => b.BlockedId)
            .Concat(db.UserBlocks.Where(b => b.BlockedId == viewerId).Select(b => b.BlockerId));
}

/// <summary>
/// Blocking (SPEC F36): making a block (follows both ways end; the notifications each wrote for the other go), and the
/// checks every write and direct link uses. The blocked person is never told: their writes and links answer a plain
/// not-found; only the blocker gets <c>403 block.blocked</c>.
/// </summary>
public sealed class BlockRelations(IAppDbContext db)
{
    /// <summary>The notification types whose entries name an actor; an entry left without one is deleted.</summary>
    private static readonly string[] ActorTypes =
    [
        NotificationTypes.NewFollower, NotificationTypes.ArticleComment, NotificationTypes.CommentReply, NotificationTypes.Mention,
        NotificationTypes.FollowedWriterArticle, NotificationTypes.ArticleReposted, NotificationTypes.SupportTicket,
    ];

    public async Task<BlockDirection> BetweenAsync(Guid viewerId, Guid otherId, CancellationToken ct)
    {
        if (viewerId == otherId) return BlockDirection.None;
        var rows = await db.UserBlocks.AsNoTracking()
            .Where(b => (b.BlockerId == viewerId && b.BlockedId == otherId) || (b.BlockerId == otherId && b.BlockedId == viewerId))
            .Select(b => b.BlockerId)
            .ToListAsync(ct);
        var youBlocked = rows.Contains(viewerId);
        var blockedYou = rows.Contains(otherId);
        return (youBlocked, blockedYou) switch
        {
            (true, true) => BlockDirection.Both,
            (true, false) => BlockDirection.YouBlocked,
            (false, true) => BlockDirection.BlockedYou,
            _ => BlockDirection.None,
        };
    }

    /// <summary>
    /// What a direct link or a write by <paramref name="viewerId"/> on <paramref name="ownerId"/>'s content or account answers:
    /// null when allowed; <c>403 block.blocked</c> (with the person) when the viewer blocked them; <paramref name="notFound"/>
    /// when they blocked the viewer.
    /// </summary>
    public async Task<Error?> ErrorForAsync(Guid? viewerId, Guid? ownerId, Error notFound, CancellationToken ct)
    {
        if (viewerId is not { } viewer || ownerId is not { } owner || viewer == owner) return null;
        var direction = await BetweenAsync(viewer, owner, ct);
        if (direction == BlockDirection.None) return null;
        if (direction == BlockDirection.BlockedYou) return notFound;

        var user = await db.Users.AsNoTracking().Where(u => u.Id == owner)
            .Select(u => new { u.Id, u.Username, u.DisplayName })
            .FirstOrDefaultAsync(ct);
        return user is null ? notFound : BlockErrors.BlockedUser(user.Id, user.Username, user.DisplayName);
    }

    /// <summary>
    /// A direct link (an article, a comment, a profile and its tabs) of <paramref name="ownerId"/> for <paramref name="viewer"/>:
    /// <see cref="ErrorForAsync"/>, except that holders of <c>moderation.manage</c> open everything as usual, so a case
    /// always opens (SPEC F36: blocking doesn't hide content from moderators). Guests see everything.
    /// </summary>
    public Task<Error?> DirectLinkErrorAsync(ICurrentUser viewer, Guid? ownerId, Error notFound, CancellationToken ct) =>
        viewer.Permissions.Contains(Common.Security.Permissions.Moderation.Manage)
            ? Task.FromResult<Error?>(null)
            : ErrorForAsync(viewer.UserId, ownerId, notFound, ct);

    /// <summary>
    /// <see cref="DirectLinkErrorAsync"/> for an article and what is done on it (its comments, reactions, highlights, save,
    /// preview, related, path): decided by its author. An unknown article passes (the caller answers its own 404).
    /// </summary>
    public async Task<Error?> ArticleErrorAsync(ICurrentUser viewer, Guid articleId, CancellationToken ct)
    {
        if (viewer.UserId is null) return null;
        var authorId = await db.Articles.AsNoTracking().Where(a => a.Id == articleId).Select(a => a.AuthorId).FirstOrDefaultAsync(ct);
        return await DirectLinkErrorAsync(viewer, authorId, Domain.Articles.ArticleErrors.NotFound, ct);
    }

    /// <summary>
    /// <see cref="DirectLinkErrorAsync"/> for a comment and what is done on it: decided by its author, then by its article's
    /// author. An unknown comment passes (the caller answers its own 404).
    /// </summary>
    public async Task<Error?> CommentErrorAsync(ICurrentUser viewer, Guid commentId, CancellationToken ct)
    {
        if (viewer.UserId is null) return null;
        var comment = await db.Comments.AsNoTracking().Where(c => c.Id == commentId)
            .Select(c => new { c.AuthorId, c.ArticleId })
            .FirstOrDefaultAsync(ct);
        if (comment is null) return null;
        return await DirectLinkErrorAsync(viewer, comment.AuthorId, Domain.Engagement.CommentErrors.NotFound, ct)
            ?? await ArticleErrorAsync(viewer, comment.ArticleId, ct);
    }

    /// <summary>
    /// <paramref name="blockerId"/> blocks <paramref name="blockedId"/> (both exist; checked by the caller). Idempotent. Ends
    /// the follows both ways and removes what each wrote in the other's notifications. Saves nothing: the caller saves.
    /// </summary>
    /// <returns>Whether the blocker's follow of them ended (the toast's Undo can follow again).</returns>
    public async Task<Result<bool>> BlockAsync(Guid blockerId, Guid blockedId, DateTime now, CancellationToken ct)
    {
        if (blockerId == blockedId) return BlockErrors.Self;
        if (await db.UserBlocks.AnyAsync(b => b.BlockerId == blockerId && b.BlockedId == blockedId, ct)) return false;
        if (await db.UserBlocks.CountAsync(b => b.BlockerId == blockerId, ct) >= UserBlock.MaxPerUser) return BlockErrors.Limit;

        db.UserBlocks.Add(new UserBlock(blockerId, blockedId, now));

        var follows = await db.UserFollows
            .Where(f => (f.FollowerId == blockerId && f.FolloweeId == blockedId) || (f.FollowerId == blockedId && f.FolloweeId == blockerId))
            .ToListAsync(ct);
        var followRemoved = follows.Any(f => f.FollowerId == blockerId);
        db.UserFollows.RemoveRange(follows);

        await RemoveNotificationsBetweenAsync(blockerId, blockedId, ct);
        return followRemoved;
    }

    /// <summary>
    /// Nothing either wrote reaches the other (SPEC F36): their actor rows in each other's entries are deleted, and an
    /// actor-based entry left without actors goes with them (its pending push too).
    /// </summary>
    private async Task RemoveNotificationsBetweenAsync(Guid a, Guid b, CancellationToken ct)
    {
        var between = db.NotificationActors
            .Where(x => (x.ActorId == b && db.Notifications.Any(n => n.Id == x.NotificationId && n.UserId == a))
                     || (x.ActorId == a && db.Notifications.Any(n => n.Id == x.NotificationId && n.UserId == b)));
        // Only the entries the other person was in; a "Deleted user" entry of someone else stays.
        var touched = await between.Select(x => x.NotificationId).Distinct().ToListAsync(ct);
        if (touched.Count == 0) return;
        await between.ExecuteDeleteAsync(ct);
        await db.Notifications
            .Where(n => touched.Contains(n.Id) && ActorTypes.Contains(n.Type) && !db.NotificationActors.Any(x => x.NotificationId == n.Id))
            .ExecuteDeleteAsync(ct);
    }
}
