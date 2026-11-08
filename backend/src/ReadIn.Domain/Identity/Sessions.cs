using ReadIn.Domain.Common;

namespace ReadIn.Domain.Identity;

/// <summary>
/// One link of a rotating refresh-token chain (SPEC §9.3). Only the SHA-256 hash of the token is stored. Every sign in
/// starts a new <see cref="FamilyId"/>; presenting an already-rotated token revokes the whole family (theft detection),
/// unless the client that rotated it retries with its retry key (<see cref="CanBeRetriedWith"/>).
/// </summary>
public sealed class RefreshToken : Entity
{
    private RefreshToken() { } // EF

    public Guid UserId { get; private set; }
    public string TokenHash { get; private set; } = default!;
    public Guid FamilyId { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime ExpiresAt { get; private set; }
    public string? CreatedByIp { get; private set; }
    public string? DeviceName { get; private set; }
    public DateTime? RevokedAt { get; private set; }
    public Guid? ReplacedById { get; private set; }

    /// <summary>
    /// SHA-256 of the retry key the client sent with the refresh that rotated this token. The mobile app keeps the key until
    /// it has stored the new token, so a refresh whose answer was lost can be repeated (<see cref="CanBeRetriedWith"/>).
    /// </summary>
    public string? RetryKeyHash { get; private set; }

    public static RefreshToken Issue(
        Guid userId, string tokenHash, Guid familyId, DateTime now, TimeSpan lifetime, string? ip, string? deviceName) =>
        new()
        {
            UserId = userId,
            TokenHash = tokenHash,
            FamilyId = familyId,
            CreatedAt = now,
            ExpiresAt = now + lifetime,
            CreatedByIp = ip,
            DeviceName = deviceName is { Length: > 200 } ? deviceName[..200] : deviceName,
        };

    public bool IsActiveAt(DateTime now) => RevokedAt is null && ExpiresAt > now;

    /// <summary>A revoked token that was replaced by a newer one: presenting it again means it was copied.</summary>
    public bool WasRotated => ReplacedById is not null;

    public void Revoke(DateTime now) => RevokedAt ??= now;

    /// <param name="retryKeyHash">The hash of the client's retry key, when it sent one: only that client may repeat this refresh.</param>
    public void RotateTo(RefreshToken next, DateTime now, string? retryKeyHash = null)
    {
        RevokedAt = now;
        ReplacedById = next.Id;
        RetryKeyHash = retryKeyHash;
    }

    /// <summary>
    /// The client that rotated this token repeats the refresh with the same retry key, and <paramref name="successor"/>, the
    /// token that replaced it, was never used: the answer was lost on the way, the token wasn't copied. A rotated token
    /// presented without the key, with another key or after its successor was used is still reuse.
    /// </summary>
    public bool CanBeRetriedWith(string retryKeyHash, RefreshToken successor, DateTime now) =>
        WasRotated && RetryKeyHash is not null && string.Equals(RetryKeyHash, retryKeyHash, StringComparison.Ordinal) &&
        successor.Id == ReplacedById && successor.IsActiveAt(now) && !successor.WasRotated;

    /// <summary>
    /// Repeats a refresh whose answer was lost: <paramref name="next"/> replaces this token instead of the unused
    /// <paramref name="successor"/>, which counts as rotated from now on, so presenting it later is reuse. The retry key stays,
    /// so a second lost answer can be retried the same way.
    /// </summary>
    public void RetryTo(RefreshToken successor, RefreshToken next, DateTime now)
    {
        if (successor.Id != ReplacedById || !successor.IsActiveAt(now) || successor.WasRotated)
            throw new InvalidOperationException("Only the unused token that replaced this one can be replaced again.");

        successor.RotateTo(next, now);
        ReplacedById = next.Id;
    }
}

/// <summary>Issued after a correct recovery PIN: 10 minutes, single use, bound to the user and the creating IP (SPEC §9.3).</summary>
public sealed class PasswordResetToken : Entity
{
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(10);

    private PasswordResetToken() { } // EF

