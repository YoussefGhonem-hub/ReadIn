using Mediator;
using Microsoft.AspNetCore.Mvc;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Uploads;
using ReadIn.Application.Features.Uploads.Commands.UploadImage;

namespace ReadIn.Api.Endpoints;

internal sealed class UploadEndpoints : IEndpointGroup
{
    /// <summary>The 5 MB file plus room for the multipart framing and the purpose field.</summary>
    private const long MaxRequestBytes = UploadLimits.MaxBytes + 64 * 1024;

    public void Map(RouteGroupBuilder api)
    {
        api.MapPost("/uploads", async ([FromForm] string purpose, IFormFile file, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                await using var content = file.OpenReadStream();
                var result = await sender.Send(new UploadImageCommand(purpose, content, file.Length), ct);
                return result.IsSuccess
                    ? TypedResults.Created(result.Value.Url, result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Uploads)
            // Bearer tokens, no cookies: there is no cross-site form post to defend against.
            .DisableAntiforgery()
            .WithMetadata(new RequestSizeLimitAttribute(MaxRequestBytes))
            .WithFormOptions(multipartBodyLengthLimit: MaxRequestBytes)
            .WithTags("Uploads")
            .WithSummary("Upload an image (multipart: file + purpose = avatar | cover | article-image); stored as WebP")
            .Produces<UploadedImageDto>(StatusCodes.Status201Created);
    }
}
