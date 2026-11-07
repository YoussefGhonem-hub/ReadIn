using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Notifications;

/// <summary>One notification to write (SPEC F17).</summary>
/// <param name="UserId">The recipient.</param>
/// <param name="Type">One of <see cref="NotificationTypes"/>.</param>
public sealed record NotificationRequest(Guid UserId, string Type)
{
    /// <summary>Who caused it; never the recipient (nobody is notified about themselves).</summary>
    public Guid? ActorId { get; init; }

    /// <summary>When the actor's event occurred: stable across outbox retries, so a redelivered event changes nothing.</summary>
    public DateTime? ActorAt { get; init; }

    /// <summary>Aggregates with an unread entry of the same key that moved in the last 24 hours.</summary>
    public string? GroupKey { get; init; }

    /// <summary>Writes at most one entry per user and key, ever.</summary>
    public string? DedupeKey { get; init; }

    public Guid? ArticleId { get; init; }
    public Guid? CommentId { get; init; }
    public NotificationData Data { get; init; } = NotificationData.Empty;

    /// <summary>
    /// The same actor again moves the entry up (a second comment). False for follows: following, unfollowing and
    /// following again the same day is not news.
    /// </summary>
    public bool RepeatsCount { get; init; } = true;

    /// <summary>The caller sends the push itself (the daily article): the push job leaves the entry alone.</summary>
    public bool PushedByCaller { get; init; }

    /// <summary>
    /// The entry of <see cref="GroupKey"/> counts the actor's articles instead of its actors (the official account's day
    /// entry, <see cref="OfficialArticles"/>): <see cref="ArticleId"/> joins the unread entry once, in
    /// <c>data.articleIds</c>, and the entry shows the newest article. An article already in an entry of the group changes
    /// nothing, so a retried event is a no-op.
    /// </summary>
    public bool GroupsArticles { get; init; }

    /// <summary>The push waits this long after the write, so a burst of activity is one push; quiet hours still apply.</summary>
    public TimeSpan PushDelay { get; init; }

    /// <summary>
    /// Written and pushed whatever the type's mode and the recipient's quiet hours: a test announcement its author sends
    /// to themselves (F23). Mark its data <see cref="NotificationData.IsTest"/> so the push job doesn't hold it either.
    /// </summary>
    public bool Forced { get; init; }

    /// <summary>
    /// Groups with an unread entry of <see cref="GroupKey"/> without an actor (a support reply, F35: support stays anonymous):
    /// the entry moves up with this request's data. <see cref="NotificationData.SourceKey"/> identifies the activity, so a
    /// redelivered event changes nothing.
    /// </summary>
    public bool GroupsWithoutActor { get; init; }
}

