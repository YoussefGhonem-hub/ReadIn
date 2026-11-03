using Hangfire;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Daily: deletes uploads that are older than <see cref="UploadLimits.OrphanGracePeriod"/> and not referenced by any
/// user, article, draft or revision (SPEC §24, ADR 0010). Catches abandoned uploads and failed deletes. Only files
/// named <c>{id}_{size}.webp</c> in a known purpose folder are touched, plus stale <c>.tmp</c> leftovers.
/// </summary>
public sealed partial class OrphanedUploadsCleanupJob(
    WwwrootFileStorage storage,
    UploadReferences references,
    TimeProvider clock,
    ILogger<OrphanedUploadsCleanupJob> logger)
{
    [DisableConcurrentExecution(timeoutInSeconds: 600)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var cutoff = clock.GetUtcNow().UtcDateTime - UploadLimits.OrphanGracePeriod;
        var stale = storage.EnumerateFiles().Where(f => f.LastWriteUtc < cutoff).ToList();
        if (stale.Count == 0) return 0;

        var deleted = 0;
        foreach (var leftover in stale.Where(f => f.RelativePath.EndsWith(".tmp", StringComparison.Ordinal)))
        {
            await storage.DeleteAsync(leftover.RelativePath, cancellationToken);
            deleted++;
        }

        var referenced = await references.LoadReferencedIdsAsync(cancellationToken);
        var orphans = stale
            .Select(f => (File: f, Id: UploadIdOf(f.RelativePath)))
            .Where(f => f.Id is not null && !referenced.Contains(f.Id))
            .GroupBy(f => f.Id!, f => f.File);

        foreach (var upload in orphans)
        {
            // It may have been attached since the scan; check once more right before deleting.
            if (await references.IsReferencedAsync(upload.Key, cancellationToken)) continue;

            foreach (var file in upload)
            {
                await storage.DeleteAsync(file.RelativePath, cancellationToken);
                deleted++;
            }
        }

        LogDeleted(logger, deleted);
        return deleted;
    }

    /// <summary>The upload id of <c>/uploads/{known folder}/…/{id}_{size}.webp</c>; null for every other file.</summary>
    private static string? UploadIdOf(string relativePath)
    {
        var segments = relativePath.Split('/'); // "", "uploads", folder, ..., file name
        return segments.Length > 3 && UploadPurpose.FromFolder(segments[2]) is not null
            ? UploadPath.IdFromFileName(segments[^1])
            : null;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Orphaned uploads cleanup deleted {Count} files")]
    private static partial void LogDeleted(ILogger logger, int count);
}
