using System.Globalization;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Notifications;

/// <summary>POST /me/notifications/seen: the user opened the center, so every entry is seen and the badge is 0 (SPEC F17).</summary>
[Authenticated]
public sealed record MarkNotificationsSeenCommand : ICommand<Result>;

/// <summary>POST /me/notifications/{id}/read: the entry (or its push) was opened. Idempotent.</summary>
[Authenticated]
public sealed record MarkNotificationReadCommand(Guid NotificationId) : ICommand<Result>;

/// <summary>POST /me/notifications/read-all: "mark all read".</summary>
[Authenticated]
public sealed record MarkAllNotificationsReadCommand : ICommand<Result>;

/// <summary>
/// PUT /me/notification-settings: quiet hours and the modes of the types sent (<c>all</c> | <c>inApp</c> | <c>off</c>);
/// types left out keep their mode. Security alerts and moderation notices can't be configured.
/// </summary>
[Authenticated]
public sealed record UpdateNotificationSettingsCommand(QuietHoursRequest? QuietHours, IReadOnlyDictionary<string, string?>? Types)
    : ICommand<Result>;

/// <param name="Start"><c>HH:mm</c>.</param>
/// <param name="End"><c>HH:mm</c>, different from <paramref name="Start"/>.</param>
public sealed record QuietHoursRequest(bool Enabled, string? Start, string? End);

internal sealed class MarkNotificationsSeenCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<MarkNotificationsSeenCommand, Result>
{
    public async ValueTask<Result> Handle(MarkNotificationsSeenCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var now = clock.GetUtcNow().UtcDateTime;
        var changed = await db.Notifications
            .Where(n => n.UserId == userId && n.SeenAt == null)
            .ExecuteUpdateAsync(set => set.SetProperty(n => n.SeenAt, now), cancellationToken);
        if (changed > 0) await NotificationBadgeEvents.RaiseAsync(db, userId, cancellationToken);
        return Result.Success();
    }
}

internal sealed class MarkNotificationReadCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<MarkNotificationReadCommand, Result>
{
    public async ValueTask<Result> Handle(MarkNotificationReadCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var notification = await db.Notifications
            .FirstOrDefaultAsync(n => n.Id == command.NotificationId && n.UserId == userId, cancellationToken);
        if (notification is null) return NotificationErrors.NotFound;

        var wasUnseen = notification.SeenAt is null;
        if (!notification.MarkRead(clock.GetUtcNow().UtcDateTime)) return Result.Success();

        if (wasUnseen) await NotificationBadgeEvents.RaiseAsync(db, userId, cancellationToken, save: false);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}

internal sealed class MarkAllNotificationsReadCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<MarkAllNotificationsReadCommand, Result>
{
    public async ValueTask<Result> Handle(MarkAllNotificationsReadCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var now = clock.GetUtcNow().UtcDateTime;
        var unseen = await db.Notifications.AnyAsync(n => n.UserId == userId && n.SeenAt == null, cancellationToken);
        await db.Notifications
            .Where(n => n.UserId == userId && (n.ReadAt == null || n.SeenAt == null))
            .ExecuteUpdateAsync(set => set
                .SetProperty(n => n.ReadAt, n => n.ReadAt ?? now)
                .SetProperty(n => n.SeenAt, n => n.SeenAt ?? now), cancellationToken);
        if (unseen) await NotificationBadgeEvents.RaiseAsync(db, userId, cancellationToken);
        return Result.Success();
    }
}

internal sealed class UpdateNotificationSettingsCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UpdateNotificationSettingsCommand, Result>
{
    public async ValueTask<Result> Handle(UpdateNotificationSettingsCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var modes = new Dictionary<string, NotificationMode>(StringComparer.Ordinal);
        foreach (var (type, value) in command.Types ?? new Dictionary<string, string?>())
        {
            if (!NotificationTypes.IsConfigurable(type)) return NotificationErrors.TypeInvalid;
            if (!TryParseMode(value, out var mode)) return NotificationErrors.ModeInvalid;
            modes[type] = mode;
        }

        (bool Enabled, TimeOnly Start, TimeOnly End)? quiet = null;
        if (command.QuietHours is { } q)
        {
            if (!TryParseTime(q.Start, out var start) || !TryParseTime(q.End, out var end) || start == end)
                return NotificationErrors.QuietHoursInvalid;
            quiet = (q.Enabled, start, end);
        }

        if (quiet is { } hours)
        {
            var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);
            user.SetQuietHours(hours.Enabled, hours.Start, hours.End);
        }

        if (modes.Count > 0)
        {
            var types = modes.Keys.ToList();
            var stored = await db.UserNotificationSettings
                .Where(s => s.UserId == userId && types.Contains(s.Type))
                .ToDictionaryAsync(s => s.Type, cancellationToken);
            foreach (var (type, mode) in modes)
            {
                var row = stored.GetValueOrDefault(type);
                // Sparse: the default (all) is no row.
                if (mode == NotificationMode.All)
                {
                    if (row is not null) db.UserNotificationSettings.Remove(row);
                }
                else if (row is null)
                {
                    db.UserNotificationSettings.Add(new UserNotificationSetting(userId, type, mode));
                }
                else
                {
                    row.Change(mode);
                }
            }
        }

        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }

    /// <summary><c>all</c> | <c>inApp</c> | <c>off</c>, ignoring case. Numbers are refused.</summary>
    internal static bool TryParseMode(string? value, out NotificationMode mode)
    {
        mode = default;
        foreach (var candidate in Enum.GetValues<NotificationMode>())
        {
            if (!string.Equals(candidate.ToString(), value?.Trim(), StringComparison.OrdinalIgnoreCase)) continue;
            mode = candidate;
            return true;
        }
        return false;
    }

    internal static bool TryParseTime(string? value, out TimeOnly time) =>
        TimeOnly.TryParseExact(value, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out time);
}

internal static class NotificationBadgeEvents
{
    /// <summary>
    /// Raises the "notifications changed" event on the user, so the outbox republishes their badge after the commit.
    /// </summary>
    public static async Task RaiseAsync(IAppDbContext db, Guid userId, CancellationToken ct, bool save = true)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null) return;
        user.NotificationsChanged();
        if (save) await db.SaveChangesAsync(ct);
    }
}