    public Guid UserId { get; private set; }
    public string TokenHash { get; private set; } = default!;
    public DateTime CreatedAt { get; private set; }
    public DateTime ExpiresAt { get; private set; }
    public DateTime? UsedAt { get; private set; }
    public string? CreatedByIp { get; private set; }

    public static PasswordResetToken Issue(Guid userId, string tokenHash, DateTime now, string? ip) => new()
    {
        UserId = userId,
        TokenHash = tokenHash,
        CreatedAt = now,
        ExpiresAt = now + Lifetime,
        CreatedByIp = ip,
    };

    public bool IsUsableAt(DateTime now, string? ip) => UsedAt is null && ExpiresAt > now && CreatedByIp == ip;

    public void MarkUsed(DateTime now) => UsedAt = now;
}

/// <summary>Every recovery PIN check, for per-number limits and abuse review. The number is stored as a keyed hash only.</summary>
public sealed class RecoveryAttempt : Entity
{
    private RecoveryAttempt() { } // EF

    public Guid? UserId { get; private set; }
    public string PhoneNumberHash { get; private set; } = default!;
    public string? Ip { get; private set; }
    public bool Succeeded { get; private set; }
    public DateTime CreatedAt { get; private set; }

    public static RecoveryAttempt Record(Guid? userId, string phoneNumberHash, string? ip, bool succeeded, DateTime now) => new()
    {
        UserId = userId,
        PhoneNumberHash = phoneNumberHash,
        Ip = ip,
        Succeeded = succeeded,
        CreatedAt = now,
    };
}

/// <summary>Security-relevant actions on accounts (SPEC §9.5): password resets, admin resets, deletions…</summary>
public sealed class AuditLog : Entity
{
    private AuditLog() { } // EF

    /// <summary>Stable code, e.g. <c>auth.password_reset</c>.</summary>
    public string Action { get; private set; } = default!;

    /// <summary>Who did it; null for anonymous flows (recovery) and jobs.</summary>
    public Guid? ActorId { get; private set; }

    /// <summary>The account it was done to.</summary>
    public Guid? UserId { get; private set; }
    public string? Ip { get; private set; }
    public DateTime CreatedAt { get; private set; }

    /// <summary>What the action touched besides an account (SPEC F23): <c>field</c>, <c>topic</c>, <c>tag</c>, <c>path</c>…</summary>
    public string? TargetType { get; private set; }

    /// <summary>The target's id; no foreign key, the log outlives what it describes.</summary>
    public Guid? TargetId { get; private set; }

    /// <summary>A short note on what changed (≤ 500), e.g. <c>nameEn, isEnabled=false</c>; never personal data.</summary>
    public string? Details { get; private set; }

    public const int MaxDetailsLength = 500;

    public static AuditLog Record(string action, Guid? actorId, Guid? userId, string? ip, DateTime now) => new()
    {
        Action = action,
        ActorId = actorId,
        UserId = userId,
        Ip = ip,
        CreatedAt = now,
    };

    /// <summary>An admin action on something other than (or besides) an account (SPEC F23).</summary>
    public static AuditLog Record(
        string action, Guid? actorId, Guid? userId, string? ip, DateTime now, string? targetType, Guid? targetId, string? details) => new()
    {
        Action = action,
        ActorId = actorId,
        UserId = userId,
        Ip = ip,
        CreatedAt = now,
        TargetType = targetType,
        TargetId = targetId,
        Details = details is null ? null : details.Length <= MaxDetailsLength ? details : details[..MaxDetailsLength],
    };
}

/// <summary>The <see cref="AuditLog.TargetType"/> values (SPEC F23).</summary>
public static class AuditTargets
{
    public const string User = "user";
    public const string Article = "article";
    public const string Comment = "comment";
    public const string Field = "field";
    public const string Topic = "topic";
    public const string Tag = "tag";
    public const string Path = "path";
    public const string Announcement = "announcement";
    public const string Ticket = "ticket";
}

public static class AuditActions
{
    public const string SignUp = "auth.sign_up";
    public const string PasswordChanged = "auth.password_changed";
    public const string PasswordReset = "auth.password_reset";
    public const string RecoveryPinSet = "auth.recovery_pin_set";
    public const string RecoveryPinChanged = "auth.recovery_pin_changed";
    public const string RecoveryLockedOut = "auth.recovery_locked_out";
    public const string PhoneNumberChanged = "auth.phone_changed";
    public const string ExternalSignUp = "auth.external_sign_up";
    public const string ExternalLoginLinked = "auth.external_linked";
    public const string ExternalLoginUnlinked = "auth.external_unlinked";
    public const string PhoneSignInAdded = "auth.phone_sign_in_added";
    public const string SignedOutEverywhere = "auth.signed_out_everywhere";
    public const string RefreshTokenReused = "auth.refresh_token_reused";
    public const string AdminPasswordReset = "admin.password_reset";

