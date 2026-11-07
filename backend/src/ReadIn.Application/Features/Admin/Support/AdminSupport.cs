using System.Globalization;
using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Admin.Dashboard;
using ReadIn.Application.Features.Admin.Users;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Moderation;
using ReadIn.Application.Features.Notifications;
using ReadIn.Application.Features.Search;
using ReadIn.Application.Features.Support;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Support;

namespace ReadIn.Application.Features.Admin.Support;

/// <summary>
/// GET /admin/support/tickets (SPEC F35): the queue. <c>open</c> (default; waiting longest first), <c>answered</c> (latest
/// reply first), <c>closed</c> (latest closed first); filtered by category; <c>q</c> = words of the subject, the member's
/// name or <c>@username</c>, or <c>#12</c>. Parameters are text so a bad one is <c>400 validation.failed</c> on it.
/// </summary>
[RequirePermission(Permissions.Support.Manage)]
public sealed record GetAdminTicketsQuery(string? Status = null, string? Category = null, string? Q = null, int? Page = null, int? PageSize = null)
    : IQuery<Result<PagedList<AdminTicketRowDto>>>
{
    public const int MaxQueryLength = 100;
}

/// <summary>GET /admin/support/tickets/{id} (SPEC F35): the conversation with notes, the member's card and their history.</summary>
[RequirePermission(Permissions.Support.Manage)]
public sealed record GetAdminTicketQuery(Guid TicketId) : IQuery<Result<AdminTicketDto>>;

/// <summary>
/// POST /admin/support/tickets/{id}/messages (SPEC F35): a reply (the ticket becomes Answered, the member gets
/// <c>support_reply</c>) or, with <paramref name="Internal"/>, a note only admins see (any status, nobody told).
/// </summary>
[RequirePermission(Permissions.Support.Manage)]
public sealed record AddAdminTicketMessageCommand(Guid TicketId, string? Body, bool Internal) : ICommand<Result<AdminSupportMessageDto>>;

/// <summary>
/// PATCH /admin/support/tickets/{id} (SPEC F35): close (the member gets <c>support_reply</c>) or reopen, and/or change the
/// category. The same value as now changes and writes nothing.
/// </summary>
/// <param name="Status"><c>open</c> | <c>closed</c>.</param>
[RequirePermission(Permissions.Support.Manage)]
public sealed record UpdateAdminTicketCommand(Guid TicketId, string? Status, string? Category) : ICommand<Result<AdminTicketDto>>;

internal static class AdminTicketStatuses
{
    public const string Open = "open";
    public const string Answered = "answered";
    public const string Closed = "closed";
}

internal sealed class AddAdminTicketMessageCommandValidator : AbstractValidator<AddAdminTicketMessageCommand>
{
    public AddAdminTicketMessageCommandValidator() =>
        RuleFor(c => c.Body).NotEmpty().Must(b => b is null || b.Trim().Length <= SupportTicket.MaxMessageLength)
            .WithErrorCode("validation.max_length");
}

internal sealed class UpdateAdminTicketCommandValidator : AbstractValidator<UpdateAdminTicketCommand>
{
    public UpdateAdminTicketCommandValidator()
    {
        RuleFor(c => c.Status).NotNull().When(c => c.Category is null);
        RuleFor(c => c.Status).Must(s => s is AdminTicketStatuses.Open or AdminTicketStatuses.Closed).When(c => c.Status is not null)
            .WithErrorCode("validation.invalid");
        RuleFor(c => c.Category).Must(SupportCategories.IsKnown).When(c => c.Category is not null).WithErrorCode(SupportErrors.CategoryInvalid);
    }
}

/// <summary>The queue's rows and a ticket's page, shared with a user's page in the console (<c>AdminUserDto.tickets</c>).</summary>
internal static class AdminTickets
{
    /// <summary>The rows of <paramref name="tickets"/> (already ordered and paged), in that order.</summary>
    public static async Task<List<AdminTicketRowDto>> RowsAsync(IAppDbContext db, IFileStorage storage, IQueryable<SupportTicket> tickets, CancellationToken ct)
    {
        var rows = await tickets
            .Select(t => new
            {
                t.Id,
                t.Number,
                t.Category,
                t.Subject,
                t.Status,
                t.UserId,
                t.CreatedAt,
                t.LastUserMessageAt,
                t.ClosedAt,
                Last = t.Messages.OrderByDescending(m => m.CreatedAt).ThenByDescending(m => m.Id)
                    .Select(m => new { m.FromSupport, m.IsInternalNote, m.Body, m.CreatedAt })
                    .FirstOrDefault(),
            })
            .ToListAsync(ct);
        var userIds = rows.Select(r => r.UserId).Distinct().ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => userIds.Contains(u.Id))
            .Select(u => new AuthorDto(u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified, u.Headline))
            .ToDictionaryAsync(u => u.Id, ct);

