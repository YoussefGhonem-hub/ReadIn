using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Search;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Follows.Queries.GetSuggestedWriters;

internal sealed class GetSuggestedWritersQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage, TimeProvider clock)
    : IQueryHandler<GetSuggestedWritersQuery, Result<IReadOnlyList<UserSummaryDto>>>
{
    public async ValueTask<Result<IReadOnlyList<UserSummaryDto>>> Handle(GetSuggestedWritersQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var limit = Math.Clamp(query.Limit, 1, 50);

        var interests = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .SelectMany(u => u.Interests)
            .Select(i => new { i.FieldId, i.TopicId })
            .ToListAsync(cancellationToken);
        var topicIds = interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value).ToList();
        var fieldIds = interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value)
            .Concat(await db.Topics.AsNoTracking().Where(t => topicIds.Contains(t.Id)).Select(t => t.FieldId).ToListAsync(cancellationToken))
            .Distinct()
            .ToList();

        var writers = await SuggestAsync(userId, fieldIds, limit, cancellationToken);
        if (writers.Count == 0 && fieldIds.Count > 0) writers = await SuggestAsync(userId, fieldIds: [], limit, cancellationToken);
        return writers.Select(w => w.WithPublicUrls(storage)).ToList();
    }

    /// <param name="fieldIds">Empty means any field.</param>
    private Task<List<UserSummaryDto>> SuggestAsync(Guid userId, List<Guid> fieldIds, int limit, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var published = db.Articles.Visible();
        if (fieldIds.Count > 0) published = published.Where(a => fieldIds.Contains(a.FieldId));

        return db.Users.AsNoTracking()
            .Where(u => u.Id != userId)
            .Where(u => !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)))
            .Where(u => !db.UserFollows.Any(f => f.FollowerId == userId && f.FolloweeId == u.Id))
            .WithoutMutedFor(db, userId)
            .Where(u => published.Any(a => a.AuthorId == u.Id))
            .OrderByDescending(u => u.IsVerified)
            .ThenByDescending(u => db.UserFollows.Count(f => f.FolloweeId == u.Id))
            .ThenBy(u => u.Username)
            .Take(limit)
            .Select(UserSummaries.For(db, userId))
            .ToListAsync(ct);
    }
}
