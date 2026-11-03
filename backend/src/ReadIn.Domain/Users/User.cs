using System.Text.RegularExpressions;
using ReadIn.Domain.Common;

namespace ReadIn.Domain.Users;

public sealed partial class User : AggregateRoot, IAuditable, ISoftDeletable, IHasRowVersion
{
    public const int MinInterests = 3;
    public static readonly TimeOnly DefaultReminderTime = new(8, 0);
    public const string DefaultTimeZone = "Africa/Cairo";
    public const string DeletedDisplayName = "Deleted user";
    public const int MaxDisplayNameLength = 60;

    /// <summary>Fields of expertise shown on the profile (SPEC F14).</summary>
    public const int MaxExpertiseFields = 5;

    private readonly List<UserRole> _roles = [];
    private readonly List<UserInterest> _interests = [];
    private readonly List<UserDevice> _devices = [];
    private readonly List<ExternalLogin> _externalLogins = [];
    private readonly List<UserExpertiseField> _expertise = [];

    private User() { } // EF

    /// <summary>
    /// E.164 (<c>+201001234567</c>), the phone sign-in identifier (SPEC §9.1). Null for accounts that only sign in with
    /// Google or Apple, and once a deleted account is anonymized.
    /// </summary>
    public string? PhoneNumber { get; private set; }

    /// <summary>
    /// Only ever set from an email that Google or Apple reported as verified (or by seeding), so a later Google or Apple
    /// sign in with the same address can be linked to this account (SPEC §9.1). Never set it from user input.
    /// </summary>
    public string? Email { get; private set; }

    public string DisplayName { get; private set; } = default!;
    public string Username { get; private set; } = default!;
    public string? AvatarUrl { get; private set; }
    public string? Bio { get; private set; }
    public UserLinks Links { get; private set; } = new();

    public string UiLanguage { get; private set; } = UiLanguages.Arabic;
    public string ArticleLanguagePref { get; private set; } = ArticleLanguages.EgyptianArabic;
    public ThemePreference ThemePref { get; private set; } = ThemePreference.System;
    public string TimeZone { get; private set; } = DefaultTimeZone;
    public TimeOnly ReminderTime { get; private set; } = DefaultReminderTime;

    /// <summary>Privacy (SPEC F18): the reading stats card and heatmap are on the public profile. Off by default.</summary>
    public bool PublicReadingStats { get; private set; }

    /// <summary>Null for accounts without phone sign in: Google/Apple only, or the official ReadIn account.</summary>
    public string? PasswordHash { get; private set; }

    /// <summary>Embedded in every access token; changing it signs out every session (SPEC §9.3).</summary>
    public string SecurityStamp { get; private set; } = NewSecurityStamp();

    public int FailedLoginCount { get; private set; }
    public DateTime? LockoutEndAt { get; private set; }
    public bool MustChangePassword { get; private set; }

    public string? RecoveryPinHash { get; private set; }
    public DateTime? RecoveryPinSetAt { get; private set; }
    public int RecoveryFailedCount { get; private set; }
    public DateTime? RecoveryLockoutEndAt { get; private set; }

    /// <summary>Recovery lockouts since <see cref="RecoveryLockoutWindowStartAt"/>; the third within 7 days disables recovery.</summary>
    public int RecoveryLockoutCount { get; private set; }
    public DateTime? RecoveryLockoutWindowStartAt { get; private set; }
    public bool RecoveryDisabled { get; private set; }
    public bool MustSetRecoveryPin { get; private set; }

    /// <summary>False until the user picks a display name and @username after sign up (SPEC §9.2).</summary>
    public bool IsProfileComplete { get; private set; }

    public bool IsSuspended { get; private set; }
    public DateTime? SuspendedUntil { get; private set; }
    public bool IsSystemAccount { get; private set; }

    public IReadOnlyCollection<UserRole> Roles => _roles.AsReadOnly();
    public IReadOnlyCollection<UserInterest> Interests => _interests.AsReadOnly();
    public IReadOnlyCollection<UserDevice> Devices => _devices.AsReadOnly();
    public IReadOnlyCollection<ExternalLogin> ExternalLogins => _externalLogins.AsReadOnly();

