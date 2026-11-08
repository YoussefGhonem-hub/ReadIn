using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Notifications;

/// <summary>
/// The notification push job (SPEC F17, §21.1), run every minute by Hangfire and right after new pushes are written.
/// It sends the Pending entries that are due, each to every device of its user, with the title and body in the user's UI
/// language and the entry's group (or type) as the collapse key, so a newer push of the same group replaces the older one.
/// <list type="bullet">
/// <item>Checked again when sending: an entry older than 24 hours (4 for the streak reminder), a type now in-app only or
/// off, a suspended account, a comment or article gone since, an acknowledged moderation notice, or a user without
/// devices is skipped; quiet hours that started since push it to their end (security alerts ignore them).</item>
/// <item>Tokens FCM reports as invalid are deleted; other failures are retried, up to <see cref="Notification.MaxPushAttempts"/>
/// sends in all.</item>
/// <item>Batched: <see cref="BatchSize"/> entries at a time, their users, devices, actors and content loaded once per batch,
/// one FCM call per batch.</item>
/// </list>
/// </summary>
public sealed partial class NotificationPusher(IAppDbContext db, IPushSender pushSender, ILogger<NotificationPusher> logger)
{
    internal const int BatchSize = 200;

    public static readonly TimeSpan MaxAge = TimeSpan.FromHours(24);

    /// <summary>The 20:00 reminder is about today: after 4 hours it would arrive after the day is over.</summary>
    public static readonly TimeSpan StreakReminderMaxAge = TimeSpan.FromHours(4);

    private static readonly TimeSpan MinTimeToLive = TimeSpan.FromMinutes(15);

    private sealed record UserInfo(
        Guid Id, string UiLanguage, string ArticleLanguagePref, string TimeZone, string Username, bool QuietEnabled, TimeOnly QuietStart,
        TimeOnly QuietEnd, List<string> Tokens);

    private sealed record TranslationInfo(string Language, string Title, bool IsSource);

    private sealed record ArticleInfo(Guid Id, string Slug, bool IsVisible, List<TranslationInfo> Translations);

    private sealed record NoticeInfo(Guid Id, string? Kind, string? Note, string? Label, bool Acknowledged);

    private sealed record Context(
        Dictionary<Guid, UserInfo> Users,
        Dictionary<(Guid UserId, string Type), NotificationMode> Modes,
        Dictionary<Guid, (int Count, string? Name, string? Username)> Actors,
        Dictionary<Guid, ArticleInfo> Articles,
        Dictionary<Guid, string> Comments,
        Dictionary<Guid, NoticeInfo> Notices,
        HashSet<Guid> Tickets);

    public static TimeSpan MaxAgeOf(string type) => type == NotificationTypes.StreakReminder ? StreakReminderMaxAge : MaxAge;

    /// <summary>The wait before the next try after a failed send: 1 minute, then 5.</summary>
    public static TimeSpan RetryDelay(int attempts) => attempts <= 1 ? TimeSpan.FromMinutes(1) : TimeSpan.FromMinutes(5);

    public async Task<NotificationPushRunResult> RunAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        var result = new NotificationPushRunResult();
        var handled = new HashSet<Guid>();
        while (true)
        {
            // Served by the filtered (PushStatus, PushAfter) index. Every entry handled leaves it or moves past now.
            var batch = (await db.Notifications
                    .Where(n => n.PushStatus == NotificationPushStatus.Pending && n.PushAfter <= utcNow)
                    .OrderBy(n => n.PushAfter)
                    .ThenBy(n => n.Id)
                    .Take(BatchSize)
                    .ToListAsync(cancellationToken))
                .Where(n => handled.Add(n.Id))
                .ToList();
            if (batch.Count == 0) break;

            var unreachable = await PushBatchAsync(batch, utcNow, result, cancellationToken);
            foreach (var notification in batch) db.Notifications.Entry(notification).State = EntityState.Detached;
            if (unreachable) break;
        }

