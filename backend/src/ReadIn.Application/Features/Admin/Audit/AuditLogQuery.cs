using System.Data.SqlTypes;
using System.Globalization;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Admin.Audit;

public sealed record AuditUserDto(Guid Id, string DisplayName, string Username, string? AvatarUrl);

/// <param name="Type"><c>user</c>, <c>article</c>, <c>comment</c>, <c>field</c>, <c>topic</c>, <c>tag</c>, <c>path</c>, <c>announcement</c>, <c>ticket</c>.</param>
/// <param name="Label">The moderation log's label at the time, or what the target is called now; null once it is gone.</param>
public sealed record AuditTargetDto(string Type, Guid Id, string? Label);

/// <param name="Source"><c>audit</c> (AuditLogs) or <c>moderation</c> (ModerationActions).</param>
/// <param name="Action">An audit code (<c>admin.pii_viewed</c>) or a moderation log action (<c>user.suspend</c>).</param>
/// <param name="Actor">Null for a job, an anonymous flow (recovery) or a deleted account.</param>
/// <param name="TargetUser">The account it concerns.</param>
/// <param name="Details">The audit entry's details or the moderator's note; never personal data.</param>
/// <param name="Ip">Only for <c>users.read.pii</c>; never on moderation rows.</param>
public sealed record AuditEntryDto(
    Guid Id,
    string Source,
    string Action,
    AuditUserDto? Actor,
    AuditUserDto? TargetUser,
    AuditTargetDto? Target,
    string? Details,
    string? Ip,
    DateTime CreatedAt);

/// <summary>
/// GET /admin/audit (SPEC F23): <c>AuditLogs</c> and <c>ModerationActions</c> together, newest first, offset pages. The
/// <c>moderation.*</c> audit entries are left out (each repeats a moderation log entry, which has the label and the note).
/// Parameters are text so a bad one is <c>400 validation.failed</c> on that parameter.
/// </summary>
/// <param name="Actor">Who did it (an account id).</param>
/// <param name="Target">Whom it concerns (an account id).</param>
/// <param name="Action">An exact code, or a prefix ending in <c>.</c>; ≤ 64.</param>
/// <param name="Source"><c>audit</c> | <c>moderation</c>; both when omitted.</param>
/// <param name="From">A date (<c>YYYY-MM-DD</c>) in <c>Admin:TimeZone</c>, included.</param>
/// <param name="To">A date, included.</param>
[RequirePermission(Permissions.Audit.Read)]
public sealed record GetAuditLogQuery(
    string? Actor = null,
    string? Target = null,
    string? Action = null,
    string? Source = null,
    string? From = null,
    string? To = null,
    int? Page = null,
    int? PageSize = null) : IQuery<Result<PagedList<AuditEntryDto>>>
{
    public const int MaxActionLength = 64;
}

