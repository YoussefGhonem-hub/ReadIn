using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.WriterCategories;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Moderation;

/// <summary>GET /moderation/summary: how many targets have open reports, per type (the nav badge).</summary>
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record GetModerationSummaryQuery : IQuery<Result<ModerationSummaryDto>>;

/// <summary>
/// GET /moderation/reports?status=&amp;type= (SPEC F22): the queue, one item per target. Open: most reports first, then
/// the most recent report. Resolved and dismissed: most recently closed first. Keyset paging, so closing items while
/// going through the queue never skips any.
/// </summary>
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record GetModerationQueueQuery(string? Status, string? Type, string? Cursor, int Limit = 20)
    : IQuery<Result<CursorPage<ModerationQueueItemDto>>>;

/// <summary>GET /moderation/reports/{targetType}/{targetId}: the target, every report on it and its history.</summary>
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record GetModerationCaseQuery(string TargetType, Guid TargetId) : IQuery<Result<ModerationCaseDto>>;

/// <summary>GET /moderation/actions: the moderation log, newest first, by affected user, moderator or target type.</summary>
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record GetModerationLogQuery(Guid? TargetUserId, Guid? ModeratorId, string? TargetType, string? Cursor, int Limit = 20)
    : IQuery<Result<CursorPage<ModerationActionDto>>>;

internal sealed class GetModerationQueueQueryValidator : AbstractValidator<GetModerationQueueQuery>
{
    public GetModerationQueueQueryValidator()
    {
        RuleFor(q => q.Status).Must(s => s is null || ModerationValues.TryParseStatus(s, out _)).WithErrorCode("report.status_invalid");
        RuleFor(q => q.Type).Must(t => t is null || ModerationValues.TryParseTarget(t, out _)).WithErrorCode("report.target_invalid");
    }
}

internal sealed class GetModerationCaseQueryValidator : AbstractValidator<GetModerationCaseQuery>
{
    public GetModerationCaseQueryValidator() =>
        RuleFor(q => q.TargetType).Must(t => ModerationValues.TryParseTarget(t, out _)).WithErrorCode("report.target_invalid");
}

internal sealed class GetModerationLogQueryValidator : AbstractValidator<GetModerationLogQuery>
{
    public GetModerationLogQueryValidator() =>
        RuleFor(q => q.TargetType).Must(t => t is null || ModerationValues.TryParseTarget(t, out _)).WithErrorCode("report.target_invalid");
}

internal sealed class GetModerationSummaryQueryHandler(IAppDbContext db) : IQueryHandler<GetModerationSummaryQuery, Result<ModerationSummaryDto>>
{
    public async ValueTask<Result<ModerationSummaryDto>> Handle(GetModerationSummaryQuery query, CancellationToken cancellationToken)
    {
        // Served by the (Status, TargetType, TargetId) index.
        var counts = await db.Reports.AsNoTracking()
            .Where(r => r.Status == ReportStatus.Open)
            .GroupBy(r => r.TargetType)
            .Select(g => new { Type = g.Key, Targets = g.Select(r => r.TargetId).Distinct().Count() })
            .ToDictionaryAsync(c => c.Type, c => c.Targets, cancellationToken);

        int Of(ReportTargetType type) => counts.GetValueOrDefault(type);
        return new ModerationSummaryDto(new OpenReportCountsDto(
            Of(ReportTargetType.Article), Of(ReportTargetType.Comment), Of(ReportTargetType.User), counts.Values.Sum())
        {
            Repost = Of(ReportTargetType.Repost),
        });
    }
}

