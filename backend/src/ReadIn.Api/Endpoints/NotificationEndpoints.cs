using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Notifications;

namespace ReadIn.Api.Endpoints;

/// <summary>F17 Notifications (SPEC §17.2, §21.1): the center, the badge and the settings. Reads unthrottled, writes on <c>writes</c>.</summary>
internal sealed class NotificationEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var notifications = api.MapGroup("/me/notifications").RequireAuthorization().WithTags("Notifications");

        notifications.MapGet("/", async (string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetNotificationsQuery(cursor, limit ?? 20), ct)).ToHttp(http))
            .WithSummary("The notification center, latest activity first (limit 1–50, default 20)")
            .Produces<CursorPage<NotificationDto>>();

        notifications.MapGet("/unread-count", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetUnreadNotificationsQuery(), ct)).ToHttp(http))
            .WithSummary("The badge: entries not seen yet (the REST fallback of /live/users/{id}/unreadNotifications)")
            .Produces<UnreadNotificationsDto>();

        notifications.MapPost("/seen", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new MarkNotificationsSeenCommand(), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Opening the center: every entry is seen, the badge goes to 0; entries stay unread until opened");

        notifications.MapPost("/{id:guid}/read", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new MarkNotificationReadCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("An entry or its push was opened; idempotent");

        notifications.MapPost("/read-all", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new MarkAllNotificationsReadCommand(), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Mark every entry read");

        var settings = api.MapGroup("/me/notification-settings").RequireAuthorization().WithTags("Notifications");

        settings.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetNotificationSettingsQuery(), ct)).ToHttp(http))
            .WithSummary("Quiet hours and every configurable type's mode (all | inApp | off)")
            .Produces<NotificationSettingsDto>();

        settings.MapPut("/", async (UpdateNotificationSettingsCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Change quiet hours and the modes of the types sent; security alerts and moderation notices always come");
    }
}
