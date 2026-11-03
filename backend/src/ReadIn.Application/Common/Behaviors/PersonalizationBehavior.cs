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

/// <summary>Runs before <see cref="CachingBehavior{TMessage,TResponse}"/>, so it personalizes cached and fresh results alike.</summary>
internal sealed class PersonalizationBehavior<TMessage, TResponse>(ICurrentUser viewer) : IPipelineBehavior<TMessage, TResponse>
    where TMessage : notnull, IMessage
{
    public async ValueTask<TResponse> Handle(TMessage message, MessageHandlerDelegate<TMessage, TResponse> next, CancellationToken cancellationToken)
    {
        var response = await next(message, cancellationToken);
        return message is IPersonalizedQuery<TResponse> query ? query.Personalize(response, viewer) : response;
    }
}
