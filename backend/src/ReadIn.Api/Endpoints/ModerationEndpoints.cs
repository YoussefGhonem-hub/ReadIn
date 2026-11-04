using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Moderation;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F22 Reporting &amp; Moderation (SPEC §17.2): reports, the moderators' queue, actions and log, and the notices of the
/// affected user.
/// </summary>
internal sealed class ModerationEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapPost("/reports", async (ReportContentCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Moderation")
            .WithSummary("Report an article, comment or user: reason spam | misinformation | harassment | copyright | other; again is a no-op");

        var moderation = api.MapGroup("/moderation").RequireAuthorization().WithTags("Moderation");

        moderation.MapGet("/summary", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetModerationSummaryQuery(), ct)).ToHttp(http))
            .WithSummary("Moderators: targets with open reports per type (the nav badge)")
            .Produces<ModerationSummaryDto>();

        moderation.MapGet("/reports", async (string? status, string? type, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetModerationQueueQuery(status, type, cursor, limit ?? 20), ct)).ToHttp(http))
            .WithSummary("Moderators: the queue, one item per target. status=open (default) | resolved | dismissed; type=article | comment | user")
            .Produces<CursorPage<ModerationQueueItemDto>>();

        moderation.MapGet("/reports/{targetType}/{targetId:guid}", async (string targetType, Guid targetId, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetModerationCaseQuery(targetType, targetId), ct)).ToHttp(http))
            .WithSummary("Moderators: one case, with the target, every report on it and its history")
            .Produces<ModerationCaseDto>();

        moderation.MapPost("/actions", async (ModerateContentCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Moderators: hide | unhide | delete | warn | suspend | unsuspend | dismiss; resolves reports, logged and audited");

        moderation.MapGet("/actions", async (Guid? targetUserId, Guid? moderatorId, string? targetType, string? cursor, int? limit, ISender sender,
                HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetModerationLogQuery(targetUserId, moderatorId, targetType, cursor, limit ?? 20), ct)).ToHttp(http))
            .WithSummary("Moderators: the moderation log, newest first; filter by affected user, moderator or target type")
            .Produces<CursorPage<ModerationActionDto>>();

        var notices = api.MapGroup("/me/moderation-notices").RequireAuthorization().WithTags("Moderation");

        notices.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyModerationNoticesQuery(), ct)).ToHttp(http))
            .WithSummary("Your warnings and hidden articles to acknowledge, oldest first")
            .Produces<ModerationNoticesDto>();

        notices.MapPost("/{id:guid}/acknowledge", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new AcknowledgeModerationNoticeCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Acknowledge a notice (\"فهمت\"); idempotent");
    }
}
