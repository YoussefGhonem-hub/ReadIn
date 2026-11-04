using ReadIn.Domain.Common;

namespace ReadIn.Domain.Moderation;

/// <summary>
/// One moderator action that changed something (SPEC F22, §16.2): the moderation log. A warning and a hidden article are
/// also a notice the affected user acknowledges (<see cref="NoticeKind"/>). <see cref="TargetUserId"/> and
/// <see cref="ModeratorId"/> have no foreign keys (SQL Server refuses a second cascade path from Users); account deletion
/// nulls them. <see cref="TargetLabel"/> keeps what the target looked like at the time.
/// </summary>
public sealed class ModerationAction : AggregateRoot
{
    public const int MaxNoteLength = 500;
    public const int MaxLabelLength = 200;

    /// <summary>A comment's label: its first 80 characters.</summary>
    public const int CommentLabelLength = 80;

    public const int MinSuspensionDays = 1;
    public const int MaxSuspensionDays = 365;

    private ModerationAction() { } // EF

    /// <summary>One of <see cref="ModerationActionTypes"/>, e.g. <c>article.hide</c>.</summary>
    public string Action { get; private set; } = default!;

    public ReportTargetType TargetType { get; private set; }
    public Guid TargetId { get; private set; }

    /// <summary>The affected user: the author of the article or comment, or the user target. Null once deleted.</summary>
    public Guid? TargetUserId { get; private set; }

    /// <summary>Null once the moderator deleted their account.</summary>
    public Guid? ModeratorId { get; private set; }

    /// <summary>Article title, first 80 characters of the comment, or @username, at the time.</summary>
    public string? TargetLabel { get; private set; }

    public string? Note { get; private set; }

    /// <summary><c>user.suspend</c> only: when it ends; null = permanent.</summary>
    public DateTime? SuspendedUntil { get; private set; }

    /// <summary>Open reports this action resolved or dismissed.</summary>
    public int ReportsClosed { get; private set; }

    public DateTime CreatedAt { get; private set; }

    /// <summary>One of <see cref="NoticeKinds"/> when the affected user must see it; null otherwise.</summary>
    public string? NoticeKind { get; private set; }

    public DateTime? AcknowledgedAt { get; private set; }

    public bool IsNotice => NoticeKind is not null;

    /// <summary><c>comment.hide</c>, <c>comment.unhide</c> or <c>comment.delete</c>.</summary>
    public static ModerationAction OnComment(
        string action, Guid commentId, Guid? authorId, string body, Guid moderatorId, string? note, int reportsClosed, DateTime now)
    {
        if (action is not (ModerationActionTypes.CommentHide or ModerationActionTypes.CommentUnhide or ModerationActionTypes.CommentDelete))
            throw new ArgumentException($"'{action}' is not a comment action.", nameof(action));
        return Create(action, ReportTargetType.Comment, commentId, authorId, Label(body, CommentLabelLength), moderatorId, note, reportsClosed, now);
    }

    /// <summary>
    /// <c>article.hide</c> or <c>article.unhide</c>. A hide that changed the article is a notice to its author; pass
    /// <paramref name="notifyAuthor"/> false when it only closed reports of an already hidden article.
    /// </summary>
    public static ModerationAction OnArticle(
        string action, Guid articleId, Guid? authorId, string? title, Guid moderatorId, string? note, int reportsClosed, DateTime now,
        bool notifyAuthor = true)
    {
        if (action is not (ModerationActionTypes.ArticleHide or ModerationActionTypes.ArticleUnhide))
            throw new ArgumentException($"'{action}' is not an article action.", nameof(action));

        var logged = Create(action, ReportTargetType.Article, articleId, authorId, Label(title, MaxLabelLength), moderatorId, note, reportsClosed, now);
        // A deleted writer's kept article has no author (SPEC F01), so there is nobody to tell.
        if (action == ModerationActionTypes.ArticleHide && notifyAuthor && authorId is not null) logged.IssueNotice(NoticeKinds.ArticleHidden);
        return logged;
    }

