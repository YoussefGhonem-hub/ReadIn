using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

/// <summary>
/// Who an author may @mention (SPEC F18 "who can mention me"): comments (F11), the editor's publish (F05) and the article
/// mention notifications (F17) ask here. <see cref="User.CanBeMentionedBy"/> decides; <see cref="MentionQueries.MentionableBy"/>
/// is the same rule as a query, for the suggestions.
/// </summary>
public sealed class UserMentions(IAppDbContext db, TimeProvider clock)
{
    /// <summary>
    /// Of <paramref name="userIds"/>, the users <paramref name="authorId"/> may mention (the author too), with their
    /// current @username. Unknown, deleted, suspended and system accounts, and users who don't allow the author, are left out.
    /// </summary>
    public async Task<IReadOnlyDictionary<Guid, string>> AllowedAsync(Guid authorId, IEnumerable<Guid> userIds, CancellationToken cancellationToken)
    {
        var ids = userIds.Distinct().ToList();
        if (ids.Count == 0) return new Dictionary<Guid, string>();

        var allowed = await AllowedAsync(authorId, db.Users.Where(u => ids.Contains(u.Id)), cancellationToken);
        return allowed.ToDictionary(u => u.Id, u => u.Username);
    }

    /// <summary>Of <paramref name="usernames"/> (lowercase handles), the ids of the users <paramref name="authorId"/> may mention.</summary>
    public async Task<IReadOnlyList<Guid>> AllowedByUsernameAsync(
        Guid authorId, IReadOnlyCollection<string> usernames, CancellationToken cancellationToken)
    {
        if (usernames.Count == 0) return [];

        var allowed = await AllowedAsync(authorId, db.Users.Where(u => usernames.Contains(u.Username)), cancellationToken);
        return [.. allowed.Select(u => u.Id)];
    }

    private async Task<List<User>> AllowedAsync(Guid authorId, IQueryable<User> candidates, CancellationToken ct)
    {
        // Deleted accounts are left out by the query filter; the rest is decided on the loaded users.
        var users = await candidates.AsNoTracking().ToListAsync(ct);
        if (users.Count == 0) return users;

        var ids = users.Select(u => u.Id).ToList();
        var followers = (await db.UserFollows.AsNoTracking()
                .Where(f => f.FolloweeId == authorId && ids.Contains(f.FollowerId))
                .Select(f => f.FollowerId)
                .ToListAsync(ct))
            .ToHashSet();
        var now = clock.GetUtcNow().UtcDateTime;
        return [.. users.Where(u => u.CanBeMentionedBy(authorId, followers.Contains(u.Id), now))];
    }
}

public static class MentionQueries
{
    /// <summary>
    /// The users <paramref name="authorId"/> may @mention: <see cref="User.CanBeMentionedBy"/> as a query (deleted accounts
    /// are left out by the query filter). Keep the two in step.
    /// </summary>
    public static IQueryable<User> MentionableBy(this IQueryable<User> users, IAppDbContext db, Guid authorId, DateTime now) =>
        users.Where(u => !u.IsSystemAccount
            && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now))
            && (u.Id == authorId
                || u.WhoCanMention == MentionPolicy.Everyone
                || (u.WhoCanMention == MentionPolicy.Following && db.UserFollows.Any(f => f.FollowerId == u.Id && f.FolloweeId == authorId))));
}
