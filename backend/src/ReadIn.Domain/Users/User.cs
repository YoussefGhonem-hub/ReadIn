using System.Text.RegularExpressions;
using ReadIn.Domain.Common;

namespace ReadIn.Domain.Users;

public sealed partial class User : AggregateRoot, IAuditable, ISoftDeletable, IHasRowVersion
{
    public const int MinInterests = 3;
    public static readonly TimeOnly DefaultReminderTime = new(8, 0);
    public const string DefaultTimeZone = "Africa/Cairo";

    private readonly List<UserRole> _roles = [];
    private readonly List<UserInterest> _interests = [];
    private readonly List<UserDevice> _devices = [];

    private User() { } // EF

    public string FirebaseUid { get; private set; } = default!;
    public string Email { get; private set; } = default!;
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

    public bool IsSuspended { get; private set; }
    public DateTime? SuspendedUntil { get; private set; }
    public bool IsSystemAccount { get; private set; }

    public IReadOnlyCollection<UserRole> Roles => _roles.AsReadOnly();
    public IReadOnlyCollection<UserInterest> Interests => _interests.AsReadOnly();
    public IReadOnlyCollection<UserDevice> Devices => _devices.AsReadOnly();

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }
    public bool IsDeleted { get; private set; }
    public DateTime? DeletedAt { get; private set; }
    public byte[] RowVersion { get; private set; } = [];

    public bool OnboardingCompleted => _interests.Count >= MinInterests;

    public static User Register(
        string firebaseUid,
        string email,
        string displayName,
        string username,
        string? avatarUrl,
        Guid memberRoleId,
        string? uiLanguage = null,
        string? timeZone = null,
        Guid? id = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(firebaseUid);
        ArgumentException.ThrowIfNullOrWhiteSpace(email);

        var user = new User
        {
            Id = id ?? Guid.CreateVersion7(),
            FirebaseUid = firebaseUid,
            Email = email.Trim().ToLowerInvariant(),
            DisplayName = string.IsNullOrWhiteSpace(displayName) ? email.Split('@')[0] : displayName.Trim(),
            Username = username,
            AvatarUrl = avatarUrl,
            UiLanguage = UiLanguages.Normalize(uiLanguage),
            TimeZone = string.IsNullOrWhiteSpace(timeZone) ? DefaultTimeZone : timeZone,
        };
        user._roles.Add(new UserRole(user.Id, memberRoleId));
        user.Raise(new UserRegisteredDomainEvent(user.Id, user.Email));
        return user;
    }

    /// <summary>Refreshes identity data that Firebase owns (email, photo) on every sign-in sync.</summary>
    public void SyncIdentity(string email, string? avatarUrl)
    {
        Email = email.Trim().ToLowerInvariant();
        if (AvatarUrl is null && avatarUrl is not null) AvatarUrl = avatarUrl;
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

    public bool HasRole(Guid roleId) => _roles.Any(r => r.RoleId == roleId);

    public void GrantRole(Guid roleId)
    {
        if (HasRole(roleId)) return;
        _roles.Add(new UserRole(Id, roleId));
        Raise(new UserRolesChangedDomainEvent(Id));
    }

    public void RevokeRole(Guid roleId)
    {
        if (_roles.RemoveAll(r => r.RoleId == roleId) > 0) Raise(new UserRolesChangedDomainEvent(Id));
    }

    public void Suspend(DateTime? until)
    {
        IsSuspended = true;
        SuspendedUntil = until;
        Raise(new UserRolesChangedDomainEvent(Id));
    }

    public void Unsuspend()
    {
        IsSuspended = false;
        SuspendedUntil = null;
        Raise(new UserRolesChangedDomainEvent(Id));
    }

    public bool IsSuspendedAt(DateTime now) => IsSuspended && (SuspendedUntil is null || SuspendedUntil > now);

    internal void MarkAsSystemAccount() => IsSystemAccount = true;

    public static User CreateSystemAccount(string firebaseUid, string email, string displayName, string username, Guid id)
    {
        var user = new User
        {
            Id = id,
            FirebaseUid = firebaseUid,
            Email = email,
            DisplayName = displayName,
            Username = username,
        };
        user.MarkAsSystemAccount();
        return user;
    }

    public static bool IsValidUsername(string? username) => username is not null && UsernameRegex().IsMatch(username);

    /// <summary>Builds a valid handle candidate from an email/display name, e.g. "reader.one@x" → "reader_one".</summary>
    public static string SuggestUsername(string source)
    {
        var local = source.Split('@')[0].ToLowerInvariant();
        var cleaned = new string(local.Select(c => char.IsAsciiLetterOrDigit(c) ? c : '_').ToArray()).Trim('_');
        if (cleaned.Length < 3) cleaned = $"reader_{cleaned}".TrimEnd('_');
        return cleaned.Length > 24 ? cleaned[..24] : cleaned;
    }

    [GeneratedRegex("^[a-z0-9_]{3,30}$")]
    private static partial Regex UsernameRegex();
}

public sealed record UserLinks
{
    public string? GitHub { get; init; }
    public string? LinkedIn { get; init; }
    public string? Website { get; init; }
}

public sealed record UserRegisteredDomainEvent(Guid UserId, string Email) : DomainEvent;

public sealed record UserRolesChangedDomainEvent(Guid UserId) : DomainEvent;
