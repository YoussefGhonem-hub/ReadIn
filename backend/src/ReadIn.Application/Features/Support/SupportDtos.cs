using ReadIn.Application.Features.Admin.Users;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Moderation;
using ReadIn.Domain.Support;

namespace ReadIn.Application.Features.Support;

/// <summary>Help & support settings (SPEC F35): the support email shown on <c>/support</c>, the suspension screen and "forgot the PIN".</summary>
public sealed class SupportOptions
{
    public const string Section = "Support";

    /// <summary>Empty or missing: the clients hide the email.</summary>
    public string? Email { get; set; }
}

/// <summary>GET /support/config (contract <c>SupportConfigDto</c>).</summary>
public sealed record SupportConfigDto(
    string? Email, IReadOnlyList<string> Categories, int MaxAttachments, int MaxAttachmentBytes, IReadOnlyList<string> AttachmentTypes);

public sealed record SupportDeviceDto(string? Platform, string? OsVersion, string? AppVersion, string? Language, string? Screen);

/// <summary>A screenshot: read it with <c>GET /support/attachments/{id}</c> and the session.</summary>
public sealed record SupportAttachmentDto(Guid Id, string ContentType, int SizeBytes);

/// <param name="FromSupport">True: «فريق الدعم» / "Support" (the admin stays anonymous to the member).</param>
public record SupportMessageDto(Guid Id, bool FromSupport, string Body, IReadOnlyList<SupportAttachmentDto> Attachments, DateTime CreatedAt);

public sealed record SupportLastMessageDto(bool FromSupport, string Excerpt, DateTime CreatedAt);

/// <summary>A row of My tickets (contract <c>SupportTicketSummaryDto</c>).</summary>
public record SupportTicketSummaryDto(
    Guid Id,
    int Number,
    string Category,
    string Subject,
    SupportTicketStatus Status,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    SupportLastMessageDto LastMessage,
    DateTime? ClosedAt,
    bool CanReopen);

/// <summary>A member's ticket with its conversation, never internal notes (contract <c>SupportTicketDto</c>).</summary>
public sealed record SupportTicketDto : SupportTicketSummaryDto
{
    public SupportTicketDto(SupportTicketSummaryDto summary) : base(summary)
    {
    }

    public SupportDeviceDto Device { get; init; } = default!;

    /// <summary>Oldest first.</summary>
    public IReadOnlyList<SupportMessageDto> Messages { get; init; } = [];
}

public sealed record AdminLastMessageDto(bool FromSupport, bool IsInternalNote, string Excerpt, DateTime CreatedAt);

/// <summary>A row of the admin queue (contract <c>AdminTicketRowDto</c>).</summary>
/// <param name="WaitingSince">Open: the member's last message; null otherwise.</param>
public record AdminTicketRowDto(
    Guid Id,
    int Number,
    string Category,
    string Subject,
    SupportTicketStatus Status,
    AuthorDto User,
    DateTime CreatedAt,
    DateTime? WaitingSince,
    AdminLastMessageDto LastMessage,
    DateTime? ClosedAt);

public sealed record SupportAuthorDto(Guid Id, string DisplayName, string Username);

/// <summary>A message as admins see it: notes included, with who wrote it (contract <c>AdminSupportMessageDto</c>).</summary>
public sealed record AdminSupportMessageDto : SupportMessageDto
{
    public AdminSupportMessageDto(SupportMessageDto message) : base(message)
    {
    }

    public bool IsInternalNote { get; init; }

    /// <summary>The member or the admin; null once that account is deleted.</summary>
    public SupportAuthorDto? Author { get; init; }
}

/// <summary>The member card of a ticket's page.</summary>
public sealed record SupportMemberCardDto(
    string Status, DateTime? SuspendedUntil, DateTime JoinedAt, IReadOnlyList<string> SignInMethods, int TicketCount);

/// <summary>A ticket's page in the console (contract <c>AdminTicketDto</c>).</summary>
public sealed record AdminTicketDto : AdminTicketRowDto
{
    public AdminTicketDto(AdminTicketRowDto row) : base(row)
    {
    }

    public SupportDeviceDto Device { get; init; } = default!;

    /// <summary>Oldest first, internal notes included.</summary>
    public IReadOnlyList<AdminSupportMessageDto> Messages { get; init; } = [];

    public SupportClosedBy? ClosedBy { get; init; }
    public SupportMemberCardDto Member { get; init; } = default!;

    /// <summary>Reports the member filed, newest 10; null without <c>moderation.manage</c>.</summary>
    public AdminListDto<AdminUserReportDto>? ReportsFiled { get; init; }

    /// <summary>Open reports about the member, their articles and comments; null without <c>moderation.manage</c>.</summary>
    public int? ReportsAgainst { get; init; }

    /// <summary>Warnings and suspensions about the member, newest 10; null without <c>moderation.manage</c>.</summary>
    public IReadOnlyList<ModerationActionDto>? Moderation { get; init; }
}
