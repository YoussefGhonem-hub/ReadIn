using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Profiles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.LearningPaths.Queries.GetMyPaths;

/// <summary>GET /me/paths — your enrolled paths: in progress first (latest activity first), then completed (SPEC F09).</summary>
[Authenticated]
public sealed record GetMyPathsQuery(string UiLanguage) : IQuery<Result<IReadOnlyList<PathCardDto>>>;

/// <summary>
/// GET /me/paths/active — the Home "learning path" card (SPEC F03): the enrolled path with the latest activity that
/// still has an unread article. Null (→ 204) when there is none.
/// </summary>
[Authenticated]
public sealed record GetActivePathQuery(string UiLanguage) : IQuery<Result<PathCardDto?>>;

/// <summary>
/// GET /users/{username}/paths — the paths a user is enrolled in, with that user's progress (SPEC F09, F14). Same privacy
/// rule as their reading stats: <c>profile.stats_private</c> unless it's your own profile or they made stats public.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetProfilePathsQuery(string Username, string UiLanguage) : IQuery<Result<IReadOnlyList<PathCardDto>>>;

internal sealed class GetMyPathsQueryHandler(IAppDbContext db, ICurrentUser currentUser, PathCards cards)
    : IQueryHandler<GetMyPathsQuery, Result<IReadOnlyList<PathCardDto>>>
{
    public async ValueTask<Result<IReadOnlyList<PathCardDto>>> Handle(GetMyPathsQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        return await EnrolledPaths.ListAsync(db, cards, userId, query.UiLanguage, await cards.ArticleLanguageOfAsync(userId, query.UiLanguage, ct), ct);
    }
}

internal sealed class GetActivePathQueryHandler(IAppDbContext db, ICurrentUser currentUser, PathCards cards)
    : IQueryHandler<GetActivePathQuery, Result<PathCardDto?>>
{
    public async ValueTask<Result<PathCardDto?>> Handle(GetActivePathQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var inProgress = await db.PathEnrollments.AsNoTracking()
            .Where(e => e.UserId == userId && e.CompletedAt == null)
            .OrderByDescending(e => e.LastActivityAt)
            .Select(e => e.PathId)
            .ToListAsync(ct);

        var language = await cards.ArticleLanguageOfAsync(userId, query.UiLanguage, ct);
        var active = (await cards.BuildAsync(inProgress, userId, query.UiLanguage, language, ct))
            .FirstOrDefault(c => c.Progress?.Next is not null);
        return Result.Success(active);
    }
}

internal sealed class GetProfilePathsQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock, PathCards cards)
    : IQueryHandler<GetProfilePathsQuery, Result<IReadOnlyList<PathCardDto>>>
{
    public async ValueTask<Result<IReadOnlyList<PathCardDto>>> Handle(GetProfilePathsQuery query, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        if (await db.FindProfileAsync(query.Username, now, ct) is not { } owner) return UserErrors.NotFound;
        if (!owner.ReadingStatsVisibleTo(currentUser.UserId)) return ProfileErrors.StatsPrivate;

        // Titles follow the viewer's article language, progress is the profile owner's.
        var language = await cards.ArticleLanguageOfAsync(currentUser.UserId, query.UiLanguage, ct);
        return await EnrolledPaths.ListAsync(db, cards, owner.Id, query.UiLanguage, language, ct);
    }
}

internal static class EnrolledPaths
{
    /// <summary><paramref name="userId"/>'s enrolled paths: in progress (latest activity first), then completed (latest first).</summary>
    public static async Task<List<PathCardDto>> ListAsync(
        IAppDbContext db, PathCards cards, Guid userId, string uiLanguage, string? articleLanguage, CancellationToken ct)
    {
        var ids = await db.PathEnrollments.AsNoTracking()
            .Where(e => e.UserId == userId)
            .OrderBy(e => e.CompletedAt != null)
            .ThenByDescending(e => e.CompletedAt)
            .ThenByDescending(e => e.LastActivityAt)
            .Select(e => e.PathId)
            .ToListAsync(ct);
        return await cards.BuildAsync(ids, userId, uiLanguage, articleLanguage, ct);
    }
}
