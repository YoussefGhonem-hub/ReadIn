using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Features.Realtime.EventHandlers;

/// <summary>
/// Moves <c>/live/feed/latestPublishedAt</c>, which shows the "مقالات جديدة ↑" banner (F27), whenever an article goes
/// live: published now, by the scheduled-publishing job or by an import. The value is the newest publish time the feed
/// can show rather than this article's, so a redelivered, late or backdated event never moves it backwards.
/// </summary>
internal sealed class ArticlePublishedLiveFeedEventHandler(IAppDbContext db, IRealtimePublisher realtime)
    : IDomainEventHandler<ArticlePublishedDomainEvent>
{
    public async Task Handle(ArticlePublishedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        // The for-you feed's filter (GetForYouFeedQueryHandler), served by the (Status, PublishedAt DESC) index.
        var latest = await db.Articles
            .Where(a => a.Status == ArticleStatus.Published && a.PublishedAt != null && a.Field.IsEnabled)
            .MaxAsync(a => a.PublishedAt, cancellationToken);

        if (latest is { } publishedAt) await realtime.PublishFeedAsync(publishedAt, cancellationToken);
    }
}