/// <summary>
/// Writes notification entries for outbox handlers and jobs (SPEC F17). It never pushes: entries whose type the user has
/// on <see cref="NotificationMode.All"/> are left Pending for the push job (from the end of their quiet hours), then the
/// job is signalled and the recipients' unread counts are published under <c>/live/users/{id}</c>.
/// <list type="bullet">
/// <item>Nobody is notified about their own action; system, suspended and deleted accounts get nothing.</item>
/// <item>Nothing comes from a writer the recipient muted (F28): the request is dropped, so no entry and no actor.</item>
/// <item><see cref="NotificationMode.Off"/> writes nothing; <see cref="NotificationMode.InApp"/> writes the entry without a push.</item>
/// <item>Idempotent: a dedupe key is written once per user, and an actor already in an aggregated entry with the same
/// activity changes nothing, so the outbox's at-least-once delivery never duplicates anything.</item>
/// </list>
/// </summary>
public sealed class NotificationWriter(
    IAppDbContext db,
    NotificationBadge badge,
    INotificationPushSignal pushSignal,
    TimeProvider clock)
{
    private sealed record Recipient(Guid Id, string TimeZone, bool QuietEnabled, TimeOnly QuietStart, TimeOnly QuietEnd);

    public async Task<Guid?> WriteAsync(NotificationRequest request, CancellationToken cancellationToken) =>
        (await WriteAsync([request], cancellationToken))[0];

    /// <param name="utcNow">The time to write at (jobs pass their run time); the clock's time when null.</param>
    /// <returns>Per request, the entry it wrote, joined or found (by its dedupe key); null when nothing was written.</returns>
    public async Task<IReadOnlyList<Guid?>> WriteAsync(
        IReadOnlyList<NotificationRequest> requests, CancellationToken cancellationToken, DateTime? utcNow = null)
    {
        if (requests.Count == 0) return [];
        var now = utcNow ?? clock.GetUtcNow().UtcDateTime;

        try
        {
            return await WriteOnceAsync(requests, now, cancellationToken);
        }
        catch (DbUpdateException)
        {
            // A concurrent write took a dedupe key or an actor row first (two outbox runs on one event): start over, and
            // this time the rows written meanwhile are found.
            return await WriteOnceAsync(requests, now, cancellationToken);
        }
    }

    private async Task<IReadOnlyList<Guid?>> WriteOnceAsync(IReadOnlyList<NotificationRequest> requests, DateTime now, CancellationToken ct)
    {
        var results = new Guid?[requests.Count];
        var userIds = requests.Select(r => r.UserId).Distinct().ToList();
        var types = requests.Select(r => r.Type).Distinct().ToList();

        var recipients = await db.Users.AsNoTracking()
            .Where(u => userIds.Contains(u.Id) && !u.IsSystemAccount && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)))
            .Select(u => new Recipient(u.Id, u.TimeZone, u.QuietHoursEnabled, u.QuietHoursStart, u.QuietHoursEnd))
            .ToDictionaryAsync(u => u.Id, ct);
        if (recipients.Count == 0) return results;

        var modes = (await db.UserNotificationSettings.AsNoTracking()
                .Where(s => userIds.Contains(s.UserId) && types.Contains(s.Type))
                .Select(s => new { s.UserId, s.Type, s.Mode })
                .ToListAsync(ct))
            .ToDictionary(s => (s.UserId, s.Type), s => s.Mode);

        // F28: a muted writer's activity tells the recipient nothing, and joins no aggregated entry of theirs.
        var actorIds = requests.Where(r => r.ActorId is not null).Select(r => r.ActorId!.Value).Distinct().ToList();
        var muted = actorIds.Count == 0
            ? []
            : (await db.UserMutes.AsNoTracking()
                    .Where(m => userIds.Contains(m.MuterId) && actorIds.Contains(m.MutedUserId))
                    .Select(m => new { m.MuterId, m.MutedUserId })
                    .ToListAsync(ct))
                .Select(m => (m.MuterId, m.MutedUserId))
                .ToHashSet();

        var keys = requests.Where(r => r.DedupeKey is not null).Select(r => r.DedupeKey!).Distinct().ToList();
        var existing = keys.Count == 0
            ? []
            : (await db.Notifications.AsNoTracking()
                    .Where(n => userIds.Contains(n.UserId) && n.DedupeKey != null && keys.Contains(n.DedupeKey))
                    .Select(n => new { n.UserId, n.DedupeKey, n.Id })
                    .ToListAsync(ct))
                .ToDictionary(n => (n.UserId, n.DedupeKey!), n => n.Id);

        // Entries that count articles (the official account's day entries): every entry of their groups, in one query.
        var articleGroups = await LoadArticleGroupsAsync(requests, ct);

        var touched = new List<Notification>();
        var created = new Dictionary<(Guid, string), Notification>();
        for (var i = 0; i < requests.Count; i++)
        {
            var request = requests[i];
            if (request.ActorId == request.UserId || !recipients.TryGetValue(request.UserId, out var recipient)) continue;
            if (request.ActorId is { } actor && muted.Contains((request.UserId, actor))) continue;

            var mode = NotificationTypes.IsConfigurable(request.Type) && !request.Forced
                ? modes.GetValueOrDefault((request.UserId, request.Type), NotificationMode.All)
                : NotificationMode.All;
            if (mode == NotificationMode.Off) continue;

            if (request.DedupeKey is { } key)
            {
                if (existing.TryGetValue((request.UserId, key), out var found)) { results[i] = found; continue; }
                if (created.TryGetValue((request.UserId, key), out var twin)) { results[i] = twin.Id; continue; }
            }

            DateTime? pushAfter = request.Forced
                ? now
                : mode == NotificationMode.All && !request.PushedByCaller
                ? NotificationSchedule.PushAfter(request.Type, now + request.PushDelay, recipient.TimeZone,
                    NotificationSchedule.QuietHoursOf(recipient.QuietEnabled, recipient.QuietStart, recipient.QuietEnd))
                : null;

            if (request is { GroupsArticles: true, GroupKey: { } articleGroup, ActorId: { } author, ArticleId: { } articleId })
            {
                var entries = articleGroups.TryGetValue((request.UserId, articleGroup), out var list) ? list : articleGroups[(request.UserId, articleGroup)] = [];
                if (entries.FirstOrDefault(e => NotificationData.Parse(e.Data).ArticleIds?.Contains(articleId) == true) is { } holder)
                {
                    results[i] = holder.Id; // a retried event: the article is in the group already
                    continue;
                }

                if (entries.Where(e => e.CanAggregate(now)).OrderByDescending(e => e.UpdatedAt).FirstOrDefault() is { } open)
                {
                    var data = NotificationData.Parse(open.Data);
                    open.AddArticle(author, request.ActorAt ?? now, articleId,
                        (data with { ArticleIds = [.. data.ArticleIds ?? [], articleId] }).Serialize(), now, pushAfter);
                    if (!touched.Contains(open)) touched.Add(open);
                    results[i] = open.Id;
                    continue;
                }

                var first = Notification.Create(
                    request.UserId,
                    request.Type,
                    now,
                    pushAfter,
                    articleGroup,
                    articleId: articleId,
                    data: (request.Data with { ArticleIds = [articleId] }).Serialize(),
                    actorId: author,
                    actorAt: request.ActorAt ?? now);
                db.Notifications.Add(first);
                touched.Add(first);
                entries.Add(first);
                results[i] = first.Id;
                continue;
            }

            if (request is { GroupsWithoutActor: true, GroupKey: { } plainGroup }
                && await RefreshGroupAsync(request, plainGroup, now, pushAfter, ct) is { } refreshed)
            {
                var entry = refreshed.Entry;
                results[i] = entry.Id;
                if (touched.Contains(entry)) continue;
                if (refreshed.Changed) touched.Add(entry);
                else Forget([entry]);
                continue;
            }

            if (request.GroupKey is { } group && request.ActorId is { } actorId
                && await AggregateIntoAsync(request, group, actorId, now, pushAfter, ct) is { } joined)
            {
                var entry = joined.Entry;
                results[i] = entry.Id;
                if (touched.Contains(entry)) continue;
                if (joined.Changed) touched.Add(entry);
                else Forget([entry]); // nothing to save: nothing stays tracked
                continue;
            }

            var notification = Notification.Create(
                request.UserId,
                request.Type,
                now,
                pushAfter,
                request.GroupKey,
                request.DedupeKey,
                request.ArticleId,
                request.CommentId,
                request.Data.Serialize(),
                request.ActorId,
                request.ActorAt ?? now);
            db.Notifications.Add(notification);
            touched.Add(notification);
            results[i] = notification.Id;
            if (request.DedupeKey is { } newKey) created[(request.UserId, newKey)] = notification;
        }

        // Entries loaded for an article group that didn't change: nothing to save, nothing stays tracked.
        Forget(articleGroups.Values.SelectMany(entries => entries).Except(touched));
        if (touched.Count == 0) return results;

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            Forget(touched);
            throw;
        }
        // The context may be the outbox's, shared by the next events: nothing stays tracked.
        Forget(touched);

        await badge.PublishAsync(touched.Select(n => n.UserId), ct);
        if (touched.Any(n => n.PushStatus == NotificationPushStatus.Pending && n.PushAfter <= now))
            await pushSignal.NotifyAsync(ct);
        return results;
    }

    /// <summary>
    /// Every entry (read or not) of the groups that <see cref="NotificationRequest.GroupsArticles"/> requests write to, by
    /// recipient and group, tracked with their actors. A group is one day of one account, so it holds a few entries at most.
    /// </summary>
    private async Task<Dictionary<(Guid UserId, string Group), List<Notification>>> LoadArticleGroupsAsync(
        IReadOnlyList<NotificationRequest> requests, CancellationToken ct)
    {
        var grouped = requests.Where(r => r is { GroupsArticles: true, GroupKey: not null }).ToList();
        if (grouped.Count == 0) return [];

        var userIds = grouped.Select(r => r.UserId).Distinct().ToList();
        var groups = grouped.Select(r => r.GroupKey!).Distinct().ToList();
        var types = grouped.Select(r => r.Type).Distinct().ToList();
        var entries = await db.Notifications
            .Include(n => n.Actors)
            .Where(n => userIds.Contains(n.UserId) && types.Contains(n.Type) && n.GroupKey != null && groups.Contains(n.GroupKey))
            .ToListAsync(ct);
        return entries
            .GroupBy(n => (n.UserId, n.GroupKey!))
            .ToDictionary(g => g.Key, g => g.ToList());
    }

    /// <summary>
    /// The unread entry of the group that moved within the window, with the actor added (or moved up). Null when there is
    /// none; <c>Changed</c> is false for a redelivered or repeated activity that changes nothing.
    /// </summary>
    private async Task<(Notification Entry, bool Changed)?> AggregateIntoAsync(
        NotificationRequest request, string group, Guid actorId, DateTime now, DateTime? pushAfter, CancellationToken ct)
    {
        var since = now - Notification.AggregationWindow;
        var entry = await db.Notifications
            .Include(n => n.Actors.Where(a => a.ActorId == actorId))
            .Where(n => n.UserId == request.UserId && n.Type == request.Type && n.GroupKey == group && n.ReadAt == null && n.UpdatedAt >= since)
            .OrderByDescending(n => n.UpdatedAt)
            .FirstOrDefaultAsync(ct);
        if (entry is null) return null;

        var changed = entry.AddActivity(actorId, request.ActorAt ?? now, request.CommentId, request.RepeatsCount, now, pushAfter);
        return (entry, changed);
    }

    /// <summary>
    /// For <see cref="NotificationRequest.GroupsWithoutActor"/>: the entry of the group that already told this activity (no
    /// change), else the unread one that moved within the window, refreshed with the request's data. Null when there is none.
    /// </summary>
    private async Task<(Notification Entry, bool Changed)?> RefreshGroupAsync(
        NotificationRequest request, string group, DateTime now, DateTime? pushAfter, CancellationToken ct)
    {
        var entries = await db.Notifications
            .Where(n => n.UserId == request.UserId && n.Type == request.Type && n.GroupKey == group)
            .OrderByDescending(n => n.UpdatedAt)
            .ToListAsync(ct);
        var source = request.Data.SourceKey;
        var told = source is null ? null : entries.FirstOrDefault(e => NotificationData.Parse(e.Data).SourceKey == source);
        var open = told ?? entries.FirstOrDefault(e => e.CanAggregate(now));
        Forget(entries.Where(e => e != open));
        if (open is null) return null;
        if (told is not null) return (told, false);

        open.Refresh(request.Data.Serialize(), now, pushAfter);
        return (open, true);
    }

    private void Forget(IEnumerable<Notification> notifications)
    {
        foreach (var notification in notifications)
        {
            foreach (var actor in notification.Actors) db.NotificationActors.Entry(actor).State = EntityState.Detached;
            db.Notifications.Entry(notification).State = EntityState.Detached;
        }
    }
}