        return [.. rows.Where(r => users.ContainsKey(r.UserId)).Select(r => new AdminTicketRowDto(
            r.Id,
            r.Number,
            r.Category,
            r.Subject,
            r.Status,
            users[r.UserId] with { AvatarUrl = storage.ToPublicUrl(users[r.UserId].AvatarUrl) },
            r.CreatedAt,
            r.Status == SupportTicketStatus.Open ? r.LastUserMessageAt : null,
            r.Last is null
                ? new AdminLastMessageDto(false, false, string.Empty, r.CreatedAt)
                : new AdminLastMessageDto(r.Last.FromSupport, r.Last.IsInternalNote, NotificationExcerpt.Of(r.Last.Body), r.Last.CreatedAt),
            r.ClosedAt))];
    }

    public static async Task<AdminTicketDto?> PageAsync(
        IAppDbContext db, IFileStorage storage, ICurrentUser currentUser, ModerationReader moderation, AdminClock clock, Guid ticketId,
        CancellationToken ct)
    {
        var row = (await RowsAsync(db, storage, db.SupportTickets.AsNoTracking().Where(t => t.Id == ticketId), ct)).SingleOrDefault();
        if (row is null) return null;

        var ticket = await db.SupportTickets.AsNoTracking()
            .Include(t => t.Messages).ThenInclude(m => m.Attachments)
            .SingleAsync(t => t.Id == ticketId, ct);
        var authorIds = ticket.Messages.Where(m => m.AuthorId != null).Select(m => m.AuthorId!.Value).Distinct().ToList();
        var authors = await db.Users.AsNoTracking()
            .Where(u => authorIds.Contains(u.Id))
            .Select(u => new SupportAuthorDto(u.Id, u.DisplayName, u.Username))
            .ToDictionaryAsync(u => u.Id, ct);

        var member = (await AdminUserQueries.RowsAsync(db, storage, [ticket.UserId], clock.UtcNow, ct)).Single();
        var canModerate = currentUser.Permissions.Contains(Permissions.Moderation.Manage);
        return new AdminTicketDto(row)
        {
            Device = new SupportDeviceDto(ticket.Platform, ticket.OsVersion, ticket.AppVersion, ticket.Language, ticket.Screen),
            Messages = [.. ticket.Messages.OrderBy(m => m.CreatedAt).ThenBy(m => m.Id).Select(m => Message(m, authors))],
            ClosedBy = ticket.ClosedBy,
            Member = new SupportMemberCardDto(
                member.Status, member.SuspendedUntil, member.JoinedAt, member.SignInMethods,
                await db.SupportTickets.CountAsync(t => t.UserId == ticket.UserId, ct)),
            ReportsFiled = canModerate ? await ReportsFiledAsync(db, ticket.UserId, ct) : null,
            ReportsAgainst = canModerate ? member.OpenReports : null,
            Moderation = canModerate ? await ModerationAsync(db, moderation, ticket.UserId, ct) : null,
        };
    }

    public static AdminSupportMessageDto Message(SupportMessage m, IReadOnlyDictionary<Guid, SupportAuthorDto> authors) =>
        new(new SupportMessageDto(
            m.Id,
            m.FromSupport,
            m.Body,
            [.. m.Attachments.OrderBy(a => a.Position).Select(a => new SupportAttachmentDto(a.Id, a.ContentType, a.SizeBytes))],
            m.CreatedAt))
        {
            IsInternalNote = m.IsInternalNote,
            Author = m.AuthorId is { } id ? authors.GetValueOrDefault(id) : null,
        };

    private static async Task<AdminListDto<AdminUserReportDto>> ReportsFiledAsync(IAppDbContext db, Guid userId, CancellationToken ct)
    {
        var filed = db.Reports.AsNoTracking().Where(r => r.ReporterId == userId);
        var rows = await filed.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id).Take(10).ToListAsync(ct);

        var articleIds = rows.Where(r => r.TargetType == ReportTargetType.Article).Select(r => r.TargetId).ToList();
        var commentIds = rows.Where(r => r.TargetType == ReportTargetType.Comment).Select(r => r.TargetId).ToList();
        var userIds = rows.Where(r => r.TargetType == ReportTargetType.User).Select(r => r.TargetId).ToList();
        var labels = new Dictionary<Guid, string>();
        foreach (var t in await db.ArticleTranslations.AsNoTracking().Where(t => articleIds.Contains(t.ArticleId) && t.IsSource)
                     .Select(t => new { t.ArticleId, t.Title }).ToListAsync(ct))
            labels[t.ArticleId] = t.Title;
        foreach (var c in await db.Comments.AsNoTracking().Where(c => commentIds.Contains(c.Id)).Select(c => new { c.Id, c.Body }).ToListAsync(ct))
            labels[c.Id] = c.Body.Length <= 80 ? c.Body : c.Body[..80];
        foreach (var u in await db.Users.AsNoTracking().Where(u => userIds.Contains(u.Id)).Select(u => new { u.Id, u.Username }).ToListAsync(ct))
            labels[u.Id] = "@" + u.Username;

        return new AdminListDto<AdminUserReportDto>(
            [.. rows.Select(r => new AdminUserReportDto(
                r.Id, r.TargetType, r.TargetId, labels.GetValueOrDefault(r.TargetId), r.Reason, r.Details, r.Status, r.CreatedAt, null))],
            await filed.CountAsync(ct));
    }

    /// <summary>Warnings and suspensions about the member, newest 10.</summary>
    private static async Task<IReadOnlyList<ModerationActionDto>> ModerationAsync(
        IAppDbContext db, ModerationReader moderation, Guid userId, CancellationToken ct)
    {
        string[] kinds = [ModerationActionTypes.UserWarn, ModerationActionTypes.UserSuspend, ModerationActionTypes.UserUnsuspend];
        var rows = await db.ModerationActions.AsNoTracking()
            .Where(a => a.TargetUserId == userId && kinds.Contains(a.Action))
            .OrderByDescending(a => a.CreatedAt).ThenByDescending(a => a.Id)
            .Take(10)
            .ToListAsync(ct);
        return await moderation.ActionsAsync(rows, ct);
    }
}

