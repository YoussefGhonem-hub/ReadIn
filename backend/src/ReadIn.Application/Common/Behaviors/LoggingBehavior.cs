using System.Diagnostics;
using Mediator;
using Microsoft.Extensions.Logging;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Behaviors;

internal sealed partial class LoggingBehavior<TMessage, TResponse>(ILogger<LoggingBehavior<TMessage, TResponse>> logger)
    : IPipelineBehavior<TMessage, TResponse>
    where TMessage : notnull, IMessage
{
    public async ValueTask<TResponse> Handle(TMessage message, MessageHandlerDelegate<TMessage, TResponse> next, CancellationToken cancellationToken)
    {
        var name = typeof(TMessage).Name;
        var started = Stopwatch.GetTimestamp();

        var response = await next(message, cancellationToken);

        var elapsed = Stopwatch.GetElapsedTime(started).TotalMilliseconds;
        if (response is Result { IsFailure: true } failed)
            LogFailed(logger, name, failed.Error.Code, elapsed);
        else
            LogHandled(logger, name, elapsed);

        return response;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Handled {Message} in {ElapsedMs:0.0} ms")]
    private static partial void LogHandled(ILogger logger, string message, double elapsedMs);

    [LoggerMessage(Level = LogLevel.Warning, Message = "{Message} failed with {ErrorCode} in {ElapsedMs:0.0} ms")]
    private static partial void LogFailed(ILogger logger, string message, string errorCode, double elapsedMs);
}
