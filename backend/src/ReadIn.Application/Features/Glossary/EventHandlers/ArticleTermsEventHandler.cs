using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Features.Glossary.EventHandlers;

/// <summary>A published article starts showing under the glossary terms it uses (SPEC F21).</summary>
internal sealed class ArticleTermsEventHandler(ArticleTermsIndex index, HybridCache cache) : IDomainEventHandler<ArticlePublishedDomainEvent>
{
    public async Task Handle(ArticlePublishedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (await index.RebuildAsync([domainEvent.ArticleId], cancellationToken) > 0)
            await cache.RemoveByTagAsync(CacheTags.Glossary, cancellationToken);
    }
}
