using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using SkiaSharp;

namespace ReadIn.Infrastructure.Storage;

/// <summary>
/// SkiaSharp implementation of <see cref="IImageProcessor"/> (ADR 0010). The header is read before any pixel is
/// decoded, so oversized images are rejected cheaply. Output is encoded from pixels only, so EXIF, XMP and ICC
/// metadata never reach the stored file; EXIF orientation is applied first so photos stay upright.
/// </summary>
internal sealed class SkiaImageProcessor : IImageProcessor
{
    public const int WebpQuality = 80;

    private static readonly SKSamplingOptions Sampling = new(SKFilterMode.Linear, SKMipmapMode.Linear);

    // An 8000 × 8000 decode needs 256 MB; cap how many run at once.
    private static readonly SemaphoreSlim Gate = new(Math.Max(2, Environment.ProcessorCount / 2));

    public Result<IReadOnlyList<ProcessedImage>> Process(Stream content, ImageFormat format, UploadPurpose purpose)
    {
        using var data = SKData.Create(content);
        using var codec = data is null ? null : SKCodec.Create(data);
        if (codec is null || codec.EncodedFormat != ToSkia(format)) return UploadErrors.InvalidImage;

        var info = codec.Info;
        if (info.Width <= 0 || info.Height <= 0) return UploadErrors.InvalidImage;
        if (info.Width > UploadLimits.MaxDimension || info.Height > UploadLimits.MaxDimension) return UploadErrors.DimensionsTooLarge;

        Gate.Wait();
        try
        {
            using var upright = DecodeUpright(codec, purpose.Sizes[^1], purpose.Square);
            if (upright is null) return UploadErrors.InvalidImage;

            var images = purpose.Sizes.Select(size => Encode(upright, size, purpose.Square)).ToList();
            return Result.Success<IReadOnlyList<ProcessedImage>>(images);
        }
        finally
        {
            Gate.Release();
        }
    }

    /// <summary>
    /// Decodes into sRGB and applies the EXIF orientation. Codecs that can (JPEG: 1/2, 1/4, 1/8) decode at a reduced
    /// scale when that still covers the largest size, which keeps memory low for big photos.
    /// </summary>
    private static SKImage? DecodeUpright(SKCodec codec, int largestSize, bool square)
    {
        var origin = codec.EncodedOrigin;
        var swapsAxes = origin is SKEncodedOrigin.LeftTop or SKEncodedOrigin.RightTop or SKEncodedOrigin.RightBottom or SKEncodedOrigin.LeftBottom;

        var full = codec.Info.Size;
        var decodeSize = full;
        var needed = Math.Min(largestSize, Measure(full));
        var scaled = codec.GetScaledDimensions(Math.Min(1f, (float)needed / Measure(full)));
        if (scaled.Width > 0 && scaled.Height > 0 && Measure(scaled) >= needed) decodeSize = scaled;

        var decodeInfo = new SKImageInfo(decodeSize.Width, decodeSize.Height, SKColorType.Rgba8888, SKAlphaType.Premul, SKColorSpace.CreateSrgb());
        using var bitmap = new SKBitmap(decodeInfo);
        if (codec.GetPixels(decodeInfo, bitmap.GetPixels()) != SKCodecResult.Success) return null;
        bitmap.SetImmutable();

        using var decoded = SKImage.FromBitmap(bitmap);
        var (width, height) = swapsAxes ? (decodeSize.Height, decodeSize.Width) : (decodeSize.Width, decodeSize.Height);

        // Redraw even when already upright: the copy has no color space, so the encoder writes no ICC profile.
        using var surface = SKSurface.Create(new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul));
        if (surface is null) return null;
        surface.Canvas.SetMatrix(OrientationMatrix(origin, decodeSize.Width, decodeSize.Height));
        // Quarter turns and flips land exactly on pixels: nearest sampling copies them unchanged.
        surface.Canvas.DrawImage(decoded, 0, 0, new SKSamplingOptions(SKFilterMode.Nearest), paint: null);
        return surface.Snapshot();

        // The side that size buckets limit, in upright terms: width, or the short side for square crops.
        int Measure(SKSizeI size)
        {
            var uprightWidth = swapsAxes ? size.Height : size.Width;
            return square ? Math.Min(size.Width, size.Height) : uprightWidth;
        }
    }

    private static ProcessedImage Encode(SKImage upright, int size, bool square)
    {
        SKRect source;
        int width, height;
        if (square)
        {
            var side = Math.Min(upright.Width, upright.Height);
            source = SKRect.Create((upright.Width - side) / 2, (upright.Height - side) / 2, side, side);
            width = height = Math.Min(size, side);
        }
        else
        {
            source = SKRect.Create(upright.Width, upright.Height);
            width = Math.Min(size, upright.Width);
            height = Math.Max(1, (int)Math.Round(upright.Height * (double)width / upright.Width));
        }

        using var surface = SKSurface.Create(new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul))
            ?? throw new InvalidOperationException($"Could not allocate a {width}×{height} image surface.");
        surface.Canvas.DrawImage(upright, source, SKRect.Create(width, height), Sampling, paint: null);

        using var pixels = surface.PeekPixels();
        using var webp = pixels.Encode(new SKWebpEncoderOptions(SKWebpEncoderCompression.Lossy, WebpQuality))
            ?? throw new InvalidOperationException("WebP encoding failed.");
        return new ProcessedImage(size, width, height, webp.ToArray());
    }

    /// <summary>Maps encoded pixel coordinates to upright ones (Skia's SkEncodedOriginToMatrix).</summary>
    private static SKMatrix OrientationMatrix(SKEncodedOrigin origin, int width, int height) => origin switch
    {
        SKEncodedOrigin.TopRight => new SKMatrix(-1, 0, width, 0, 1, 0, 0, 0, 1),
        SKEncodedOrigin.BottomRight => new SKMatrix(-1, 0, width, 0, -1, height, 0, 0, 1),
        SKEncodedOrigin.BottomLeft => new SKMatrix(1, 0, 0, 0, -1, height, 0, 0, 1),
        SKEncodedOrigin.LeftTop => new SKMatrix(0, 1, 0, 1, 0, 0, 0, 0, 1),
        SKEncodedOrigin.RightTop => new SKMatrix(0, -1, height, 1, 0, 0, 0, 0, 1),
        SKEncodedOrigin.RightBottom => new SKMatrix(0, -1, height, -1, 0, width, 0, 0, 1),
        SKEncodedOrigin.LeftBottom => new SKMatrix(0, 1, 0, -1, 0, width, 0, 0, 1),
        _ => SKMatrix.Identity,
    };

    private static SKEncodedImageFormat ToSkia(ImageFormat format) => format switch
    {
        ImageFormat.Jpeg => SKEncodedImageFormat.Jpeg,
        ImageFormat.Png => SKEncodedImageFormat.Png,
        ImageFormat.Webp => SKEncodedImageFormat.Webp,
        _ => throw new ArgumentOutOfRangeException(nameof(format), format, null),
    };
}
