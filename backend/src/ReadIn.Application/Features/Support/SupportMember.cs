using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Support;

namespace ReadIn.Application.Features.Support;

/// <summary>A screenshot as the endpoint received it: the stream is read once, up to the limit.</summary>
public sealed record SupportScreenshotUpload(Stream Content);

/// <summary>GET /support/config (SPEC F35, anonymous): the support email and the ticket form's rules.</summary>
public sealed record GetSupportConfigQuery : IQuery<Result<SupportConfigDto>>;

/// <summary>
/// POST /support/tickets (SPEC F35): a new ticket with its first message and up to 3 screenshots. 5 a day and 10 not closed
/// per member (<c>429 support.limit</c>); screenshots are JPEG, PNG or WebP ≤ 5 MB by their bytes, stored privately.
/// </summary>
[RequirePermission(Permissions.Support.Create)]
public sealed record CreateSupportTicketCommand(
    string? Category,
    string? Subject,
    string? Message,
    string? Platform,
    string? OsVersion,
    string? AppVersion,
    string? Language,
    string? Screen,
    IReadOnlyList<SupportScreenshotUpload> Screenshots) : ICommand<Result<SupportTicketDto>>;

/// <summary>GET /me/support/tickets (SPEC F35): your tickets, latest activity first. <c>status</c> = active | closed.</summary>
[RequirePermission(Permissions.Support.Create)]
public sealed record GetMySupportTicketsQuery(string? Status, string? Cursor, int Limit) : IQuery<Result<CursorPage<SupportTicketSummaryDto>>>
{
    public const int MaxLimit = 50;
}

/// <summary>GET /support/tickets/{id} (SPEC F35): your ticket and its conversation, never internal notes.</summary>
[RequirePermission(Permissions.Support.Create)]
public sealed record GetSupportTicketQuery(Guid TicketId) : IQuery<Result<SupportTicketDto>>;

/// <summary>POST /support/tickets/{id}/messages (SPEC F35): an Answered ticket is Open again; a closed one takes nothing.</summary>
[RequirePermission(Permissions.Support.Create)]
public sealed record PostSupportMessageCommand(Guid TicketId, string? Message, IReadOnlyList<SupportScreenshotUpload> Screenshots)
    : ICommand<Result<SupportMessageDto>>;

/// <summary>POST /support/tickets/{id}/close (SPEC F35): idempotent.</summary>
[RequirePermission(Permissions.Support.Create)]
public sealed record CloseSupportTicketCommand(Guid TicketId) : ICommand<Result>;

/// <summary>POST /support/tickets/{id}/reopen (SPEC F35): within 30 days of closing (<c>409 support.reopen_expired</c>).</summary>
[RequirePermission(Permissions.Support.Create)]
public sealed record ReopenSupportTicketCommand(Guid TicketId) : ICommand<Result>;

/// <summary>A screenshot to send back: its bytes, type and the neutral download name.</summary>
public sealed record SupportAttachmentFile(Stream Content, string ContentType, string FileName);

/// <summary>GET /support/attachments/{id} (SPEC F35): the ticket's owner, or <c>support.manage</c>; anyone else gets 404.</summary>
[Authenticated]
public sealed record GetSupportAttachmentQuery(Guid AttachmentId) : IQuery<Result<SupportAttachmentFile>>;

internal sealed class CreateSupportTicketCommandValidator : AbstractValidator<CreateSupportTicketCommand>
{
    public CreateSupportTicketCommandValidator()
    {
        RuleFor(c => c.Category).Must(SupportCategories.IsKnown).WithErrorCode(SupportErrors.CategoryInvalid);
        RuleFor(c => c.Subject).NotEmpty()
            .Must(s => SupportText.Fits(s, SupportTicket.MinSubjectLength, SupportTicket.MaxSubjectLength)).WithErrorCode("validation.length");
        RuleFor(c => c.Message).NotEmpty()
            .Must(m => SupportText.Fits(m, SupportTicket.MinFirstMessageLength, SupportTicket.MaxMessageLength)).WithErrorCode("validation.length");
    }
}

internal sealed class PostSupportMessageCommandValidator : AbstractValidator<PostSupportMessageCommand>
{
    public PostSupportMessageCommandValidator()
    {
        RuleFor(c => c.Message).NotEmpty()
            .Must(m => SupportText.Fits(m, 1, SupportTicket.MaxMessageLength)).WithErrorCode("validation.length");
    }
}

