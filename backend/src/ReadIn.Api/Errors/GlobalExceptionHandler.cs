using Microsoft.AspNetCore.Diagnostics;
using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Common;

namespace ReadIn.Api.Errors;

/// <summary>Unhandled exceptions → ProblemDetails (no internals leaked) + Serilog with the trace id (SPEC §6.5).</summary>
internal sealed partial class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var error = exception switch
        {
            BadHttpRequestException => Error.Validation("request.invalid", "The request is invalid."),
            DbUpdateConcurrencyException => Error.Conflict("concurrency.conflict", "The data was changed by someone else."),
            OperationCanceledException when httpContext.RequestAborted.IsCancellationRequested => null,
            _ => Error.Failure("server.error", "Something went wrong."),
        };

        if (error is null) return true; // client went away

        if (error.Type == ErrorType.Failure) LogUnhandled(logger, exception, httpContext.Request.Method, httpContext.Request.Path);

        await error.ToProblem(httpContext).ExecuteAsync(httpContext);
        return true;
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Unhandled exception for {Method} {Path}")]
    private static partial void LogUnhandled(ILogger logger, Exception exception, string method, string path);
}
