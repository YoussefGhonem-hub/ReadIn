using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Follows.Queries.GetFollowList;

internal sealed class GetFollowListQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
    : IQueryHandler<GetFollowListQuery, Result<CursorPage<UserSummaryDto>>>
{
    public async ValueTask<Result<CursorPage<UserSummaryDto>>> Handle(GetFollowListQuery query, CancellationToken cancellationToken)
    {
        if (!await db.Users.AnyAsync(u => u.Id == query.UserId, cancellationToken)) return UserErrors.NotFound;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var follows = db.UserFollows.AsNoTracking();
        // The navigation joins Users with its query filter, so deleted accounts drop out of both lists.
        var rows = query.List == FollowList.Followers
            ? follows.Where(f => f.FolloweeId == query.UserId).Select(f => new { f.Id, f.CreatedAt, Person = f.Follower })
            : follows.Where(f => f.FollowerId == query.UserId).Select(f => new { f.Id, f.CreatedAt, Person = f.Followee });

        if (query.Search?.Trim().TrimStart('@') is { Length: > 0 } search)
            rows = rows.Where(r => r.Person.DisplayName.Contains(search) || r.Person.Username.Contains(search));

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            rows = rows.Where(r =>
                r.CreatedAt < cursor.Timestamp ||
                (r.CreatedAt == cursor.Timestamp && r.Id.CompareTo(cursor.Id) < 0));
        }

        var page = await rows
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .Take(limit + 1)
            .Select(r => new { r.Id, r.CreatedAt, PersonId = r.Person.Id })
            .ToListAsync(cancellationToken);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].CreatedAt, page[^1].Id).Encode();
        }

        var ids = page.Select(p => p.PersonId).ToList();
        var people = await db.Users.AsNoTracking()
            .Where(u => ids.Contains(u.Id))
            .Select(UserSummaries.For(db, currentUser.UserId))
            .ToDictionaryAsync(u => u.Id, cancellationToken);

        return new CursorPage<UserSummaryDto>(
            [.. page.Where(p => people.ContainsKey(p.PersonId)).Select(p => people[p.PersonId].WithPublicUrls(storage))],
            next);
    }
}