internal sealed class GetAdminTicketsQueryHandler(IAppDbContext db, IFileStorage storage)
    : IQueryHandler<GetAdminTicketsQuery, Result<PagedList<AdminTicketRowDto>>>
{
    public async ValueTask<Result<PagedList<AdminTicketRowDto>>> Handle(GetAdminTicketsQuery query, CancellationToken ct)
    {
        var status = query.Status switch
        {
            null or AdminTicketStatuses.Open => SupportTicketStatus.Open,
            AdminTicketStatuses.Answered => SupportTicketStatus.Answered,
            AdminTicketStatuses.Closed => SupportTicketStatus.Closed,
            _ => (SupportTicketStatus?)null,
        };
        if (status is not { } wanted) return AdminErrors.InvalidParameter("status");

        var filtered = db.SupportTickets.AsNoTracking().Where(t => t.Status == wanted);
        if (query.Category is { } category)
        {
            if (!SupportCategories.IsKnown(category)) return ValidationErrors.For("category", [SupportErrors.CategoryInvalid]);
            filtered = filtered.Where(t => t.Category == category);
        }
        if (!string.IsNullOrWhiteSpace(query.Q))
        {
            var q = query.Q.Trim();
            if (q.Length > GetAdminTicketsQuery.MaxQueryLength) return ValidationErrors.For("q", ["validation.max_length"]);
            filtered = Matching(filtered, q);
        }

        var ordered = wanted switch
        {
            // Open: waiting longest first. Answered: the latest reply first. Closed: the latest closed first.
            SupportTicketStatus.Open => filtered.OrderBy(t => t.LastUserMessageAt),
            SupportTicketStatus.Answered => filtered.OrderByDescending(t => t.LastAdminReplyAt),
            _ => filtered.OrderByDescending(t => t.ClosedAt),
        };

        var (page, pageSize) = AdminPaging.Normalize(query.Page, query.PageSize);
        var total = await filtered.CountAsync(ct);
        var rows = total <= (page - 1) * pageSize
            ? []
            : await AdminTickets.RowsAsync(db, storage, ordered.ThenBy(t => t.Id).Skip((page - 1) * pageSize).Take(pageSize), ct);
        return new PagedList<AdminTicketRowDto>(rows, page, pageSize, total);
    }

    /// <summary><c>#12</c> → that ticket; otherwise every word in the subject, or the member's name or <c>@username</c>.</summary>
    private IQueryable<SupportTicket> Matching(IQueryable<SupportTicket> tickets, string q)
    {
        if (q.StartsWith('#') && int.TryParse(q[1..], NumberStyles.None, CultureInfo.InvariantCulture, out var number))
            return tickets.Where(t => t.Number == number);

        var handle = q.TrimStart('@');
        var handlePrefix = SearchTerms.EscapeLike(handle) + "%";
        var phrase = "%" + SearchTerms.EscapeLike(q) + "%";
        var words = q.Split(' ', StringSplitOptions.RemoveEmptyEntries).Take(8).Select(w => "%" + SearchTerms.EscapeLike(w) + "%").ToList();

        var bySubject = tickets;
        foreach (var word in words) bySubject = bySubject.Where(t => EF.Functions.Like(t.Subject, word, SearchTerms.LikeEscape));
        var subjectIds = bySubject.Select(t => t.Id);
        var members = db.Users.Where(u =>
            EF.Functions.Like(u.DisplayName, phrase, SearchTerms.LikeEscape) || EF.Functions.Like(u.Username, handlePrefix, SearchTerms.LikeEscape))
            .Select(u => u.Id);
        return tickets.Where(t => subjectIds.Contains(t.Id) || members.Contains(t.UserId));
    }
}