internal sealed class GetAuditLogQueryHandler(IAppDbContext db, ICurrentUser currentUser, AdminClock clock, IFileStorage storage)
    : IQueryHandler<GetAuditLogQuery, Result<PagedList<AuditEntryDto>>>
{
    public const string AuditSource = "audit";
    public const string ModerationSource = "moderation";
    private const string ModerationAuditPrefix = "moderation.";

    private sealed record Key(string Source, Guid Id, DateTime CreatedAt);

    public async ValueTask<Result<PagedList<AuditEntryDto>>> Handle(GetAuditLogQuery query, CancellationToken ct)
    {
        if (!TryGuid(query.Actor, out var actor)) return AdminErrors.InvalidParameter("actor");
        if (!TryGuid(query.Target, out var target)) return AdminErrors.InvalidParameter("target");
        if (!TryDate(query.From, out var from)) return AdminErrors.InvalidParameter("from");
        if (!TryDate(query.To, out var to)) return AdminErrors.InvalidParameter("to");
        if (query.Source is not (null or "" or AuditSource or ModerationSource)) return AdminErrors.InvalidParameter("source");
        var action = string.IsNullOrWhiteSpace(query.Action) ? null : query.Action.Trim();
        if (action is { Length: > GetAuditLogQuery.MaxActionLength }) return AdminErrors.InvalidParameter("action");

        var (page, pageSize) = AdminPaging.Normalize(query.Page, query.PageSize);
        var (fromUtc, toUtc) = clock.Range(from, to);
        var withAudit = query.Source is null or "" or AuditSource;
        var withModeration = query.Source is null or "" or ModerationSource;

        var audits = db.AuditLogs.AsNoTracking().Where(a => !a.Action.StartsWith(ModerationAuditPrefix));
        var moderation = db.ModerationActions.AsNoTracking().AsQueryable();
        if (actor is { } actorId)
        {
            audits = audits.Where(a => a.ActorId == actorId);
            moderation = moderation.Where(m => m.ModeratorId == actorId);
        }
        if (target is { } targetId)
        {
            audits = audits.Where(a => a.UserId == targetId);
            moderation = moderation.Where(m => m.TargetUserId == targetId);
        }
        if (action is not null)
        {
            if (action.EndsWith('.'))
            {
                audits = audits.Where(a => a.Action.StartsWith(action));
                moderation = moderation.Where(m => m.Action.StartsWith(action));
            }
            else
            {
                audits = audits.Where(a => a.Action == action);
                moderation = moderation.Where(m => m.Action == action);
            }
        }
        if (fromUtc is { } since)
        {
            audits = audits.Where(a => a.CreatedAt >= since);
            moderation = moderation.Where(m => m.CreatedAt >= since);
        }
        if (toUtc is { } until)
        {
            audits = audits.Where(a => a.CreatedAt < until);
            moderation = moderation.Where(m => m.CreatedAt < until);
        }

        // Two tables, one order: the newest (page × size) keys of each, merged, then the page's rows.
        var take = page * pageSize;
        var auditTotal = withAudit ? await audits.CountAsync(ct) : 0;
        var moderationTotal = withModeration ? await moderation.CountAsync(ct) : 0;
        var keys = new List<Key>();
        if (withAudit && auditTotal > 0)
        {
            keys.AddRange((await audits.OrderByDescending(a => a.CreatedAt).ThenByDescending(a => a.Id).Take(take)
                    .Select(a => new { a.Id, a.CreatedAt }).ToListAsync(ct))
                .Select(a => new Key(AuditSource, a.Id, a.CreatedAt)));
        }
        if (withModeration && moderationTotal > 0)
        {
            keys.AddRange((await moderation.OrderByDescending(m => m.CreatedAt).ThenByDescending(m => m.Id).Take(take)
                    .Select(m => new { m.Id, m.CreatedAt }).ToListAsync(ct))
                .Select(m => new Key(ModerationSource, m.Id, m.CreatedAt)));
        }
        var pageKeys = keys
            .OrderByDescending(k => k.CreatedAt)
            .ThenBy(k => k.Source, StringComparer.Ordinal)
            .ThenByDescending(k => new SqlGuid(k.Id)) // SQL Server's uniqueidentifier order, as each table was read
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        var items = await LoadAsync(pageKeys, ct);
        return new PagedList<AuditEntryDto>(items, page, pageSize, auditTotal + moderationTotal);
    }

    private async Task<IReadOnlyList<AuditEntryDto>> LoadAsync(List<Key> keys, CancellationToken ct)
    {
        if (keys.Count == 0) return [];
        var auditIds = keys.Where(k => k.Source == AuditSource).Select(k => k.Id).ToList();
        var moderationIds = keys.Where(k => k.Source == ModerationSource).Select(k => k.Id).ToList();
        var audits = auditIds.Count == 0
            ? []
            : await db.AuditLogs.AsNoTracking().Where(a => auditIds.Contains(a.Id)).ToDictionaryAsync(a => a.Id, ct);
        var moderation = moderationIds.Count == 0
            ? []
            : await db.ModerationActions.AsNoTracking().Where(m => moderationIds.Contains(m.Id)).ToDictionaryAsync(m => m.Id, ct);

        var userIds = audits.Values.SelectMany(a => new[] { a.ActorId, a.UserId })
            .Concat(moderation.Values.SelectMany(m => new[] { m.ModeratorId, m.TargetUserId }))
            .Where(id => id is not null).Select(id => id!.Value).Distinct().ToList();
        var users = userIds.Count == 0
            ? []
            : (await db.Users.AsNoTracking()
                    .Where(u => userIds.Contains(u.Id))
                    .Select(u => new { u.Id, u.DisplayName, u.Username, u.AvatarUrl })
                    .ToListAsync(ct))
                .ToDictionary(u => u.Id, u => new AuditUserDto(u.Id, u.DisplayName, u.Username, storage.ToPublicUrl(u.AvatarUrl)));
        var labels = await AuditTargetLabels.LoadAsync(db, currentUser.UiLanguage,
            audits.Values.Where(a => a.TargetType is not null && a.TargetId is not null).Select(a => (a.TargetType!, a.TargetId!.Value)), ct);
        var showIp = currentUser.Permissions.Contains(Permissions.Users.ReadPii);

        var items = new List<AuditEntryDto>(keys.Count);
        foreach (var key in keys)
        {
            if (key.Source == AuditSource && audits.TryGetValue(key.Id, out var a))
            {
                items.Add(new AuditEntryDto(
                    a.Id, AuditSource, a.Action, User(a.ActorId), User(a.UserId),
                    a is { TargetType: { } type, TargetId: { } id } ? new AuditTargetDto(type, id, labels.GetValueOrDefault((type, id))) : null,
                    a.Details, showIp ? a.Ip : null, a.CreatedAt));
            }
            else if (key.Source == ModerationSource && moderation.TryGetValue(key.Id, out var m))
            {
                items.Add(new AuditEntryDto(
                    m.Id, ModerationSource, m.Action, User(m.ModeratorId), User(m.TargetUserId),
                    new AuditTargetDto(m.TargetType.ToString().ToLowerInvariant(), m.TargetId, m.TargetLabel),
                    m.Note, null, m.CreatedAt));
            }
        }
        return items;

        AuditUserDto? User(Guid? id) => id is { } userId ? users.GetValueOrDefault(userId) : null;
    }

    private static bool TryGuid(string? text, out Guid? value)
    {
        value = null;
        if (string.IsNullOrWhiteSpace(text)) return true;
        if (!Guid.TryParse(text.Trim(), out var parsed)) return false;
        value = parsed;
        return true;
    }

    private static bool TryDate(string? text, out DateOnly? value)
    {
        value = null;
        if (string.IsNullOrWhiteSpace(text)) return true;
        if (!DateOnly.TryParseExact(text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed)) return false;
        value = parsed;
        return true;
    }
}

