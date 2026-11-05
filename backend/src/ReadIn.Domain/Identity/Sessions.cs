using ReadIn.Domain.Common;

namespace ReadIn.Domain.Identity;

/// <summary>
/// One link of a rotating refresh-token chain (SPEC §9.3). Only the SHA-256 hash of the token is stored. Every sign in
/// starts a new <see cref="FamilyId"/>; presenting an already-rotated token revokes the whole family (theft detection).
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

    public void RotateTo(RefreshToken next, DateTime now)
    {
        RevokedAt = now;
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

    public static AuditLog Record(string action, Guid? actorId, Guid? userId, string? ip, DateTime now) => new()
    {
        Action = action,
        ActorId = actorId,
        UserId = userId,
        Ip = ip,
        CreatedAt = now,
    };
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
}