internal sealed class GetModerationQueueQueryHandler(IAppDbContext db, ModerationReader reader, TimeProvider clock)
    : IQueryHandler<GetModerationQueueQuery, Result<CursorPage<ModerationQueueItemDto>>>
{
    public async ValueTask<Result<CursorPage<ModerationQueueItemDto>>> Handle(GetModerationQueueQuery query, CancellationToken cancellationToken)
    {
        var status = ModerationValues.TryParseStatus(query.Status, out var parsed) ? parsed : ReportStatus.Open;
        var limit = Math.Clamp(query.Limit, 1, 50);

        var reports = db.Reports.AsNoTracking().Where(r => r.Status == status);
        if (ModerationValues.TryParseTarget(query.Type, out var type)) reports = reports.Where(r => r.TargetType == type);

        var targets = reports
            .GroupBy(r => new { r.TargetType, r.TargetId })
            .Select(g => new
            {
                g.Key.TargetType,
                g.Key.TargetId,
                Count = g.Count(),
                First = g.Min(r => r.CreatedAt),
                Last = g.Max(r => r.CreatedAt),
                Closed = g.Max(r => r.ResolvedAt),
            });

        var cursor = QueueCursor.Decode(query.Cursor);
        if (status == ReportStatus.Open)
        {
            if (cursor is { } c)
            {
                targets = targets.Where(t =>
                    t.Count < c.Count ||
                    (t.Count == c.Count && (t.Last < c.At || (t.Last == c.At && t.TargetId.CompareTo(c.Id) < 0))));
            }
            targets = targets.OrderByDescending(t => t.Count).ThenByDescending(t => t.Last).ThenByDescending(t => t.TargetId);
        }
        else
        {
            if (cursor is { } c)
                targets = targets.Where(t => t.Closed < c.At || (t.Closed == c.At && t.TargetId.CompareTo(c.Id) < 0));
            targets = targets.OrderByDescending(t => t.Closed).ThenByDescending(t => t.TargetId);
        }

        var page = await targets.Take(limit + 1).ToListAsync(cancellationToken);
        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            var last = page[^1];
            next = (status == ReportStatus.Open
                ? new QueueCursor(last.Count, last.Last, last.TargetId)
                : new QueueCursor(0, last.Closed ?? default, last.TargetId)).Encode();
        }
        if (page.Count == 0) return new CursorPage<ModerationQueueItemDto>([], next);

        // Target ids are unique across types, so the reasons can be counted by id alone.
        var ids = page.Select(p => p.TargetId).ToList();
        var reasons = (await db.Reports.AsNoTracking()
                .Where(r => r.Status == status && ids.Contains(r.TargetId))
                .GroupBy(r => new { r.TargetId, r.Reason })
                .Select(g => new { g.Key.TargetId, g.Key.Reason, Count = g.Count() })
                .ToListAsync(cancellationToken))
            .ToLookup(r => r.TargetId, r => (r.Reason, r.Count));

        var keys = page.Select(p => new ModerationTargetKey(p.TargetType, p.TargetId)).ToList();
        var previews = await reader.TargetsAsync(keys, cancellationToken);
        var now = clock.GetUtcNow().UtcDateTime;
        return new CursorPage<ModerationQueueItemDto>(
            [
                .. page.Select(p => new ModerationQueueItemDto(
                    p.TargetType,
                    p.TargetId,
                    status,
                    p.Count,
                    ModerationReader.Reasons(reasons[p.TargetId]),
                    p.First,
                    p.Last,
                    status == ReportStatus.Open ? null : p.Closed,
                    previews[new ModerationTargetKey(p.TargetType, p.TargetId)]).Aged(p.First, now)),
            ],
            next);
    }
}

