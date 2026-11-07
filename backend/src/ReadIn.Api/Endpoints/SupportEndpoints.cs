using Mediator;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Support;
using ReadIn.Domain.Support;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F35 Help & support, the member's side (SPEC §17.2 "Support"): the public config, sending a ticket with screenshots, the
/// member's tickets and their conversation, closing and reopening, and the private screenshots (owner or support.manage).
/// </summary>
internal sealed class SupportEndpoints : IEndpointGroup
{
    /// <summary>Three screenshots plus room for the multipart framing and the text fields next to them.</summary>
    private const long MaxBodyBytes = SupportAttachment.MaxPerMessage * (long)SupportAttachment.MaxBytes + 64 * 1024;

    private static readonly Domain.Common.Error RequestInvalid = Domain.Common.Error.Validation("request.invalid", "The request is invalid.");

    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/support/config", async (ISender sender, HttpContext http, CancellationToken ct) =>
            {
                http.Response.Headers.CacheControl = "public, max-age=300";
                return (await sender.Send(new GetSupportConfigQuery(), ct)).ToHttp(http);
            })
            .AllowAnonymous()
            .WithTags("Support")
            .WithSummary("The support email (null when not set) and the ticket form's rules; anonymous")
            .Produces<SupportConfigDto>();

        var tickets = api.MapGroup("/support/tickets").RequireAuthorization().WithTags("Support");

        tickets.MapPost("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var form = await ReadFormAsync(http, ct);
                if (form.Problem is { } problem) return problem;
                var (fields, files) = form.Value!.Value;
                var result = await sender.Send(new CreateSupportTicketCommand(
                    fields["category"], fields["subject"], fields["message"], fields["platform"], fields["osVersion"], fields["appVersion"],
                    fields["language"], fields["screen"], files), ct);
                await DisposeAsync(files);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/support/tickets/{result.Value.Id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            // Bearer tokens, no cookies: there is no cross-site form post to defend against.
            .DisableAntiforgery()
            .WithMetadata(new RequestSizeLimitAttribute(MaxBodyBytes))
            .Accepts<SupportTicketForm>("multipart/form-data")
            .WithSummary("Send a ticket (multipart: category, subject 5–120, message 10–2000, device fields, screenshots ≤ 3 JPEG/PNG/WebP ≤ 5 MB); 5 a day, 10 open")
            .Produces<SupportTicketDto>(StatusCodes.Status201Created);

        tickets.MapGet("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetSupportTicketQuery(id), ct)).ToHttp(http))
            .WithSummary("Your ticket and its conversation (no internal notes); someone else's is 404")
            .Produces<SupportTicketDto>();

        tickets.MapPost("/{id:guid}/messages", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var form = await ReadFormAsync(http, ct);
                if (form.Problem is { } problem) return problem;
                var (fields, files) = form.Value!.Value;
                var result = await sender.Send(new PostSupportMessageCommand(id, fields["message"], files), ct);
                await DisposeAsync(files);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/support/tickets/{id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .DisableAntiforgery()
            .WithMetadata(new RequestSizeLimitAttribute(MaxBodyBytes))
            .Accepts<SupportMessageForm>("multipart/form-data")
            .WithSummary("Write on your ticket (multipart: message 1–2000, screenshots ≤ 3); an Answered ticket is Open again, a closed one is 409")
            .Produces<SupportMessageDto>(StatusCodes.Status201Created);

        tickets.MapPost("/{id:guid}/close", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new CloseSupportTicketCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Close your ticket (idempotent)");

        tickets.MapPost("/{id:guid}/reopen", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new ReopenSupportTicketCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Reopen your closed ticket within 30 days of closing (409 support.reopen_expired later)");

        api.MapGet("/me/support/tickets", async (string? status, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMySupportTicketsQuery(status, cursor, limit ?? 20), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithTags("Support")
            .WithSummary("Your tickets, latest activity first; status = active (open or answered) | closed")
            .Produces<CursorPage<SupportTicketSummaryDto>>();

        api.MapGet("/support/attachments/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetSupportAttachmentQuery(id), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);

                // Never cached, never sniffed, never shown inline by a browser: the client fetches it with the session.
                var file = result.Value;
                http.Response.Headers.ContentDisposition = $"attachment; filename=\"{file.FileName}\"";
                http.Response.Headers.CacheControl = "no-store";
                http.Response.Headers.XContentTypeOptions = "nosniff";
                return Results.Stream(file.Content, file.ContentType);
            })
            .RequireAuthorization()
            .WithTags("Support")
            .WithSummary("A ticket's screenshot: its owner or support.manage (attachment, no-store); anyone else 404")
            .Produces(StatusCodes.Status200OK, contentType: "application/octet-stream");
    }

    private sealed record FormResult(IResult? Problem, (IFormCollection Fields, List<SupportScreenshotUpload> Files)? Value);

    /// <summary>
    /// Reads the multipart body here rather than binding it, so a body over the limit gets the same answer as a screenshot
    /// that is too large (<c>support.attachment_invalid</c>). Another content type (JSON) never gets here: the endpoint
    /// only accepts multipart, so it is <c>415 request.unsupported_media_type</c>.
    /// </summary>
    private static async Task<FormResult> ReadFormAsync(HttpContext http, CancellationToken ct)
    {
        if (!http.Request.HasFormContentType) return new FormResult(RequestInvalid.ToProblem(http), null);

        IFormCollection form;
        try
        {
            http.Features.Set<IFormFeature>(new FormFeature(http.Request, new FormOptions { MultipartBodyLengthLimit = MaxBodyBytes }));
            form = await http.Request.ReadFormAsync(ct);
        }
        catch (Exception ex) when (ex is InvalidDataException or BadHttpRequestException)
        {
            return new FormResult(SupportErrors.AttachmentInvalid.ToProblem(http), null);
        }

        var files = form.Files.GetFiles("screenshots").Select(f => new SupportScreenshotUpload(f.OpenReadStream())).ToList();
        return new FormResult(null, (form, files));
    }

    private static async Task DisposeAsync(List<SupportScreenshotUpload> files)
    {
        foreach (var file in files) await file.Content.DisposeAsync();
    }
}

/// <summary>The multipart form of POST /support/tickets, for the OpenAPI document only (the endpoint reads the form itself).</summary>
/// <param name="Category">app_problem | account | content | verification | suggestion | other.</param>
/// <param name="Subject">5–120 characters.</param>
/// <param name="Message">10–2000 characters.</param>
/// <param name="Platform">ios | android | web (optional).</param>
/// <param name="OsVersion">Optional, ≤ 60.</param>
/// <param name="AppVersion">Optional, ≤ 40, e.g. 1.2.0+57.</param>
/// <param name="Language">ar | en (optional): the UI language.</param>
/// <param name="Screen">Optional, ≤ 100: the route the ticket came from.</param>
/// <param name="Screenshots">Up to 3 JPEG, PNG or WebP images of at most 5 MB each.</param>
internal sealed record SupportTicketForm(
    string Category, string Subject, string Message, string? Platform, string? OsVersion, string? AppVersion, string? Language,
    string? Screen, IFormFileCollection? Screenshots);

/// <summary>The multipart form of POST /support/tickets/{id}/messages, for the OpenAPI document only.</summary>
/// <param name="Message">1–2000 characters.</param>
/// <param name="Screenshots">Up to 3 JPEG, PNG or WebP images of at most 5 MB each.</param>
internal sealed record SupportMessageForm(string Message, IFormFileCollection? Screenshots);
