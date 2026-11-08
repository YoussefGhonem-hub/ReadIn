using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>
/// A block (SPEC F36): <see cref="BlockerId"/> and <see cref="BlockedId"/> no longer see each other's articles, comments
/// or profiles, can't follow, mention or comment on each other, and nothing either does notifies the other. Both ways,
/// whoever made it. The blocked person is never told.
/// </summary>
public sealed class UserBlock : Entity
{
    public const int MaxPerUser = 1000;

    private UserBlock() { } // EF

    public UserBlock(Guid blockerId, Guid blockedId, DateTime now)
    {
        BlockerId = blockerId;
        BlockedId = blockedId;
        CreatedAt = now;
    }

    public Guid BlockerId { get; private set; }
    public Guid BlockedId { get; private set; }
    public DateTime CreatedAt { get; private set; }
}

public static class BlockErrors
{
    public static readonly Error Self = Error.Validation("block.self", "You can't block yourself.");
    public static readonly Error Limit = Error.Validation("block.limit", "You've reached the limit of 1,000 blocked accounts.");

    /// <summary>To the blocker only, with <c>blockedUser</c>; the blocked person gets a plain not-found instead.</summary>
    public static readonly Error Blocked = Error.Forbidden("block.blocked", "You blocked this account. Unblock it first.");

    public static Error BlockedUser(Guid id, string username, string displayName) => Blocked with
    {
        Extensions = new Dictionary<string, object?> { ["blockedUser"] = new { id, username, displayName } },
    };
}
