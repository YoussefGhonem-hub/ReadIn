using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Local only (SPEC §18.2 step 8, §18.3): reading history and streaks of different shapes for the demo users, so the
/// streak badge, stats card and heatmap look real in development (SPEC F08). Days are relative to each user's local
/// today and the checksum includes today's date, so it re-runs once a day on startup and the streaks stay current. Each
/// run replaces the demo users' reading data. Every completed read is a different published article; when there are
/// too few, the oldest planned days are dropped.
/// </summary>
internal sealed class DemoReadingSeeder(AppDbContext db, TimeProvider clock) : ISeeder
{
    /// <param name="DaysAgo">Local days with a completed article: 0 = today, 1 = yesterday, …</param>
    /// <param name="InProgress">Articles left part-way, for "continue reading".</param>
    private sealed record Plan(string Handle, int[] DaysAgo, int InProgress = 0);

    private static readonly Plan[] Plans =
    [
        // SPEC §18.3: reader1 has a 12-day streak (read today to make it 13), and an older 9-day run.
        new("reader1", [.. Run(1, 12), .. Run(40, 48)], InProgress: 2),
        // One read away from the 7-day milestone celebration.
        new("reader2", Run(1, 6), InProgress: 1),
        // 29 read days with a freeze 15 days ago: reading today reaches the 30-day milestone.
        new("reader3", [.. Run(1, 14), .. Run(16, 30)], InProgress: 1),
        // Streak lost two days ago; the best run (21 days) was two months ago.
        new("reader4", [.. Run(3, 8), .. Run(60, 80)]),
        // Missed yesterday: the freeze is pending until they read today.
        new("reader5", Run(2, 5), InProgress: 1),
        // A daily reader for six weeks who already read today.
        new("reader6", Run(0, 44)),
        // Started today.
        new("reader7", [0], InProgress: 1),
        // Occasional readers without a streak.
        new("reader8", [2, 9, 16, 30, 31, 45]),
        new("reader9", [5, 6, 20, 33]),
        new("writer.verified", Run(0, 2)),
        new("reviewer.dotnet", [1, 4, 7, 10, 13]),
    ];

