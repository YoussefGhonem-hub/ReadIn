using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Common.Uploads;

/// <summary>Deletes the files of a replaced or removed upload once nothing references it any more (SPEC §24).</summary>
public sealed partial class UploadCleanup(UploadReferences references, IAppDbContext db, IFileStorage storage, ILogger<UploadCleanup> logger)
{
    /// <summary>
    /// Call after the change that dropped <paramref name="previous"/> is saved. External URLs are ignored. The upload's
    /// MediaAssets row goes with it (ADR 0011). A failed delete is only logged: the file is then an orphan and the daily
    /// cleanup job removes it.
    /// </summary>
    public async Task ReleaseAsync(string? previous, CancellationToken cancellationToken)
    {
        if (!UploadPath.TryParse(previous, out var path)) return;
        if (await references.IsReferencedAsync(path.Id, cancellationToken)) return;

        // Exact files from the asset row when there is one (variants are named by their real widths), else every bucket.
        var assets = await db.MediaAssets.Include(a => a.Pages)
            .Where(a => a.OriginalPath != null && a.OriginalPath.Contains(path.Id))
            .ToListAsync(cancellationToken);
        var files = assets.Count > 0
            ? assets.SelectMany(a => a.StoredPaths()).ToList()
            : [.. path.Variants.Select(v => v.Value)];
        if (assets.Count > 0)
        {
            db.MediaAssets.RemoveRange(assets);
            await db.SaveChangesAsync(cancellationToken);
        }

        try
        {
            foreach (var file in files)
                await storage.DeleteAsync(file, cancellationToken);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            LogDeleteFailed(logger, ex, path.Id);
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete the files of upload {UploadId}; the orphan cleanup job will retry")]
    private static partial void LogDeleteFailed(ILogger logger, Exception exception, string uploadId);
}