    /// <summary>Unordered as loaded by EF: <see cref="UserExpertiseField.Position"/> holds the user's order.</summary>
    public IReadOnlyCollection<UserExpertiseField> Expertise => _expertise.AsReadOnly();

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }
    public bool IsDeleted { get; private set; }
    public DateTime? DeletedAt { get; private set; }

    /// <summary>When the personal data of a deleted account was removed (SPEC F01); null until then.</summary>
    public DateTime? AnonymizedAt { get; private set; }
    public byte[] RowVersion { get; private set; } = [];

    public bool OnboardingCompleted => _interests.Count >= MinInterests;
    public bool HasRecoveryPin => RecoveryPinHash is not null;
    public bool HasPassword => PasswordHash is not null;
    public bool CanSignInWithPassword => PasswordHash is not null && PhoneNumber is not null;

    /// <summary>Phone + password or a linked Google/Apple account. Needs <see cref="ExternalLogins"/> loaded.</summary>
    public bool CanSignIn => CanSignInWithPassword || _externalLogins.Count > 0;

    /// <summary>
    /// Sign up with phone + password (SPEC §9.2). The profile starts incomplete with a placeholder @username. The recovery
    /// PIN is set right after, once EF Core has assigned the id its hash is bound to; until then the account must set one.
    /// </summary>
    public static User Register(
        string phoneNumber,
        string passwordHash,
        string placeholderUsername,
        Guid memberRoleId,
        string? uiLanguage = null,
        string? timeZone = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(phoneNumber);
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);

        var user = new User
        {
            PhoneNumber = phoneNumber,
            PasswordHash = passwordHash,
            DisplayName = placeholderUsername,
            Username = placeholderUsername,
            UiLanguage = UiLanguages.Normalize(uiLanguage),
            TimeZone = string.IsNullOrWhiteSpace(timeZone) ? DefaultTimeZone : timeZone,
            MustSetRecoveryPin = true,
        };
        user._roles.Add(new UserRole(user.Id, memberRoleId));
        user.Raise(() => new UserRegisteredDomainEvent(user.Id));
        return user;
    }

    /// <summary>
    /// Sign up with Google or Apple (SPEC §9.2): no phone, password or recovery PIN (the provider handles recovery). The
    /// profile starts incomplete; Apple sends the name only on the first authorization, so it's used when there is one.
    /// </summary>
    public static User RegisterExternal(
        string provider,
        string subject,
        string? verifiedEmail,
        string? displayName,
        string placeholderUsername,
        Guid memberRoleId,
        DateTime now,
        string? uiLanguage = null,
        string? timeZone = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(subject);
        if (!ExternalProviders.IsKnown(provider)) throw new ArgumentOutOfRangeException(nameof(provider), provider, null);

        var name = displayName?.Trim();
        var user = new User
        {
            Email = verifiedEmail,
            DisplayName = string.IsNullOrEmpty(name) ? placeholderUsername : name[..Math.Min(name.Length, MaxDisplayNameLength)],
            Username = placeholderUsername,
            UiLanguage = UiLanguages.Normalize(uiLanguage),
            TimeZone = string.IsNullOrWhiteSpace(timeZone) ? DefaultTimeZone : timeZone,
        };
        user._roles.Add(new UserRole(user.Id, memberRoleId));
        user._externalLogins.Add(new ExternalLogin(user.Id, provider, subject, verifiedEmail, now));
        user.Raise(() => new UserRegisteredDomainEvent(user.Id));
        return user;
    }

    /// <summary>Seeded accounts (SPEC §18.3) start with a complete profile; credentials are set separately.</summary>
    public static User CreateSeeded(
        string? phoneNumber, string displayName, string username, Guid? id = null, bool systemAccount = false, string? email = null) =>
        new()
        {
            Id = id ?? Guid.Empty,
            PhoneNumber = phoneNumber,
            Email = email,
            DisplayName = displayName,
            Username = username,
            IsProfileComplete = true,
            IsSystemAccount = systemAccount,
        };

    public Result CompleteProfile(string displayName, string username, string? avatarUrl)
    {
        if (!IsValidUsername(username)) return UserErrors.InvalidUsername;

        DisplayName = displayName.Trim();
        Username = username;
        AvatarUrl = avatarUrl;
        IsProfileComplete = true;
        return Result.Success();
    }

    public Result UpdateProfile(string displayName, string username, string? bio, string? avatarUrl, UserLinks links)
    {
        if (!IsValidUsername(username)) return UserErrors.InvalidUsername;

        DisplayName = displayName.Trim();
        Username = username;
        Bio = string.IsNullOrWhiteSpace(bio) ? null : bio.Trim();
        AvatarUrl = avatarUrl;
        Links = links;
        return Result.Success();
    }

    /// <summary>
    /// Replaces the fields of expertise (SPEC F14) in the given order; a repeated id counts once. Rows of fields that
    /// stay are moved rather than re-added, so a key is never removed and inserted in the same save.
    /// </summary>
    public Result SetExpertise(IReadOnlyList<Guid> fieldIds)
    {
        var ordered = fieldIds.Distinct().ToList();
        if (ordered.Count > MaxExpertiseFields) return ProfileErrors.ExpertiseInvalid;

        _expertise.RemoveAll(e => !ordered.Contains(e.FieldId));
        for (var position = 0; position < ordered.Count; position++)
        {
            var existing = _expertise.FirstOrDefault(e => e.FieldId == ordered[position]);
            if (existing is null) _expertise.Add(new UserExpertiseField(Id, ordered[position], position));
            else existing.MoveTo(position);
        }
        return Result.Success();
    }

    public void SetPrivacy(bool publicReadingStats) => PublicReadingStats = publicReadingStats;

    public Result SetPreferences(string uiLanguage, string articleLanguage, ThemePreference theme, string timeZone, TimeOnly reminderTime)
    {
        if (!UiLanguages.IsValid(uiLanguage)) return UserErrors.InvalidLanguage;
        if (!ArticleLanguages.IsValid(articleLanguage)) return UserErrors.InvalidLanguage;

        UiLanguage = uiLanguage;
        ArticleLanguagePref = articleLanguage;
        ThemePref = theme;
        TimeZone = timeZone;
        ReminderTime = reminderTime;
        return Result.Success();
    }

    public Result SetInterests(IReadOnlyCollection<Guid> fieldIds, IReadOnlyCollection<Guid> topicIds)
    {
        if (fieldIds.Distinct().Count() + topicIds.Distinct().Count() < MinInterests)
            return UserErrors.InterestsMinThree;

        _interests.Clear();
        _interests.AddRange(fieldIds.Distinct().Select(f => UserInterest.ForField(Id, f)));
        _interests.AddRange(topicIds.Distinct().Select(t => UserInterest.ForTopic(Id, t)));
        return Result.Success();
    }

    // ---- Following fields and topics (SPEC F12): one interest at a time ----

    /// <summary>Idempotent: following a field that is already an interest changes nothing.</summary>
    public void FollowField(Guid fieldId)
    {
        if (_interests.Any(i => i.FieldId == fieldId)) return;
        _interests.Add(UserInterest.ForField(Id, fieldId));
    }

    public void FollowTopic(Guid topicId)
    {
        if (_interests.Any(i => i.TopicId == topicId)) return;
        _interests.Add(UserInterest.ForTopic(Id, topicId));
    }

    /// <summary>Idempotent, but never leaves fewer than <see cref="MinInterests"/> interests (SPEC F02).</summary>
    public Result UnfollowField(Guid fieldId) => RemoveInterest(_interests.FirstOrDefault(i => i.FieldId == fieldId));

    public Result UnfollowTopic(Guid topicId) => RemoveInterest(_interests.FirstOrDefault(i => i.TopicId == topicId));

    private Result RemoveInterest(UserInterest? interest)
    {
        if (interest is null) return Result.Success();
        if (_interests.Count - 1 < MinInterests) return UserErrors.InterestsMinThree;

        _interests.Remove(interest);
        return Result.Success();
    }

    public void RegisterDevice(string token, DevicePlatform platform, DateTime now)
    {
        var existing = _devices.FirstOrDefault(d => d.Token == token);
        if (existing is not null)
        {
            existing.Touch(now);
            return;
        }
        _devices.Add(new UserDevice(Id, token, platform, now));
    }

    /// <returns>false when the token was not registered for this user.</returns>
    public bool UnregisterDevice(string token) => _devices.RemoveAll(d => d.Token == token) > 0;

    // ---- Sign in (SPEC §9.5) ----

    public bool IsLockedOutAt(DateTime now) => LockoutEndAt > now;

    /// <returns>true when this failure locked the account.</returns>
    public bool RecordFailedSignIn(DateTime now)
    {
        if (++FailedLoginCount < AccountSecurity.MaxFailedSignIns) return false;

        FailedLoginCount = 0;
        LockoutEndAt = now + AccountSecurity.SignInLockout;
        return true;
    }

    public void RecordSuccessfulSignIn()
    {
        FailedLoginCount = 0;
        LockoutEndAt = null;
    }

    /// <summary>Stores a hash in the current format after a successful sign in (no other effect).</summary>
    public void UpgradePasswordHash(string passwordHash) => PasswordHash = passwordHash;

    /// <summary>Password of a seeded account. Production's SuperAdmin must change it on first sign in.</summary>
    public void SetInitialPassword(string passwordHash, bool mustChange)
    {
        PasswordHash = passwordHash;
        MustChangePassword = mustChange;
    }

    public void ChangePassword(string passwordHash)
    {
        PasswordHash = passwordHash;
        MustChangePassword = false;
        RotateSecurityStamp();
        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.PasswordChanged));
    }

    /// <summary>Forgot password: phone + PIN, then a new password (SPEC §9.2). Clears every lockout.</summary>
    public void ResetPassword(string passwordHash)
    {
        PasswordHash = passwordHash;
        MustChangePassword = false;
        FailedLoginCount = 0;
        LockoutEndAt = null;
        RecoveryFailedCount = 0;
        RecoveryLockoutEndAt = null;
        RotateSecurityStamp();
        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.PasswordReset));
    }

    /// <summary>"Forgot the PIN too" (SPEC §9.5): temporary password, PIN cleared, recovery re-enabled, sessions revoked.</summary>
    public void ResetByAdmin(string temporaryPasswordHash)
    {
        PasswordHash = temporaryPasswordHash;
        MustChangePassword = true;
        RecoveryPinHash = null;
        RecoveryPinSetAt = null;
        MustSetRecoveryPin = true;
        RecoveryDisabled = false;
        FailedLoginCount = 0;
        LockoutEndAt = null;
        RecoveryFailedCount = 0;
        RecoveryLockoutEndAt = null;
        RecoveryLockoutCount = 0;
        RecoveryLockoutWindowStartAt = null;
        RotateSecurityStamp();
    }

    /// <summary>Invalidates every access token; used by "sign out of all devices" and every credential change.</summary>
    public void RotateSecurityStamp() => SecurityStamp = NewSecurityStamp();

    // ---- Recovery PIN (SPEC §9.5) ----

    /// <summary>First PIN: at sign up, or on the mandatory "set recovery PIN" screen.</summary>
    public void SetRecoveryPin(string pinHash, DateTime now)
    {
        RecoveryPinHash = pinHash;
        RecoveryPinSetAt = now;
        MustSetRecoveryPin = false;
        RecoveryFailedCount = 0;
        RecoveryLockoutEndAt = null;
    }

    public void ChangeRecoveryPin(string pinHash, DateTime now)
    {
        SetRecoveryPin(pinHash, now);
        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.RecoveryPinChanged));
    }

    /// <summary>Accounts without a PIN (created before it existed, admin resets, production SuperAdmin) must set one.</summary>
    public void RequireRecoveryPin()
    {
        if (!HasRecoveryPin) MustSetRecoveryPin = true;
    }

    public bool IsRecoveryLockedAt(DateTime now) => RecoveryLockoutEndAt > now;

    /// <summary>
    /// 5 wrong PINs lock recovery for an hour; the third lockout within 7 days disables recovery until an Admin reset.
    /// </summary>
    /// <returns>true when this failure locked recovery.</returns>
    public bool RecordFailedRecovery(DateTime now)
    {
        if (++RecoveryFailedCount < AccountSecurity.MaxFailedRecoveries) return false;

        RecoveryFailedCount = 0;
        RecoveryLockoutEndAt = now + AccountSecurity.RecoveryLockout;
        if (RecoveryLockoutWindowStartAt is null || now - RecoveryLockoutWindowStartAt > AccountSecurity.RecoveryLockoutWindow)
        {
            RecoveryLockoutWindowStartAt = now;
            RecoveryLockoutCount = 0;
        }
        if (++RecoveryLockoutCount >= AccountSecurity.MaxRecoveryLockouts) RecoveryDisabled = true;

        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.RecoveryLockedOut));
        return true;
    }

    public void RecordSuccessfulRecovery() => RecoveryFailedCount = 0;

    // ---- Phone number ----

    public void ChangePhoneNumber(string phoneNumber)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(phoneNumber);
        PhoneNumber = phoneNumber;
        RotateSecurityStamp();
        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.PhoneNumberChanged));
    }

    /// <summary>Seeding only: sets the number of a seeded account without signing it out or notifying anyone.</summary>
    public void AssignSeedPhoneNumber(string phoneNumber)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(phoneNumber);
        PhoneNumber = phoneNumber;
    }

    // ---- Google / Apple (SPEC §9.1) ----

    public ExternalLogin? FindExternalLogin(string provider) => _externalLogins.FirstOrDefault(l => l.Provider == provider);

    /// <summary>One identity per provider: a second Google account can't be added next to the first.</summary>
    public Result LinkExternalLogin(string provider, string subject, string? email, DateTime now)
    {
        if (FindExternalLogin(provider) is { } existing)
        {
            if (existing.Subject != subject) return CredentialErrors.ExternalConflict;
            existing.Touch(now);
            return Result.Success();
        }

        _externalLogins.Add(new ExternalLogin(Id, provider, subject, email, now));
        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.ExternalLoginLinked));
        return Result.Success();
    }

    /// <summary>Refused when it is the only way left to sign in.</summary>
    public Result UnlinkExternalLogin(string provider)
    {
        if (FindExternalLogin(provider) is not { } login) return CredentialErrors.ExternalLoginNotFound;
        if (!CanSignInWithPassword && _externalLogins.Count == 1) return CredentialErrors.LastSignInMethod;

        _externalLogins.Remove(login);
        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.ExternalLoginUnlinked));
        return Result.Success();
    }

    public void RecordExternalSignIn(string provider, DateTime now) => FindExternalLogin(provider)?.Touch(now);

    /// <summary>On delete (SPEC F01): the Google/Apple identities can sign up again at once.</summary>
    public void ReleaseExternalLogins() => _externalLogins.Clear();

    /// <summary>
    /// A Google/Apple account adds phone + password sign in (SPEC F18). The recovery PIN is set right after, like at sign
    /// up; other sessions are signed out.
    /// </summary>
    public Result AddPhoneSignIn(string phoneNumber, string passwordHash)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(phoneNumber);
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);
        if (HasPassword) return CredentialErrors.PhoneSignInExists;

        PhoneNumber = phoneNumber;
        PasswordHash = passwordHash;
        MustChangePassword = false;
        MustSetRecoveryPin = true;
        RotateSecurityStamp();
        Raise(() => new UserSecurityChangedDomainEvent(Id, SecurityChange.PhoneSignInAdded));
        return Result.Success();
    }

    // ---- Roles & moderation ----

    public bool HasRole(Guid roleId) => _roles.Any(r => r.RoleId == roleId);

    public void GrantRole(Guid roleId)
    {
        if (HasRole(roleId)) return;
        _roles.Add(new UserRole(Id, roleId));
        Raise(() => new UserRolesChangedDomainEvent(Id));
    }

    public void RevokeRole(Guid roleId)
    {
        if (_roles.RemoveAll(r => r.RoleId == roleId) > 0) Raise(() => new UserRolesChangedDomainEvent(Id));
    }

    public void Suspend(DateTime? until)
    {
        IsSuspended = true;
        SuspendedUntil = until;
        Raise(() => new UserRolesChangedDomainEvent(Id));
    }

    public void Unsuspend()
    {
        IsSuspended = false;
        SuspendedUntil = null;
        Raise(() => new UserRolesChangedDomainEvent(Id));
    }

    public bool IsSuspendedAt(DateTime now) => IsSuspended && (SuspendedUntil is null || SuspendedUntil > now);

    // ---- Deletion (SPEC F01) ----

    /// <summary>
    /// Runs <see cref="AccountSecurity.DeletionGracePeriod"/> after the soft delete: personal data is removed, while articles
    /// and comments stay attributed to "Deleted user". The phone number is released, so it can sign up again.
    /// </summary>
    public void Anonymize(DateTime now)
    {
        AnonymizedAt = now;
        PhoneNumber = null;
        Email = null;
        PasswordHash = null;
        RecoveryPinHash = null;
        RecoveryPinSetAt = null;
        DisplayName = DeletedDisplayName;
        Username = $"deleted_{Id:N}"[..30];
        AvatarUrl = null;
        Bio = null;
        Links = new UserLinks();
        _devices.Clear();
        _interests.Clear();
        _expertise.Clear();
        PublicReadingStats = false;
        _externalLogins.Clear(); // the Google/Apple account can sign up again
        RotateSecurityStamp();
    }

    public static bool IsValidUsername(string? username) => username is not null && UsernameRegex().IsMatch(username);

    private static string NewSecurityStamp() => Guid.NewGuid().ToString("N");

    [GeneratedRegex("^[a-z0-9_]{3,30}$")]
    private static partial Regex UsernameRegex();
}

