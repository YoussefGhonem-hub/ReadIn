using Mediator;
using Microsoft.AspNetCore.Mvc;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Uploads;
using ReadIn.Application.Features.Uploads.Commands.DeleteMediaAsset;
using ReadIn.Application.Features.Uploads.Commands.UploadDocument;
using ReadIn.Application.Features.Uploads.Commands.UploadImage;
using ReadIn.Application.Features.Uploads.Queries.GetDocumentDownload;
using ReadIn.Application.Features.Uploads.Queries.GetMediaAsset;

namespace ReadIn.Api.Endpoints;

/// <summary>Images and PDF documents (SPEC §24, ADR 0010, ADR 0011).</summary>
internal sealed class UploadEndpoints : IEndpointGroup
{
    /// <summary>Room for the multipart framing and the text fields next to the file.</summary>
    private const long FormOverhead = 64 * 1024;

    public void Map(RouteGroupBuilder api)
    {
        var uploads = api.MapGroup("/uploads").WithTags("Uploads").RequireAuthorization();

        uploads.MapPost("/images", async ([FromForm] string? purpose, IFormFile file, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                await using var content = file.OpenReadStream();
                var result = await sender.Send(new UploadImageCommand(purpose ?? UploadPurpose.ArticleImage.Name, content, file.Length), ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/uploads/{result.Value.Id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Uploads)
            // Bearer tokens, no cookies: there is no cross-site form post to defend against.
            .DisableAntiforgery()
            .WithMetadata(new RequestSizeLimitAttribute(UploadLimits.MaxBytes + FormOverhead))
            .WithFormOptions(multipartBodyLengthLimit: UploadLimits.MaxBytes + FormOverhead)
            .WithSummary("Upload an image (multipart: file + purpose = image | avatar | cover); stored as responsive WebP variants")
            .Produces<MediaAssetDto>(StatusCodes.Status201Created);

        uploads.MapPost("/documents", async ([FromForm] string? title, [FromForm] bool? allowDownload, IFormFile file,
                ISender sender, HttpContext http, CancellationToken ct) =>
            {
                await using var content = file.OpenReadStream();
                var result = await sender.Send(new UploadDocumentCommand(content, file.FileName, title, allowDownload ?? true), ct);
                return result.IsSuccess
                    ? TypedResults.Accepted($"/api/v1/uploads/{result.Value.Id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Uploads)
            .DisableAntiforgery()
            .WithMetadata(new RequestSizeLimitAttribute(UploadLimits.MaxDocumentBytes + FormOverhead))
            .WithFormOptions(multipartBodyLengthLimit: UploadLimits.MaxDocumentBytes + FormOverhead)
            .WithSummary("Upload a PDF (multipart: file + title + allowDownload, default true); pages are rendered in the background")
            .Produces<MediaAssetDto>(StatusCodes.Status202Accepted);

        uploads.MapGet("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMediaAssetQuery(id), ct)).ToHttp(http))
            .WithSummary("An own upload and its processing state (poll every 2 s while processing)")
            .Produces<MediaAssetDto>();

        uploads.MapDelete("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeleteMediaAssetCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete an own upload that is not attached to an article");

        api.MapGet("/documents/{assetId:guid}/download", async (Guid assetId, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetDocumentDownloadQuery(assetId), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);

                // The original PDF is never shown inline or run in our origin: attachment + sandboxed CSP (ADR 0011).
                http.Response.Headers.ContentSecurityPolicy = "sandbox";
                http.Response.Headers.XContentTypeOptions = "nosniff";
                http.Response.Headers.CacheControl = "private, no-store";
                return Results.File(result.Value.Content, "application/pdf", result.Value.FileName);
            })
            .AllowAnonymous()
            .WithTags("Uploads")
            .WithSummary("Download the original PDF of a document attachment (author's permission, or owner / moderator)")
            .Produces(StatusCodes.Status200OK, contentType: "application/pdf");
    }
}
