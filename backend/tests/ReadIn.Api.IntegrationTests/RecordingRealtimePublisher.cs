using System.Collections.Concurrent;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Stands in for the Firebase publisher (F27) and records what the outbox handlers publish.</summary>
public sealed class RecordingRealtimePublisher : IRealtimePublisher
{
    private readonly ConcurrentQueue<(Guid ArticleId, ArticleLiveCounters Counters)> _counters = new();
    private readonly ConcurrentQueue<(Guid ArticleId, ArticleLiveEvent Event)> _events = new();

    /// <summary>Every feed signal, oldest first.</summary>
    public ConcurrentQueue<DateTime> FeedSignals { get; } = new();

    /// <summary>Every counters write for the article, oldest first.</summary>
    public IReadOnlyList<ArticleLiveCounters> CountersFor(Guid articleId) =>
        [.. _counters.Where(c => c.ArticleId == articleId).Select(c => c.Counters)];

    /// <summary>Every comment event of the article (F11), oldest first.</summary>
    public IReadOnlyList<ArticleLiveEvent> EventsFor(Guid articleId) =>
        [.. _events.Where(e => e.ArticleId == articleId).Select(e => e.Event)];

    public Task PublishArticleCountersAsync(Guid articleId, ArticleLiveCounters counters, CancellationToken cancellationToken = default)
    {
        _counters.Enqueue((articleId, counters));
        return Task.CompletedTask;
    }

    public Task PublishArticleEventAsync(Guid articleId, ArticleLiveEvent liveEvent, CancellationToken cancellationToken = default)
    {
        _events.Enqueue((articleId, liveEvent));
        return Task.CompletedTask;
    }

    public Task PublishFeedAsync(DateTime latestPublishedAt, CancellationToken cancellationToken = default)
    {
        FeedSignals.Enqueue(latestPublishedAt);
        return Task.CompletedTask;
    }

    public Task PublishUserNotificationsAsync(
        Guid userId, int unreadNotifications, DateTime? lastNotificationAt, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
