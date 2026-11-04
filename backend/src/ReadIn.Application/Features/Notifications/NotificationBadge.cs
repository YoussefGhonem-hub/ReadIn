using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Notifications;

/// <summary>
/// The unread badge (SPEC F17, §21.2): entries of the center the user hasn't seen yet. Published under
/// <c>/live/users/{id}</c> after every change, and served by <c>GET /me/notifications/unread-count</c>.
/// </summary>
public sealed class NotificationBadge(IAppDbContext db, IRealtimePublisher realtime)
{
    public Task<int> CountAsync(Guid userId, CancellationToken cancellationToken) =>
        db.Notifications.AsNoTracking().Where(n => n.UserId == userId && n.SeenAt == null).InCenter(db).CountAsync(cancellationToken);

    /// <summary>
    /// Publishes each user's count and last activity, read for all of them in one query (a new article can notify
    /// hundreds of followers at once). A Realtime Database failure never fails the caller.
    /// </summary>
    public async Task PublishAsync(IEnumerable<Guid> userIds, CancellationToken cancellationToken)
    {
        var ids = userIds.Distinct().ToList();
        if (ids.Count == 0) return;

        var badges = await db.Notifications.AsNoTracking()
            .Where(n => ids.Contains(n.UserId))
            .InCenter(db)
            .GroupBy(n => n.UserId)
            .Select(g => new { UserId = g.Key, Unread = g.Count(n => n.SeenAt == null), Last = g.Max(n => (DateTime?)n.UpdatedAt) })
            .ToDictionaryAsync(b => b.UserId, cancellationToken);

        foreach (var userId in ids)
        {
            var badge = badges.GetValueOrDefault(userId);
            await realtime.PublishUserNotificationsAsync(userId, badge?.Unread ?? 0, badge?.Last, cancellationToken);
        }
    }
}

internal static class NotificationVisibility
{
    /// <summary>
    /// What the center shows (SPEC F17): entries whose comment was deleted or hidden, or whose article isn't readable any
    /// more, drop out, and so does a "new follower" entry whose followers all deleted their accounts. A moderation notice
    /// keeps its hidden article (that is what it is about) until the article is deleted. Nothing is rewritten: the entry
    /// comes back if the comment or article does.
    /// </summary>
    public static IQueryable<Notification> InCenter(this IQueryable<Notification> notifications, IAppDbContext db) =>
        notifications.Where(n =>
            (n.CommentId == null || db.Comments.Any(c => c.Id == n.CommentId && c.HiddenAt == null))
            && (n.ArticleId == null
                || (n.Type == NotificationTypes.ModerationNotice && db.Articles.Any(a => a.Id == n.ArticleId))
                || (n.Type != NotificationTypes.ModerationNotice && db.Articles.Any(a => a.Id == n.ArticleId
                    && a.Status == ArticleStatus.Published && a.Field.IsEnabled && a.HiddenAt == null)))
            && (n.Type != NotificationTypes.NewFollower || n.Actors.Any()));
}
