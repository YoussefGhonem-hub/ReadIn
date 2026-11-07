using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Support;
using ReadIn.Domain.Support;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Hourly (SPEC F35): an Answered ticket whose last support reply is 14 days old, with no message from the member since,
/// is closed (closed by "auto"). The member isn't told; they can still reopen it for 30 days.
/// </summary>
public sealed partial class SupportAutoCloseJob(AppDbContext db, TimeProvider clock, ILogger<SupportAutoCloseJob> logger)
{
    private const int BatchSize = 200;

    [DisableConcurrentExecution(timeoutInSeconds: 600)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var due = now - SupportTicket.AutoCloseAfter;
        var closed = 0;
        while (true)
        {
            var batch = await db.SupportTickets
                .Where(t => t.Status == SupportTicketStatus.Answered && t.LastAdminReplyAt <= due && t.LastUserMessageAt <= t.LastAdminReplyAt)
                .OrderBy(t => t.LastAdminReplyAt)
                .Take(BatchSize)
                .ToListAsync(cancellationToken);
            var changed = batch.Count(t => t.AutoClose(now));
            if (changed == 0) break;
            await db.SaveChangesAsync(cancellationToken);
            db.ChangeTracker.Clear();
            closed += changed;
            if (batch.Count < BatchSize) break;
        }
        if (closed > 0) LogClosed(logger, closed);
        return closed;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Support auto-close closed {Count} answered tickets")]
    private static partial void LogClosed(ILogger logger, int count);
}

/// <summary>
/// Daily (SPEC F35): tickets closed more than a year ago are deleted with their messages and screenshots, and screenshots no
/// row points at any more (a delete that failed, or a request that died after writing) go once they are a day old.
/// </summary>
public sealed partial class SupportRetentionJob(
    AppDbContext db, LocalPrivateFileStorage storage, SupportScreenshots screenshots, TimeProvider clock, ILogger<SupportRetentionJob> logger)
{
    public const string Folder = "support";
    private const int BatchSize = 200;

    [DisableConcurrentExecution(timeoutInSeconds: 1800)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<(int Tickets, int Orphans)> RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var expired = now - SupportTicket.Retention;
        var tickets = 0;
        while (true)
        {
            var ids = await db.SupportTickets.AsNoTracking()
                .Where(t => t.Status == SupportTicketStatus.Closed && t.ClosedAt <= expired)
                .OrderBy(t => t.ClosedAt)
                .Select(t => t.Id)
                .Take(BatchSize)
                .ToListAsync(cancellationToken);
            if (ids.Count == 0) break;

            var files = await db.SupportAttachments.AsNoTracking()
                .Where(a => db.SupportMessages.Any(m => m.Id == a.MessageId && ids.Contains(m.TicketId)))
                .Select(a => a.FilePath)
                .ToListAsync(cancellationToken);
            // Messages and attachments go with the ticket (cascade); the files right after.
            tickets += await db.SupportTickets.Where(t => ids.Contains(t.Id)).ExecuteDeleteAsync(cancellationToken);
            await screenshots.DeleteAsync(files, cancellationToken);
            if (ids.Count < BatchSize) break;
        }

        var orphans = await DeleteOrphansAsync(now, cancellationToken);
        if (tickets + orphans > 0) LogDeleted(logger, tickets, orphans);
        return (tickets, orphans);
    }

    private async Task<int> DeleteOrphansAsync(DateTime now, CancellationToken ct)
    {
        var cutoff = now - UploadLimits.OrphanGracePeriod;
        var stale = storage.EnumerateFiles(Folder, recursive: true).Where(f => f.LastWriteUtc < cutoff).ToList();
        if (stale.Count == 0) return 0;

        var stored = (await db.SupportAttachments.AsNoTracking().Select(a => a.FilePath).ToListAsync(ct)).ToHashSet(StringComparer.Ordinal);
        var orphans = stale.Where(f => !stored.Contains(f.RelativePath)).Select(f => f.RelativePath).ToList();
        await screenshots.DeleteAsync(orphans, ct);
        return orphans.Count;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Support retention deleted {Tickets} tickets closed over a year ago and {Orphans} orphaned screenshots")]
    private static partial void LogDeleted(ILogger logger, int tickets, int orphans);
}
