using System.Threading.RateLimiting;
using Mediator;
using Microsoft.AspNetCore.RateLimiting;
using ReadIn.Api.Auth;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Articles.QuoteCards;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// <c>POST /articles/{id}/quote-card</c> (SPEC F24, §24, ADR 0019): a PNG of a selected quote for social media, drawn in
/// the request with the article PDFs' Chromium. Guests too.
/// </summary>
internal sealed class QuoteCardEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapPost("/articles/{id:guid}/quote-card", async (Guid id, QuoteCardRequest? body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new RenderQuoteCardQuery(
                    id, body?.Language, body?.BlockId, body?.StartOffset, body?.EndOffset, body?.Text, body?.Theme, body?.Format), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);

                var headers = http.Response.Headers;
                headers.ContentDisposition = ContentDisposition(result.Value.FileName);
                headers.XContentTypeOptions = "nosniff";
                // Public content, but per request: a POST answer is never stored by shared caches anyway.
                headers.CacheControl = "private, max-age=600";
                return Results.Bytes(result.Value.Content, "image/png");
            })
            .AllowAnonymous()
            .RequireRateLimiting(QuoteCardRateLimitPolicy.Name)
            .WithTags("Articles")
            .WithSummary("A quote card (F24): a PNG of an F30 range of the version being read; theme light|dark, format square (1080×1080) | landscape (1200×630)")
            .Produces<Stream>(StatusCodes.Status200OK, "image/png")
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status409Conflict)
            .ProducesProblem(StatusCodes.Status429TooManyRequests)
            .ProducesProblem(StatusCodes.Status500InternalServerError)
            .ProducesProblem(StatusCodes.Status503ServiceUnavailable);
    }

    /// <summary>
    /// <c>inline</c> with the ASCII fallback <c>readin-quote.png</c> and the real name as RFC 5987 <c>filename*</c>, as the
    /// article PDF, so any slug survives the browser and the share sheet.
    /// </summary>
    public static string ContentDisposition(string fileName) =>
        $"inline; filename=\"{QuoteCardFile.AsciiFileName}\"; filename*=UTF-8''{ArticlePdfEndpoints.Rfc5987(fileName)}";
}

/// <summary>Body of POST /articles/{id}/quote-card. Nullable, so a missing member is the validation code validation.required.</summary>
internal sealed record QuoteCardRequest(
    string? Language, string? BlockId, int? StartOffset, int? EndOffset, string? Text, string? Theme, string? Format);

/// <summary>
/// 30 quote cards per user per hour, guests per IP address (SPEC F24; <c>RateLimits:QuoteCardPerHour</c>): a fixed one-hour
/// window, in memory, so per API instance. A rejected request answers <c>429 quote.limit</c>, not the generic
/// <c>rate_limited</c>.
/// </summary>
internal sealed class QuoteCardRateLimitPolicy(IConfiguration configuration) : IRateLimiterPolicy<string>
{
    public const string Name = "quote-card";

    private readonly int _perHour = configuration.GetValue("RateLimits:QuoteCardPerHour", 30);

    public Func<OnRejectedContext, CancellationToken, ValueTask>? OnRejected { get; } = static async (context, _) =>
        await QuoteCardErrors.Limit.ToProblem(context.HttpContext).ExecuteAsync(context.HttpContext);

    public RateLimitPartition<string> GetPartition(HttpContext httpContext) =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.User.FindFirst(JwtClaims.Subject)?.Value is { } user
                ? "user:" + user
                : "ip:" + (httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous"),
            _ => new FixedWindowRateLimiterOptions { PermitLimit = _perHour, Window = TimeSpan.FromHours(1) });
}
