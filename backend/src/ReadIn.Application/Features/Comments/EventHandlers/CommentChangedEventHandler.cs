using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Comments.EventHandlers;

/// <summary>
/// After a comment change commits (SPEC F11, F27): recomputes the article's comment count when it may have moved (which
/// also republishes <c>/live/articles/{id}</c> counters), then appends the live event clients use to refetch the
/// comment. Recomputing and appending are both safe to repeat, so the outbox's at-least-once delivery is fine; a
/// repeated event only makes clients refetch twice.
/// </summary>
internal sealed class CommentChangedEventHandler(ArticleCounters counters, IRealtimePublisher realtime)
    : IDomainEventHandler<CommentChangedDomainEvent>
{
    public async Task Handle(CommentChangedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (domainEvent.ChangesCount) await counters.RecomputeAsync([domainEvent.ArticleId], cancellationToken);
        await realtime.PublishArticleEventAsync(
            domainEvent.ArticleId,
            new ArticleLiveEvent(LiveType(domainEvent), domainEvent.CommentId, domainEvent.ParentId),
            cancellationToken);
    }

    internal static string LiveType(CommentChangedDomainEvent e) => e.Change switch
    {
        CommentChange.Created => e.ParentId is null ? "comment.created" : "reply.created",
        CommentChange.Deleted => "comment.deleted",
        CommentChange.Liked => "comment.liked",
        CommentChange.Pinned => "comment.pinned",
        _ => "comment.updated", // edited, hidden, unhidden
    };
}
