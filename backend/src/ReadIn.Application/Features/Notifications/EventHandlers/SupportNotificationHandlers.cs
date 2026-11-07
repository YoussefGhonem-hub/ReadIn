using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Support;

namespace ReadIn.Application.Features.Notifications.EventHandlers;

// Help & support (SPEC F35): who hears about a ticket. Both types are grouped per ticket, and both are idempotent, as the
// outbox delivers at least once.

/// <summary>
/// A member's message (a new ticket or a reply) → <c>support_ticket</c> to every holder of <c>support.manage</c> but the
/// member (actor = the member, grouped per ticket); a support reply → <c>support_reply</c> to the member (no actor: support
/// stays anonymous). Internal notes raise nothing.
/// </summary>
internal sealed class SupportMessageNotificationHandler(IAppDbContext db, NotificationWriter writer)
    : IDomainEventHandler<SupportMessagePostedDomainEvent>
{
    public async Task Handle(SupportMessagePostedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var ticket = await SupportNotifications.TicketAsync(db, domainEvent.TicketId, cancellationToken);
        if (ticket is null) return;
        var data = new NotificationData { TicketId = ticket.Id, TicketNumber = ticket.Number, Subject = ticket.Subject };

        if (domainEvent.FromSupport)
        {
            await writer.WriteAsync(new NotificationRequest(ticket.UserId, NotificationTypes.SupportReply)
            {
                GroupKey = SupportNotifications.ReplyGroup(ticket.Id),
                GroupsWithoutActor = true,
                Data = data with { SourceKey = $"m:{domainEvent.MessageId:N}" },
            }, cancellationToken);
            return;
        }

        var holders = await SupportNotifications.HoldersAsync(db, cancellationToken);
        await writer.WriteAsync(
            [
                .. holders.Where(id => id != ticket.UserId).Select(id => new NotificationRequest(id, NotificationTypes.SupportTicket)
                {
                    ActorId = ticket.UserId,
                    ActorAt = domainEvent.OccurredAt,
                    GroupKey = SupportNotifications.TicketGroup(ticket.Id),
                    Data = data,
                }),
            ],
            cancellationToken);
    }
}

/// <summary>Support closed the ticket → <c>support_reply</c> with <c>closed</c>. The member's own close and the auto-close tell nobody.</summary>
internal sealed class SupportClosedNotificationHandler(IAppDbContext db, NotificationWriter writer)
    : IDomainEventHandler<SupportTicketClosedDomainEvent>
{
    public async Task Handle(SupportTicketClosedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        if (domainEvent.ClosedBy != SupportClosedBy.Support) return;
        var ticket = await SupportNotifications.TicketAsync(db, domainEvent.TicketId, cancellationToken);
        if (ticket is null) return;

        await writer.WriteAsync(new NotificationRequest(ticket.UserId, NotificationTypes.SupportReply)
        {
            GroupKey = SupportNotifications.ReplyGroup(ticket.Id),
            GroupsWithoutActor = true,
            Data = new NotificationData
            {
                TicketId = ticket.Id,
                TicketNumber = ticket.Number,
                Subject = ticket.Subject,
                Closed = true,
                SourceKey = $"c:{domainEvent.OccurredAt.Ticks}",
            },
        }, cancellationToken);
    }
}

internal static class SupportNotifications
{
    public sealed record TicketInfo(Guid Id, int Number, string Subject, Guid UserId);

    /// <summary>Also the pushes' collapse keys: a newer push of the ticket replaces the older one.</summary>
    public static string ReplyGroup(Guid ticketId) => $"{NotificationTypes.SupportReply}:{ticketId}";

    public static string TicketGroup(Guid ticketId) => $"{NotificationTypes.SupportTicket}:{ticketId}";

    public static Task<TicketInfo?> TicketAsync(IAppDbContext db, Guid ticketId, CancellationToken ct) =>
        db.SupportTickets.AsNoTracking()
            .Where(t => t.Id == ticketId)
            .Select(t => new TicketInfo(t.Id, t.Number, t.Subject, t.UserId))
            .FirstOrDefaultAsync(ct);

    /// <summary>Every account holding <c>support.manage</c> (today the SuperAdmin), through its roles.</summary>
    public static async Task<List<Guid>> HoldersAsync(IAppDbContext db, CancellationToken ct)
    {
        var roleIds = await db.Roles.AsNoTracking()
            .Where(r => r.Permissions.Any(p => db.Permissions.Any(x => x.Id == p.PermissionId && x.Code == Permissions.Support.Manage)))
            .Select(r => r.Id)
            .ToListAsync(ct);
        return await db.Users.AsNoTracking()
            .Where(u => u.Roles.Any(r => roleIds.Contains(r.RoleId)))
            .Select(u => u.Id)
            .ToListAsync(ct);
    }
}
