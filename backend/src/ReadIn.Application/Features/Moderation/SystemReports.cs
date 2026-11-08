using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Moderation;

/// <summary>
/// Reports from the content filter (SPEC F37, F22 store requirements): no reporter («فلتر المحتوى» / "Content filter"), the
/// matched terms kept for staff, one per target. A later flag of the same target reopens it with the new terms. They go
/// through the queue, the badge, the dashboard and <c>report_new</c> like any report.
/// </summary>
public sealed class SystemReports(IAppDbContext db)
{
    /// <summary>
    /// Files a system report on the target, or reopens (and updates) the one it has. Adds to the unit of work: the caller
    /// saves. A target with nothing matched is left alone.
    /// </summary>
    public async Task FlagAsync(ReportTargetType targetType, Guid targetId, IReadOnlyCollection<string> matchedTerms, DateTime now, CancellationToken ct)
    {
        if (matchedTerms.Count == 0) return;

        var existing = db.Reports.Local.FirstOrDefault(r => r.ReporterId == null && r.TargetType == targetType && r.TargetId == targetId)
            ?? await db.Reports.FirstOrDefaultAsync(r => r.ReporterId == null && r.TargetType == targetType && r.TargetId == targetId, ct);
        if (existing is null)
            db.Reports.Add(Report.FileSystem(targetType, targetId, matchedTerms, now));
        else
            existing.Reflag(matchedTerms, now);
    }
}
