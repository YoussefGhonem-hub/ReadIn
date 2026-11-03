using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Features.Uploads;

/// <summary>
/// Deletes the files of removed assets after the database change is saved. A failed delete is only logged: the files
/// are then orphans (no MediaAssets row mentions them) and the daily cleanup job removes them.
/// </summary>
public sealed partial class MediaFiles(IFileStorage storage, ILogger<MediaFiles> logger)
{
    public async Task DeleteAsync(IEnumerable<string> paths, CancellationToken cancellationToken)
    {
        foreach (var path in paths)
        {
            try
            {
                await storage.DeleteAsync(path, cancellationToken);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException)
            {
                LogDeleteFailed(logger, ex, path);
            }
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete {Path}; the orphan cleanup job will retry")]
    private static partial void LogDeleteFailed(ILogger logger, Exception exception, string path);
}