internal sealed class GetModerationCaseQueryHandler(IAppDbContext db, ModerationReader reader, WriterCategoryReader categories, TimeProvider clock)
    : IQueryHandler<GetModerationCaseQuery, Result<ModerationCaseDto>>
{
    /// <summary>The history shows at most this many actions.</summary>
    private const int HistoryLimit = 100;

    public async ValueTask<Result<ModerationCaseDto>> Handle(GetModerationCaseQuery query, CancellationToken cancellationToken)
    {
        ModerationValues.TryParseTarget(query.TargetType, out var type);
        var reports = await db.Reports.AsNoTracking()
            .Where(r => r.TargetType == type && r.TargetId == query.TargetId)
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .ToListAsync(cancellationToken);
        if (reports.Count == 0) return ReportErrors.TargetNotFound;

        var status = reports.Any(r => r.Status == ReportStatus.Open)
            ? ReportStatus.Open
            : reports.MaxBy(r => r.ResolvedAt)!.Status;
        var inStatus = reports.Where(r => r.Status == status).ToList();

        var key = new ModerationTargetKey(type, query.TargetId);
        var target = (await reader.TargetsAsync([key], cancellationToken))[key];
        var item = new ModerationQueueItemDto(
            type,
            query.TargetId,
            status,
            inStatus.Count,
            ModerationReader.Reasons(inStatus.GroupBy(r => r.Reason).Select(g => (g.Key, g.Count()))),
            inStatus.Min(r => r.CreatedAt),
            inStatus.Max(r => r.CreatedAt),
            status == ReportStatus.Open ? null : inStatus.Max(r => r.ResolvedAt),
            target).Aged(inStatus.Min(r => r.CreatedAt), clock.GetUtcNow().UtcDateTime);

        var users = await reader.SummariesAsync(reports.SelectMany(r => new Guid?[] { r.ReporterId, r.ResolvedById }), cancellationToken);
        var reportDtos = reports.Select(r => new ModerationReportDto(
            r.Id, ModerationReader.Find(users, r.ReporterId), r.Reason, r.Details, r.Status, r.CreatedAt, r.ResolvedAt,
            ModerationReader.Find(users, r.ResolvedById))
        {
            // F37: the content filter's own reports, with what it matched (staff only).
            IsSystem = r.IsSystem,
            MatchedTerms = r.IsSystem ? r.MatchedTermList : null,
        }).ToList();

        // Actions on the target, and for content also those on its author's account (warnings, suspensions).
        var authorId = type == ReportTargetType.User ? (Guid?)null : target.Author?.Id;
        var history = await db.ModerationActions.AsNoTracking()
            .Where(m => (m.TargetType == type && m.TargetId == query.TargetId) ||
                        (authorId != null && m.TargetType == ReportTargetType.User && m.TargetId == authorId))
            .OrderByDescending(m => m.CreatedAt)
            .ThenByDescending(m => m.Id)
            .Take(HistoryLimit)
            .ToListAsync(cancellationToken);

        // A user's writer categories (F31), so a moderator can clear an offensive name from the case.
        IReadOnlyList<WriterCategoryDto> userCategories = type == ReportTargetType.User
            ? (await categories.LoadAsync(query.TargetId, cancellationToken)).Items
            : [];
        return new ModerationCaseDto(item, reportDtos, await reader.ActionsAsync(history, cancellationToken), userCategories);
    }
}

internal sealed class GetModerationLogQueryHandler(IAppDbContext db, ModerationReader reader)
    : IQueryHandler<GetModerationLogQuery, Result<CursorPage<ModerationActionDto>>>
{
    public async ValueTask<Result<CursorPage<ModerationActionDto>>> Handle(GetModerationLogQuery query, CancellationToken cancellationToken)
    {
        var limit = Math.Clamp(query.Limit, 1, 50);
        var actions = db.ModerationActions.AsNoTracking();
        if (query.TargetUserId is { } targetUserId) actions = actions.Where(m => m.TargetUserId == targetUserId);
        if (query.ModeratorId is { } moderatorId) actions = actions.Where(m => m.ModeratorId == moderatorId);
        if (ModerationValues.TryParseTarget(query.TargetType, out var type)) actions = actions.Where(m => m.TargetType == type);

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            actions = actions.Where(m =>
                m.CreatedAt < cursor.Timestamp ||
                (m.CreatedAt == cursor.Timestamp && m.Id.CompareTo(cursor.Id) < 0));
        }

        var page = await actions
            .OrderByDescending(m => m.CreatedAt)
            .ThenByDescending(m => m.Id)
            .Take(limit + 1)
            .ToListAsync(cancellationToken);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].CreatedAt, page[^1].Id).Encode();
        }

        return new CursorPage<ModerationActionDto>(await reader.ActionsAsync(page, cancellationToken), next);
    }
}
