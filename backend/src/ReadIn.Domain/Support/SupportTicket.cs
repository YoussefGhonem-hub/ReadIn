using ReadIn.Domain.Common;

namespace ReadIn.Domain.Support;

/// <summary>Open: waiting for support. Answered: support replied and waits for the member. Closed (SPEC F35).</summary>
public enum SupportTicketStatus : byte
{
    Open = 0,
    Answered = 1,
    Closed = 2,
}

/// <summary>Who closed a ticket: the member, support, or the auto-close job (14 days after Answered).</summary>
public enum SupportClosedBy : byte
{
    Member = 0,
    Support = 1,
    Auto = 2,
}

/// <summary>A ticket's category (SPEC F35, contract decision 1).</summary>
public static class SupportCategories
{
    public const string AppProblem = "app_problem";
    public const string Account = "account";
    public const string Content = "content";
    public const string Verification = "verification";
    public const string Suggestion = "suggestion";
    public const string Other = "other";

    /// <summary>In display order.</summary>
    public static readonly IReadOnlyList<string> All = [AppProblem, Account, Content, Verification, Suggestion, Other];

    public static bool IsKnown(string? category) => category is not null && All.Contains(category);
}

/// <summary>The device details the app sends with a ticket (SPEC F35): optional, cut to size, never an identifier.</summary>
public sealed record SupportDevice(string? Platform, string? OsVersion, string? AppVersion, string? Language, string? Screen)
{
    public const int MaxOsVersionLength = 60;
    public const int MaxAppVersionLength = 40;
    public const int MaxScreenLength = 100;

    public static readonly IReadOnlyList<string> Platforms = ["ios", "android", "web"];

    public static readonly SupportDevice None = new(null, null, null, null, null);

    /// <summary>Unknown platform or language → null; text trimmed and cut, empty → null (contract decision 10).</summary>
    public static SupportDevice Clean(string? platform, string? osVersion, string? appVersion, string? language, string? screen) => new(
        Platforms.Contains(platform?.Trim().ToLowerInvariant()) ? platform!.Trim().ToLowerInvariant() : null,
        Cut(osVersion, MaxOsVersionLength),
        Cut(appVersion, MaxAppVersionLength),
        UiLanguages.IsValid(language?.Trim().ToLowerInvariant()) ? language!.Trim().ToLowerInvariant() : null,
        Cut(screen, MaxScreenLength));

    private static string? Cut(string? text, int max)
    {
        var value = text?.Trim();
        if (string.IsNullOrEmpty(value)) return null;
        // Control characters (and BiDi overrides) never reach the console.
        value = new string(value.Where(c => !char.IsControl(c) && char.GetUnicodeCategory(c) != System.Globalization.UnicodeCategory.Format).ToArray());
        return value.Length == 0 ? null : value.Length <= max ? value : value[..max];
    }
}

/// <summary>
/// A member's support ticket (SPEC F35): the conversation with support, its status and the device it came from. Status
/// rules (contract decision 6): a member's message moves Answered → Open; a support reply makes it Answered; internal notes
/// and category changes never change the status; a closed ticket takes no message until it is reopened (by the member
/// within 30 days, by support any time).
/// </summary>
public sealed class SupportTicket : AggregateRoot
{
    public const int MinSubjectLength = 5;
    public const int MaxSubjectLength = 120;
    public const int MinFirstMessageLength = 10;
    public const int MaxMessageLength = 2000;
    public const int MaxNewPerDay = 5;
    public const int MaxOpen = 10;
    public static readonly TimeSpan NewTicketWindow = TimeSpan.FromHours(24);
    public static readonly TimeSpan ReopenWindow = TimeSpan.FromDays(30);
    public static readonly TimeSpan AutoCloseAfter = TimeSpan.FromDays(14);
    public static readonly TimeSpan Retention = TimeSpan.FromDays(365);

    private readonly List<SupportMessage> _messages = [];

    private SupportTicket() { } // EF

    /// <summary>A sequence from 1, for "#12" in both apps and in email; set by the database.</summary>
    public int Number { get; private set; }

    public Guid UserId { get; private set; }
    public string Category { get; private set; } = default!;
    public string Subject { get; private set; } = default!;
    public SupportTicketStatus Status { get; private set; }

    public string? Platform { get; private set; }
    public string? OsVersion { get; private set; }
    public string? AppVersion { get; private set; }
    public string? Language { get; private set; }
    public string? Screen { get; private set; }

    public DateTime CreatedAt { get; private set; }

    /// <summary>The latest message of the member or support (not an internal note): the member's list order.</summary>
    public DateTime UpdatedAt { get; private set; }

    /// <summary>The member's latest message: how long an Open ticket has waited.</summary>
    public DateTime LastUserMessageAt { get; private set; }

    public DateTime? LastAdminReplyAt { get; private set; }
    public DateTime? ClosedAt { get; private set; }

    /// <summary>Who closed it (the member or an admin); no foreign key, account deletion nulls it (SPEC §9.6).</summary>
    public Guid? ClosedById { get; private set; }