/// <summary>Text rules of tickets and messages (SPEC F35).</summary>
public static class SupportText
{
    public const int ExcerptLength = 140;

    /// <summary>Blank counts as missing (<c>validation.required</c>, checked separately); otherwise the trimmed length.</summary>
    public static bool Fits(string? text, int min, int max) =>
        string.IsNullOrWhiteSpace(text) || text.Trim().Length is var length && length >= min && length <= max;

    /// <summary>One line of at most 140 characters: whitespace runs (line breaks too) become one space.</summary>
    public static string Excerpt(string body)
    {
        var line = string.Join(' ', body.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
        if (line.Length <= ExcerptLength) return line;
        var cut = char.IsHighSurrogate(line[ExcerptLength - 2]) ? ExcerptLength - 2 : ExcerptLength - 1;
        return line[..cut].TrimEnd() + "…";
    }
}

/// <summary>A screenshot's type by its bytes (never its name or the part's content type).</summary>
public sealed record SupportScreenshotFormat(string ContentType, string Extension)
{
    public static readonly SupportScreenshotFormat Jpeg = new("image/jpeg", ".jpg");
    public static readonly SupportScreenshotFormat Png = new("image/png", ".png");
    public static readonly SupportScreenshotFormat Webp = new("image/webp", ".webp");

    public static readonly IReadOnlyList<SupportScreenshotFormat> All = [Jpeg, Png, Webp];

    public const int HeaderLength = 16;

    public static SupportScreenshotFormat? Detect(ReadOnlySpan<byte> header) => ImageSignatures.Detect(header) switch
    {
        ImageFormat.Jpeg => Jpeg,
        ImageFormat.Png => Png,
        ImageFormat.Webp => Webp,
        _ => null,
    };

    public static SupportScreenshotFormat? FromContentType(string contentType) => All.FirstOrDefault(f => f.ContentType == contentType);
}

/// <summary>
/// Screenshots of support messages (SPEC F35): read and checked before anything is saved, written to the private store as
/// <c>support/{messageId}/{n}{.ext}</c>, and deleted again when the request fails or the ticket goes.
/// </summary>
public sealed partial class SupportScreenshots(IPrivateFileStorage storage, ILogger<SupportScreenshots> logger)
{
    public sealed record Checked(byte[] Bytes, SupportScreenshotFormat Format);

    /// <summary>At most 3, each a non-empty JPEG, PNG or WebP of at most 5 MB.</summary>
    public static async Task<Result<IReadOnlyList<Checked>>> CheckAsync(IReadOnlyList<SupportScreenshotUpload> uploads, CancellationToken ct)
    {
        if (uploads.Count > SupportAttachment.MaxPerMessage) return SupportErrors.TooManyAttachments;
        var files = new List<Checked>(uploads.Count);
        foreach (var upload in uploads)
        {
            var bytes = await UploadBuffer.ReadAtMostAsync(upload.Content, SupportAttachment.MaxBytes, ct);
            var format = bytes.Length is > 0 and <= SupportAttachment.MaxBytes
                ? SupportScreenshotFormat.Detect(bytes.AsSpan(0, Math.Min(bytes.Length, SupportScreenshotFormat.HeaderLength)))
                : null;
            if (format is null) return SupportErrors.AttachmentInvalid;
            files.Add(new Checked(bytes, format));
        }
        return files;
    }

    /// <summary>Writes the files and records them on <paramref name="message"/> (whose id is assigned); returns their paths.</summary>
    public async Task<List<string>> SaveAsync(SupportMessage message, IReadOnlyList<Checked> files, DateTime now, CancellationToken ct)
    {
        var paths = new List<string>(files.Count);
        try
        {
            for (var i = 0; i < files.Count; i++)
            {
                var path = SupportAttachment.PathFor(message.Id, i + 1, files[i].Format.Extension);
                using (var content = new MemoryStream(files[i].Bytes, writable: false))
                    await storage.SaveAsync(path, content, ct);
                paths.Add(path);
                message.AddAttachment(i + 1, path, files[i].Format.ContentType, files[i].Bytes.Length, now);
            }
        }
        catch
        {
            await DeleteAsync(paths, CancellationToken.None);
            throw;
        }
        return paths;
    }

