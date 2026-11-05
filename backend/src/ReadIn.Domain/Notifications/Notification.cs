using ReadIn.Domain.Common;

namespace ReadIn.Domain.Notifications;

/// <summary>
/// One entry of the notification center (SPEC F17, §21.1). Outbox handlers and jobs write it; the push job sends its push
/// later (<see cref="PushStatus"/>). An aggregated entry (<see cref="GroupKey"/>, e.g. comments on one article) collects
/// distinct <see cref="Actors"/> while it is unread and active in the last <see cref="AggregationWindow"/>, so ten comments
/// are one "Ahmed and 9 others commented on your article". <see cref="UpdatedAt"/> is the last activity: the list order.
/// </summary>
public sealed class Notification : Entity
{
    public const int MaxTypeLength = 40;
    public const int MaxKeyLength = 200;

    /// <summary>A push is retried this many times when FCM fails for a reason other than a dead token.</summary>
    public const int MaxPushAttempts = 3;

    /// <summary>New activity joins an unread entry of the same group that moved within this window.</summary>
    public static readonly TimeSpan AggregationWindow = TimeSpan.FromHours(24);

    private readonly List<NotificationActor> _actors = [];

    private Notification() { } // EF

    public Guid UserId { get; private set; }

    /// <summary>One of <see cref="NotificationTypes"/>; also the push's <c>data.type</c>.</summary>
    public string Type { get; private set; } = default!;

    /// <summary>Entries with the same key (per user) aggregate, e.g. <c>article_comment:{articleId}</c>; null = never.</summary>
    public string? GroupKey { get; private set; }

    /// <summary>Unique per user when set, so a retried outbox event never writes the same entry twice.</summary>
    public string? DedupeKey { get; private set; }

    public Guid? ArticleId { get; private set; }

    /// <summary>The comment it is about; for an aggregated entry, the latest one.</summary>
    public Guid? CommentId { get; private set; }

    /// <summary>Type-specific values as JSON (threshold, streak days, security change, moderation notice).</summary>
    public string? Data { get; private set; }

    public DateTime CreatedAt { get; private set; }

    /// <summary>The last activity; the list is ordered by it.</summary>
    public DateTime UpdatedAt { get; private set; }

    /// <summary>Set when the user opened the center: the badge counts entries without it.</summary>
    public DateTime? SeenAt { get; private set; }

    /// <summary>Set when the user opened the entry (or the push), or marked everything read.</summary>
    public DateTime? ReadAt { get; private set; }

    public NotificationPushStatus PushStatus { get; private set; }

    /// <summary>When the push job may send it (the end of quiet hours, or a retry); set while <see cref="PushStatus"/> is Pending.</summary>
    public DateTime? PushAfter { get; private set; }

    public DateTime? PushedAt { get; private set; }

    /// <summary>Failed sends of the current push (reset when new activity re-arms it).</summary>
    public int PushAttempts { get; private set; }

    /// <summary>Distinct users who caused it, with their latest activity. Aggregation loads only the actor it adds.</summary>
    public IReadOnlyCollection<NotificationActor> Actors => _actors.AsReadOnly();

    public bool IsRead => ReadAt is not null;

    /// <param name="pushAfter">When the push may go out; null when there is no push (in-app only, or sent by its caller).</param>
    public static Notification Create(
        Guid userId,
        string type,
        DateTime now,
        DateTime? pushAfter,
        string? groupKey = null,
        string? dedupeKey = null,
        Guid? articleId = null,
        Guid? commentId = null,
        string? data = null,
        Guid? actorId = null,
        DateTime? actorAt = null)
    {
        if (!NotificationTypes.IsKnown(type)) throw new ArgumentOutOfRangeException(nameof(type), type, "Unknown notification type.");
        if (groupKey?.Length > MaxKeyLength) throw new ArgumentException("The group key is too long.", nameof(groupKey));
        if (dedupeKey?.Length > MaxKeyLength) throw new ArgumentException("The dedupe key is too long.", nameof(dedupeKey));

        var notification = new Notification
        {
            UserId = userId,
            Type = type,
            GroupKey = groupKey,
            DedupeKey = dedupeKey,
            ArticleId = articleId,
            CommentId = commentId,
            Data = data,
            CreatedAt = now,
            UpdatedAt = now,
        };
        if (actorId is { } actor) notification._actors.Add(new NotificationActor(notification.Id, actor, actorAt ?? now));
        notification.ArmPush(pushAfter);
        return notification;
    }

