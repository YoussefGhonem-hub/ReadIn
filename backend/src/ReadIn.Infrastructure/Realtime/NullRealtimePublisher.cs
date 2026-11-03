using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Infrastructure.Realtime;

/// <summary>Placeholder until the Firebase publisher is registered (F27): live signals are optional, REST is the truth.</summary>
internal sealed class NullRealtimePublisher : IRealtimePublisher
{
    public Task PublishArticleCountersAsync(Guid articleId, ArticleLiveCounters counters, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task PublishArticleEventAsync(Guid articleId, ArticleLiveEvent liveEvent, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task PublishFeedAsync(DateTime latestPublishedAt, CancellationToken cancellationToken = default) => Task.CompletedTask;

    public Task PublishUserNotificationsAsync(
        Guid userId, int unreadNotifications, DateTime? lastNotificationAt, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
