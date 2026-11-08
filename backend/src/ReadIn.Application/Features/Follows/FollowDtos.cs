using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Follows;

/// <summary>Your follow and the writer's follower count right after the change.</summary>
public sealed record FollowStateDto(bool IsFollowing, int FollowerCount);

/// <summary>
/// A user in followers/following lists and suggestions; never the phone number (SPEC §9.5). <see cref="Headline"/> is
/// their title (F14), null when they have none.
/// </summary>
public sealed record UserSummaryDto(
    Guid Id,
    string DisplayName,
    string Username,
    string? AvatarUrl,
    bool IsVerified,
    string? Headline,
    string? Bio,
    bool IsFollowing,
    bool FollowsYou);

internal static class UserSummaries
{
    /// <summary>
    /// The SQL projection. <c>isFollowing</c> / <c>followsYou</c> are EXISTS lookups on the unique (FollowerId,
    /// FolloweeId) index, only for a signed-in viewer; guests get false without touching UserFollows.
    /// </summary>
    public static Expression<Func<User, UserSummaryDto>> For(IAppDbContext db, Guid? viewerId)
    {
        if (viewerId is not { } viewer)
        {
            return u => new UserSummaryDto(
                u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified, u.Headline, u.Bio, false, false);
        }

        return u => new UserSummaryDto(
            u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified, u.Headline, u.Bio,
            db.UserFollows.Any(f => f.FollowerId == viewer && f.FolloweeId == u.Id),
            db.UserFollows.Any(f => f.FollowerId == u.Id && f.FolloweeId == viewer));
    }

    public static UserSummaryDto WithPublicUrls(this UserSummaryDto user, IFileStorage storage) =>
        user with { AvatarUrl = storage.ToPublicUrl(user.AvatarUrl) };

    public static async Task<FollowStateDto> FollowStateAsync(this IAppDbContext db, Guid followerId, Guid followeeId, CancellationToken ct) => new(
        await db.UserFollows.AnyAsync(f => f.FollowerId == followerId && f.FolloweeId == followeeId, ct),
        // The App Review account's follows never count (SPEC §32).
        await db.UserFollows.CountAsync(f => f.FolloweeId == followeeId && !db.Users.Any(r => r.Id == f.FollowerId && r.IsReviewAccount), ct));
}
