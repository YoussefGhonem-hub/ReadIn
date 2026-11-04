using ReadIn.Domain.Common;

namespace ReadIn.Domain.Moderation;

public enum ReportTargetType
{
    Article = 0,
    Comment = 1,
    User = 2,
}

/// <summary>SPEC F22 reasons.</summary>
public enum ReportReason
{
    Spam = 0,
    Misinformation = 1,
    Harassment = 2,
    Copyright = 3,
    Other = 4,
}

public enum ReportStatus
{
    Open = 0,
    Resolved = 1,
    Dismissed = 2,
}

/// <summary>
/// A user's report of an article, a comment or a user (SPEC F22). One report per user and target: reporting again is a
/// no-op. Moderators close it from the queue: resolved when they acted on the target, dismissed when they didn't.
/// </summary>
public sealed class Report
{
    public const int MaxDetailsLength = 500;

    private Report() { } // EF

    public Guid Id { get; private set; }
    public ReportTargetType TargetType { get; private set; }
    public Guid TargetId { get; private set; }
    public Guid ReporterId { get; private set; }
    public ReportReason Reason { get; private set; }
    public string? Details { get; private set; }
    public ReportStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }

    /// <summary>When it was resolved or dismissed.</summary>
    public DateTime? ResolvedAt { get; private set; }

    /// <summary>The moderator who resolved or dismissed it.</summary>
    public Guid? ResolvedById { get; private set; }

    public static Report File(ReportTargetType targetType, Guid targetId, Guid reporterId, ReportReason reason, string? details, DateTime now) =>
        new()
        {
            TargetType = targetType,
            TargetId = targetId,
            ReporterId = reporterId,
            Reason = reason,
            Details = string.IsNullOrWhiteSpace(details) ? null : details.Trim(),
            Status = ReportStatus.Open,
            CreatedAt = now,
        };

    /// <summary>A moderator acted on the reported target, e.g. hid the comment or warned the user.</summary>
    public void Resolve(Guid moderatorId, DateTime now) => Close(ReportStatus.Resolved, moderatorId, now);

    /// <summary>A moderator closed the report without touching the target.</summary>
    public void Dismiss(Guid moderatorId, DateTime now) => Close(ReportStatus.Dismissed, moderatorId, now);

    private void Close(ReportStatus status, Guid moderatorId, DateTime now)
    {
        if (Status != ReportStatus.Open) return;
        Status = status;
        ResolvedAt = now;
        ResolvedById = moderatorId;
    }
}

public static class ReportErrors
{
    public static readonly Error TargetNotFound = Error.NotFound("report.target_not_found", "The reported content doesn't exist.");
    public static readonly Error OwnContent = Error.Validation("report.own_content", "You can't report your own content.");
}