internal sealed class GetAdminTicketQueryHandler(
    IAppDbContext db, IFileStorage storage, ICurrentUser currentUser, ModerationReader moderation, AdminClock clock)
    : IQueryHandler<GetAdminTicketQuery, Result<AdminTicketDto>>
{
    public async ValueTask<Result<AdminTicketDto>> Handle(GetAdminTicketQuery query, CancellationToken ct) =>
        await AdminTickets.PageAsync(db, storage, currentUser, moderation, clock, query.TicketId, ct) is { } page
            ? page
            : SupportErrors.TicketNotFound;
}

internal sealed class AddAdminTicketMessageCommandHandler(IAppDbContext db, ICurrentUser currentUser, AuditTrail audit, TimeProvider clock)
    : ICommandHandler<AddAdminTicketMessageCommand, Result<AdminSupportMessageDto>>
{
    public async ValueTask<Result<AdminSupportMessageDto>> Handle(AddAdminTicketMessageCommand command, CancellationToken ct)
    {
        var ticket = await db.SupportTickets.Include(t => t.Messages).FirstOrDefaultAsync(t => t.Id == command.TicketId, ct);
        if (ticket is null) return SupportErrors.TicketNotFound;

        var adminId = currentUser.RequireUserId();
        var now = clock.GetUtcNow().UtcDateTime;
        var body = command.Body!.Trim();
        SupportMessage message;
        if (command.Internal)
        {
            message = ticket.AddNote(adminId, body, now);
            audit.Record(AuditActions.TicketNoteAdded, ticket.UserId, AuditTargets.Ticket, ticket.Id);
        }
        else
        {
            var reply = ticket.Reply(adminId, body, now);
            if (reply.IsFailure) return reply.Error!;
            message = reply.Value;
            audit.Record(AuditActions.TicketReplied, ticket.UserId, AuditTargets.Ticket, ticket.Id);
        }
        await db.SaveChangesAsync(ct);

        var author = await db.Users.AsNoTracking()
            .Where(u => u.Id == adminId)
            .Select(u => new SupportAuthorDto(u.Id, u.DisplayName, u.Username))
            .ToDictionaryAsync(u => u.Id, ct);
        return AdminTickets.Message(message, author);
    }
}

internal sealed class UpdateAdminTicketCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IFileStorage storage,
    ModerationReader moderation,
    AdminClock clock,
    AuditTrail audit)
    : ICommandHandler<UpdateAdminTicketCommand, Result<AdminTicketDto>>
{
    public async ValueTask<Result<AdminTicketDto>> Handle(UpdateAdminTicketCommand command, CancellationToken ct)
    {
        var ticket = await db.SupportTickets.FirstOrDefaultAsync(t => t.Id == command.TicketId, ct);
        if (ticket is null) return SupportErrors.TicketNotFound;

        var changed = false;
        if (command.Category is { } category && ticket.Category != category)
        {
            var old = ticket.Category;
            ticket.ChangeCategory(category);
            audit.Record(AuditActions.TicketCategoryChanged, ticket.UserId, AuditTargets.Ticket, ticket.Id, $"{old} → {category}");
            changed = true;
        }
        if (command.Status == AdminTicketStatuses.Closed && ticket.CloseBySupport(currentUser.RequireUserId(), clock.UtcNow))
        {
            audit.Record(AuditActions.TicketClosed, ticket.UserId, AuditTargets.Ticket, ticket.Id);
            changed = true;
        }
        else if (command.Status == AdminTicketStatuses.Open && ticket.ReopenBySupport())
        {
            audit.Record(AuditActions.TicketReopened, ticket.UserId, AuditTargets.Ticket, ticket.Id);
            changed = true;
        }
        if (changed) await db.SaveChangesAsync(ct);

        return (await AdminTickets.PageAsync(db, storage, currentUser, moderation, clock, ticket.Id, ct))!;
    }
}

/// <summary>Open tickets for the console badge and the dashboard (SPEC F35): tickets waiting for support.</summary>
internal sealed class SupportOpenTicketCounter(IAppDbContext db) : IOpenTicketCounter
{
    public Task<int> CountOpenAsync(CancellationToken cancellationToken) =>
        db.SupportTickets.CountAsync(t => t.Status == SupportTicketStatus.Open, cancellationToken);
}
