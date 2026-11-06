using System.Text;
using System.Threading.RateLimiting;
using Mediator;
using Microsoft.AspNetCore.RateLimiting;
using ReadIn.Api.Auth;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Articles.Pdf;

namespace ReadIn.Api.Endpoints;

/// <summary><c>GET /articles/{id}/pdf</c> (SPEC F33, §24): your own article as a PDF, built in the request.</summary>
internal sealed class ArticlePdfEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/articles/{id:guid}/pdf", async (Guid id, string? lang, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetArticlePdfQuery(id, lang), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);

                var headers = http.Response.Headers;
                headers.ContentDisposition = ContentDisposition(result.Value.FileName);
                headers.XContentTypeOptions = "nosniff";
                headers.CacheControl = "private, no-store";
                return Results.Bytes(result.Value.Content, "application/pdf");
            })
            .RequireAuthorization()
            .RequireRateLimiting(ArticlePdfRateLimitPolicy.Name)
            .WithTags("Articles")
            .WithSummary("Your own published or archived article as a PDF (F33); ?lang=ar-EG|en picks the version (falls back to the source language)")
            .Produces<Stream>(StatusCodes.Status200OK, "application/pdf")
            .ProducesProblem(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status409Conflict)
            .ProducesProblem(StatusCodes.Status429TooManyRequests)
            .ProducesProblem(StatusCodes.Status500InternalServerError)
            .ProducesProblem(StatusCodes.Status503ServiceUnavailable);
    }

    /// <summary>
    /// <c>attachment</c> with the ASCII fallback <c>readin-article.pdf</c> and the real name as RFC 5987 <c>filename*</c>,
    /// so an Arabic slug survives every browser and the share sheet.
    /// </summary>
    public static string ContentDisposition(string fileName) =>
        $"attachment; filename=\"{ArticlePdfFile.AsciiFileName}\"; filename*=UTF-8''{Rfc5987(fileName)}";

    /// <summary>RFC 5987 <c>attr-char</c>s stay; every other UTF-8 byte is percent-encoded.</summary>
    internal static string Rfc5987(string value)
    {
        var encoded = new StringBuilder(value.Length * 3);
        foreach (var b in Encoding.UTF8.GetBytes(value))
        {
            var c = (char)b;
            if (char.IsAsciiLetterOrDigit(c) || "!#$&+-.^_`|~".Contains(c, StringComparison.Ordinal)) encoded.Append(c);
            else encoded.Append('%').Append(b.ToString("X2", System.Globalization.CultureInfo.InvariantCulture));
        }
        return encoded.ToString();
    }
}

/// <summary>
/// 10 PDFs per user per hour (SPEC F33; <c>RateLimits:ArticlePdfPerHour</c>): a fixed one-hour window per user, in memory,
/// so per API instance. A rejected request answers <c>429 article.pdf_limit</c>, not the generic <c>rate_limited</c>.
/// </summary>
internal sealed class ArticlePdfRateLimitPolicy(IConfiguration configuration) : IRateLimiterPolicy<string>
{
    public const string Name = "article-pdf";

    private readonly int _perHour = configuration.GetValue("RateLimits:ArticlePdfPerHour", 10);

    public Func<OnRejectedContext, CancellationToken, ValueTask>? OnRejected { get; } = static async (context, _) =>
        await ArticlePdfErrors.Limit.ToProblem(context.HttpContext).ExecuteAsync(context.HttpContext);

    public RateLimitPartition<string> GetPartition(HttpContext httpContext) =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.User.FindFirst(JwtClaims.Subject)?.Value ?? httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            _ => new FixedWindowRateLimiterOptions { PermitLimit = _perHour, Window = TimeSpan.FromHours(1) });
}
