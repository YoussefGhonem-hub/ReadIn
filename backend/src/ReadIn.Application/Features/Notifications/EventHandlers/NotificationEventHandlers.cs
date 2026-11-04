using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Notifications.EventHandlers;

// The F17 producers (SPEC F17, §21.1). Outbox handlers only write entries through NotificationWriter, never push; the
// push job sends what is due. Each one is idempotent, as the outbox delivers at least once.

/// <summary><c>new_follower</c>, one entry per day (in the followee's time zone) collecting the day's followers.</summary>
internal sealed class NewFollowerNotificationHandler(IAppDbContext db, NotificationWriter writer)
    : IDomainEventHandler<UserFollowedDomainEvent>
{
    public async Task Handle(UserFollowedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        // Unfollowed before this ran: nothing to tell.
        if (!await db.UserFollows.AnyAsync(f => f.FollowerId == domainEvent.FollowerId && f.FolloweeId == domainEvent.FolloweeId, cancellationToken))
            return;

        var timeZone = await db.Users.AsNoTracking().Where(u => u.Id == domainEvent.FolloweeId).Select(u => u.TimeZone).FirstOrDefaultAsync(cancellationToken);
        if (timeZone is null) return;

        var day = DailySchedule.LocalDate(domainEvent.OccurredAt, timeZone);
        await writer.WriteAsync(new NotificationRequest(domainEvent.FolloweeId, NotificationTypes.NewFollower)
        {
            ActorId = domainEvent.FollowerId,
            ActorAt = domainEvent.OccurredAt,
            GroupKey = $"{NotificationTypes.NewFollower}:{day:yyyy-MM-dd}",
            RepeatsCount = false,
        }, cancellationToken);
    }
}

/// <summary>
/// <c>mention</c>, <c>comment_reply</c> and <c>article_comment</c> for a new or edited comment, one per recipient by
/// precedence (<see cref="CommentRecipients"/>). Replies aggregate per thread, comments per article; mentions don't.
/// </summary>
internal sealed class CommentNotificationHandler(IAppDbContext db, NotificationWriter writer)
    : IDomainEventHandler<CommentChangedDomainEvent>
{
    public async Task Handle(CommentChangedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (domainEvent.Change is not (CommentChange.Created or CommentChange.Edited)) return;

        // Deleted (query filter) or hidden since: nothing to tell.
        var comment = await db.Comments.AsNoTracking()
            .Where(c => c.Id == domainEvent.CommentId && c.HiddenAt == null)
            .Select(c => new { c.AuthorId, c.ParentId, Mentioned = c.Mentions.Select(m => m.UserId).ToList() })
            .FirstOrDefaultAsync(cancellationToken);
        if (comment?.AuthorId is not { } authorId) return;

        var article = await db.Articles.AsNoTracking().Visible()
            .Where(a => a.Id == domainEvent.ArticleId)
            .Select(a => new { a.AuthorId })
            .FirstOrDefaultAsync(cancellationToken);
        if (article is null) return;

        Guid? parentAuthorId = comment.ParentId is { } parentId
            ? await db.Comments.AsNoTracking().Where(c => c.Id == parentId).Select(c => c.AuthorId).FirstOrDefaultAsync(cancellationToken)
            : null;

        var recipients = CommentRecipients.Resolve(
            domainEvent.Change, authorId, article.AuthorId, parentAuthorId, comment.ParentId is not null, comment.Mentioned);
        if (recipients.Count == 0) return;

        await writer.WriteAsync(
            [
                .. recipients.Select(r => new NotificationRequest(r.UserId, r.Type)
                {
                    ActorId = authorId,
                    ActorAt = domainEvent.OccurredAt,
                    ArticleId = domainEvent.ArticleId,
                    CommentId = domainEvent.CommentId,
                    GroupKey = r.Type switch
                    {
                        NotificationTypes.ArticleComment => $"{NotificationTypes.ArticleComment}:{domainEvent.ArticleId}",
                        NotificationTypes.CommentReply => $"{NotificationTypes.CommentReply}:{comment.ParentId}",
                        _ => null,
                    },
                    DedupeKey = r.Type == NotificationTypes.Mention ? $"{NotificationTypes.Mention}:{domainEvent.CommentId}" : null,
                }),
            ],
            cancellationToken);
    }
}

/// <summary>
/// <c>mention</c> in an article (no comment): every user the live version @mentions hears about it once per article (the
/// dedupe key <see cref="ArticleMentions.DedupeKey"/>), so an update tells only newly mentioned users and removing and
/// re-adding a mention tells nobody again. The article must still be readable and the mention still allowed.
/// </summary>
internal sealed class ArticleMentionNotificationHandler(IAppDbContext db, UserMentions mentions, NotificationWriter writer)
    : IDomainEventHandler<ArticleMentionsDomainEvent>
{
    public async Task Handle(ArticleMentionsDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (!await db.Articles.AsNoTracking().Visible()
                .AnyAsync(a => a.Id == domainEvent.ArticleId && a.AuthorId == domainEvent.AuthorId, cancellationToken))
            return;

        // "Who can mention me" may have changed since the publish (or the account was suspended): checked again.
        var allowed = await mentions.AllowedAsync(domainEvent.AuthorId, domainEvent.MentionedUserIds, cancellationToken);
        await writer.WriteAsync(
            [
                .. domainEvent.MentionedUserIds
                    .Where(id => id != domainEvent.AuthorId && allowed.ContainsKey(id))
                    .Distinct()
                    .Select(id => new NotificationRequest(id, NotificationTypes.Mention)
                    {
                        ActorId = domainEvent.AuthorId,
                        ActorAt = domainEvent.OccurredAt,
                        ArticleId = domainEvent.ArticleId,
                        DedupeKey = ArticleMentions.DedupeKey(domainEvent.ArticleId),
                    }),
            ],
            cancellationToken);
    }
}

