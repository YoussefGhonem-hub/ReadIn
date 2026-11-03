using Mediator;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Uploads.Commands.UploadImage;

internal sealed class UploadImageCommandHandler(
    IFileStorage storage,
    IImageProcessor images,
    ICurrentUser currentUser,
    TimeProvider clock)
    : ICommandHandler<UploadImageCommand, Result<UploadedImageDto>>
{
    public async ValueTask<Result<UploadedImageDto>> Handle(UploadImageCommand command, CancellationToken cancellationToken)
    {
        var purpose = UploadPurpose.FromName(command.Purpose);
        if (purpose is null) return UploadErrors.PurposeInvalid;

        // Covers and article images belong to articles, so they need the right to write one.
        if (purpose != UploadPurpose.Avatar && !currentUser.Permissions.Contains(Permissions.Articles.Create))
            return AuthErrors.Forbidden;

        // Read at most one byte past the limit: the declared length is not trusted.
        using var buffer = new MemoryStream();
        await CopyAtMostAsync(command.Content, buffer, UploadLimits.MaxBytes + 1, cancellationToken);
        if (buffer.Length == 0) return UploadErrors.Empty;
        if (buffer.Length > UploadLimits.MaxBytes) return UploadErrors.TooLarge;

        var header = buffer.GetBuffer().AsSpan(0, (int)Math.Min(buffer.Length, ImageSignatures.HeaderLength));
        if (ImageSignatures.Detect(header) is not { } format) return UploadErrors.UnsupportedType;

        buffer.Position = 0;
        var processed = images.Process(buffer, format, purpose);
        if (processed.IsFailure) return processed.Error;

        // Random name: the client's file name never reaches the path. A failure halfway leaves unreferenced
        // files that the orphan cleanup job removes.
        var id = Guid.NewGuid();
        var now = clock.GetUtcNow().UtcDateTime;
        var variants = new List<UploadedImageVariantDto>(processed.Value.Count);
        foreach (var image in processed.Value)
        {
            var path = UploadPath.Create(purpose, now, id, image.Size).Value;
            using var content = new MemoryStream(image.Content, writable: false);
            await storage.SaveAsync(path, content, cancellationToken);
            variants.Add(new UploadedImageVariantDto(image.Size, path, storage.GetPublicUrl(path), image.Width, image.Height));
        }

        var largest = variants[^1];
        return new UploadedImageDto(purpose.Name, largest.Path, largest.Url, largest.Width, largest.Height, variants);
    }

    private static async Task CopyAtMostAsync(Stream source, Stream destination, long maxBytes, CancellationToken ct)
    {
        var chunk = new byte[81920];
        long total = 0;
        int read;
        while (total < maxBytes && (read = await source.ReadAsync(chunk.AsMemory(0, (int)Math.Min(chunk.Length, maxBytes - total)), ct)) > 0)
        {
            await destination.WriteAsync(chunk.AsMemory(0, read), ct);
            total += read;
        }
    }
}
