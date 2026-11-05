using Mediator;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Verification;
using ReadIn.Domain.Verification;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F19 Writer Verification (SPEC §17.2): a user's request and its status, and the admins' queue with approve and reject.
/// Proof files are private: only <c>GET /admin/verification-requests/{id}/proof</c> reads them, as an attachment.
/// </summary>
internal sealed class VerificationEndpoints : IEndpointGroup
{
    /// <summary>The proof file plus room for the multipart framing and the text fields next to it.</summary>
    private const long MaxBodyBytes = VerificationRequest.MaxProofBytes + 64 * 1024;

    private static readonly Domain.Common.Error RequestInvalid = Domain.Common.Error.Validation("request.invalid", "The request is invalid.");

    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/me/verification", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyVerificationQuery(), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithTags("Verification")
            .WithSummary("Your verification status: isVerified, canRequest and your latest request")
            .Produces<VerificationStatusDto>();

        api.MapPost("/verification-requests", async (ISender sender, HttpContext http, CancellationToken ct) =>
            {
                if (!http.Request.HasFormContentType) return RequestInvalid.ToProblem(http);

                // Read here rather than bound, so a body over the limit gets the same answer as a file that is too large
                // (verification.proof_invalid) instead of the framework's request.invalid.
                IFormCollection form;
                try
                {
                    http.Features.Set<IFormFeature>(new FormFeature(http.Request, new FormOptions { MultipartBodyLengthLimit = MaxBodyBytes }));
                    form = await http.Request.ReadFormAsync(ct);
                }
                catch (Exception ex) when (ex is InvalidDataException or BadHttpRequestException)
                {
                    return VerificationErrors.ProofInvalid.ToProblem(http);
                }

                var proof = form.Files.GetFile("proof");
                await using var content = proof?.OpenReadStream();
                var command = new SubmitVerificationRequestCommand(
                    Guid.TryParse(form["fieldId"], out var id) ? id : Guid.Empty,
                    form["jobTitle"],
                    form["proofUrl"],
                    form["note"],
                    content is null ? null : new VerificationProofUpload(content, proof!.FileName));
                var result = await sender.Send(command, ct);
                return result.IsSuccess
                    ? TypedResults.Created("/api/v1/me/verification", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            // Bearer tokens, no cookies: there is no cross-site form post to defend against.
            .DisableAntiforgery()
            .WithMetadata(new RequestSizeLimitAttribute(MaxBodyBytes))
            .Accepts<VerificationRequestForm>("multipart/form-data")
            .WithTags("Verification")
            .WithSummary("Request verification (multipart: fieldId, jobTitle, proofUrl?, note?, proof? = PDF/JPEG/PNG/WebP ≤ 10 MB); a URL or a file is required")
            .Produces<MyVerificationRequestDto>(StatusCodes.Status201Created);

        api.MapDelete("/me/verification", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new WithdrawVerificationRequestCommand(), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Verification")
            .WithSummary("Withdraw your pending request (deleted with its file)");

        var admin = api.MapGroup("/admin/verification-requests").RequireAuthorization().WithTags("Admin");

        admin.MapGet("/", async (string? status, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetVerificationRequestsQuery(status, cursor, limit ?? 20), ct)).ToHttp(http))
            .WithSummary("Admins (verification.manage): status=pending (default, oldest first) | approved | rejected (newest decided first)")
            .Produces<CursorPage<AdminVerificationRequestDto>>();

        admin.MapGet("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetVerificationRequestQuery(id), ct)).ToHttp(http))
            .WithSummary("Admins: one request")
            .Produces<AdminVerificationRequestDto>();

        admin.MapGet("/{id:guid}/proof", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetVerificationProofQuery(id), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);

                // Never cached, never sniffed, never shown inline by a browser: the client fetches it with the session.
                var proof = result.Value;
                http.Response.Headers.ContentDisposition = $"attachment; filename=\"{proof.FileName}\"";
                http.Response.Headers.CacheControl = "no-store";
                http.Response.Headers.XContentTypeOptions = "nosniff";
                return Results.Stream(proof.Content, proof.ContentType);
            })
            .WithSummary("Admins: the private proof file (attachment, no-store); 404 verification.proof_not_found once decided")
            .Produces(StatusCodes.Status200OK, contentType: "application/octet-stream");

        admin.MapPost("/{id:guid}/approve", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new ApproveVerificationRequestCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins: approve; the user gets the Verified badge (no role change) and a notification, the proof file is deleted");

        admin.MapPost("/{id:guid}/reject", async (Guid id, RejectVerificationRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RejectVerificationRequestCommand(id, body.Reason), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins: reject with a reason (5–500 characters) the user sees; the proof file is deleted");

        api.MapDelete("/admin/users/{id:guid}/verification", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RemoveVerificationCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Admin")
            .WithSummary("Admins (verification.manage): remove a user's Verified badge; 409 verification.not_verified without one, 409 verification.system_account for the official account");
    }
}

/// <summary>The multipart form of POST /verification-requests, for the OpenAPI document only (the endpoint reads the form itself).</summary>
/// <param name="FieldId">An enabled field's id.</param>
/// <param name="JobTitle">2–100 characters.</param>
/// <param name="ProofUrl">An absolute https URL (≤ 500); this and/or <paramref name="Proof"/>.</param>
/// <param name="Note">≤ 500 characters.</param>
/// <param name="Proof">A PDF, JPEG, PNG or WebP of at most 10 MB.</param>
internal sealed record VerificationRequestForm(Guid FieldId, string JobTitle, string? ProofUrl, string? Note, IFormFile? Proof);
