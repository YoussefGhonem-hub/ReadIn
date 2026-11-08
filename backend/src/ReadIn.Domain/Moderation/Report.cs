using ReadIn.Domain.Common;

namespace ReadIn.Domain.Moderation;

public enum ReportTargetType
{
    Article = 0,
    Comment = 1,
    User = 2,

    /// <summary>A repost: its caption is the reposter's text (SPEC F22 store requirements).</summary>
    Repost = 3,
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
/// A user's report of an article, a comment, a user or a repost (SPEC F22). One report per user and target: reporting again
/// is a no-op. Moderators close it from the queue: resolved when they acted on the target, dismissed when they didn't. A
/// system report (the content filter, F37) has no reporter and keeps the matched terms for staff; there is one per target.
/// </summary>
public sealed class Report : AggregateRoot
{
    public const int MaxDetailsLength = 500;
    public const int MaxMatchedTermsLength = 400;

    /// <summary>The F22 24-hour target: open cases older than this are marked urgent.</summary>
    public static readonly TimeSpan UrgentAfter = TimeSpan.FromHours(12);

    /// <summary>The F22 target: every open report is closed within this.</summary>
    public static readonly TimeSpan ResponseTarget = TimeSpan.FromHours(24);

    private const char TermSeparator = '\u001F';

    private Report() { } // EF

    public ReportTargetType TargetType { get; private set; }
    public Guid TargetId { get; private set; }

    /// <summary>Who reported it; null for a system report (the content filter, F37).</summary>
    public Guid? ReporterId { get; private set; }

    public ReportReason Reason { get; private set; }
    public string? Details { get; private set; }
    public ReportStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }

    /// <summary>When it was resolved or dismissed.</summary>
    public DateTime? ResolvedAt { get; private set; }

    /// <summary>The moderator who resolved or dismissed it.</summary>
    public Guid? ResolvedById { get; private set; }

    /// <summary>The filter's matched terms of a system report (≤ 400 characters together); staff only.</summary>
    public string? MatchedTerms { get; private set; }

    public bool IsSystem => ReporterId is null;

    public IReadOnlyList<string> MatchedTermList => MatchedTerms is null ? [] : MatchedTerms.Split(TermSeparator);

    public static Report File(ReportTargetType targetType, Guid targetId, Guid reporterId, ReportReason reason, string? details, DateTime now) =>
        new Report
        {
            TargetType = targetType,
            TargetId = targetId,
            ReporterId = reporterId,
            Reason = reason,
            Details = string.IsNullOrWhiteSpace(details) ? null : details.Trim(),
            Status = ReportStatus.Open,
            CreatedAt = now,
        }.Filed();

    /// <summary>The content filter flagged the target (SPEC F37): a report with no reporter and the matched terms.</summary>
    public static Report FileSystem(ReportTargetType targetType, Guid targetId, IEnumerable<string> matchedTerms, DateTime now) =>
        new Report
        {
            TargetType = targetType,
            TargetId = targetId,
            ReporterId = null,
            Reason = ReportReason.Other,
            MatchedTerms = JoinTerms(matchedTerms),
            Status = ReportStatus.Open,
            CreatedAt = now,
        }.Filed();

    /// <summary>The filter flagged the same target again: the one system report is open again, with the new terms.</summary>
    public void Reflag(IEnumerable<string> matchedTerms, DateTime now)
    {
        MatchedTerms = JoinTerms(matchedTerms);
        if (Status == ReportStatus.Open) return;
        Status = ReportStatus.Open;
        CreatedAt = now;
        ResolvedAt = null;
        ResolvedById = null;
        Filed();
    }

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
        Raise(() => new ReportClosedDomainEvent(Id, TargetType, TargetId, ReporterId, status));
    }

    private Report Filed()
    {
        Raise(() => new ReportFiledDomainEvent(Id, TargetType, TargetId, ReporterId));
        return this;
    }

    private static string JoinTerms(IEnumerable<string> terms)
    {
        var joined = string.Join(TermSeparator, terms.Distinct(StringComparer.Ordinal));
        return joined.Length <= MaxMatchedTermsLength ? joined : joined[..MaxMatchedTermsLength];
    }
}

/// <summary>A report was filed (or a system report flagged again): <c>report_new</c> to staff (SPEC F22).</summary>
public sealed record ReportFiledDomainEvent(Guid ReportId, ReportTargetType TargetType, Guid TargetId, Guid? ReporterId) : DomainEvent;

/// <summary>A moderator resolved or dismissed a report: <c>report_resolved</c> to its reporter (SPEC F22).</summary>
public sealed record ReportClosedDomainEvent(
    Guid ReportId, ReportTargetType TargetType, Guid TargetId, Guid? ReporterId, ReportStatus Status) : DomainEvent;

public static class ReportErrors
{
    public static readonly Error TargetNotFound = Error.NotFound("report.target_not_found", "The reported content doesn't exist.");
    public static readonly Error OwnContent = Error.Validation("report.own_content", "You can't report your own content.");

    /// <summary>A reported or moderated repost that is gone (SPEC F22 store requirements).</summary>
    public static readonly Error RepostNotFound = Error.NotFound("repost.not_found", "This repost no longer exists.");
}
