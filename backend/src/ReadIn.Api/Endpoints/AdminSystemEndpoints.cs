using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Admin.Announcements;
using ReadIn.Application.Features.Admin.Audit;
using ReadIn.Application.Features.Admin.SystemPage;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// The admin console's announcements, audit log and system page (SPEC F23, contract "Admin console (F23)"). Every route checks
/// its permission in the pipeline: <c>notifications.broadcast</c>, <c>audit.read</c>, <c>system.settings</c>.
/// </summary>
internal sealed class AdminSystemEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var admin = api.MapGroup("/admin").RequireAuthorization().WithTags("Admin");

        admin.MapGet("/announcements", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAnnouncementsQuery(), ct)).ToHttp(http))
            .WithSummary("Announcements (notifications.broadcast): whether one can be sent today, and the latest 50")
            .Produces<AnnouncementsDto>();

        admin.MapPost("/announcements/preview", async (AnnouncementRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new PreviewAnnouncementQuery(body.TitleAr, body.TitleEn, body.BodyAr, body.BodyEn, body.Link, body.Audience), ct))
                .ToHttp(http))
            .WithSummary("Who an announcement would reach now (recipients, pushes); nothing is sent")
            .Produces<AnnouncementPreviewDto>();

        admin.MapPost("/announcements/test", async (AnnouncementRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new TestAnnouncementCommand(body.TitleAr, body.TitleEn, body.BodyAr, body.BodyEn, body.Link, body.Audience), ct))
                .ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Send the announcement to yourself alone, at once; it isn't the day's announcement");

        admin.MapPost("/announcements", async (AnnouncementRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(
                    new SendAnnouncementCommand(body.TitleAr, body.TitleEn, body.BodyAr, body.BodyEn, body.Link, body.Audience), ct);
                return result.IsSuccess
                    ? TypedResults.Accepted("/api/v1/admin/announcements", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Send an announcement (one a day: 429 announcement.limit); the entries are written in the background")
            .Produces<AnnouncementDto>(StatusCodes.Status202Accepted);

        admin.MapGet("/audit", async (
                    string? actor, string? target, string? action, string? source, string? from, string? to, int? page, int? pageSize,
                    ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAuditLogQuery(actor, target, action, source, from, to, page, pageSize), ct)).ToHttp(http))
            .WithSummary("The audit log (audit.read): AuditLogs and the moderation log, newest first; IPs only with users.read.pii")
            .Produces<PagedList<AuditEntryDto>>();

        admin.MapGet("/system", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetSystemStatusQuery(), ct)).ToHttp(http))
            .WithSummary("System status (system.settings): API, update policy, database, Firebase, jobs, push failures, storage")
            .Produces<AdminSystemDto>();
    }
}
