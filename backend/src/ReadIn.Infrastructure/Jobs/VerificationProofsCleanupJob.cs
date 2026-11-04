using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Verification;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Daily: deletes private proof files (SPEC F19) that no request points at any more and that are older than
/// <see cref="UploadLimits.OrphanGracePeriod"/>, plus stale <c>.tmp</c> leftovers. Proofs are deleted when a request is
/// decided or withdrawn and when an account is deleted; this finishes a delete that failed then, so a private document
/// never stays on the server by accident. The grace period leaves a submit that is still saving alone.
/// </summary>
public sealed partial class VerificationProofsCleanupJob(
    LocalPrivateFileStorage storage,
    AppDbContext db,
    TimeProvider clock,
    ILogger<VerificationProofsCleanupJob> logger)
{
    [DisableConcurrentExecution(timeoutInSeconds: 600)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var cutoff = clock.GetUtcNow().UtcDateTime - UploadLimits.OrphanGracePeriod;
        var stale = storage.EnumerateFiles(VerificationProofs.Folder).Where(f => f.LastWriteUtc < cutoff).ToList();
        if (stale.Count == 0) return 0;

        var stored = (await db.VerificationRequests.AsNoTracking()
                .Where(r => r.ProofFilePath != null)
                .Select(r => r.ProofFilePath!)
                .ToListAsync(cancellationToken))
            .ToHashSet(StringComparer.Ordinal);

        var deleted = 0;
        foreach (var file in stale.Where(f => !stored.Contains(f.RelativePath)))
        {
            await storage.DeleteAsync(file.RelativePath, cancellationToken);
            deleted++;
        }

        if (deleted > 0) LogDeleted(logger, deleted);
        return deleted;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Verification proofs cleanup deleted {Count} private files no request points at")]
    private static partial void LogDeleted(ILogger logger, int count);
}