    public SupportClosedBy? ClosedBy { get; private set; }

    public IReadOnlyCollection<SupportMessage> Messages => _messages.AsReadOnly();

    public bool IsClosed => Status == SupportTicketStatus.Closed;

    /// <summary>A new ticket with the member's first message (already checked: category, subject, body).</summary>
    public static SupportTicket Open(Guid userId, string category, string subject, string body, SupportDevice device, DateTime now)
    {
        var ticket = new SupportTicket
        {
            UserId = userId,
            Category = category,
            Subject = subject,
            Status = SupportTicketStatus.Open,
            Platform = device.Platform,
            OsVersion = device.OsVersion,
            AppVersion = device.AppVersion,
            Language = device.Language,
            Screen = device.Screen,
            CreatedAt = now,
            UpdatedAt = now,
            LastUserMessageAt = now,
        };
        var message = new SupportMessage(userId, fromSupport: false, isInternalNote: false, body, now);
        ticket._messages.Add(message);
        ticket.Raise(() => new SupportMessagePostedDomainEvent(ticket.Id, message.Id, ticket.UserId, FromSupport: false, IsNewTicket: true));
        return ticket;
    }

    /// <summary>The member writes again: an Answered ticket is Open once more. A closed ticket takes nothing (reopen first).</summary>
    public Result<SupportMessage> AddMemberMessage(string body, DateTime now)
    {
        if (IsClosed) return SupportErrors.TicketClosed;
        var message = new SupportMessage(UserId, fromSupport: false, isInternalNote: false, body, now);
        _messages.Add(message);
        Status = SupportTicketStatus.Open;
        LastUserMessageAt = now;
        UpdatedAt = now;
        Raise(() => new SupportMessagePostedDomainEvent(Id, message.Id, UserId, FromSupport: false, IsNewTicket: false));
        return message;
    }

    /// <summary>Support replies: the ticket is Answered and the member is told. A closed ticket takes nothing (reopen first).</summary>
    public Result<SupportMessage> Reply(Guid adminId, string body, DateTime now)
    {
        if (IsClosed) return SupportErrors.TicketClosed;
        var message = new SupportMessage(adminId, fromSupport: true, isInternalNote: false, body, now);
        _messages.Add(message);
        Status = SupportTicketStatus.Answered;
        LastAdminReplyAt = now;
        UpdatedAt = now;
        Raise(() => new SupportMessagePostedDomainEvent(Id, message.Id, UserId, FromSupport: true, IsNewTicket: false));
        return message;
    }

    /// <summary>An internal note: only admins see it, in any status; nothing changes and nobody is told.</summary>
    public SupportMessage AddNote(Guid adminId, string body, DateTime now)
    {
        var message = new SupportMessage(adminId, fromSupport: true, isInternalNote: true, body, now);
        _messages.Add(message);
        return message;
    }

    /// <summary>The member closes it; returns false when it was closed already.</summary>
    public bool CloseByMember(DateTime now) => Close(UserId, SupportClosedBy.Member, now);

    /// <summary>Support closes it; the member is told (<c>support_reply</c>). False when it was closed already.</summary>
    public bool CloseBySupport(Guid adminId, DateTime now) => Close(adminId, SupportClosedBy.Support, now);

    /// <summary>The auto-close job: an Answered ticket whose last support reply is <see cref="AutoCloseAfter"/> old with no member message since.</summary>
    public bool AutoClose(DateTime now) =>
        Status == SupportTicketStatus.Answered && LastAdminReplyAt is { } replied && replied <= now - AutoCloseAfter && LastUserMessageAt <= replied
        && Close(null, SupportClosedBy.Auto, now);

    /// <summary>The member may reopen a closed ticket for <see cref="ReopenWindow"/> after it was closed.</summary>
    public bool CanReopen(DateTime now) => IsClosed && ClosedAt is { } closed && now - closed <= ReopenWindow;

    /// <summary>The member reopens it: Open again. A ticket that isn't closed stays as it is.</summary>
    public Result ReopenByMember(DateTime now)
    {
        if (!IsClosed) return Result.Success();
        if (!CanReopen(now)) return SupportErrors.ReopenExpired;
        Reopen();
        return Result.Success();
    }

    /// <summary>Support reopens it, whenever it was closed; returns false when it wasn't closed.</summary>
    public bool ReopenBySupport()
    {
        if (!IsClosed) return false;
        Reopen();
        return true;
    }

    /// <summary>Returns false when it has that category already.</summary>
    public bool ChangeCategory(string category)
    {
        if (Category == category) return false;
        Category = category;
        return true;
    }

    /// <summary>Account deletion (SPEC §9.6): the ticket stays with its member, without the link to the admin who closed it.</summary>
    public void ForgetCloser() => ClosedById = null;

    private bool Close(Guid? byId, SupportClosedBy by, DateTime now)
    {
        if (IsClosed) return false;
        Status = SupportTicketStatus.Closed;
        ClosedAt = now;
        ClosedById = byId;
        ClosedBy = by;
        Raise(() => new SupportTicketClosedDomainEvent(Id, UserId, by));
        return true;
    }