    /// <summary>Best effort: a file that can't be deleted now is an orphan the retention job removes.</summary>
    public async Task DeleteAsync(IEnumerable<string> paths, CancellationToken ct)
    {
        foreach (var path in paths)
        {
            try
            {
                await storage.DeleteAsync(path, ct);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException)
            {
                LogDeleteFailed(logger, ex, path);
            }
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete the support screenshot {Path}; the support retention job will retry")]
    private static partial void LogDeleteFailed(ILogger logger, Exception exception, string path);
}

/// <summary>The member's view of tickets (SPEC F35): no internal notes, support replies without the admin's name.</summary>
internal static class SupportMemberViews
{
    public static SupportTicketSummaryDto Summary(SupportTicket ticket, SupportMessage? last, DateTime now) => new(
        ticket.Id,
        ticket.Number,
        ticket.Category,
        ticket.Subject,
        ticket.Status,
        ticket.CreatedAt,
        ticket.UpdatedAt,
        last is null
            ? new SupportLastMessageDto(false, string.Empty, ticket.CreatedAt)
            : new SupportLastMessageDto(last.FromSupport, SupportText.Excerpt(last.Body), last.CreatedAt),
        ticket.ClosedAt,
        ticket.CanReopen(now));

    public static SupportMessageDto Message(SupportMessage message) => new(
        message.Id,
        message.FromSupport,
        message.Body,
        [.. message.Attachments.OrderBy(a => a.Position).Select(a => new SupportAttachmentDto(a.Id, a.ContentType, a.SizeBytes))],
        message.CreatedAt);

    /// <summary>A ticket loaded with its messages and their attachments.</summary>
    public static SupportTicketDto Ticket(SupportTicket ticket, DateTime now)
    {
        var visible = ticket.Messages.Where(m => !m.IsInternalNote).OrderBy(m => m.CreatedAt).ThenBy(m => m.Id).ToList();
        return new SupportTicketDto(Summary(ticket, visible.LastOrDefault(), now))
        {
            Device = new SupportDeviceDto(ticket.Platform, ticket.OsVersion, ticket.AppVersion, ticket.Language, ticket.Screen),
            Messages = [.. visible.Select(Message)],
        };
    }

    /// <summary>The member's own ticket with every message and attachment, or null (unknown or someone else's).</summary>
    public static Task<SupportTicket?> LoadOwnAsync(IAppDbContext db, Guid ticketId, Guid userId, CancellationToken ct) =>
        db.SupportTickets
            .Include(t => t.Messages).ThenInclude(m => m.Attachments)
            .FirstOrDefaultAsync(t => t.Id == ticketId && t.UserId == userId, ct);
}

internal sealed class GetSupportConfigQueryHandler(IOptions<SupportOptions> options) : IQueryHandler<GetSupportConfigQuery, Result<SupportConfigDto>>
{
    public ValueTask<Result<SupportConfigDto>> Handle(GetSupportConfigQuery query, CancellationToken cancellationToken)
    {
        var email = options.Value.Email?.Trim();
        return ValueTask.FromResult<Result<SupportConfigDto>>(new SupportConfigDto(
            string.IsNullOrEmpty(email) ? null : email,
            SupportCategories.All,
            SupportAttachment.MaxPerMessage,
            SupportAttachment.MaxBytes,
            [.. SupportScreenshotFormat.All.Select(f => f.ContentType)]));
    }
}

internal sealed class CreateSupportTicketCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, SupportScreenshots screenshots, TimeProvider clock)
    : ICommandHandler<CreateSupportTicketCommand, Result<SupportTicketDto>>
{
    public async ValueTask<Result<SupportTicketDto>> Handle(CreateSupportTicketCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        if (await LimitAsync(userId, clock.GetUtcNow().UtcDateTime, cancellationToken) is { } limit) return limit;

        var checkedFiles = await SupportScreenshots.CheckAsync(command.Screenshots, cancellationToken);
        if (checkedFiles.IsFailure) return checkedFiles.Error;

        var device = SupportDevice.Clean(command.Platform, command.OsVersion, command.AppVersion, command.Language, command.Screen);
        List<string> written = [];
        try
        {
            // One member's checks and insert run one after the other (an update lock on their row), so two tickets sent at
            // once can't both pass the limits.
            return await db.LockedForUserAsync<Result<SupportTicketDto>>(userId, async ct =>
            {
                var now = clock.GetUtcNow().UtcDateTime;
                if (await LimitAsync(userId, now, ct) is { } error) return error;

                var ticket = SupportTicket.Open(userId, command.Category!, command.Subject!.Trim(), command.Message!.Trim(), device, now);
                db.SupportTickets.Add(ticket); // EF Core assigns the ids here, which name the files
                await screenshots.DeleteAsync(written, CancellationToken.None); // a retried attempt starts over
                written = await screenshots.SaveAsync(ticket.Messages.Single(), checkedFiles.Value, now, ct);
                await db.SaveChangesAsync(ct);
                return SupportMemberViews.Ticket(ticket, now);
            }, cancellationToken);
        }
        catch
        {
            await screenshots.DeleteAsync(written, CancellationToken.None);
            throw;
        }
    }

    /// <summary>5 new tickets in 24 hours, 10 not closed (SPEC F35).</summary>
    private async Task<Error?> LimitAsync(Guid userId, DateTime now, CancellationToken ct)
    {
        var since = now - SupportTicket.NewTicketWindow;
        if (await db.SupportTickets.CountAsync(t => t.UserId == userId && t.CreatedAt > since, ct) >= SupportTicket.MaxNewPerDay)
            return SupportErrors.LimitOf("daily");
        if (await db.SupportTickets.CountAsync(t => t.UserId == userId && t.Status != SupportTicketStatus.Closed, ct) >= SupportTicket.MaxOpen)
            return SupportErrors.LimitOf("open");
        return null;
    }
}

internal sealed class GetMySupportTicketsQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : IQueryHandler<GetMySupportTicketsQuery, Result<CursorPage<SupportTicketSummaryDto>>>
{
    public async ValueTask<Result<CursorPage<SupportTicketSummaryDto>>> Handle(GetMySupportTicketsQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var tickets = db.SupportTickets.AsNoTracking().Where(t => t.UserId == userId);
        switch (query.Status)
        {
            case null or "":
                break;
            case "active":
                tickets = tickets.Where(t => t.Status != SupportTicketStatus.Closed);
                break;
            case "closed":
                tickets = tickets.Where(t => t.Status == SupportTicketStatus.Closed);
                break;
            default:
                return ValidationErrors.For("status", ["validation.invalid"]);
        }
        if (TimeCursor.Decode(query.Cursor) is { } after)
        {
            tickets = tickets.Where(t => t.UpdatedAt < after.Timestamp || (t.UpdatedAt == after.Timestamp && t.Id.CompareTo(after.Id) < 0));
        }

        var limit = Math.Clamp(query.Limit, 1, GetMySupportTicketsQuery.MaxLimit);
        var page = await tickets.OrderByDescending(t => t.UpdatedAt).ThenByDescending(t => t.Id).Take(limit + 1).ToListAsync(ct);
        var ids = page.Select(t => t.Id).ToList();
        var lastMessages = await db.SupportMessages.AsNoTracking()
            .Where(m => ids.Contains(m.TicketId) && !m.IsInternalNote)
            .GroupBy(m => m.TicketId)
            .Select(g => g.OrderByDescending(m => m.CreatedAt).ThenByDescending(m => m.Id).First())
            .ToListAsync(ct);
        var byTicket = lastMessages.ToDictionary(m => m.TicketId);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].UpdatedAt, page[^1].Id).Encode();
        }
        var now = clock.GetUtcNow().UtcDateTime;
        return new CursorPage<SupportTicketSummaryDto>([.. page.Select(t => SupportMemberViews.Summary(t, byTicket.GetValueOrDefault(t.Id), now))], next);
    }
}

