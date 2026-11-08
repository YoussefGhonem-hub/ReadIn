using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Moderation;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Notifications.EventHandlers;

// Reports (SPEC F22 store requirements): staff hear about a new report at once (report_new), and the reporter about the
// outcome (report_resolved). Both are idempotent, as the outbox delivers at least once.

/// <summary>
/// A report was filed (or a system report flagged again) → <c>report_new</c> to every holder of <c>moderation.manage</c> but
/// the reporter: one entry per target (grouped, no actor: reporters stay anonymous here), the open count and the target's
/// label, at most one push per target per hour.
/// </summary>
internal sealed class ReportFiledNotificationHandler(IAppDbContext db, ModerationReader reader, NotificationWriter writer)
    : IDomainEventHandler<ReportFiledDomainEvent>
{
    public static readonly TimeSpan PushInterval = TimeSpan.FromHours(1);

    public async Task Handle(ReportFiledDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var report = await db.Reports.AsNoTracking()
            .Where(r => r.Id == domainEvent.ReportId && r.Status == ReportStatus.Open)
            .Select(r => new { r.Id, r.ReporterId })
            .FirstOrDefaultAsync(cancellationToken);
        if (report is null) return; // closed (or gone) before the event was handled: nothing to tell

        var holders = await ReportNotifications.HoldersAsync(db, Permissions.Moderation.Manage, cancellationToken);
        if (holders.Count == 0) return;

        var openCount = await db.Reports.AsNoTracking().CountAsync(
            r => r.TargetType == domainEvent.TargetType && r.TargetId == domainEvent.TargetId && r.Status == ReportStatus.Open, cancellationToken);
        var label = await ReportNotifications.LabelAsync(reader, domainEvent.TargetType, domainEvent.TargetId, cancellationToken);
        var data = new NotificationData
        {
            TargetType = ReportNotifications.Name(domainEvent.TargetType),
            TargetId = domainEvent.TargetId,
            TargetLabel = label,
            ReportCount = openCount,
            System = report.ReporterId is null ? true : null,
            SourceKey = $"r:{report.Id:N}:{domainEvent.OccurredAt.Ticks}",
        };

        await writer.WriteAsync(
            [
                .. holders.Where(id => id != report.ReporterId).Select(id => new NotificationRequest(id, NotificationTypes.ReportNew)
                {
                    GroupKey = ReportNotifications.Group(domainEvent.TargetType, domainEvent.TargetId),
                    GroupsWithoutActor = true,
                    MinPushInterval = PushInterval,
                    Data = data,
                }),
            ],
            cancellationToken);
    }
}

/// <summary>
/// A moderator resolved or dismissed a report → <c>report_resolved</c> to its reporter (not for system reports): in-app only,
/// never pushed, no actor and no article, so it never names who acted or what was done, and stays when the content is gone.
/// </summary>
internal sealed class ReportClosedNotificationHandler(ModerationReader reader, NotificationWriter writer)
    : IDomainEventHandler<ReportClosedDomainEvent>
{
    public async Task Handle(ReportClosedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (domainEvent.ReporterId is not { } reporterId) return;

        await writer.WriteAsync(new NotificationRequest(reporterId, NotificationTypes.ReportResolved)
        {
            DedupeKey = $"{NotificationTypes.ReportResolved}:{domainEvent.ReportId:N}",
            // In-app only: the push job leaves it alone.
            PushedByCaller = true,
            Data = new NotificationData
            {
                TargetType = ReportNotifications.Name(domainEvent.TargetType),
                TargetLabel = await ReportNotifications.LabelAsync(reader, domainEvent.TargetType, domainEvent.TargetId, cancellationToken),
                Outcome = domainEvent.Status == ReportStatus.Resolved ? ReportOutcomes.Actioned : ReportOutcomes.NoViolation,
            },
        }, cancellationToken);
    }
}

internal static class ReportNotifications
{
    public const int LabelLength = 80;

    /// <summary>Also the pushes' collapse key: a newer push about the target replaces the older one.</summary>
    public static string Group(ReportTargetType type, Guid targetId) => $"{NotificationTypes.ReportNew}:{Name(type)}:{targetId}";

    /// <summary><c>article</c> | <c>comment</c> | <c>user</c> | <c>repost</c>, as the API writes the type.</summary>
    public static string Name(ReportTargetType type) => JsonNamingPolicy.CamelCase.ConvertName(type.ToString());

    /// <summary>The article's title, the comment's (or caption's) first 80 characters, or <c>@username</c>; null when gone.</summary>
    public static async Task<string?> LabelAsync(ModerationReader reader, ReportTargetType type, Guid targetId, CancellationToken ct)
    {
        var key = new ModerationTargetKey(type, targetId);
        var target = (await reader.TargetsAsync([key], ct))[key];
        var text = type switch
        {
            ReportTargetType.Article => target.Title,
            ReportTargetType.User => target.Author is { } user ? $"@{user.Username}" : null,
            ReportTargetType.Repost => target.Body ?? target.ArticleTitle,
            _ => target.Body,
        };
        if (string.IsNullOrWhiteSpace(text)) return null;
        var line = string.Join(' ', text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
        return line.Length <= LabelLength ? line : line[..LabelLength];
    }

    /// <summary>Every account holding <paramref name="permission"/> (today the SuperAdmin), through its roles.</summary>
    public static async Task<List<Guid>> HoldersAsync(IAppDbContext db, string permission, CancellationToken ct)
    {
        var roleIds = await db.Roles.AsNoTracking()
            .Where(r => r.Permissions.Any(p => db.Permissions.Any(x => x.Id == p.PermissionId && x.Code == permission)))
            .Select(r => r.Id)
            .ToListAsync(ct);
        return await db.Users.AsNoTracking()
            .Where(u => u.Roles.Any(r => roleIds.Contains(r.RoleId)))
            .Select(u => u.Id)
            .ToListAsync(ct);
    }
}
