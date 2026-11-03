using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Puts a committed image (the official avatar, article covers) through the same pipeline as a user upload: processed
/// variants in wwwroot/uploads and a <see cref="MediaAsset"/> row with the BlurHash (ADR 0011). The file id is derived
/// from the image bytes, so a seeder can tell an unchanged image from its stored URL without re-processing it.
/// </summary>
internal static class SeedImages
{
    public static Guid IdFor(byte[] bytes) => new(SHA256.HashData(bytes).AsSpan(0, 16));

    /// <summary>True when <paramref name="storedUrl"/> already points at the variants of exactly these bytes.</summary>
    public static bool IsStored(string? storedUrl, byte[] bytes) =>
        storedUrl?.Contains(IdFor(bytes).ToString("N"), StringComparison.OrdinalIgnoreCase) == true;

    /// <summary>The stored path of the variant clients should reference (closest to <paramref name="width"/>).</summary>
    public static string Pick(MediaAsset asset, int width) =>
        (asset.Variants.FirstOrDefault(v => v.Width == width) ?? asset.Variants.MaxBy(v => v.Width)!).Path;

    public static async Task<Result<MediaAsset>> ImportAsync(
        IImageProcessor images,
        IFileStorage storage,
        AppDbContext db,
        Guid ownerId,
        UploadPurpose purpose,
        byte[] bytes,
        DateTime now,
        CancellationToken ct)
    {
        // Same bytes → same id → same files: reuse the asset when it is already stored (e.g. a forced re-seed).
        var id = IdFor(bytes);
        var key = id.ToString("N");
        var stored = await db.MediaAssets.FirstOrDefaultAsync(
            a => a.OwnerId == ownerId && a.Purpose == purpose.MediaPurpose && a.OriginalPath != null && a.OriginalPath.Contains(key), ct);
        if (stored is not null) return stored;

        if (ImageSignatures.Detect(bytes.AsSpan(0, Math.Min(bytes.Length, ImageSignatures.HeaderLength))) is not { } format)
            return UploadErrors.UnsupportedType;

        Result<ProcessedImageSet> processed;
        using (var source = new MemoryStream(bytes, writable: false))
            processed = images.Process(source, format, purpose);
        if (processed.IsFailure) return processed.Error;

        var variants = new List<MediaVariant>();
        foreach (var image in processed.Value.Variants)
        {
            var path = UploadPath.Create(purpose, now, id, image.Size).Value;
            using var file = new MemoryStream(image.Content, writable: false);
            await storage.SaveAsync(path, file, ct);
            variants.Add(new MediaVariant(image.Width, image.Height, path, image.Content.Length));
        }

        var asset = MediaAsset.StartImage(ownerId, purpose.MediaPurpose, bytes.Length);
        asset.CompleteImage(processed.Value.Width, processed.Value.Height, processed.Value.BlurHash, variants);
        db.MediaAssets.Add(asset);
        return asset;
    }
}
