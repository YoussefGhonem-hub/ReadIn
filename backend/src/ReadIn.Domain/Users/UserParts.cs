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

    public Guid Id { get; private set; } = Guid.CreateVersion7();
    public Guid UserId { get; private set; }
    public Guid? FieldId { get; private set; }
    public Guid? TopicId { get; private set; }

    internal static UserInterest ForField(Guid userId, Guid fieldId) => new() { UserId = userId, FieldId = fieldId };
    internal static UserInterest ForTopic(Guid userId, Guid topicId) => new() { UserId = userId, TopicId = topicId };
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

    public Guid Id { get; private set; } = Guid.CreateVersion7();
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