internal sealed class GetSupportTicketQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : IQueryHandler<GetSupportTicketQuery, Result<SupportTicketDto>>
{
    public async ValueTask<Result<SupportTicketDto>> Handle(GetSupportTicketQuery query, CancellationToken ct)
    {
        var ticket = await SupportMemberViews.LoadOwnAsync(db, query.TicketId, currentUser.RequireUserId(), ct);
        return ticket is null ? SupportErrors.TicketNotFound : SupportMemberViews.Ticket(ticket, clock.GetUtcNow().UtcDateTime);
    }
}

internal sealed class PostSupportMessageCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, SupportScreenshots screenshots, TimeProvider clock)
    : ICommandHandler<PostSupportMessageCommand, Result<SupportMessageDto>>
{
    public async ValueTask<Result<SupportMessageDto>> Handle(PostSupportMessageCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var ticket = await db.SupportTickets.FirstOrDefaultAsync(t => t.Id == command.TicketId && t.UserId == userId, cancellationToken);
        if (ticket is null) return SupportErrors.TicketNotFound;
        if (ticket.IsClosed) return SupportErrors.TicketClosed;

        var checkedFiles = await SupportScreenshots.CheckAsync(command.Screenshots, cancellationToken);
        if (checkedFiles.IsFailure) return checkedFiles.Error;

        var now = clock.GetUtcNow().UtcDateTime;
        var added = ticket.AddMemberMessage(command.Message!.Trim(), now);
        if (added.IsFailure) return added.Error;
        var message = added.Value;
        db.SupportMessages.Add(message); // EF Core assigns the id here, which names the files

        List<string> written = [];
        try
        {
            written = await screenshots.SaveAsync(message, checkedFiles.Value, now, cancellationToken);
            await db.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            await screenshots.DeleteAsync(written, CancellationToken.None);
            throw;
        }
        return SupportMemberViews.Message(message);
    }
}

