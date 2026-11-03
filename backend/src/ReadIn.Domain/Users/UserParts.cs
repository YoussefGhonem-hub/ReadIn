namespace ReadIn.Domain.Users;

public sealed class UserRole
{
    private UserRole() { } // EF

    internal UserRole(Guid userId, Guid roleId)
    {
        UserId = userId;
        RoleId = roleId;
    }

    public Guid UserId { get; private set; }
    public Guid RoleId { get; private set; }
}

/// <summary>A followed interest: either a whole field or a single topic (SPEC F02).</summary>
public sealed class UserInterest
{
    private UserInterest() { } // EF

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public Guid? FieldId { get; private set; }
    public Guid? TopicId { get; private set; }

    internal static UserInterest ForField(Guid userId, Guid fieldId) => new() { UserId = userId, FieldId = fieldId };
    internal static UserInterest ForTopic(Guid userId, Guid topicId) => new() { UserId = userId, TopicId = topicId };
}

/// <summary>A field of expertise on the profile (SPEC F14). <see cref="Position"/> is the user's order, 0 first.</summary>
public sealed class UserExpertiseField
{
    private UserExpertiseField() { } // EF

    internal UserExpertiseField(Guid userId, Guid fieldId, int position)
    {
        UserId = userId;
        FieldId = fieldId;
        Position = position;
    }

    public Guid UserId { get; private set; }
    public Guid FieldId { get; private set; }
    public int Position { get; private set; }

    internal void MoveTo(int position) => Position = position;
}

public enum DevicePlatform
{
    Android = 0,
    Ios = 1,
    Web = 2,
}

public sealed class UserDevice
{
    private UserDevice() { } // EF

    internal UserDevice(Guid userId, string token, DevicePlatform platform, DateTime now)
    {
        UserId = userId;
        Token = token;
        Platform = platform;
        LastSeenAt = now;
    }

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public string Token { get; private set; } = default!;
    public DevicePlatform Platform { get; private set; }
    public DateTime LastSeenAt { get; private set; }

    internal void Touch(DateTime now) => LastSeenAt = now;
}

/// <summary>Fields a Reviewer is assigned to (SPEC F20, seed table §18.3).</summary>
public sealed class ReviewerField
{
    private ReviewerField() { } // EF

    public ReviewerField(Guid userId, Guid fieldId)
    {
        UserId = userId;
        FieldId = fieldId;
    }

    public Guid UserId { get; private set; }
    public Guid FieldId { get; private set; }
}

/// <summary>Google or Apple sign in (SPEC §9.1).</summary>
public static class ExternalProviders
{
    public const string Google = "google";
    public const string Apple = "apple";

    public static readonly IReadOnlyList<string> All = [Google, Apple];

    public static bool IsKnown(string? provider) => provider is Google or Apple;
}

/// <summary>
/// A Google or Apple identity linked to an account (SPEC §9.1). <see cref="Subject"/> is the provider's stable user id
/// (<c>sub</c>); the email is only what the provider reported when it was linked, shown in Settings.
/// </summary>
public sealed class ExternalLogin
{
    private ExternalLogin() { } // EF

    internal ExternalLogin(Guid userId, string provider, string subject, string? email, DateTime now)
    {
        UserId = userId;
        Provider = provider;
        Subject = subject;
        Email = email;
        LinkedAt = now;
        LastUsedAt = now;
    }

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public string Provider { get; private set; } = default!;
    public string Subject { get; private set; } = default!;
    public string? Email { get; private set; }
    public DateTime LinkedAt { get; private set; }
    public DateTime LastUsedAt { get; private set; }

    internal void Touch(DateTime now) => LastUsedAt = now;
}
