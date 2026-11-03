namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// Live signals in the Firebase Realtime Database (SPEC §21.2, F27). RTDB carries signals, never content: counters and
/// event ids only, so clients refetch the data itself through the REST API. Called from outbox handlers, after the SQL
/// commit. A failure is logged and never fails the caller, because the app keeps working through REST without RTDB.
/// </summary>
public interface IRealtimePublisher
{
    /// <summary>Overwrites <c>/live/articles/{articleId}</c> counters (reactions per type, comments, saves).</summary>
    Task PublishArticleCountersAsync(Guid articleId, ArticleLiveCounters counters, CancellationToken cancellationToken = default);

    /// <summary>Appends <c>/live/articles/{articleId}/events/{pushId}</c> (comments, F11).</summary>
    Task PublishArticleEventAsync(Guid articleId, ArticleLiveEvent liveEvent, CancellationToken cancellationToken = default);

    /// <summary>Sets <c>/live/feed/latestPublishedAt</c>, which drives the "new articles ↑" banner.</summary>
    Task PublishFeedAsync(DateTime latestPublishedAt, CancellationToken cancellationToken = default);

    /// <summary>Sets <c>/live/users/{userId}</c> unread notifications (F17), readable only by that user.</summary>
    Task PublishUserNotificationsAsync(
        Guid userId, int unreadNotifications, DateTime? lastNotificationAt, CancellationToken cancellationToken = default);
}

/// <summary>Counters under <c>/live/articles/{articleId}</c>: reactions per type (F10), comments (F11), saves (F13).</summary>
public sealed record ArticleLiveCounters(int Insightful, int Love, int Fire, int MindBlown, int CommentCount, int SaveCount);

/// <summary>
/// One comment event (F11). <see cref="Type"/> is one of <c>comment.created</c>, <c>comment.updated</c>,
/// <c>comment.deleted</c>, <c>reply.created</c>, <c>comment.liked</c>, <c>comment.pinned</c>.
/// </summary>
public sealed record ArticleLiveEvent(string Type, Guid CommentId, Guid? ParentId = null);
