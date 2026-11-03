using Mapster;
using Mediator;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Commands.UploadImage;

internal sealed class UploadImageCommandHandler(
    IAppDbContext db,
    IFileStorage storage,
    IImageProcessor images,
    ICurrentUser currentUser,
    IMediaQuota quota,
    TypeAdapterConfig mapping,
    TimeProvider clock)
    : ICommandHandler<UploadImageCommand, Result<MediaAssetDto>>
{
    public async ValueTask<Result<MediaAssetDto>> Handle(UploadImageCommand command, CancellationToken cancellationToken)
    {
        var purpose = UploadPurpose.FromName(command.Purpose);
        if (purpose is null) return UploadErrors.PurposeInvalid;

        // Covers and post images belong to articles, so they need the right to write one.
        if (purpose != UploadPurpose.Avatar && !currentUser.Permissions.Contains(Permissions.Articles.Create))
            return AuthErrors.Forbidden;

        var userId = currentUser.RequireUserId();
        if (await quota.CheckNewUploadAsync(userId, incomingBytes: 0, cancellationToken) is { } quotaError) return quotaError;

        // Read at most one byte past the limit: the declared length is not trusted.
        var bytes = await UploadBuffer.ReadAtMostAsync(command.Content, UploadLimits.MaxBytes, cancellationToken);
        if (bytes.Length == 0) return UploadErrors.Empty;
        if (bytes.Length > UploadLimits.MaxBytes) return UploadErrors.TooLarge;

        if (ImageSignatures.Detect(bytes.AsSpan(0, Math.Min(bytes.Length, ImageSignatures.HeaderLength))) is not { } format)
            return UploadErrors.UnsupportedType;

        // Always re-processed on the server: client-side compression is never trusted (ADR 0011).
        Result<ProcessedImageSet> processed;
        using (var content = new MemoryStream(bytes, writable: false))
            processed = images.Process(content, format, purpose);
        if (processed.IsFailure) return processed.Error;

        var set = processed.Value;
        if (await quota.CheckStorageAsync(userId, set.Variants.Sum(v => (long)v.Content.Length), cancellationToken) is { } storageError)
            return storageError;

        // Random name: the client's file name never reaches the path. A failure halfway leaves unreferenced
        // files that the orphan cleanup job removes.
        var id = Guid.NewGuid();
        var now = clock.GetUtcNow().UtcDateTime;
        var variants = new List<MediaVariant>(set.Variants.Count);
        foreach (var image in set.Variants)
        {
            var path = UploadPath.Create(purpose, now, id, image.Size).Value;
            using var content = new MemoryStream(image.Content, writable: false);
            await storage.SaveAsync(path, content, cancellationToken);
            variants.Add(new MediaVariant(image.Width, image.Height, path, image.Content.Length));
        }

        var asset = MediaAsset.StartImage(userId, purpose.MediaPurpose, bytes.Length);
        asset.CompleteImage(set.Width, set.Height, set.BlurHash, variants);
        db.MediaAssets.Add(asset);
        await db.SaveChangesAsync(cancellationToken);

        return asset.ToDto(mapping, storage);
    }
}