/// <summary>Sign-in and recovery limits (SPEC §9.5).</summary>
public static class AccountSecurity
{
    public const int MaxFailedSignIns = 5;
    public static readonly TimeSpan SignInLockout = TimeSpan.FromMinutes(15);

    public const int MaxFailedRecoveries = 5;
    public static readonly TimeSpan RecoveryLockout = TimeSpan.FromHours(1);
    public const int MaxRecoveryLockouts = 3;
    public static readonly TimeSpan RecoveryLockoutWindow = TimeSpan.FromDays(7);

    /// <summary>Soft-deleted accounts are anonymized after this period (SPEC F01).</summary>
    public static readonly TimeSpan DeletionGracePeriod = TimeSpan.FromDays(30);
}

public sealed record UserLinks
{
    public string? GitHub { get; init; }
    public string? LinkedIn { get; init; }
    public string? Website { get; init; }
}

public enum SecurityChange
{
    PasswordChanged,
    PasswordReset,
    RecoveryPinChanged,
    PhoneNumberChanged,
    RecoveryLockedOut,
    ExternalLoginLinked,
    ExternalLoginUnlinked,
    PhoneSignInAdded,
}

public sealed record UserRegisteredDomainEvent(Guid UserId) : DomainEvent;

public sealed record UserRolesChangedDomainEvent(Guid UserId) : DomainEvent;

/// <summary>Source of the owner notifications in SPEC §9.5; delivered once F17 Notifications ships.</summary>
public sealed record UserSecurityChangedDomainEvent(Guid UserId, SecurityChange Change) : DomainEvent;
