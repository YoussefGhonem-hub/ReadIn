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

        var touched = new List<Notification>();
        var created = new Dictionary<(Guid, string), Notification>();
        for (var i = 0; i < requests.Count; i++)
        {
            var request = requests[i];
            if (request.ActorId == request.UserId || !recipients.TryGetValue(request.UserId, out var recipient)) continue;
            if (request.ActorId is { } actor && muted.Contains((request.UserId, actor))) continue;

            var mode = NotificationTypes.IsConfigurable(request.Type)
                ? modes.GetValueOrDefault((request.UserId, request.Type), NotificationMode.All)
                : NotificationMode.All;
            if (mode == NotificationMode.Off) continue;

            if (request.DedupeKey is { } key)
            {
                if (existing.TryGetValue((request.UserId, key), out var found)) { results[i] = found; continue; }
                if (created.TryGetValue((request.UserId, key), out var twin)) { results[i] = twin.Id; continue; }
            }

            DateTime? pushAfter = mode == NotificationMode.All && !request.PushedByCaller
                ? NotificationSchedule.PushAfter(request.Type, now, recipient.TimeZone,
                    NotificationSchedule.QuietHoursOf(recipient.QuietEnabled, recipient.QuietStart, recipient.QuietEnd))
                : null;

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

    private void Forget(IEnumerable<Notification> notifications)
    {
        foreach (var notification in notifications)
        {
            foreach (var actor in notification.Actors) db.NotificationActors.Entry(actor).State = EntityState.Detached;
            db.Notifications.Entry(notification).State = EntityState.Detached;
        }
    }
}
