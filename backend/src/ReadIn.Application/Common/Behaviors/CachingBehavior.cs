using System.Reflection;
using Mediator;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Behaviors;

/// <summary>A query whose successful result is cached in <see cref="HybridCache"/> and invalidated by tag (SPEC §6.3).</summary>
public interface ICachedQuery
{
    string CacheKey { get; }
    IReadOnlyCollection<string> CacheTags { get; }
    TimeSpan Expiration { get; }
}

/// <summary>Cache tags shared by queries and the event handlers that invalidate them.</summary>
public static class CacheTags
{
    public const string Taxonomy = "taxonomy";
    public const string Feed = "feed";
    public const string Articles = "articles";

    public static string Article(string slug) => $"article:{slug}";
}

internal sealed class CachingBehavior<TMessage, TResponse>(HybridCache cache) : IPipelineBehavior<TMessage, TResponse>
    where TMessage : notnull, IMessage
{
    public ValueTask<TResponse> Handle(TMessage message, MessageHandlerDelegate<TMessage, TResponse> next, CancellationToken cancellationToken)
    {
        if (message is not ICachedQuery query || !CachedResult<TResponse>.IsSupported)
            return next(message, cancellationToken);

        return CachedResult<TResponse>.Run(cache, query, () => next(message, cancellationToken), cancellationToken);
    }
}

/// <summary>
/// Caches only the success value of a <see cref="Result{T}"/>. Failures are never cached: the factory throws
/// to abort the cache write and the failure is returned as-is.
/// </summary>
internal static class CachedResult<TResponse>
{
    private delegate ValueTask<TResponse> Runner(HybridCache cache, ICachedQuery query, Func<ValueTask<TResponse>> next, CancellationToken ct);

    private static readonly Runner? Invoker = Build();

    public static bool IsSupported => Invoker is not null;

    public static ValueTask<TResponse> Run(HybridCache cache, ICachedQuery query, Func<ValueTask<TResponse>> next, CancellationToken ct) =>
        Invoker!(cache, query, next, ct);

    private static Runner? Build()
    {
        var type = typeof(TResponse);
        if (!type.IsGenericType || type.GetGenericTypeDefinition() != typeof(Result<>)) return null;

        var method = typeof(CachedResult<TResponse>)
            .GetMethod(nameof(RunTyped), BindingFlags.NonPublic | BindingFlags.Static)!
            .MakeGenericMethod(type.GetGenericArguments()[0]);
        return method.CreateDelegate<Runner>();
    }

    private static async ValueTask<TResponse> RunTyped<T>(HybridCache cache, ICachedQuery query, Func<ValueTask<TResponse>> next, CancellationToken ct)
    {
        try
        {
            var value = await cache.GetOrCreateAsync(
                query.CacheKey,
                next,
                static async (next, _) =>
                {
                    var result = (Result<T>)(object)(await next())!;
                    return result.IsSuccess ? result.Value : throw new SkipCacheException(result);
                },
                new HybridCacheEntryOptions { Expiration = query.Expiration, LocalCacheExpiration = query.Expiration },
                query.CacheTags,
                ct);

            return (TResponse)(object)Result.Success(value);
        }
        catch (SkipCacheException skip)
        {
            return (TResponse)skip.Result;
        }
    }

    private sealed class SkipCacheException(object result) : Exception
    {
        public object Result { get; } = result;
    }
}
