using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Notifications;

/// <summary>
/// The streak reminder (SPEC F17): at 20:00 in the user's time zone, a <c>streak_reminder</c> for every user whose streak
/// is alive (at least 1 day, ADR 0013's rules, a pending freeze included) and who hasn't read today. Run every few
/// minutes by Hangfire; a late run still reminds up to <see cref="LateWindow"/> after 20:00, and the dedupe key (one per
/// local date) keeps it to one a day. The push job sends it (quiet hours apply; it is dropped 4 hours after).
/// </summary>
public sealed partial class StreakReminders(IAppDbContext db, NotificationWriter writer, ILogger<StreakReminders> logger)
{
    public static readonly TimeOnly ReminderTime = new(20, 0);
    public static readonly TimeSpan LateWindow = TimeSpan.FromHours(2);
    internal const int BatchSize = 500;

    public static string DedupeKey(DateOnly localDate) => $"{NotificationTypes.StreakReminder}:{localDate:yyyy-MM-dd}";

    /// <summary>The reminder of the user's local day is due from 20:00 to 22:00.</summary>
    public static bool IsDue(DateTime localNow)
    {
        var time = TimeOnly.FromDateTime(localNow);
        return time >= ReminderTime && time <= ReminderTime.Add(LateWindow);
    }

    /// <returns>How many reminders were written.</returns>
    public async Task<int> RunAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        // Streaks a reminder can still save: the last read at most two local days ago (a pending freeze), whatever the zone.
        var earliest = DateOnly.FromDateTime(utcNow).AddDays(-3);
        var candidates = db.UserStats.AsNoTracking()
            .Where(s => s.CurrentStreak >= 1 && s.LastReadDate >= earliest)
            .Join(db.Users.Where(u => !u.IsSystemAccount && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > utcNow))),
                s => s.UserId, u => u.Id, (s, u) => new { Stats = s, u.TimeZone })
            .Where(x => !db.UserNotificationSettings.Any(m =>
                m.UserId == x.Stats.UserId && m.Type == NotificationTypes.StreakReminder && m.Mode == NotificationMode.Off));

        var written = 0;
        var zones = await candidates.Select(x => x.TimeZone).Distinct().ToListAsync(cancellationToken);
        foreach (var zone in zones)
        {
            var localNow = DailySchedule.LocalNow(utcNow, zone);
            if (!IsDue(localNow)) continue;

            var today = DateOnly.FromDateTime(localNow);
            var key = DedupeKey(today);
            var after = Guid.Empty;
            while (true)
            {
                var batch = await candidates
                    .Where(x => x.TimeZone == zone && x.Stats.LastReadDate < today && x.Stats.UserId > after
                        && !db.Notifications.Any(n => n.UserId == x.Stats.UserId && n.DedupeKey == key))
                    .OrderBy(x => x.Stats.UserId)
                    .Select(x => new
                    {
                        x.Stats.UserId,
                        x.Stats.CurrentStreak,
                        x.Stats.LongestStreak,
                        x.Stats.LastReadDate,
                        x.Stats.LastFreezeDate,
                    })
                    .Take(BatchSize)
                    .ToListAsync(cancellationToken);
                if (batch.Count == 0) break;
                after = batch[^1].UserId;

                var requests = new List<NotificationRequest>(batch.Count);
                foreach (var row in batch)
                {
                    var history = new StreakHistory(row.CurrentStreak, row.LongestStreak, row.LastReadDate, row.LastFreezeDate, []);
                    var status = Streaks.StatusOn(history, today);
                    if (status.Current < 1 || status.ReadToday) continue;

                    requests.Add(new NotificationRequest(row.UserId, NotificationTypes.StreakReminder)
                    {
                        DedupeKey = key,
                        Data = new NotificationData { StreakDays = status.Current },
                    });
                }
                written += (await writer.WriteAsync(requests, cancellationToken, utcNow)).Count(id => id is not null);

                if (batch.Count < BatchSize) break;
            }
        }

        if (written > 0) LogRun(logger, written);
        return written;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Streak reminders: {Written} written")]
    private static partial void LogRun(ILogger logger, int written);
}
