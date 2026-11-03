using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Reading.Queries.GetMyStats;

/// <summary>GET /me/stats: streak, totals, the last 7/30 days and top fields (SPEC F08). Owner only.</summary>
[Authenticated]
public sealed record GetMyReadingStatsQuery : IQuery<Result<ReadingStatsDto>>;

internal sealed class GetMyReadingStatsQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : IQueryHandler<GetMyReadingStatsQuery, Result<ReadingStatsDto>>
{
    private const int TopFieldCount = 3;

    public async ValueTask<Result<ReadingStatsDto>> Handle(GetMyReadingStatsQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var now = clock.GetUtcNow().UtcDateTime;
        var timeZone = await db.Users.AsNoTracking().Where(u => u.Id == userId).Select(u => u.TimeZone).FirstAsync(cancellationToken);
        var today = ReadingClock.LocalDate(now, timeZone);

        var stats = await db.UserStats.AsNoTracking().FirstOrDefaultAsync(s => s.UserId == userId, cancellationToken);
        var status = Streaks.StatusOn(stats?.History ?? StreakHistory.Empty, today);

        var weekFrom = today.AddDays(-6);
        var monthFrom = today.AddDays(-29);
        var recent = await db.ReadingDays.AsNoTracking()
            .Where(d => d.UserId == userId && d.Date >= monthFrom && d.Date <= today)
            .Select(d => new { d.Date, d.ArticlesRead, d.ActiveSeconds })
            .ToListAsync(cancellationToken);
        var week = recent.Where(d => d.Date >= weekFrom).ToList();

        var fieldCounts = await db.ReadingProgress.AsNoTracking()
            .Where(r => r.UserId == userId && r.CompletedAt != null)
            .Join(db.Articles, r => r.ArticleId, a => a.Id, (r, a) => a.FieldId)
            .GroupBy(fieldId => fieldId)
            .Select(g => new { FieldId = g.Key, Articles = g.Count() })
            .OrderByDescending(g => g.Articles)
            .Take(TopFieldCount)
            .ToListAsync(cancellationToken);
        var fieldIds = fieldCounts.Select(f => f.FieldId).ToList();
        var fields = await db.Fields.AsNoTracking()
            .Where(f => fieldIds.Contains(f.Id))
            .Select(f => new { f.Id, f.Slug, f.NameAr, f.NameEn, f.Icon, f.Color })
            .ToDictionaryAsync(f => f.Id, cancellationToken);
        var arabic = currentUser.UiLanguage == UiLanguages.Arabic;
        var topFields = fieldCounts
            .Where(c => fields.ContainsKey(c.FieldId))
            .Select(c =>
            {
                var f = fields[c.FieldId];
                return new TopFieldDto(f.Id, f.Slug, arabic ? f.NameAr : f.NameEn, f.Icon, f.Color, c.Articles);
            })
            .ToList();

        return new ReadingStatsDto(
            StreakDto.From(status, today),
            stats?.TotalArticles ?? 0,
            Minutes(stats?.TotalSeconds ?? 0),
            week.Sum(d => d.ArticlesRead),
            Minutes(week.Sum(d => d.ActiveSeconds)),
            recent.Sum(d => d.ArticlesRead),
            topFields);
    }

    internal static int Minutes(int seconds) => (int)Math.Round(seconds / 60.0, MidpointRounding.AwayFromZero);
}
