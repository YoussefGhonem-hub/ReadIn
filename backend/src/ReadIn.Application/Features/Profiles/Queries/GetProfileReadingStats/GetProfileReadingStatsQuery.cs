using Mediator;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Reading;
using ReadIn.Application.Features.Reading.Queries.GetMyHeatmap;
using ReadIn.Application.Features.Reading.Queries.GetMyStats;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Profiles.Queries.GetProfileReadingStats;

/// <summary>
/// GET /users/{username}/stats — the F08 stats of a profile, in that user's time zone (SPEC F14). Only on your own
/// profile or when the user made them public (F18); otherwise <c>profile.stats_private</c>. Guests are allowed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetProfileReadingStatsQuery(string Username) : IQuery<Result<ReadingStatsDto>>;

/// <summary>GET /users/{username}/stats/heatmap — as <see cref="GetMyReadingHeatmapQuery"/>, with the same privacy rule.</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetProfileReadingHeatmapQuery(string Username, int Days = GetMyReadingHeatmapQuery.DefaultDays)
    : IQuery<Result<ReadingHeatmapDto>>;

internal sealed class GetProfileReadingStatsQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : IQueryHandler<GetProfileReadingStatsQuery, Result<ReadingStatsDto>>
{
    public async ValueTask<Result<ReadingStatsDto>> Handle(GetProfileReadingStatsQuery query, CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        if (await db.FindProfileForAsync(query.Username, now, currentUser, cancellationToken) is not { } owner) return UserErrors.NotFound;
        if (!owner.ReadingStatsVisibleTo(currentUser.UserId)) return ProfileErrors.StatsPrivate;

        return await GetMyReadingStatsQueryHandler.ComputeAsync(db, owner.Id, currentUser.UiLanguage, now, cancellationToken);
    }
}

internal sealed class GetProfileReadingHeatmapQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : IQueryHandler<GetProfileReadingHeatmapQuery, Result<ReadingHeatmapDto>>
{
    public async ValueTask<Result<ReadingHeatmapDto>> Handle(GetProfileReadingHeatmapQuery query, CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        if (await db.FindProfileForAsync(query.Username, now, currentUser, cancellationToken) is not { } owner) return UserErrors.NotFound;
        if (!owner.ReadingStatsVisibleTo(currentUser.UserId)) return ProfileErrors.StatsPrivate;

        return await GetMyReadingHeatmapQueryHandler.ComputeAsync(db, owner.Id, query.Days, now, cancellationToken);
    }
}
