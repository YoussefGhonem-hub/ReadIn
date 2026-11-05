using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Reposts;

/// <summary>A repost or its undo: the article's <c>RepostCount</c> is recounted and published live (F27, SPEC §21.2).</summary>
internal sealed class RepostCountersEventHandler(ArticleCounters counters) : IDomainEventHandler<RepostChangedDomainEvent>
{
    public Task Handle(RepostChangedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        counters.RecomputeAsync([domainEvent.ArticleId], cancellationToken);
}

/// <summary>
/// <c>article_reposted</c> (SPEC F29, F17) to the article's author, aggregated per article. Not news: a repost undone
/// before this ran, a hidden or deleted article, and a reposter the author already heard about for this article (undoing
/// and reposting again). The writer also drops it for a muted reposter, your own action and inactive accounts.
/// </summary>
internal sealed class RepostNotificationHandler(IAppDbContext db, NotificationWriter writer) : IDomainEventHandler<RepostChangedDomainEvent>
{
    public static string GroupKey(Guid articleId) => $"{NotificationTypes.ArticleReposted}:{articleId}";

    public async Task Handle(RepostChangedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (!domainEvent.IsReposted) return;
        if (!await db.Reposts.AnyAsync(r => r.UserId == domainEvent.UserId && r.ArticleId == domainEvent.ArticleId, cancellationToken)) return;

        var authorId = await db.Articles.AsNoTracking().Visible()
            .Where(a => a.Id == domainEvent.ArticleId)
            .Select(a => a.AuthorId)
            .FirstOrDefaultAsync(cancellationToken);
        if (authorId is not { } author || author == domainEvent.UserId) return;

        var toldBefore = await db.Notifications.AsNoTracking().AnyAsync(
            n => n.UserId == author && n.Type == NotificationTypes.ArticleReposted && n.ArticleId == domainEvent.ArticleId
                && n.Actors.Any(a => a.ActorId == domainEvent.UserId),
            cancellationToken);
        if (toldBefore) return;

        await writer.WriteAsync(new NotificationRequest(author, NotificationTypes.ArticleReposted)
        {
            ActorId = domainEvent.UserId,
            ActorAt = domainEvent.OccurredAt,
            ArticleId = domainEvent.ArticleId,
            GroupKey = GroupKey(domainEvent.ArticleId),
            RepeatsCount = false,
        }, cancellationToken);
    }
}
