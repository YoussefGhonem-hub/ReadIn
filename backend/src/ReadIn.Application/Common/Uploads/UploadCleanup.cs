using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Common.Uploads;

/// <summary>Deletes the files of a replaced or removed upload once nothing references it any more (SPEC §24).</summary>
public sealed partial class UploadCleanup(UploadReferences references, IFileStorage storage, ILogger<UploadCleanup> logger)
{
    /// <summary>
    /// Call after the change that dropped <paramref name="previous"/> is saved. External URLs are ignored. A failed
    /// delete is only logged: the file is then an orphan and the daily cleanup job removes it.
    /// </summary>
    public async Task ReleaseAsync(string? previous, CancellationToken cancellationToken)
    {
        if (!UploadPath.TryParse(previous, out var path)) return;
        if (await references.IsReferencedAsync(path.Id, cancellationToken)) return;

        try
        {
            foreach (var variant in path.Variants)
                await storage.DeleteAsync(variant.Value, cancellationToken);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            LogDeleteFailed(logger, ex, path.Id);
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete the files of upload {UploadId}; the orphan cleanup job will retry")]
    private static partial void LogDeleteFailed(ILogger logger, Exception exception, string uploadId);
}