/// <summary>What an audit entry's target is called now (SPEC F23), in the caller's UI language; missing once it is gone.</summary>
internal static class AuditTargetLabels
{
    public static async Task<Dictionary<(string Type, Guid Id), string>> LoadAsync(
        IAppDbContext db, string uiLanguage, IEnumerable<(string Type, Guid Id)> targets, CancellationToken ct)
    {
        var english = uiLanguage == UiLanguages.English;
        var byType = targets.Distinct().GroupBy(t => t.Type).ToDictionary(g => g.Key, g => g.Select(t => t.Id).ToList());
        var labels = new Dictionary<(string, Guid), string>();

        if (byType.TryGetValue(AuditTargets.Field, out var fieldIds))
        {
            foreach (var f in await db.Fields.AsNoTracking().Where(f => fieldIds.Contains(f.Id)).Select(f => new { f.Id, f.NameAr, f.NameEn }).ToListAsync(ct))
                labels[(AuditTargets.Field, f.Id)] = english ? f.NameEn : f.NameAr;
        }
        if (byType.TryGetValue(AuditTargets.Topic, out var topicIds))
        {
            foreach (var t in await db.Topics.AsNoTracking().Where(t => topicIds.Contains(t.Id)).Select(t => new { t.Id, t.NameAr, t.NameEn }).ToListAsync(ct))
                labels[(AuditTargets.Topic, t.Id)] = english ? t.NameEn : t.NameAr;
        }
        if (byType.TryGetValue(AuditTargets.Tag, out var tagIds))
        {
            foreach (var t in await db.Tags.AsNoTracking().Where(t => tagIds.Contains(t.Id)).Select(t => new { t.Id, t.Name }).ToListAsync(ct))
                labels[(AuditTargets.Tag, t.Id)] = t.Name;
        }
        if (byType.TryGetValue(AuditTargets.Path, out var pathIds))
        {
            foreach (var p in await db.LearningPaths.AsNoTracking().Where(p => pathIds.Contains(p.Id)).Select(p => new { p.Id, p.TitleAr, p.TitleEn }).ToListAsync(ct))
                labels[(AuditTargets.Path, p.Id)] = english ? p.TitleEn : p.TitleAr;
        }
        if (byType.TryGetValue(AuditTargets.Announcement, out var announcementIds))
        {
            foreach (var a in await db.Announcements.AsNoTracking().Where(a => announcementIds.Contains(a.Id)).Select(a => new { a.Id, a.TitleAr, a.TitleEn }).ToListAsync(ct))
                labels[(AuditTargets.Announcement, a.Id)] = english ? a.TitleEn : a.TitleAr;
        }
        if (byType.TryGetValue(AuditTargets.Article, out var articleIds))
        {
            var language = english ? ArticleLanguages.English : ArticleLanguages.EgyptianArabic;
            foreach (var a in await db.Articles.AsNoTracking().Where(a => articleIds.Contains(a.Id))
                         .Select(a => new
                         {
                             a.Id,
                             Title = a.Translations.Where(t => t.Language == language).Select(t => t.Title).FirstOrDefault()
                                 ?? a.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault(),
                         })
                         .ToListAsync(ct))
            {
                if (a.Title is not null) labels[(AuditTargets.Article, a.Id)] = a.Title;
            }
        }
        if (byType.TryGetValue(AuditTargets.Comment, out var commentIds))
        {
            foreach (var c in await db.Comments.AsNoTracking().Where(c => commentIds.Contains(c.Id)).Select(c => new { c.Id, c.Body }).ToListAsync(ct))
                labels[(AuditTargets.Comment, c.Id)] = NotificationExcerpt.Of(c.Body, ModerationAction.CommentLabelLength);
        }
        return labels;
    }
}