    /// <summary>A warning is always a notice to the user. The note (what they did wrong) is required.</summary>
    public static ModerationAction Warning(Guid userId, string username, Guid moderatorId, string note, int reportsClosed, DateTime now)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(note);
        var logged = Create(ModerationActionTypes.UserWarn, ReportTargetType.User, userId, userId, UserLabel(username), moderatorId, note,
            reportsClosed, now);
        logged.IssueNotice(NoticeKinds.Warning);
        return logged;
    }

    /// <param name="until">Null for a permanent suspension.</param>
    public static ModerationAction Suspension(
        Guid userId, string username, Guid moderatorId, string note, DateTime? until, int reportsClosed, DateTime now)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(note);
        var logged = Create(ModerationActionTypes.UserSuspend, ReportTargetType.User, userId, userId, UserLabel(username), moderatorId, note,
            reportsClosed, now);
        logged.SuspendedUntil = until;
        return logged;
    }

    public static ModerationAction Unsuspension(Guid userId, string username, Guid moderatorId, string? note, DateTime now) =>
        Create(ModerationActionTypes.UserUnsuspend, ReportTargetType.User, userId, userId, UserLabel(username), moderatorId, note, 0, now);

    /// <summary>Open reports closed without touching the target.</summary>
    public static ModerationAction Dismissal(
        ReportTargetType targetType, Guid targetId, Guid? targetUserId, string? label, Guid moderatorId, string? note, int reportsClosed,
        DateTime now)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(reportsClosed);
        var maxLength = targetType == ReportTargetType.Comment ? CommentLabelLength : MaxLabelLength;
        return Create(ModerationActionTypes.ReportsDismiss, targetType, targetId, targetUserId, Label(label, maxLength), moderatorId, note,
            reportsClosed, now);
    }

    /// <summary>The affected user saw the notice ("فهمت"); idempotent.</summary>
    public void Acknowledge(DateTime now)
    {
        if (!IsNotice || AcknowledgedAt is not null) return;
        AcknowledgedAt = now;
    }

    private static ModerationAction Create(
        string action, ReportTargetType targetType, Guid targetId, Guid? targetUserId, string? label, Guid moderatorId, string? note,
        int reportsClosed, DateTime now)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(reportsClosed);
        var cleanNote = string.IsNullOrWhiteSpace(note) ? null : note.Trim();
        if (cleanNote?.Length > MaxNoteLength) throw new ArgumentException($"A note has at most {MaxNoteLength} characters.", nameof(note));

        return new ModerationAction
        {
            Action = action,
            TargetType = targetType,
            TargetId = targetId,
            TargetUserId = targetUserId,
            ModeratorId = moderatorId,
            TargetLabel = label,
            Note = cleanNote,
            ReportsClosed = reportsClosed,
            CreatedAt = now,
        };
    }

    private void IssueNotice(string kind)
    {
        NoticeKind = kind;
        Raise(() => new ModerationNoticeIssuedDomainEvent(Id));
    }

    private static string UserLabel(string username) => $"@{username}";

    /// <summary>The first <paramref name="maxLength"/> characters, on one line, never splitting a surrogate pair.</summary>
    private static string? Label(string? text, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(text)) return null;
        var line = string.Join(' ', text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
        if (line.Length <= maxLength) return line;
        var cut = char.IsHighSurrogate(line[maxLength - 1]) ? maxLength - 1 : maxLength;
        return line[..cut];
    }
}

/// <summary><see cref="ModerationAction.Action"/> codes: what the log shows (SPEC F22).</summary>
public static class ModerationActionTypes
{
    public const string CommentHide = "comment.hide";
    public const string CommentUnhide = "comment.unhide";
    public const string CommentDelete = "comment.delete";
    public const string ArticleHide = "article.hide";
    public const string ArticleUnhide = "article.unhide";
    public const string UserWarn = "user.warn";
    public const string UserSuspend = "user.suspend";
    public const string UserUnsuspend = "user.unsuspend";
    public const string ReportsDismiss = "reports.dismiss";
}

/// <summary><see cref="ModerationAction.NoticeKind"/>: what the affected user is shown until they acknowledge it.</summary>
public static class NoticeKinds
{
    public const string Warning = "warning";
    public const string ArticleHidden = "article_hidden";
}

/// <summary>After the commit: a <c>moderation_notice</c> notification for the affected user, with its push (F17).</summary>
public sealed record ModerationNoticeIssuedDomainEvent(Guid NoticeId) : DomainEvent;

public static class ModerationErrors
{
    public static readonly Error ActionInvalid =
        Error.Validation("moderation.action_invalid", "This action doesn't apply to this target.");
    public static readonly Error Self =
        Error.Validation("moderation.self", "You can't take this action on your own account.");
    public static readonly Error StaffTarget =
        Error.Forbidden("moderation.staff_target", "Moderators and admins can't be warned or suspended.");
    public static readonly Error NoteRequired =
        Error.Validation("moderation.note_required", "Write a note that tells the user why.");
    public static readonly Error DurationInvalid =
        Error.Validation("moderation.duration_invalid", "A suspension lasts 1 to 365 days, or until it is lifted.");
    public static readonly Error NoticeNotFound =
        Error.NotFound("moderation.notice_not_found", "Notice not found.");
}