    /// <summary>New activity of the same group may join this entry: it is unread and moved within the window.</summary>
    public bool CanAggregate(DateTime now) => ReadAt is null && now - UpdatedAt <= AggregationWindow;

    /// <summary>
    /// Adds <paramref name="actorId"/>'s activity to this aggregated entry: it moves to the top as unseen and unread, and
    /// its push is armed again (the device replaces the older one, same collapse key). Load the entry with that actor's
    /// row only (or none). An actor already in it changes nothing unless <paramref name="repeatsCount"/> and the activity
    /// is newer than the one recorded, so a redelivered event is a no-op.
    /// </summary>
    /// <returns>false when nothing changed.</returns>
    public bool AddActivity(Guid actorId, DateTime actorAt, Guid? commentId, bool repeatsCount, DateTime now, DateTime? pushAfter)
    {
        var existing = _actors.FirstOrDefault(a => a.ActorId == actorId);
        if (existing is not null)
        {
            if (!repeatsCount || actorAt <= existing.At) return false;
            existing.MoveTo(actorAt);
        }
        else
        {
            _actors.Add(new NotificationActor(Id, actorId, actorAt));
        }

        if (commentId is not null) CommentId = commentId;
        UpdatedAt = now;
        SeenAt = null;
        ReadAt = null;
        ArmPush(pushAfter);
        return true;
    }

    /// <returns>false when it was seen already.</returns>
    public bool MarkSeen(DateTime now)
    {
        if (SeenAt is not null) return false;
        SeenAt = now;
        return true;
    }

    /// <summary>Opened: read, and seen too. Idempotent.</summary>
    /// <returns>false when nothing changed.</returns>
    public bool MarkRead(DateTime now)
    {
        var changed = MarkSeen(now);
        if (ReadAt is not null) return changed;
        ReadAt = now;
        return true;
    }

    /// <summary>Pending from <paramref name="pushAfter"/>, or no push when it is null.</summary>
    public void ArmPush(DateTime? pushAfter)
    {
        PushStatus = pushAfter is null ? NotificationPushStatus.None : NotificationPushStatus.Pending;
        PushAfter = pushAfter;
        PushAttempts = 0;
    }

    /// <summary>Quiet hours: the push waits until <paramref name="pushAfter"/>.</summary>
    public void DeferPush(DateTime pushAfter)
    {
        if (PushStatus != NotificationPushStatus.Pending) return;
        PushAfter = pushAfter;
    }

    public void MarkPushed(DateTime now)
    {
        PushStatus = NotificationPushStatus.Sent;
        PushedAt = now;
        PushAfter = null;
    }

    /// <summary>Not sent and never will be (too old, turned off, no device, the content is gone).</summary>
    public void SkipPush()
    {
        PushStatus = NotificationPushStatus.Skipped;
        PushAfter = null;
    }

    /// <summary>
    /// FCM failed for a reason other than a dead token: tried again at <paramref name="retryAt"/>, at most
    /// <see cref="MaxPushAttempts"/> times in all, then <see cref="NotificationPushStatus.Failed"/>.
    /// </summary>
    /// <returns>true when it will be retried.</returns>
    public bool RecordPushFailure(DateTime retryAt)
    {
        PushAttempts++;
        if (PushAttempts >= MaxPushAttempts)
        {
            PushStatus = NotificationPushStatus.Failed;
            PushAfter = null;
            return false;
        }

        PushAfter = retryAt;
        return true;
    }
}

/// <summary>
/// A user who caused a notification (SPEC F17). The key (NotificationId, ActorId) keeps actors distinct and makes a
/// retried event harmless. No cascade from Users (SQL Server refuses a second path): account deletion removes the rows.
/// </summary>
public sealed class NotificationActor
{
    private NotificationActor() { } // EF

