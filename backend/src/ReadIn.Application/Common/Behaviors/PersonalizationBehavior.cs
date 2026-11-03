using Mediator;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Common.Behaviors;

/// <summary>
/// A cached query whose result has caller-specific parts (e.g. <c>canDownload</c> for the author and moderators).
/// The cache stores the caller-independent result; <see cref="Personalize"/> runs on every request, after the cache.
/// </summary>
public interface IPersonalizedQuery<TResponse>
{
    TResponse Personalize(TResponse response, ICurrentUser viewer);
}

/// <summary>
/// Adds caller-specific parts that need the database (the viewer's reaction, save, follow) to a cached query's result,
/// on every request, after the cache. Registered in DI for the one message type it personalizes.
/// </summary>
public interface IQueryPersonalizer<in TMessage, TResponse>
{
    ValueTask<TResponse> PersonalizeAsync(TMessage message, TResponse response, CancellationToken cancellationToken);
}

/// <summary>Runs before <see cref="CachingBehavior{TMessage,TResponse}"/>, so it personalizes cached and fresh results alike.</summary>
internal sealed class PersonalizationBehavior<TMessage, TResponse>(
    ICurrentUser viewer,
    IEnumerable<IQueryPersonalizer<TMessage, TResponse>> personalizers) : IPipelineBehavior<TMessage, TResponse>
    where TMessage : notnull, IMessage
{
    public async ValueTask<TResponse> Handle(TMessage message, MessageHandlerDelegate<TMessage, TResponse> next, CancellationToken cancellationToken)
    {
        var response = await next(message, cancellationToken);
        if (message is IPersonalizedQuery<TResponse> query) response = query.Personalize(response, viewer);
        foreach (var personalizer in personalizers)
            response = await personalizer.PersonalizeAsync(message, response, cancellationToken);
        return response;
    }
}
