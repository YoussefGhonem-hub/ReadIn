using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Infrastructure.Realtime;

/// <summary>
/// Live signals in the Firebase Realtime Database (SPEC §21.2, F27), written only by the API after the SQL commit.
/// Paths and payloads are the contract the web and mobile listeners read; every write is best effort
/// (<see cref="RealtimeDatabaseClient"/>).
/// </summary>
internal sealed class FirebaseRealtimePublisher(RealtimeDatabaseClient database) : IRealtimePublisher
{
    /// <summary>PATCH, so the article's <c>events</c> list is never replaced with the counters.</summary>
    public Task PublishArticleCountersAsync(Guid articleId, ArticleLiveCounters counters, CancellationToken cancellationToken = default) =>
        database.PatchAsync($"live/articles/{articleId}", new Dictionary<string, object>
        {
            ["reactions"] = new Dictionary<string, int>
            {
                ["insightful"] = counters.Insightful,
                ["love"] = counters.Love,
                ["fire"] = counters.Fire,
                ["mindBlown"] = counters.MindBlown,
            },
            ["commentCount"] = counters.CommentCount,
            ["saveCount"] = counters.SaveCount,
            ["updatedAt"] = RealtimeDatabaseClient.ServerTimestamp,
        }, cancellationToken);

    /// <summary>
    /// POST: RTDB names the event with a chronological push id. <c>at</c> is the server's clock, which clients query
    /// from (<c>orderByChild("at").startAt(serverNow)</c>). A retried POST can leave a duplicate event; that only makes a
    /// client refetch the same comment.
    /// </summary>
    public Task PublishArticleEventAsync(Guid articleId, ArticleLiveEvent liveEvent, CancellationToken cancellationToken = default)
    {
        var value = new Dictionary<string, object>
        {
            ["type"] = liveEvent.Type,
            ["commentId"] = liveEvent.CommentId,
            ["at"] = RealtimeDatabaseClient.ServerTimestamp,
        };
        if (liveEvent.ParentId is { } parentId) value["parentId"] = parentId;
        return database.PostAsync($"live/articles/{articleId}/events", value, cancellationToken);
    }

    /// <summary>Epoch ms, like every other time in RTDB.</summary>
    public Task PublishFeedAsync(DateTime latestPublishedAt, CancellationToken cancellationToken = default) =>
        database.PutAsync("live/feed/latestPublishedAt", ToEpochMilliseconds(latestPublishedAt), cancellationToken);

    /// <summary>PATCH, so the user's <c>media</c> processing signals are kept.</summary>
    public Task PublishUserNotificationsAsync(
        Guid userId, int unreadNotifications, DateTime? lastNotificationAt, CancellationToken cancellationToken = default) =>
        database.PatchAsync($"live/users/{userId}", new Dictionary<string, object?>
        {
            ["unreadNotifications"] = unreadNotifications,
            // null removes the child: no notification yet.
            ["lastNotificationAt"] = lastNotificationAt is { } at ? ToEpochMilliseconds(at) : null,
        }, cancellationToken);

    /// <summary>Times from SQL Server are UTC (SPEC §16.1), whatever their <see cref="DateTime.Kind"/>.</summary>
    internal static long ToEpochMilliseconds(DateTime value) =>
        new DateTimeOffset(value.Kind == DateTimeKind.Local ? value.ToUniversalTime() : DateTime.SpecifyKind(value, DateTimeKind.Utc))
            .ToUnixTimeMilliseconds();
}
