using Mapster;
using Mediator;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Commands.UploadDocument;

internal sealed class UploadDocumentCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IFileStorage storage,
    IPdfInspector inspector,
    IMediaJobScheduler jobs,
    IMediaStatusNotifier notifier,
    IMediaQuota quota,
    IOptions<MediaOptions> options,
    TypeAdapterConfig mapping,
    TimeProvider clock)
    : ICommandHandler<UploadDocumentCommand, Result<MediaAssetDto>>
{
    public async ValueTask<Result<MediaAssetDto>> Handle(UploadDocumentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var limits = options.Value;

        var pdf = await UploadBuffer.ReadAtMostAsync(command.Content, UploadLimits.MaxDocumentBytes, cancellationToken);
        if (pdf.Length == 0) return MediaErrors.FileRequired;
        if (pdf.Length > UploadLimits.MaxDocumentBytes) return MediaErrors.TooLarge;

        if (await quota.CheckNewUploadAsync(userId, pdf.Length, cancellationToken) is { } quotaError) return quotaError;

        // Magic bytes, encryption and damage are checked by actually opening the file, never by its name or type.
        var info = inspector.Inspect(pdf);
        if (info.IsFailure) return info.Error;
        if (info.Value.PageCount > limits.MaxDocumentPages) return MediaErrors.PdfTooManyPages;

        var asset = MediaAsset.StartDocument(userId, TitleFor(command, info.Value), command.AllowDownload, pdf.Length, info.Value.PageCount);
        var path = DocumentPath.Create(clock.GetUtcNow().UtcDateTime, Guid.NewGuid());
        using (var content = new MemoryStream(pdf, writable: false))
            await storage.SaveAsync(path.Original, content, cancellationToken);

        asset.StartProcessing(path.Original);
        db.MediaAssets.Add(asset);
        quota.RecordUpload(userId);
        await db.SaveChangesAsync(cancellationToken);

        await jobs.EnqueueDocumentAsync(asset.Id, cancellationToken);
        await notifier.NotifyAsync(asset, cancellationToken);
        return asset.ToDto(mapping, storage);
    }

    /// <summary>The title typed by the user, else the file name without its extension, else the PDF's own title.</summary>
    private static string TitleFor(UploadDocumentCommand command, PdfInfo info)
    {
        if (!string.IsNullOrWhiteSpace(command.Title)) return command.Title;

        var fromFile = Path.GetFileNameWithoutExtension(Path.GetFileName(command.FileName ?? string.Empty)).Trim();
        if (fromFile.Length > 0) return fromFile;

        return info.Title ?? "Document";
    }
}
