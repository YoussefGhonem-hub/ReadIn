using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Daily: first deletes unused MediaAssets rows with their files, then uploads that are older than
/// <see cref="UploadLimits.OrphanGracePeriod"/> and not referenced by any user, article, draft, revision or media asset
/// (SPEC §24, ADR 0010, ADR 0011). Catches abandoned uploads and failed deletes. Only files named
/// <c>{id}_{size}.webp</c> in a known purpose folder or inside a <c>documents/…/{id}/</c> folder are touched, plus stale
/// <c>.tmp</c> leftovers.
/// </summary>
public sealed partial class OrphanedUploadsCleanupJob(
    WwwrootFileStorage storage,
    UploadReferences references,
    AppDbContext db,
    TimeProvider clock,
    ILogger<OrphanedUploadsCleanupJob> logger)
{
    [DisableConcurrentExecution(timeoutInSeconds: 600)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var cutoff = clock.GetUtcNow().UtcDateTime - UploadLimits.OrphanGracePeriod;
        await DeleteUnusedMediaAsync(cutoff, cancellationToken);

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

    /// <summary>
    /// ADR 0011: MediaAssets rows older than the grace period that nothing uses (no article attachment, no working copy or
    /// revision naming it, and for images no avatar, cover or RDoc reference either) are deleted with all their files and pages. This also catches
    /// documents whose processing failed and uploads abandoned in the composer.
    /// </summary>
    private async Task DeleteUnusedMediaAsync(DateTime cutoff, CancellationToken cancellationToken)
    {
        var candidates = await db.MediaAssets.Include(a => a.Pages)
            .Where(a => a.CreatedAt < cutoff && !db.ArticleAttachments.Any(x => x.MediaAssetId == a.Id))
            .OrderBy(a => a.CreatedAt)
            .Take(500)
            .ToListAsync(cancellationToken);

        var deleted = 0;
        foreach (var asset in candidates)
        {
            if (await references.IsAssetReferencedAsync(asset.Id, cancellationToken)) continue;
            if (UploadPath.TryParse(asset.OriginalPath, out var image) && await references.IsReferencedAsync(image.Id, cancellationToken))
                continue;

            var files = asset.StoredPaths().ToList();
            db.MediaAssets.Remove(asset);
            await db.SaveChangesAsync(cancellationToken);
            foreach (var file in files)
                await storage.DeleteAsync(file, cancellationToken);
            deleted++;
        }

        if (deleted > 0) LogMediaDeleted(logger, deleted);
    }

    /// <summary>
    /// The upload id of <c>/uploads/{known folder}/…/{id}_{size}.webp</c> or of any file of
    /// <c>/uploads/documents/{yyyy}/{MM}/{id}/…</c>; null for every other file.
    /// </summary>
    private static string? UploadIdOf(string relativePath)
    {
        if (DocumentPath.TryParse(relativePath, out var document)) return document.Id;

        var segments = relativePath.Split('/'); // "", "uploads", folder, ..., file name
        return segments.Length > 3 && UploadPurpose.FromFolder(segments[2]) is not null
            ? UploadPath.IdFromFileName(segments[^1])
            : null;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Orphaned uploads cleanup deleted {Count} unused media assets")]
    private static partial void LogMediaDeleted(ILogger logger, int count);

    [LoggerMessage(Level = LogLevel.Information, Message = "Orphaned uploads cleanup deleted {Count} files")]
    private static partial void LogDeleted(ILogger logger, int count);
}