    public string Name => "demo-reading";
    public int Order => 10;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public async Task<string> ComputeChecksumAsync(CancellationToken cancellationToken)
    {
        var published = await Published().CountAsync(cancellationToken);
        var anchor = ReadingClock.LocalDate(clock.GetUtcNow().UtcDateTime, User.DefaultTimeZone);
        return SeedChecksum.Of(
            [.. Plans.Select(p => $"{p.Handle}|{string.Join(',', p.DaysAgo)}|{p.InProgress}"), $"published:{published}", $"today:{anchor:O}"]);
    }

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var emails = Plans.Select(p => Email(p.Handle)).ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .Select(u => new DemoReader(
                u.Id,
                u.Email!,
                u.TimeZone,
                u.ArticleLanguagePref,
                u.Interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value).ToList()))
            .ToListAsync(cancellationToken);
        if (users.Count == 0) return true;

        var userIds = users.Select(u => u.Id).ToList();
        await db.ReadingProgress.Where(r => userIds.Contains(r.UserId)).ExecuteDeleteAsync(cancellationToken);
        await db.ReadingDays.Where(d => userIds.Contains(d.UserId)).ExecuteDeleteAsync(cancellationToken);
        await db.UserStats.Where(s => userIds.Contains(s.UserId)).ExecuteDeleteAsync(cancellationToken);

        var articles = await Published()
            .OrderBy(a => a.PublishedAt)
            .Select(a => new DemoArticle(
                a.Id,
                a.FieldId,
                a.Translations.Select(t => new DemoTranslation(t.Language, t.ReadingTimeMinutes)).ToList()))
            .ToListAsync(cancellationToken);

        foreach (var plan in Plans)
        {
            if (users.FirstOrDefault(u => u.Email == Email(plan.Handle)) is not { } user) continue;
            SeedReader(plan, user, articles, now);
        }
        await db.SaveChangesAsync(cancellationToken);

        // Read counts follow the replaced history (normally the outbox recomputes them per read).
        await db.Articles.IgnoreQueryFilters().ExecuteUpdateAsync(
            set => set.SetProperty(a => a.ReadCount, a => db.ReadingProgress.Count(r => r.ArticleId == a.Id && r.CompletedAt != null)),
            cancellationToken);
        return true;
    }

    private void SeedReader(Plan plan, DemoReader user, IReadOnlyList<DemoArticle> articles, DateTime now)
    {
        var zone = TimeZoneInfo.TryFindSystemTimeZoneById(user.TimeZone, out var tz) ? tz : TimeZoneInfo.Utc;
        var today = ReadingClock.LocalDate(now, user.TimeZone);
        var localNow = TimeZoneInfo.ConvertTimeFromUtc(now, zone);

        // The user's interests first, in a stable per-user order, so their top fields look plausible.
        var queue = new Queue<DemoArticle>(articles
            .OrderByDescending(a => user.FieldIds.Contains(a.FieldId))
            .ThenBy(a => Mix(user.Id, a.Id)));

        var days = new List<ReadingDay>();
        var totalSeconds = 0;
        foreach (var daysAgo in plan.DaysAgo.Distinct().Order())
        {
            if (queue.Count == 0) break; // too few articles: drop the oldest days
            var date = today.AddDays(-daysAgo);
            var perDay = Mix(user.Id, date.DayNumber) % 3 == 0 && queue.Count > 1 ? 2 : 1;
            var daySeconds = 0;

            for (var i = 0; i < perDay; i++)
            {
                var article = queue.Dequeue();
                var (language, minutes) = TranslationFor(article, user.ArticleLanguage);
                var seconds = Math.Max(45, minutes * 60 * (85 + Mix(user.Id, article.Id) % 26) / 100);
                var completedAt = CompletedAt(date, i, daysAgo == 0 ? localNow : null, zone);
                db.ReadingProgress.Add(ReadingProgress.SeededCompleted(user.Id, article.Id, language, seconds, completedAt));
                daySeconds += seconds;
            }

            days.Add(ReadingDay.Seeded(user.Id, date, perDay, daySeconds));
            totalSeconds += daySeconds;
        }

        for (var i = 0; i < plan.InProgress && queue.Count > 0; i++)
        {
            var article = queue.Dequeue();
            var (language, _) = TranslationFor(article, user.ArticleLanguage);
            db.ReadingProgress.Add(ReadingProgress.SeededInProgress(user.Id, article.Id, language, 35 + 20 * i, 140, now.AddHours(-(i + 1) * 5)));
        }

        db.ReadingDays.AddRange(days);
        var stats = new UserStats(user.Id);
        stats.Rebuild(Streaks.Compute(days.Select(d => d.Date)), days.Sum(d => d.ArticlesRead), totalSeconds, now);
        db.UserStats.Add(stats);
    }

    /// <summary>Evenings in the user's time zone; today's reads are placed before now.</summary>
    private static DateTime CompletedAt(DateOnly date, int index, DateTime? localNow, TimeZoneInfo zone)
    {
        var local = date.ToDateTime(new TimeOnly(20, 0)).AddMinutes(index * 25);
        if (localNow is { } current)
        {
            var startOfToday = date.ToDateTime(TimeOnly.MinValue);
            local = current.AddMinutes(-20 * (index + 1));
            if (local < startOfToday) local = startOfToday.AddMinutes(index + 1);
        }
        return TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(local, DateTimeKind.Unspecified), zone);
    }

    private static (string Language, int Minutes) TranslationFor(DemoArticle article, string preferred)
    {
        var translation = article.Translations.FirstOrDefault(t => t.Language == preferred) ?? article.Translations.First();
        return (translation.Language, Math.Max(1, translation.ReadingTimeMinutes));
    }

    private IQueryable<Article> Published() =>
        db.Articles.Where(a => a.Status == ArticleStatus.Published && a.Translations.Any());

    private static string Email(string handle) => $"{handle}@readin.test";

    private static int[] Run(int fromDaysAgo, int toDaysAgo) =>
        [.. Enumerable.Range(fromDaysAgo, toDaysAgo - fromDaysAgo + 1)];

    /// <summary>A stable pseudo-random number (string hashes change per process in .NET).</summary>
    private static int Mix(Guid seed, Guid value) => Mix(seed, BitConverter.ToInt32(value.ToByteArray(), 12));

    private static int Mix(Guid seed, int value)
    {
        var hash = (uint)BitConverter.ToInt32(seed.ToByteArray(), 12) ^ (uint)value * 2654435761u;
        hash ^= hash >> 15;
        hash *= 2246822519u;
        hash ^= hash >> 13;
        return (int)(hash & 0x7FFFFFFF);
    }

    private sealed record DemoReader(Guid Id, string Email, string TimeZone, string ArticleLanguage, List<Guid> FieldIds);

    private sealed record DemoArticle(Guid Id, Guid FieldId, List<DemoTranslation> Translations);

    private sealed record DemoTranslation(string Language, int ReadingTimeMinutes);
}
