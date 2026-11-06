using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads;

/// <summary>
/// Per-user upload quotas (ADR 0011, contract-v1 "Media"): <see cref="MediaOptions.MaxUploadsPerDay"/> uploads in any
/// rolling 24 hours, counted from the upload log (<see cref="MediaUpload"/>), so an upload deleted since still counts;
/// and <see cref="MediaOptions.MaxStoredBytesPerUser"/> bytes kept, counted from the assets that still exist.
/// </summary>
public interface IMediaQuota
{
    /// <summary>Checked before any work is done for a new upload: uploads per day, then storage.</summary>
    Task<Error?> CheckNewUploadAsync(Guid userId, long incomingBytes, CancellationToken cancellationToken);

    Task<Error?> CheckStorageAsync(Guid userId, long incomingBytes, CancellationToken cancellationToken);

    /// <summary>
    /// Logs an accepted upload for the daily quota. Call it where the asset is added, so both are saved together; the row
    /// stays when the asset is deleted.
    /// </summary>
    void RecordUpload(Guid userId);
}

public sealed class MediaQuota(IAppDbContext db, IOptions<MediaOptions> options, TimeProvider clock) : IMediaQuota
{
    public async Task<Error?> CheckNewUploadAsync(Guid userId, long incomingBytes, CancellationToken cancellationToken)
    {
        var limits = options.Value;
        var since = clock.GetUtcNow().UtcDateTime.AddDays(-1);
        // Every accepted upload, deleted ones included: deleting doesn't give the upload back.
        var recent = await db.MediaUploads.CountAsync(u => u.UserId == userId && u.CreatedAt >= since, cancellationToken);
        if (recent >= limits.MaxUploadsPerDay) return MediaErrors.QuotaDaily;

        return await CheckStorageAsync(userId, incomingBytes, cancellationToken);
    }

    public async Task<Error?> CheckStorageAsync(Guid userId, long incomingBytes, CancellationToken cancellationToken)
    {
        var stored = await db.MediaAssets.Where(m => m.OwnerId == userId).SumAsync(m => (long?)m.StoredBytes, cancellationToken) ?? 0;
        return stored + incomingBytes > options.Value.MaxStoredBytesPerUser ? MediaErrors.QuotaStorage : null;
    }

    public void RecordUpload(Guid userId) => db.MediaUploads.Add(new MediaUpload(userId, clock.GetUtcNow().UtcDateTime));
}

/// <summary>Reads an upload into memory, stopping one byte past the limit: the declared length is never trusted.</summary>
public static class UploadBuffer
{
    public static async Task<byte[]> ReadAtMostAsync(Stream source, long maxBytes, CancellationToken cancellationToken)
    {
        using var buffer = new MemoryStream();
        var chunk = new byte[81920];
        long total = 0;
        int read;
        while (total <= maxBytes
               && (read = await source.ReadAsync(chunk.AsMemory(0, (int)Math.Min(chunk.Length, maxBytes + 1 - total)), cancellationToken)) > 0)
        {
            await buffer.WriteAsync(chunk.AsMemory(0, read), cancellationToken);
            total += read;
        }
        return buffer.ToArray();
    }
}