    // Writer verification (SPEC F19): the SuperAdmin approved (the Verified badge given) or rejected a user's request, or
    // removed a user's badge.
    public const string VerificationApproved = "admin.verification_approved";
    public const string VerificationRejected = "admin.verification_rejected";
    public const string VerificationRemoved = "admin.verification_removed";
    public const string AccountDeleted = "account.deleted";

    // Moderator actions on a user's content or account (SPEC F11, F22); the moderation log is ModerationActions.
    public const string CommentHidden = "moderation.comment_hidden";
    public const string CommentUnhidden = "moderation.comment_unhidden";
    public const string CommentDeleted = "moderation.comment_deleted";
    public const string ArticleHidden = "moderation.article_hidden";
    public const string ArticleUnhidden = "moderation.article_unhidden";
    public const string UserWarned = "moderation.user_warned";
    public const string UserSuspended = "moderation.user_suspended";
    public const string UserUnsuspended = "moderation.user_unsuspended";

    /// <summary>A moderator cleared the name of one of the user's writer categories (SPEC F31).</summary>
    public const string CategoryCleared = "moderation.category_cleared";

    /// <summary>A moderator cleared the user's social links or title (SPEC F14).</summary>
    public const string LinksCleared = "moderation.links_cleared";
    public const string HeadlineCleared = "moderation.headline_cleared";

    // Admin console (SPEC F23).
    /// <summary>Hid every article and comment of the user (hide_content), or restored what that hid (unhide_content).</summary>
    public const string ContentHidden = "moderation.content_hidden";
    public const string ContentRestored = "moderation.content_restored";
    public const string PiiViewed = "admin.pii_viewed";
    public const string SessionsRevoked = "admin.sessions_revoked";
    public const string ArticleFeatured = "admin.article_featured";
    public const string ArticleUnfeatured = "admin.article_unfeatured";
    public const string FeaturedPathsSet = "admin.featured_paths_set";
    public const string FieldCreated = "admin.field_created";
    public const string FieldUpdated = "admin.field_updated";
    public const string FieldsReordered = "admin.fields_reordered";
    public const string TopicCreated = "admin.topic_created";
    public const string TopicUpdated = "admin.topic_updated";
    public const string TopicsReordered = "admin.topics_reordered";
    public const string TagRenamed = "admin.tag_renamed";
    public const string TagMerged = "admin.tag_merged";
    public const string TagHidden = "admin.tag_hidden";
    public const string TagUnhidden = "admin.tag_unhidden";
    public const string PathCreated = "admin.path_created";
    public const string PathUpdated = "admin.path_updated";
    public const string PathItemsSet = "admin.path_items_set";
    public const string PathDeleted = "admin.path_deleted";
    public const string AnnouncementSent = "admin.announcement_sent";
    public const string AnnouncementTested = "admin.announcement_tested";
    public const string CountersRebuilt = "admin.counters_rebuilt";

    // Support tickets (SPEC F35).
    public const string TicketReplied = "admin.ticket_replied";
    public const string TicketNoteAdded = "admin.ticket_note_added";
    public const string TicketClosed = "admin.ticket_closed";
    public const string TicketReopened = "admin.ticket_reopened";
    public const string TicketCategoryChanged = "admin.ticket_category_changed";

    // Store requirements (SPEC F22, F37).
    public const string RepostDeleted = "moderation.repost_deleted";
    public const string TermsAccepted = "auth.terms_accepted";
    public const string ContentFilterUpdated = "admin.content_filter_updated";
}