    private void Reopen()
    {
        Status = SupportTicketStatus.Open;
        ClosedAt = null;
        ClosedById = null;
        ClosedBy = null;
    }
}

/// <summary>One message of a ticket: the member's, a support reply, or an internal note only admins see.</summary>
public sealed class SupportMessage : Entity
{
    private readonly List<SupportAttachment> _attachments = [];

    private SupportMessage() { } // EF

    internal SupportMessage(Guid authorId, bool fromSupport, bool isInternalNote, string body, DateTime now)
    {
        AuthorId = authorId;
        FromSupport = fromSupport;
        IsInternalNote = isInternalNote;
        Body = body;
        CreatedAt = now;
    }

    public Guid TicketId { get; private set; }

    /// <summary>The member or the admin; no foreign key, null once that account is deleted (SPEC §9.6).</summary>
    public Guid? AuthorId { get; private set; }

    /// <summary>A support reply or note (shown to the member as «فريق الدعم» / "Support", never the admin's name).</summary>
    public bool FromSupport { get; private set; }

    public bool IsInternalNote { get; private set; }
    public string Body { get; private set; } = default!;
    public DateTime CreatedAt { get; private set; }

    public IReadOnlyCollection<SupportAttachment> Attachments => _attachments.AsReadOnly();

    /// <summary>A screenshot stored in the private store as <c>support/{messageId}/{position}{.ext}</c>.</summary>
    public SupportAttachment AddAttachment(int position, string filePath, string contentType, int sizeBytes, DateTime now)
    {
        var attachment = new SupportAttachment(position, filePath, contentType, sizeBytes, now);
        _attachments.Add(attachment);
        return attachment;
    }

    /// <summary>Account deletion (SPEC §9.6): an admin's reply stays, without the link to the admin.</summary>
    public void ForgetAuthor() => AuthorId = null;
}

/// <summary>A screenshot of a member's message (SPEC F35): JPEG, PNG or WebP ≤ 5 MB, in the private store.</summary>
public sealed class SupportAttachment : Entity
{
    public const int MaxPerMessage = 3;
    public const int MaxBytes = 5 * 1024 * 1024;
    public const int MaxPathLength = 200;

    private SupportAttachment() { } // EF

    internal SupportAttachment(int position, string filePath, string contentType, int sizeBytes, DateTime now)
    {
        Position = position;
        FilePath = filePath;
        ContentType = contentType;
        SizeBytes = sizeBytes;
        CreatedAt = now;
    }

    public Guid MessageId { get; private set; }

    /// <summary>1–3, in the order sent.</summary>
    public int Position { get; private set; }

    /// <summary>Relative to the private store: <c>support/{messageId}/{position}{.ext}</c>.</summary>
    public string FilePath { get; private set; } = default!;

    public string ContentType { get; private set; } = default!;
    public int SizeBytes { get; private set; }
    public DateTime CreatedAt { get; private set; }

    public static string PathFor(Guid messageId, int position, string extension) => $"support/{messageId}/{position}{extension}";
}

/// <summary>A member's or support's message on a ticket (not a note): <c>support_ticket</c> to admins, or <c>support_reply</c> to the member.</summary>
public sealed record SupportMessagePostedDomainEvent(Guid TicketId, Guid MessageId, Guid UserId, bool FromSupport, bool IsNewTicket) : DomainEvent;

/// <summary>A ticket was closed; support closing it tells the member (<c>support_reply</c>).</summary>
public sealed record SupportTicketClosedDomainEvent(Guid TicketId, Guid UserId, SupportClosedBy ClosedBy) : DomainEvent;

public static class SupportErrors
{
    /// <summary>5 new tickets a day, 10 open at once (SPEC F35); the problem says which with <c>limit</c>.</summary>
    public static readonly Error Limit =
        Error.TooManyRequests("support.limit", "You've reached the ticket limit: 5 new tickets a day and 10 open at once.");
    public static readonly Error TicketNotFound = Error.NotFound("support.ticket_not_found", "Ticket not found.");
    public static readonly Error AttachmentNotFound = Error.NotFound("support.attachment_not_found", "Attachment not found.");
    public static readonly Error TicketClosed = Error.Conflict("support.ticket_closed", "This ticket is closed. Reopen it first.");
    public static readonly Error ReopenExpired =
        Error.Conflict("support.reopen_expired", "This ticket was closed more than 30 days ago. Send a new one.");
    public static readonly Error AttachmentInvalid =
        Error.Validation("support.attachment_invalid", "Screenshots must be JPEG, PNG or WebP, up to 5 MB each.");
    public static readonly Error TooManyAttachments = Error.Validation("support.too_many_attachments", "You can attach up to 3 images.");

    /// <summary>The validation code of an unknown category (in <c>errors.category</c>).</summary>
    public const string CategoryInvalid = "support.category_invalid";

    public static Error LimitOf(string which) => Limit with { Extensions = new Dictionary<string, object?> { ["limit"] = which } };
}
