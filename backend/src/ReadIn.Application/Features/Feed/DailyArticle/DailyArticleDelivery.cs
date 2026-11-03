using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Feed.DailyArticle;

/// <summary>
/// The daily-article job (SPEC F07, §21.1), run every few minutes by Hangfire. For every user with a push device it stores
/// the pick 30 minutes before the reminder time and sends one push at the reminder time, both in the user's time zone.
/// <list type="bullet">
/// <item>Idempotent: one pick per user and local date (unique index), and the push is claimed on the pick
/// (<see cref="DailyPick.NotifiedAt"/>) before it is sent, so a rerun never sends it twice.</item>
/// <item>Safe for missed runs: a late run still makes the day's pick, and sends a push up to
/// <see cref="DailySchedule.LateWindow"/> after the reminder time.</item>
/// <item>Batched: users are found per time zone with one range query on their reminder time, then handled
/// <see cref="BatchSize"/> at a time (profiles, articles and device tokens loaded once per batch, one FCM call per batch).</item>
/// </list>
/// Suspended, deleted and system accounts and users without a device are skipped; so is a user the algorithm finds no
/// article for. The pick is the same one <c>GET /feed/today</c> serves, so the pushed article is the hero card all day.
/// </summary>
public sealed partial class DailyArticleDelivery(
    IAppDbContext db,
    DailyArticlePicker picker,
    IPushSender pushSender,
    ILogger<DailyArticleDelivery> logger)
{
    internal const int BatchSize = 200;

    public async Task<DailyArticleRunResult> RunAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        var result = new DailyArticleRunResult();
        var zones = await Recipients(utcNow).Select(u => u.TimeZone).Distinct().ToListAsync(cancellationToken);

        foreach (var zone in zones)
        {
            var localNow = DailySchedule.LocalNow(utcNow, zone);
            foreach (var range in DailySchedule.PickRanges(localNow))
                result.Picked += await PickAsync(zone, range, utcNow, cancellationToken);

            await NotifyAsync(zone, DailySchedule.PushRange(localNow), localNow, utcNow, result, cancellationToken);
        }

        if (result.Picked + result.Notified + result.Failed > 0)
            LogRun(logger, result.Picked, result.Notified, result.Failed, result.InvalidTokens);
        return result;
    }

    /// <summary>Users who get the daily push: active accounts with at least one registered device.</summary>
    private IQueryable<User> Recipients(DateTime utcNow) => db.Users.Where(u =>
        !u.IsSystemAccount
        && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > utcNow))
        && u.Devices.Any());

    private IQueryable<User> RecipientsIn(string zone, ReminderRange range, DateTime utcNow) => Recipients(utcNow)
        .Where(u => u.TimeZone == zone && u.ReminderTime >= range.From && u.ReminderTime <= range.To);

    private async Task<int> PickAsync(string zone, ReminderRange range, DateTime utcNow, CancellationToken ct)
    {
        var picked = 0;
        var after = Guid.Empty;
        while (true)
        {
            // Keyset paging: users the algorithm finds nothing for stay unpicked and must not be fetched again.
            var userIds = await RecipientsIn(zone, range, utcNow)
                .Where(u => u.Id > after && !db.DailyPicks.Any(p => p.UserId == u.Id && p.Date == range.Date))
                .OrderBy(u => u.Id)
                .Select(u => u.Id)
                .Take(BatchSize)
                .ToListAsync(ct);
            if (userIds.Count == 0) return picked;
            after = userIds[^1];

            var picks = new List<DailyPick>(userIds.Count);
            foreach (var profile in (await picker.LoadProfilesAsync(userIds, range.Date, ct)).Values)
            {
                if (await picker.PickAsync(profile, ct) is { } articleId)
                    picks.Add(new DailyPick(profile.UserId, range.Date, articleId));
            }
            picked += await picker.StoreAsync(picks, ct);

            if (userIds.Count < BatchSize) return picked;
        }
    }

    private async Task NotifyAsync(
        string zone, ReminderRange range, DateTime localNow, DateTime utcNow, DailyArticleRunResult result, CancellationToken ct)
    {
        var timeToLive = DailySchedule.TimeToLive(localNow);
        var after = Guid.Empty;
        while (true)
        {
            // Not yet notified, not opened and not already read today: "today's article is ready" would be noise then.
            var due = await db.DailyPicks
                .Where(p => p.Date == range.Date && p.NotifiedAt == null && p.OpenedAt == null && p.Id > after)
                .Join(RecipientsIn(zone, range, utcNow), p => p.UserId, u => u.Id,
                    (p, u) => new { Pick = p, u.UiLanguage, u.ArticleLanguagePref })
                .Where(x => !db.ReadingProgress.Any(r =>
                    r.UserId == x.Pick.UserId && r.ArticleId == x.Pick.ArticleId && r.CompletedAt != null))
                .OrderBy(x => x.Pick.Id)
                .Take(BatchSize)
                .ToListAsync(ct);
            if (due.Count == 0) return;
            after = due[^1].Pick.Id;

            var articleIds = due.Select(d => d.Pick.ArticleId).Distinct().ToList();
            var articles = await db.Articles.AsNoTracking()
                .Where(a => articleIds.Contains(a.Id) && a.Status == ArticleStatus.Published)
                .Select(a => new
                {
                    a.Id,
                    a.Slug,
                    Translations = a.Translations.Select(t => new { t.Language, t.Title, t.IsSource }).ToList(),
                })
                .ToDictionaryAsync(a => a.Id, ct);

            var userIds = due.Select(d => d.Pick.UserId).ToList();
            var devices = await db.Users.AsNoTracking()
                .Where(u => userIds.Contains(u.Id))
                .SelectMany(u => u.Devices.Select(d => new { d.UserId, d.Token }))
                .ToListAsync(ct);
            var tokens = devices.ToLookup(d => d.UserId, d => d.Token);

            var batch = new List<(DailyPick Pick, PushNotification Notification)>(due.Count);
            foreach (var row in due)
            {
                // An article unpublished since the pick gets no push (the hero card disappears with it).
                if (!articles.TryGetValue(row.Pick.ArticleId, out var article)) continue;
                var userTokens = tokens[row.Pick.UserId].Distinct(StringComparer.Ordinal).ToList();
                if (userTokens.Count == 0 || InQuietHours(QuietHoursOf(row.Pick.UserId), localNow)) continue;
                if (!row.Pick.MarkNotified(utcNow)) continue;

                // The version the user reads: the preferred language when it exists, otherwise the source (as on the card).
                var translation = article.Translations.FirstOrDefault(t => t.Language == row.ArticleLanguagePref)
                    ?? article.Translations.First(t => t.IsSource);
                batch.Add((row.Pick, DailyArticlePush.Create(
                    userTokens, row.UiLanguage, article.Id, article.Slug, translation.Title, translation.Language, timeToLive)));
            }
            if (batch.Count > 0)
            {
                // Claimed before sending: if the process dies below, these pushes are lost rather than sent twice.
                await db.SaveChangesAsync(ct);
                await SendAsync(batch, result, ct);
            }

            if (due.Count < BatchSize) return;
        }
    }

    private async Task SendAsync(List<(DailyPick Pick, PushNotification Notification)> batch, DailyArticleRunResult result, CancellationToken ct)
    {
        IReadOnlyList<PushOutcome> outcomes;
        try
        {
            outcomes = await pushSender.SendAsync(batch.Select(b => b.Notification).ToList(), ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // FCM unreachable or misconfigured: give the claims back so a later run (within the late window) retries.
            foreach (var (pick, _) in batch) pick.ReleaseNotification();
            await db.SaveChangesAsync(CancellationToken.None);
            throw;
        }

        var invalidTokens = new HashSet<string>(StringComparer.Ordinal);
        var released = false;
        for (var i = 0; i < batch.Count; i++)
        {
            var outcome = outcomes[i];
            invalidTokens.UnionWith(outcome.InvalidTokens);
            if (outcome.Sent > 0) result.Notified++;
            if (outcome.ShouldRetry)
            {
                batch[i].Pick.ReleaseNotification();
                released = true;
                result.Failed++;
            }
        }
        if (released) await db.SaveChangesAsync(ct);

        if (invalidTokens.Count > 0)
        {
            // SPEC §21.1: tokens FCM reports as unregistered or invalid are removed.
            var stale = invalidTokens.ToList();
            result.InvalidTokens += await db.Users.IgnoreQueryFilters()
                .SelectMany(u => u.Devices)
                .Where(d => stale.Contains(d.Token))
                .ExecuteDeleteAsync(ct);
        }
    }

    /// <summary>
    /// F17 hook: a user's quiet hours (SPEC §21.1, default 23:00–07:00) will come from their NotificationPreferences. The
    /// daily article is not a security alert, so it waits until they end (a later run sends it, within the late window).
    /// Until F17 ships nobody has quiet hours.
    /// </summary>
    private static QuietHours? QuietHoursOf(Guid userId)
    {
        _ = userId;
        return null;
    }

    private static bool InQuietHours(QuietHours? quietHours, DateTime localNow) =>
        quietHours?.Contains(TimeOnly.FromDateTime(localNow)) == true;

    [LoggerMessage(Level = LogLevel.Information,
        Message = "Daily article: {Picked} picks stored, {Notified} pushes sent, {Failed} to retry, {InvalidTokens} invalid device tokens removed")]
    private static partial void LogRun(ILogger logger, int picked, int notified, int failed, int invalidTokens);
}

/// <summary>What one run of <see cref="DailyArticleDelivery"/> did.</summary>
public sealed class DailyArticleRunResult
{
    public int Picked { get; internal set; }
    public int Notified { get; internal set; }

    /// <summary>Pushes no device received (FCM unavailable); their picks are released for the next run.</summary>
    public int Failed { get; internal set; }

    public int InvalidTokens { get; internal set; }
}
