using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Features.Articles.EventHandlers;

/// <summary>Publishing invalidates feeds and the article's cached details (SPEC §6.3).</summary>
internal sealed class ArticlePublishedEventHandler(HybridCache cache) : IDomainEventHandler<ArticlePublishedDomainEvent>
{
    public async Task Handle(ArticlePublishedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(domainEvent.Slug)], cancellationToken);
}