        if (result.Sent + result.Skipped + result.Deferred + result.Retrying + result.Failed > 0)
            LogRun(logger, result.Sent, result.Skipped, result.Deferred, result.Retrying, result.Failed, result.InvalidTokens);
        return result;
    }

    /// <returns>true when FCM was unreachable: the run stops, and the entries are retried later.</returns>
    private async Task<bool> PushBatchAsync(List<Notification> batch, DateTime utcNow, NotificationPushRunResult result, CancellationToken ct)
    {
        var context = await LoadAsync(batch, utcNow, ct);
        var sends = new List<(Notification Entry, PushNotification Push)>();
        foreach (var entry in batch)
        {
            var push = Prepare(entry, context, utcNow, result);
            if (push is not null) sends.Add((entry, push));
        }

        if (sends.Count == 0)
        {
            await db.SaveChangesAsync(ct);
            return false;
        }

        IReadOnlyList<PushOutcome> outcomes;
        try
        {
            outcomes = await pushSender.SendAsync([.. sends.Select(s => s.Push)], ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogUnreachable(logger, ex, sends.Count);
            foreach (var (entry, _) in sends) RecordFailure(entry, utcNow, result);
            await db.SaveChangesAsync(CancellationToken.None);
            return true;
        }

        var invalidTokens = new HashSet<string>(StringComparer.Ordinal);
        for (var i = 0; i < sends.Count; i++)
        {
            var (entry, _) = sends[i];
            var outcome = outcomes[i];
            invalidTokens.UnionWith(outcome.InvalidTokens);
            if (outcome.Sent > 0)
            {
                entry.MarkPushed(utcNow);
                result.Sent++;
            }
            else if (outcome.ShouldRetry)
            {
                RecordFailure(entry, utcNow, result);
            }
            else
            {
                // Every device of the user is gone.
                entry.SkipPush();
                result.Skipped++;
            }
        }
        await db.SaveChangesAsync(ct);

        if (invalidTokens.Count > 0)
        {
            // SPEC §21.1: tokens FCM reports as unregistered or invalid are removed.
            var stale = invalidTokens.ToList();
            result.InvalidTokens += await db.Users.IgnoreQueryFilters()
                .SelectMany(u => u.Devices)
                .Where(d => stale.Contains(d.Token))
                .ExecuteDeleteAsync(ct);
        }
        return false;
    }

    private static void RecordFailure(Notification entry, DateTime utcNow, NotificationPushRunResult result)
    {
        if (entry.RecordPushFailure(utcNow + RetryDelay(entry.PushAttempts + 1))) result.Retrying++;
        else result.Failed++;
    }

    /// <summary>The push for <paramref name="entry"/>, or null after skipping or deferring it.</summary>
    private static PushNotification? Prepare(Notification entry, Context context, DateTime utcNow, NotificationPushRunResult result)
    {
        var age = utcNow - entry.UpdatedAt;
        if (age > MaxAgeOf(entry.Type) || !context.Users.TryGetValue(entry.UserId, out var user)) return Skip();

        var data = NotificationData.Parse(entry.Data);
        // A test announcement (F23) goes to its author at once, whatever their mode and quiet hours.
        var forced = data.IsTest == true;

        if (!forced && NotificationTypes.IsConfigurable(entry.Type)
            && context.Modes.GetValueOrDefault((entry.UserId, entry.Type), NotificationMode.All) != NotificationMode.All)
            return Skip();

        var after = forced
            ? utcNow
            : NotificationSchedule.PushAfter(entry.Type, utcNow, user.TimeZone,
                NotificationSchedule.QuietHoursOf(user.QuietEnabled, user.QuietStart, user.QuietEnd));
        if (after > utcNow)
        {
            entry.DeferPush(after);
            result.Deferred++;
            return null;
        }

        if (user.Tokens.Count == 0) return Skip();

        var article = entry.ArticleId is { } articleId ? context.Articles.GetValueOrDefault(articleId) : null;
        string? comment = null;
        NoticeInfo? notice = null;
        switch (entry.Type)
        {
            case NotificationTypes.Mention when entry.CommentId is null:
                // A mention in an article: the article is still readable.
                if (article is not { IsVisible: true }) return Skip();
                break;
            case NotificationTypes.ArticleComment or NotificationTypes.CommentReply or NotificationTypes.Mention:
                if (article is not { IsVisible: true } || entry.CommentId is not { } commentId || !context.Comments.TryGetValue(commentId, out comment))
                    return Skip();
                break;
            case NotificationTypes.ReactionsMilestone or NotificationTypes.FollowedWriterArticle or NotificationTypes.DailyArticle
                or NotificationTypes.ArticleReposted:
                if (article is not { IsVisible: true }) return Skip();
                break;
            case NotificationTypes.Announcement when entry.ArticleId is not null:
                // An announcement that links to an article: the article is still readable (F23).
                if (article is not { IsVisible: true }) return Skip();
                break;
            case NotificationTypes.SupportReply or NotificationTypes.SupportTicket:
                // The ticket is still there (F35): a deleted account or the retention job took it.
                if (data.TicketId is not { } ticketId || !context.Tickets.Contains(ticketId)) return Skip();
                break;
            case NotificationTypes.ModerationNotice:
                if (data.NoticeId is not { } noticeId || !context.Notices.TryGetValue(noticeId, out notice) || notice.Acknowledged)
                    return Skip();
                break;
        }

        var actor = context.Actors.GetValueOrDefault(entry.Id);
        // Every follower deleted their account since: the center drops the entry too.
        if (entry.Type is NotificationTypes.NewFollower or NotificationTypes.ArticleReposted && actor.Count == 0) return Skip();

        var english = user.UiLanguage == UiLanguages.English;
        // The version the user reads: the preferred language when it exists, otherwise the source (as on cards).
        var translation = article?.Translations.FirstOrDefault(t => t.Language == user.ArticleLanguagePref)
            ?? article?.Translations.FirstOrDefault(t => t.IsSource);
        var (title, body) = NotificationTexts.For(entry.Type, english, new NotificationTexts.Input(
            actor.Name, actor.Count, translation?.Title, comment is null ? null : NotificationExcerpt.Of(comment), data, notice?.Note,
            notice?.Label));

        var link = NotificationLinks.For(
            entry.Type, actor.Count, actor.Username, user.Username, article?.Slug, entry.CommentId, OfficialArticles.CountOf(data),
            data.PathSlug, data.TicketId, data.TargetType, data.TargetId);
        var payload = new Dictionary<string, string>
        {
            ["type"] = entry.Type,
            ["notificationId"] = entry.Id.ToString(),
            ["link"] = link,
        };
        // Article links say which version the text came from, as the daily article does; the web opens /{lang}/a/{slug}.
        if (article is not null && translation is not null && link.StartsWith(NotificationLinks.Article(article.Slug), StringComparison.Ordinal))
            payload["lang"] = translation.Language == ArticleLanguages.English ? UiLanguages.English : UiLanguages.Arabic;
        if (data.AnnouncementId is { } announcementId) payload["announcementId"] = announcementId.ToString();
        if (data.TicketId is { } pushTicketId) payload["ticketId"] = pushTicketId.ToString();
        // report_new (F22): the case it opens.
        if (entry.Type == NotificationTypes.ReportNew && data.TargetType is { } reportType && data.TargetId is { } reportTarget)
        {
            payload["targetType"] = reportType;
            payload["targetId"] = reportTarget.ToString();
        }
        if (notice is not null)
        {
            // As F22's push had them, so clients that refresh their notices on this push keep working.
            payload["noticeId"] = notice.Id.ToString();
            if (notice.Kind is not null) payload["kind"] = notice.Kind;
            if (article is not null)
            {
                payload["articleId"] = article.Id.ToString();
                payload["slug"] = article.Slug;
            }
        }

        var timeToLive = MaxAgeOf(entry.Type) - age;
        return new PushNotification(
            [.. user.Tokens.Distinct(StringComparer.Ordinal)],
            title,
            body,
            payload,
            entry.GroupKey ?? entry.Type,
            timeToLive < MinTimeToLive ? MinTimeToLive : timeToLive);

        PushNotification? Skip()
        {
            entry.SkipPush();
            result.Skipped++;
            return null;
        }
    }

    private async Task<Context> LoadAsync(List<Notification> batch, DateTime now, CancellationToken ct)
    {
        var ids = batch.Select(n => n.Id).ToList();
        var userIds = batch.Select(n => n.UserId).Distinct().ToList();

        // Active accounts only: suspended, system and deleted ones get no push.
        var users = await db.Users.AsNoTracking()
            .Where(u => userIds.Contains(u.Id) && !u.IsSystemAccount && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)))
            .Select(u => new UserInfo(u.Id, u.UiLanguage, u.ArticleLanguagePref, u.TimeZone, u.Username, u.QuietHoursEnabled, u.QuietHoursStart,
                u.QuietHoursEnd, u.Devices.Select(d => d.Token).ToList()))
            .ToDictionaryAsync(u => u.Id, ct);

        var modes = (await db.UserNotificationSettings.AsNoTracking()
                .Where(s => userIds.Contains(s.UserId))
                .Select(s => new { s.UserId, s.Type, s.Mode })
                .ToListAsync(ct))
            .ToDictionary(s => (s.UserId, s.Type), s => s.Mode);

        var actorRows = await db.Notifications.AsNoTracking()
            .Where(n => ids.Contains(n.Id))
            .Select(n => new
            {
                n.Id,
                Count = n.Actors.Count(),
                Latest = n.Actors.OrderByDescending(a => a.At).ThenByDescending(a => a.ActorId).Select(a => (Guid?)a.ActorId).FirstOrDefault(),
            })
            .ToListAsync(ct);
        var actorIds = actorRows.Where(a => a.Latest != null).Select(a => a.Latest!.Value).Distinct().ToList();
        var actorUsers = await db.Users.AsNoTracking()
            .Where(u => actorIds.Contains(u.Id))
            .Select(u => new { u.Id, u.DisplayName, u.Username })
            .ToDictionaryAsync(u => u.Id, ct);
        var actors = actorRows.ToDictionary(
            a => a.Id,
            a => a.Latest is { } latest && actorUsers.TryGetValue(latest, out var who)
                ? (a.Count, (string?)who.DisplayName, (string?)who.Username)
                : (a.Count, null, null));

        var articleIds = batch.Where(n => n.ArticleId != null).Select(n => n.ArticleId!.Value).Distinct().ToList();
        var articles = articleIds.Count == 0
            ? []
            : (await db.Articles.AsNoTracking()
                    .Where(a => articleIds.Contains(a.Id))
                    .Select(a => new
                    {
                        a.Id,
                        a.Slug,
                        IsVisible = a.Status == ArticleStatus.Published && a.Field.IsEnabled && a.HiddenAt == null,
                        Translations = a.Translations.Select(t => new { t.Language, t.Title, t.IsSource }).ToList(),
                    })
                    .ToListAsync(ct))
                .ToDictionary(a => a.Id, a => new ArticleInfo(a.Id, a.Slug, a.IsVisible, [.. a.Translations.Select(t => new TranslationInfo(t.Language, t.Title, t.IsSource))]));

        var commentIds = batch.Where(n => n.CommentId != null).Select(n => n.CommentId!.Value).Distinct().ToList();
        var comments = commentIds.Count == 0
            ? []
            : await db.Comments.AsNoTracking()
                .Where(c => commentIds.Contains(c.Id) && c.HiddenAt == null)
                .ToDictionaryAsync(c => c.Id, c => c.Body, ct);

        var noticeIds = batch.Where(n => n.Type == NotificationTypes.ModerationNotice)
            .Select(n => NotificationData.Parse(n.Data).NoticeId)
            .Where(id => id != null)
            .Select(id => id!.Value)
            .ToList();
        var notices = noticeIds.Count == 0
            ? []
            : await db.ModerationActions.AsNoTracking()
                .Where(m => noticeIds.Contains(m.Id))
                .Select(m => new NoticeInfo(m.Id, m.NoticeKind, m.Note, m.TargetLabel, m.AcknowledgedAt != null))
                .ToDictionaryAsync(m => m.Id, ct);

        var ticketIds = batch.Where(n => n.Type is NotificationTypes.SupportReply or NotificationTypes.SupportTicket)
            .Select(n => NotificationData.Parse(n.Data).TicketId)
            .Where(id => id != null)
            .Select(id => id!.Value)
            .Distinct()
            .ToList();
        var tickets = ticketIds.Count == 0
            ? []
            : (await db.SupportTickets.AsNoTracking().Where(t => ticketIds.Contains(t.Id)).Select(t => t.Id).ToListAsync(ct)).ToHashSet();

        return new Context(users, modes, actors, articles, comments, notices, tickets);
    }

    [LoggerMessage(Level = LogLevel.Information,
        Message = "Notification pushes: {Sent} sent, {Skipped} skipped, {Deferred} waiting for quiet hours to end, {Retrying} to retry, {Failed} failed, {InvalidTokens} invalid device tokens removed")]
    private static partial void LogRun(ILogger logger, int sent, int skipped, int deferred, int retrying, int failed, int invalidTokens);

    [LoggerMessage(Level = LogLevel.Warning, Message = "FCM was unreachable for {Count} notification pushes; they are retried later")]
    private static partial void LogUnreachable(ILogger logger, Exception exception, int count);
}

/// <summary>What one run of <see cref="NotificationPusher"/> did.</summary>
public sealed class NotificationPushRunResult
{
    public int Sent { get; internal set; }
    public int Skipped { get; internal set; }

    /// <summary>Moved to the end of the user's quiet hours.</summary>
    public int Deferred { get; internal set; }

    public int Retrying { get; internal set; }
    public int Failed { get; internal set; }
    public int InvalidTokens { get; internal set; }
}