/// <summary><c>reactions_milestone</c>: the article's total crossed 10, 50 or 100 (<see cref="ReactionMilestones"/>).</summary>
internal sealed class ReactionMilestoneNotificationHandler(IAppDbContext db, NotificationWriter writer)
    : IDomainEventHandler<ReactionChangedDomainEvent>
{
    public async Task Handle(ReactionChangedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (domainEvent.Type is null) return; // a removed reaction never crosses a milestone

        var authorId = await db.Articles.AsNoTracking().Visible()
            .Where(a => a.Id == domainEvent.ArticleId)
            .Select(a => a.AuthorId)
            .FirstOrDefaultAsync(cancellationToken);
        if (authorId is not { } author) return;

        var total = await db.Reactions.CountAsync(r => r.ArticleId == domainEvent.ArticleId, cancellationToken);
        var keys = ReactionMilestones.Thresholds.ToDictionary(t => ReactionMilestones.DedupeKey(domainEvent.ArticleId, t), t => t);
        var keyList = keys.Keys.ToList();
        var told = (await db.Notifications.AsNoTracking()
                .Where(n => n.UserId == author && n.DedupeKey != null && keyList.Contains(n.DedupeKey))
                .Select(n => n.DedupeKey!)
                .ToListAsync(cancellationToken))
            .Select(k => keys[k])
            .ToList();
        if (ReactionMilestones.Due(total, told) is not { } threshold) return;

        await writer.WriteAsync(new NotificationRequest(author, NotificationTypes.ReactionsMilestone)
        {
            ArticleId = domainEvent.ArticleId,
            DedupeKey = ReactionMilestones.DedupeKey(domainEvent.ArticleId, threshold),
            Data = new NotificationData { Threshold = threshold },
        }, cancellationToken);
    }
}

/// <summary>
/// <c>followed_writer_article</c> to every follower of the author. <see cref="Article.Publish"/> raises the event on the
/// first publish only (an update of a published article raises none), and the dedupe key keeps it to one per article.
/// </summary>
internal sealed class FollowedWriterArticleNotificationHandler(IAppDbContext db, NotificationWriter writer)
    : IDomainEventHandler<ArticlePublishedDomainEvent>
{
    private const int BatchSize = 500;

    public async Task Handle(ArticlePublishedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (domainEvent.AuthorId is not { } authorId) return;
        if (!await db.Articles.AsNoTracking().Visible().AnyAsync(a => a.Id == domainEvent.ArticleId, cancellationToken)) return;

        var after = Guid.Empty;
        while (true)
        {
            var followers = await db.UserFollows.AsNoTracking()
                .Where(f => f.FolloweeId == authorId && f.FollowerId > after)
                .OrderBy(f => f.FollowerId)
                .Select(f => f.FollowerId)
                .Take(BatchSize)
                .ToListAsync(cancellationToken);
            if (followers.Count == 0) return;
            after = followers[^1];

            await writer.WriteAsync(
                [
                    .. followers.Select(followerId => new NotificationRequest(followerId, NotificationTypes.FollowedWriterArticle)
                    {
                        ActorId = authorId,
                        ActorAt = domainEvent.OccurredAt,
                        ArticleId = domainEvent.ArticleId,
                        DedupeKey = $"{NotificationTypes.FollowedWriterArticle}:{domainEvent.ArticleId}",
                    }),
                ],
                cancellationToken);
            if (followers.Count < BatchSize) return;
        }
    }
}

/// <summary>
/// <c>security_alert</c> to the account's owner (SPEC §9.5): always written, and its push ignores quiet hours. The event's
/// time is stable across retries, so it is part of the dedupe key.
/// </summary>
internal sealed class SecurityAlertNotificationHandler(NotificationWriter writer) : IDomainEventHandler<UserSecurityChangedDomainEvent>
{
    public Task Handle(UserSecurityChangedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        writer.WriteAsync(new NotificationRequest(domainEvent.UserId, NotificationTypes.SecurityAlert)
        {
            DedupeKey = $"{NotificationTypes.SecurityAlert}:{NotificationData.Name(domainEvent.Change)}:{domainEvent.OccurredAt.Ticks}",
            Data = new NotificationData { SecurityChange = domainEvent.Change },
        }, cancellationToken);
}

/// <summary>Seen or read on one device: the badge of the others follows (<c>/live/users/{id}</c>).</summary>
internal sealed class UserNotificationsChangedEventHandler(NotificationBadge badge) : IDomainEventHandler<UserNotificationsChangedDomainEvent>
{
    public Task Handle(UserNotificationsChangedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        badge.PublishAsync([domainEvent.UserId], cancellationToken);
}
