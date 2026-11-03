using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Profiles;

/// <summary>
/// GET /users/{username} (SPEC F14). Never the phone number or e-mail (SPEC §9.5): this DTO has no field for them.
/// </summary>
/// <param name="AvatarUrl">The 256 px variant (as in every AuthorDto / UserSummaryDto), or null.</param>
/// <param name="AvatarVariants">
/// <c>{ "64", "128", "256", "512" }</c> → URL; null without an avatar or for an avatar that isn't an upload.
/// </param>
/// <param name="Expertise">At most 5, in the user's order; names in the request's UI language.</param>
/// <param name="IsFollowing">The viewer follows this user; false for guests and on your own profile.</param>
/// <param name="FollowsYou">This user follows the viewer; false for guests and on your own profile.</param>
/// <param name="ReadingStatsVisible">Your own profile, or the user made the reading stats public.</param>
public sealed record ProfileDto(
    Guid Id,
    string DisplayName,
    string Username,
    string? AvatarUrl,
    IReadOnlyDictionary<string, string>? AvatarVariants,
    bool IsVerified,
    string? Bio,
    UserLinksDto Links,
    IReadOnlyList<ExpertiseFieldDto> Expertise,
    DateTime JoinedAt,
    ProfileStatsDto Stats,
    bool IsMe,
    bool IsFollowing,
    bool FollowsYou,
    bool ReadingStatsVisible);

public sealed record ExpertiseFieldDto(Guid Id, string Slug, string Name, string Icon, string Color);

/// <param name="Articles">Published articles (the Articles tab).</param>
/// <param name="TotalReads">Completed reads of those articles (sum of their <c>readCount</c>).</param>
public sealed record ProfileStatsDto(int Articles, int Followers, int Following, int TotalReads);

/// <summary>The user behind a profile URL, if the profile can be shown.</summary>
internal sealed record ProfileOwner(Guid Id, bool PublicReadingStats)
{
    public bool ReadingStatsVisibleTo(Guid? viewerId) => PublicReadingStats || viewerId == Id;
}

internal static class ProfileUsers
{
    /// <summary><c>@Mona</c> → <c>mona</c>; null when it can't be a username, so the profile is not found without a query.</summary>
    public static string? Handle(string? username)
    {
        var handle = username?.Trim();
        if (handle is ['@', ..]) handle = handle[1..];
        handle = handle?.ToLowerInvariant();
        return User.IsValidUsername(handle) ? handle : null;
    }

    /// <summary>
    /// The profile at <paramref name="handle"/>: deleted accounts are filtered out by the query filter, suspended ones
    /// here. System accounts (the official ReadIn account) are shown like everyone else.
    /// </summary>
    public static IQueryable<User> Shown(this IQueryable<User> users, string handle, DateTime now) =>
        users.Where(u => u.Username == handle && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)));

    public static async Task<ProfileOwner?> FindProfileAsync(this IAppDbContext db, string? username, DateTime now, CancellationToken ct) =>
        Handle(username) is { } handle
            ? await db.Users.AsNoTracking().Shown(handle, now).Select(u => new ProfileOwner(u.Id, u.PublicReadingStats)).FirstOrDefaultAsync(ct)
            : null;
}
