using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>A user follows a writer (SPEC F12). The official ReadIn account can be followed like anyone else.</summary>
public sealed class UserFollow : AggregateRoot
{
    private UserFollow() { } // EF

    public Guid FollowerId { get; private set; }
    public Guid FolloweeId { get; private set; }
    public DateTime CreatedAt { get; private set; }

    // Read-side navigations for query projections only.
    public Users.User Follower { get; private set; } = default!;
    public Users.User Followee { get; private set; } = default!;

    public static Result<UserFollow> Create(Guid followerId, Guid followeeId, DateTime now)
    {
        if (followerId == followeeId) return FollowErrors.Self;

        var follow = new UserFollow { FollowerId = followerId, FolloweeId = followeeId, CreatedAt = now };
        follow.Raise(() => new UserFollowedDomainEvent(followerId, followeeId));
        return follow;
    }
}

public static class FollowErrors
{
    public static readonly Error Self = Error.Validation("follow.self", "You can't follow yourself.");
}

/// <summary>Source of the "new follower" notification (F17).</summary>
public sealed record UserFollowedDomainEvent(Guid FollowerId, Guid FolloweeId) : DomainEvent;
