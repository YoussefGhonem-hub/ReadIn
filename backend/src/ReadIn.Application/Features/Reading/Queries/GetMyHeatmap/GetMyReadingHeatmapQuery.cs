using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Reading.Queries.GetMyStats;
using ReadIn.Domain.Common;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Reading.Queries.GetMyHeatmap;

/// <summary>GET /me/stats/heatmap: the reading heatmap, GitHub style (SPEC F08). Owner only.</summary>
/// <param name="Days">How many local days back, today included: 1–371 (53 weeks), default 365.</param>
[Authenticated]
public sealed record GetMyReadingHeatmapQuery(int Days = GetMyReadingHeatmapQuery.DefaultDays) : IQuery<Result<ReadingHeatmapDto>>
{
    public const int DefaultDays = 365;
    public const int MaxDays = 371;
}

internal sealed class GetMyReadingHeatmapQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : IQueryHandler<GetMyReadingHeatmapQuery, Result<ReadingHeatmapDto>>
{
    public async ValueTask<Result<ReadingHeatmapDto>> Handle(GetMyReadingHeatmapQuery query, CancellationToken cancellationToken) =>
        await ComputeAsync(db, currentUser.RequireUserId(), query.Days, clock.GetUtcNow().UtcDateTime, cancellationToken);

    /// <summary>The heatmap of <paramref name="userId"/> in their own time zone; also serves public profiles (F14).</summary>
    internal static async Task<ReadingHeatmapDto> ComputeAsync(
        IAppDbContext db, Guid userId, int dayCount, DateTime now, CancellationToken cancellationToken)
    {
        var timeZone = await db.Users.AsNoTracking().Where(u => u.Id == userId).Select(u => u.TimeZone).FirstAsync(cancellationToken);
        var today = ReadingClock.LocalDate(now, timeZone);
        var from = today.AddDays(1 - Math.Clamp(dayCount, 1, GetMyReadingHeatmapQuery.MaxDays));

        // Freezes depend on the whole history (one per rolling 7 days), so every read day is loaded, not just the range.
        var readDays = await db.ReadingDays.AsNoTracking()
            .Where(d => d.UserId == userId && d.ArticlesRead > 0)
            .Select(d => new { d.Date, d.ArticlesRead, d.ActiveSeconds })
            .ToListAsync(cancellationToken);
        var history = Streaks.Compute(readDays.Select(d => d.Date));

        var days = readDays
            .Where(d => d.Date >= from && d.Date <= today)
            .Select(d => new HeatmapDayDto(d.Date, d.ArticlesRead, GetMyReadingStatsQueryHandler.Minutes(d.ActiveSeconds), Frozen: false))
            .Concat(history.FreezeDays.Where(d => d >= from && d <= today).Select(d => new HeatmapDayDto(d, 0, 0, Frozen: true)))
            .OrderBy(d => d.Date)
            .ToList();

        return new ReadingHeatmapDto(from, today, days);
    }
}
