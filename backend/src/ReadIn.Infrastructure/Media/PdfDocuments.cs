using System.Text;
using Microsoft.Extensions.Logging;
using PDFtoImage;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;
using SkiaSharp;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Core;
using UglyToad.PdfPig.Exceptions;

namespace ReadIn.Infrastructure.Media;

/// <summary>Reads PDF metadata with PdfPig, without rendering anything (ADR 0011).</summary>
internal sealed class PdfInspector : IPdfInspector
{
    public Result<PdfInfo> Inspect(byte[] pdf)
    {
        if (!PdfSignature.Matches(pdf)) return MediaErrors.UnsupportedType;
        try
        {
            using var document = PdfDocument.Open(pdf);
            // An owner password only (no user password) still opens, but the file is still encrypted: reject it too.
            if (document.IsEncrypted) return MediaErrors.PdfEncrypted;
            if (document.NumberOfPages < 1) return MediaErrors.PdfCorrupted;

            var title = document.Information.Title;
            return new PdfInfo(document.NumberOfPages, string.IsNullOrWhiteSpace(title) ? null : title.Trim());
        }
        catch (PdfDocumentEncryptedException)
        {
            return MediaErrors.PdfEncrypted;
        }
        catch (Exception ex) when (ex is PdfDocumentFormatException or InvalidOperationException or ArgumentException
                                       or IndexOutOfRangeException or NullReferenceException or InvalidCastException
                                       or KeyNotFoundException or NotSupportedException or FormatException)
        {
            // PdfPig throws a variety of exceptions on damaged files; all of them mean "unreadable".
            return MediaErrors.PdfCorrupted;
        }
    }
}

/// <summary>The PDF magic bytes: every PDF starts with <c>%PDF-</c>.</summary>
public static class PdfSignature
{
    public static bool Matches(ReadOnlySpan<byte> header) => header.StartsWith("%PDF-"u8);
}

/// <summary>One rendered page: a 1080 px view and a 400 px thumb (WebP) plus its BlurHash.</summary>
public sealed record RenderedPage(int PageNo, int Width, int Height, byte[] View, byte[] Thumb, string BlurHash);

/// <summary>
/// Renders PDF pages with PDFium (PDFtoImage) at a capped resolution, so a page with a huge or extreme size can't
/// exhaust memory: at most <see cref="MaxDpi"/> DPI, <see cref="ViewWidth"/> px wide and <see cref="MaxPageHeight"/> px tall.
/// </summary>
public sealed partial class PdfRenderer(ILogger<PdfRenderer> logger)
{
    public const int ViewWidth = 1080;
    public const int ThumbWidth = 400;
    public const int MaxDpi = 200;
    public const int MaxPageHeight = ViewWidth * 4;
    public const int WebpQuality = 78;

    /// <summary>PDFium is not thread-safe; every call into it goes through this lock.</summary>
    private static readonly Lock Pdfium = new();

    public RenderedPage Render(byte[] pdf, int pageNo)
    {
        if (!(OperatingSystem.IsWindows() || OperatingSystem.IsLinux() || OperatingSystem.IsMacOS()))
            throw new PlatformNotSupportedException("PDF rendering needs Windows, Linux or macOS.");

        SKBitmap view;
        lock (Pdfium)
        {
            // CA1416 can't follow the platform check above through the lock; the API servers run on these three OSes only.
#pragma warning disable CA1416
            var size = Conversion.GetPageSize(pdf, pageNo - 1);
            var (width, height) = TargetSize(size.Width, size.Height);
            view = Conversion.ToImage(pdf, pageNo - 1, options: new RenderOptions(
                Width: width,
                Height: height,
                WithAnnotations: true,
                BackgroundColor: SKColors.White));
#pragma warning restore CA1416
        }

        using (view)
        {
            using var thumb = ImageEncoding.Resize(view, Math.Min(ThumbWidth, view.Width));
            return new RenderedPage(
                pageNo,
                view.Width,
                view.Height,
                ImageEncoding.EncodeWebp(view, WebpQuality),
                ImageEncoding.EncodeWebp(thumb, WebpQuality),
                BlurHashEncoder.Encode(thumb));
        }
    }

    /// <summary>Plain text of every page, for search (SPEC §22). Extraction problems are logged, never fatal.</summary>
    public string? ExtractText(byte[] pdf, CancellationToken cancellationToken)
    {
        try
        {
            using var document = PdfDocument.Open(pdf);
            var text = new StringBuilder();
            foreach (var page in document.GetPages())
            {
                cancellationToken.ThrowIfCancellationRequested();
                text.AppendJoin(' ', page.GetWords().Select(w => w.Text)).Append('\n');
                if (text.Length > MaxExtractedChars) break;
            }
            var result = text.ToString().Trim();
            return result.Length == 0 ? null : result[..Math.Min(result.Length, MaxExtractedChars)];
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogTextExtractionFailed(logger, ex);
            return null;
        }
    }

    /// <summary>Text beyond this is not indexed (a 100-page document is usually far below it).</summary>
    public const int MaxExtractedChars = 1_000_000;

    internal static (int Width, int Height) TargetSize(float widthPoints, float heightPoints)
    {
        if (!(widthPoints > 0) || !(heightPoints > 0)) throw new InvalidOperationException("The PDF page has no size.");

        var width = (int)Math.Min(ViewWidth, Math.Round(widthPoints / 72f * MaxDpi));
        width = Math.Max(1, width);
        var height = (int)Math.Max(1, Math.Round(width * (double)heightPoints / widthPoints));
        if (height > MaxPageHeight)
        {
            width = (int)Math.Max(1, Math.Round(MaxPageHeight * (double)widthPoints / heightPoints));
            height = MaxPageHeight;
        }
        return (width, height);
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not extract the text of a PDF; it will not be searchable")]
    private static partial void LogTextExtractionFailed(ILogger logger, Exception exception);
}
