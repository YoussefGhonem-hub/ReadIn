using System.Diagnostics;
using ReadIn.Api.Auth;
using ReadIn.Domain.Common;

namespace ReadIn.Api.Errors;

/// <summary>Maps <see cref="Result"/>s to HTTP responses; errors become RFC 9457 ProblemDetails with a stable <c>code</c> (SPEC §6.5).</summary>
public static class ProblemResults
{
    public static IResult ToHttp(this Result result, HttpContext context) =>
        result.IsSuccess ? TypedResults.NoContent() : result.Error.ToProblem(context);

    public static IResult ToHttp<T>(this Result<T> result, HttpContext context) =>
        result.IsSuccess ? TypedResults.Ok(result.Value) : result.Error!.ToProblem(context);

    public static IResult ToProblem(this Error error, HttpContext context)
    {
        var status = error.Type switch
        {
            ErrorType.Validation => StatusCodes.Status400BadRequest,
            ErrorType.NotFound => StatusCodes.Status404NotFound,
            ErrorType.Conflict => StatusCodes.Status409Conflict,
            ErrorType.Forbidden => StatusCodes.Status403Forbidden,
            ErrorType.Unauthorized => StatusCodes.Status401Unauthorized,
            ErrorType.TooManyRequests => StatusCodes.Status429TooManyRequests,
            _ => StatusCodes.Status500InternalServerError,
        };

        var extensions = new Dictionary<string, object?>
        {
            ["code"] = error.Code,
            ["traceId"] = Activity.Current?.Id ?? context.TraceIdentifier,
        };
        if (error.Details is not null) extensions["errors"] = error.Details;

        return TypedResults.Problem(
            title: ErrorMessages.Title(error.Code, RequestLanguage.Resolve(context)) ?? error.Description,
            statusCode: status,
            type: $"https://readin.app/errors/{error.Type.ToString().ToLowerInvariant()}",
            extensions: extensions);
    }

    /// <summary>Default codes for responses produced by the framework (401 challenge, 404 route, 429 limiter…).</summary>
    public static string CodeForStatus(int? status) => status switch
    {
        StatusCodes.Status400BadRequest => "request.invalid",
        StatusCodes.Status401Unauthorized => "auth.unauthorized",
        StatusCodes.Status403Forbidden => "auth.forbidden",
        StatusCodes.Status404NotFound => "route.not_found",
        StatusCodes.Status405MethodNotAllowed => "route.method_not_allowed",
        StatusCodes.Status409Conflict => "concurrency.conflict",
        StatusCodes.Status413PayloadTooLarge => "request.too_large",
        StatusCodes.Status429TooManyRequests => "rate_limited",
        _ => "server.error",
    };
}
