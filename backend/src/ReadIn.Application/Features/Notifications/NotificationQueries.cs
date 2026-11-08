using System.Globalization;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Notifications;

/// <summary>GET /me/notifications: the center, latest activity first (SPEC F17). Keyset paging over (UpdatedAt, Id).</summary>
[Authenticated]
public sealed record GetNotificationsQuery(string? Cursor, int Limit = 20) : IQuery<Result<CursorPage<NotificationDto>>>;

/// <summary>GET /me/notifications/unread-count: the badge, for when the Realtime Database isn't there.</summary>
[Authenticated]
public sealed record GetUnreadNotificationsQuery : IQuery<Result<UnreadNotificationsDto>>;

/// <summary>GET /me/notification-settings: quiet hours and every configurable type's mode.</summary>
[Authenticated]
public sealed record GetNotificationSettingsQuery : IQuery<Result<NotificationSettingsDto>>;

internal sealed class GetNotificationsQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
    : IQueryHandler<GetNotificationsQuery, Result<CursorPage<NotificationDto>>>
{
    public async ValueTask<Result<CursorPage<NotificationDto>>> Handle(GetNotificationsQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var limit = Math.Clamp(query.Limit, 1, 50);
        var viewer = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.Username, u.ArticleLanguagePref })
            .FirstAsync(cancellationToken);

        // Served by the (UserId, UpdatedAt DESC, Id DESC) index.
        var rows = db.Notifications.AsNoTracking().Where(n => n.UserId == userId).InCenter(db);
        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            rows = rows.Where(n => n.UpdatedAt < cursor.Timestamp || (n.UpdatedAt == cursor.Timestamp && n.Id.CompareTo(cursor.Id) < 0));
        }

        var page = await rows
            .OrderByDescending(n => n.UpdatedAt)
            .ThenByDescending(n => n.Id)
            .Take(limit + 1)
            .Select(n => new
            {
                n.Id,
                n.Type,
                n.CreatedAt,
                n.UpdatedAt,
                n.ReadAt,
                n.ArticleId,
                n.CommentId,
                n.Data,
                ActorCount = n.Actors.Count(),
                LatestActorId = n.Actors.OrderByDescending(a => a.At).ThenByDescending(a => a.ActorId).Select(a => (Guid?)a.ActorId).FirstOrDefault(),
            })
            .ToListAsync(cancellationToken);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].UpdatedAt, page[^1].Id).Encode();
        }
        if (page.Count == 0) return new CursorPage<NotificationDto>([], next);

        var actorIds = page.Where(p => p.LatestActorId != null).Select(p => p.LatestActorId!.Value).Distinct().ToList();
        var actors = actorIds.Count == 0
            ? []
            : await db.Users.AsNoTracking()
                .Where(u => actorIds.Contains(u.Id))
                .Select(u => new NotificationActorDto(u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified))
                .ToDictionaryAsync(u => u.Id, cancellationToken);

        var articleIds = page.Where(p => p.ArticleId != null).Select(p => p.ArticleId!.Value).Distinct().ToList();
        var articles = articleIds.Count == 0
            ? []
            : (await db.Articles.AsNoTracking()
                    .Where(a => articleIds.Contains(a.Id))
                    .Select(a => new { a.Id, a.Slug, Translations = a.Translations.Select(t => new { t.Language, t.Title, t.IsSource }).ToList() })
                    .ToListAsync(cancellationToken))
                .ToDictionary(a => a.Id, a =>
                {
                    // The viewer's article language when that version exists, otherwise the source (as on cards).
                    var translation = a.Translations.FirstOrDefault(t => t.Language == viewer.ArticleLanguagePref)
                        ?? a.Translations.First(t => t.IsSource);
                    return new NotificationArticleDto(a.Id, a.Slug, translation.Title, translation.Language);
                });

        var commentIds = page.Where(p => p.CommentId != null).Select(p => p.CommentId!.Value).Distinct().ToList();
        var comments = commentIds.Count == 0
            ? []
            : await db.Comments.AsNoTracking()
                .Where(c => commentIds.Contains(c.Id))
                .Select(c => new { c.Id, c.ParentId, c.Body })
                .ToDictionaryAsync(c => c.Id, c => new NotificationCommentDto(c.Id, c.ParentId, NotificationExcerpt.Of(c.Body)), cancellationToken);

        return new CursorPage<NotificationDto>(
            [
                .. page.Select(p =>
                {
                    var actor = p.LatestActorId is { } actorId && actors.TryGetValue(actorId, out var found)
                        ? found with { AvatarUrl = storage.ToPublicUrl(found.AvatarUrl) }
                        : null;
                    var article = p.ArticleId is { } articleId ? articles.GetValueOrDefault(articleId) : null;
                    var comment = p.CommentId is { } commentId ? comments.GetValueOrDefault(commentId) : null;
                    var data = NotificationData.Parse(p.Data);
                    return new NotificationDto(
                        p.Id,
                        p.Type,
                        p.CreatedAt,
                        p.UpdatedAt,
                        p.ReadAt != null,
                        actor,
                        p.ActorCount,
                        article,
                        comment,
                        data.ToDto(currentUser.UiLanguage),
                        NotificationLinks.For(
                            p.Type, p.ActorCount, actor?.Username, viewer.Username, article?.Slug, p.CommentId, OfficialArticles.CountOf(data),
                            data.PathSlug, data.TicketId, data.TargetType, data.TargetId));
                }),
            ],
            next);
    }
}

internal sealed class GetUnreadNotificationsQueryHandler(NotificationBadge badge, ICurrentUser currentUser)
    : IQueryHandler<GetUnreadNotificationsQuery, Result<UnreadNotificationsDto>>
{
    public async ValueTask<Result<UnreadNotificationsDto>> Handle(GetUnreadNotificationsQuery query, CancellationToken cancellationToken) =>
        new UnreadNotificationsDto(await badge.CountAsync(currentUser.RequireUserId(), cancellationToken));
}

internal sealed class GetNotificationSettingsQueryHandler(IAppDbContext db, ICurrentUser currentUser)
    : IQueryHandler<GetNotificationSettingsQuery, Result<NotificationSettingsDto>>
{
    public async ValueTask<Result<NotificationSettingsDto>> Handle(GetNotificationSettingsQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var quiet = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.QuietHoursEnabled, u.QuietHoursStart, u.QuietHoursEnd })
            .FirstAsync(cancellationToken);
        var stored = await db.UserNotificationSettings.AsNoTracking()
            .Where(s => s.UserId == userId)
            .ToDictionaryAsync(s => s.Type, s => s.Mode, cancellationToken);

        return new NotificationSettingsDto(
            new QuietHoursDto(quiet.QuietHoursEnabled, Format(quiet.QuietHoursStart), Format(quiet.QuietHoursEnd)),
            // support_ticket (F35) is listed only for those who get it: holders of support.manage.
            NotificationTypes.ConfigurableFor(
                currentUser.Permissions.Contains(Permissions.Support.Manage), currentUser.Permissions.Contains(Permissions.Moderation.Manage))
                .ToDictionary(t => t, t => stored.GetValueOrDefault(t, NotificationMode.All)));
    }

    internal static string Format(TimeOnly time) => time.ToString("HH:mm", CultureInfo.InvariantCulture);
}