internal sealed class CloseSupportTicketCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<CloseSupportTicketCommand, Result>
{
    public async ValueTask<Result> Handle(CloseSupportTicketCommand command, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var ticket = await db.SupportTickets.FirstOrDefaultAsync(t => t.Id == command.TicketId && t.UserId == userId, ct);
        if (ticket is null) return SupportErrors.TicketNotFound;
        if (ticket.CloseByMember(clock.GetUtcNow().UtcDateTime)) await db.SaveChangesAsync(ct);
        return Result.Success();
    }
}

internal sealed class ReopenSupportTicketCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<ReopenSupportTicketCommand, Result>
{
    public async ValueTask<Result> Handle(ReopenSupportTicketCommand command, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var ticket = await db.SupportTickets.FirstOrDefaultAsync(t => t.Id == command.TicketId && t.UserId == userId, ct);
        if (ticket is null) return SupportErrors.TicketNotFound;
        if (!ticket.IsClosed) return Result.Success();

        var reopened = ticket.ReopenByMember(clock.GetUtcNow().UtcDateTime);
        if (reopened.IsFailure) return reopened;
        await db.SaveChangesAsync(ct);
        return Result.Success();
    }
}

internal sealed class GetSupportAttachmentQueryHandler(IAppDbContext db, ICurrentUser currentUser, IPrivateFileStorage storage)
    : IQueryHandler<GetSupportAttachmentQuery, Result<SupportAttachmentFile>>
{
    public async ValueTask<Result<SupportAttachmentFile>> Handle(GetSupportAttachmentQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var found = await db.SupportAttachments.AsNoTracking()
            .Where(a => a.Id == query.AttachmentId)
            .Join(db.SupportMessages, a => a.MessageId, m => m.Id, (a, m) => new { a.FilePath, a.ContentType, a.Position, m.TicketId })
            .Join(db.SupportTickets, x => x.TicketId, t => t.Id, (x, t) => new { x.FilePath, x.ContentType, x.Position, t.UserId, t.Number })
            .FirstOrDefaultAsync(ct);
        // Someone else's screenshot is "not found" too: its existence is nobody else's business.
        if (found is null || (found.UserId != userId && !currentUser.Permissions.Contains(Permissions.Support.Manage)))
            return SupportErrors.AttachmentNotFound;

        try
        {
            var content = await storage.OpenReadAsync(found.FilePath, ct);
            var extension = SupportScreenshotFormat.FromContentType(found.ContentType)?.Extension ?? string.Empty;
            return new SupportAttachmentFile(content, found.ContentType, $"support-{found.Number}-{found.Position}{extension}");
        }
        catch (FileNotFoundException)
        {
            return SupportErrors.AttachmentNotFound;
        }
    }
}
