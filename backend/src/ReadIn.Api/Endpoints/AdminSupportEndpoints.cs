using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Admin.Support;
using ReadIn.Application.Features.Support;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F35 Help &amp; support, the console's ticket queue (SPEC §17.2 "Admin"): the queue, a ticket's page, replies and internal
/// notes, closing, reopening and the category. Every route needs <c>support.manage</c>.
/// </summary>
internal sealed class AdminSupportEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var tickets = api.MapGroup("/admin/support/tickets").RequireAuthorization().WithTags("Admin");

        tickets.MapGet("/", async (string? status, string? category, string? q, int? page, int? pageSize, ISender sender, HttpContext http,
                    CancellationToken ct) =>
                (await sender.Send(new GetAdminTicketsQuery(status, category, q, page, pageSize), ct)).ToHttp(http))
            .WithSummary("Admins (support.manage): the ticket queue; status = open (default, waiting longest first) | answered | closed; " +
                "category; q = subject words, the member's name or @username, or #12")
            .Produces<PagedList<AdminTicketRowDto>>();

        tickets.MapGet("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminTicketQuery(id), ct)).ToHttp(http))
            .WithSummary("Admins (support.manage): a ticket with its notes, the member's card and their reports and suspensions")
            .Produces<AdminTicketDto>();

        tickets.MapPost("/{id:guid}/messages", async (Guid id, AdminTicketMessageRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new AddAdminTicketMessageCommand(id, body.Body, body.Internal), ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/admin/support/tickets/{id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins (support.manage): reply (the ticket becomes Answered, the member is told) or add an internal note (internal: true)")
            .Produces<AdminSupportMessageDto>(StatusCodes.Status201Created);

        tickets.MapPatch("/{id:guid}", async (Guid id, AdminTicketUpdateRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UpdateAdminTicketCommand(id, body.Status, body.Category), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins (support.manage): close (status: closed; the member is told) or reopen (open), and/or change the category")
            .Produces<AdminTicketDto>();
    }
}

/// <summary>Body of POST /admin/support/tickets/{id}/messages.</summary>
/// <param name="Body">1–2000 characters after trimming.</param>
/// <param name="Internal">An internal note only admins see.</param>
internal sealed record AdminTicketMessageRequest(string? Body, bool Internal);

/// <summary>Body of PATCH /admin/support/tickets/{id}: at least one of the two.</summary>
/// <param name="Status"><c>open</c> | <c>closed</c>.</param>
internal sealed record AdminTicketUpdateRequest(string? Status, string? Category);
