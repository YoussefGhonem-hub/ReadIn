using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Media;

/// <summary>
/// Renders an uploaded PDF in the background, never in the request (ADR 0011): page 1 first (thumb + view + BlurHash)
/// so the preview appears fast, then the remaining pages, then the text for search. Runs on the <c>media</c> queue,
/// whose Hangfire server has <see cref="MediaOptions.MaxConcurrentDocumentJobs"/> workers, and is stopped after
/// <see cref="MediaOptions.DocumentJobTimeout"/>. Any error marks the asset Failed with a stable reason.
/// </summary>
public sealed partial class DocumentProcessingJob(
    AppDbContext db,
    IFileStorage storage,
    IMediaStatusNotifier notifier,
    PdfRenderer renderer,
    IOptions<MediaOptions> options,
    ILogger<DocumentProcessingJob> logger)
{
    public const string Queue = "media";

    [Queue(Queue)]
    [AutomaticRetry(Attempts = 0)]
    public async Task RunAsync(Guid assetId, CancellationToken cancellationToken)
    {
        var asset = await db.MediaAssets.Include(a => a.Pages).FirstOrDefaultAsync(a => a.Id == assetId, cancellationToken);
        if (asset is not { Kind: MediaKind.Document, Status: MediaStatus.Processing, OriginalPath: not null }) return;

        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(options.Value.DocumentJobTimeout);
        var ct = timeout.Token;

        try
        {
            var pdf = await ReadAsync(asset.OriginalPath, ct);
            var folder = DocumentPath.TryParse(asset.OriginalPath, out var path)
                ? path
                : throw new InvalidOperationException($"Unexpected document path '{asset.OriginalPath}'.");

            var done = asset.Pages.Select(p => p.PageNo).ToHashSet();
            foreach (var pageNo in Enumerable.Range(1, asset.PageCount!.Value).Where(n => !done.Contains(n)))
            {
                // PDFium can't be interrupted inside a page; the timeout is checked between pages.
                var page = await Task.Run(() => renderer.Render(pdf, pageNo), ct).WaitAsync(ct);
                var thumbPath = folder.Page(pageNo, DocumentPath.ThumbSize);
                var viewPath = folder.Page(pageNo, DocumentPath.ViewSize);
                await SaveAsync(thumbPath, page.Thumb, ct);
                await SaveAsync(viewPath, page.View, ct);

                asset.AddPage(pageNo, thumbPath, viewPath, page.Width, page.Height, page.BlurHash, page.Thumb.Length + page.View.Length);
                await db.SaveChangesAsync(CancellationToken.None);
                if (pageNo == 1) await notifier.NotifyAsync(asset, CancellationToken.None);
            }

            var text = await Task.Run(() => renderer.ExtractText(pdf, ct), ct);
            asset.CompleteDocument(text is null ? null : ArabicNormalizer.Normalize(text));
            await db.SaveChangesAsync(CancellationToken.None);
            LogDocumentReady(logger, asset.Id, asset.PageCount.Value);
        }
        catch (OperationCanceledException) when (timeout.IsCancellationRequested && !cancellationToken.IsCancellationRequested)
        {
            LogDocumentTimedOut(logger, asset.Id, options.Value.DocumentJobTimeout);
            await FailAsync(asset, MediaErrors.ProcessingTimeout);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogDocumentFailed(logger, ex, asset.Id);
            await FailAsync(asset, MediaErrors.ProcessingFailed);
        }

        await notifier.NotifyAsync(asset, CancellationToken.None);
    }

    private async Task<byte[]> ReadAsync(string relativePath, CancellationToken ct)
    {
        await using var stream = await storage.OpenReadAsync(relativePath, ct);
        using var buffer = new MemoryStream();
        await stream.CopyToAsync(buffer, ct);
        return buffer.ToArray();
    }

    private async Task SaveAsync(string relativePath, byte[] content, CancellationToken ct)
    {
        // A retried job may find a page file whose row was never saved; storage never overwrites, so remove it first.
        await storage.DeleteAsync(relativePath, ct);
        using var stream = new MemoryStream(content, writable: false);
        await storage.SaveAsync(relativePath, stream, ct);
    }

    private async Task FailAsync(MediaAsset asset, string reason)
    {
        // Pages already rendered stay on the asset: the user deletes it (or the orphan cleanup does) with its files.
        asset.Fail(reason);
        await db.SaveChangesAsync(CancellationToken.None);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Document {AssetId} is ready ({Pages} pages)")]
    private static partial void LogDocumentReady(ILogger logger, Guid assetId, int pages);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Document {AssetId} did not finish within {Timeout}")]
    private static partial void LogDocumentTimedOut(ILogger logger, Guid assetId, TimeSpan timeout);

    [LoggerMessage(Level = LogLevel.Error, Message = "Document {AssetId} could not be processed")]
    private static partial void LogDocumentFailed(ILogger logger, Exception exception, Guid assetId);
}