    internal NotificationActor(Guid notificationId, Guid actorId, DateTime at)
    {
        NotificationId = notificationId;
        ActorId = actorId;
        At = at;
    }

    public Guid NotificationId { get; private set; }
    public Guid ActorId { get; private set; }

    /// <summary>When the event of the actor's latest activity occurred (stable across outbox retries).</summary>
    public DateTime At { get; private set; }

    internal void MoveTo(DateTime at) => At = at;
}

/// <summary>
/// A user's choice for one configurable type (SPEC F17). Sparse: no row means <see cref="NotificationMode.All"/>.
/// </summary>
public sealed class UserNotificationSetting
{
    private UserNotificationSetting() { } // EF

    public UserNotificationSetting(Guid userId, string type, NotificationMode mode)
    {
        if (!NotificationTypes.IsConfigurable(type)) throw new ArgumentOutOfRangeException(nameof(type), type, "Not a configurable type.");
        UserId = userId;
        Type = type;
        Mode = mode;
    }

    public Guid UserId { get; private set; }
    public string Type { get; private set; } = default!;
    public NotificationMode Mode { get; private set; }

    public void Change(NotificationMode mode) => Mode = mode;
}

/// <summary>Per type: push and in-app, in-app only, or nothing at all (no row is written).</summary>
public enum NotificationMode : byte
{
    All = 0,
    InApp = 1,
    Off = 2,
}

public enum NotificationPushStatus : byte
{
    /// <summary>No push from the push job (in-app only, or its caller sends it, like the daily article).</summary>
    None = 0,
    Pending = 1,
    Sent = 2,
    Skipped = 3,
    Failed = 4,
}

/// <summary>The <c>type</c> strings of SPEC F17 (docs/api/contract-v1.md).</summary>
public static class NotificationTypes
{
    public const string NewFollower = "new_follower";
    public const string ArticleComment = "article_comment";
    public const string CommentReply = "comment_reply";
    public const string Mention = "mention";
    public const string ReactionsMilestone = "reactions_milestone";
    public const string FollowedWriterArticle = "followed_writer_article";
    public const string DailyArticle = "daily_article";
    public const string StreakReminder = "streak_reminder";
    public const string SecurityAlert = "security_alert";

    /// <summary>Reserved for F19 (writer verification); nothing writes it yet.</summary>
    public const string VerificationResult = "verification_result";

    public const string ModerationNotice = "moderation_notice";

    /// <summary>Someone reposted your article (SPEC F29, which calls it <c>article.reposted</c>); aggregated per article.</summary>
    public const string ArticleReposted = "article_reposted";

    public static readonly IReadOnlyList<string> All =
    [
        NewFollower, ArticleComment, CommentReply, Mention, ReactionsMilestone, FollowedWriterArticle, DailyArticle, StreakReminder,
        SecurityAlert, VerificationResult, ModerationNotice, ArticleReposted,
    ];

    /// <summary>The types a user can set to all / in-app / off. Security alerts and moderation notices always come.</summary>
    public static readonly IReadOnlyList<string> Configurable =
    [
        NewFollower, ArticleComment, CommentReply, Mention, ReactionsMilestone, FollowedWriterArticle, DailyArticle, StreakReminder,
        ArticleReposted,
    ];

    public static bool IsKnown(string? type) => type is not null && All.Contains(type);

    public static bool IsConfigurable(string? type) => type is not null && Configurable.Contains(type);

    /// <summary>Security alerts go out at once, even at night (SPEC §9.5, §21.1).</summary>
    public static bool IgnoresQuietHours(string type) => type == SecurityAlert;
}

public static class NotificationErrors
{
    public static readonly Error NotFound = Error.NotFound("notification.not_found", "Notification not found.");
    public static readonly Error TypeInvalid = Error.Validation("notification.type_invalid", "Unknown or not configurable notification type.");
    public static readonly Error ModeInvalid = Error.Validation("notification.mode_invalid", "The mode must be all, inApp or off.");
    public static readonly Error QuietHoursInvalid =
        Error.Validation("notification.quiet_hours_invalid", "Quiet hours need a start and an end (HH:mm) that differ.");
}
