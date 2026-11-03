using System.Reflection;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Behaviors;

/// <summary>Builds a failed <see cref="Result"/>/<see cref="Result{T}"/> for any handler response type.</summary>
internal static class ResultFailure<TResponse>
{
    private static readonly Func<Error, TResponse>? Factory = Build();

    public static bool IsSupported => Factory is not null;

    public static TResponse Create(Error error) =>
        Factory is not null
            ? Factory(error)
            : throw new InvalidOperationException($"{typeof(TResponse).Name} is not a Result type; handlers must return Result or Result<T>.");

    private static Func<Error, TResponse>? Build()
    {
        var type = typeof(TResponse);
        if (type == typeof(Result))
            return error => (TResponse)(object)Result.Failure(error);

        if (type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Result<>))
        {
            var method = typeof(Result)
                .GetMethod(nameof(Result.Failure), 1, BindingFlags.Public | BindingFlags.Static, [typeof(Error)])!
                .MakeGenericMethod(type.GetGenericArguments()[0]);
            return method.CreateDelegate<Func<Error, TResponse>>();
        }

        return null;
    }
}
