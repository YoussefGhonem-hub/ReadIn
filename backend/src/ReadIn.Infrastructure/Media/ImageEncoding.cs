using SkiaSharp;

namespace ReadIn.Infrastructure.Media;

/// <summary>SkiaSharp helpers shared by the image pipeline and the PDF page renderer.</summary>
internal static class ImageEncoding
{
    private static readonly SKSamplingOptions HighQuality = new(SKCubicResampler.Mitchell);

    /// <summary>Scales to <paramref name="width"/> keeping the aspect ratio. Never upscales.</summary>
    public static SKBitmap Resize(SKBitmap source, int width)
    {
        width = Math.Clamp(width, 1, source.Width);
        var height = Math.Max(1, (int)Math.Round(source.Height * (double)width / source.Width));
        return Draw(source, new SKRectI(0, 0, source.Width, source.Height), width, height);
    }

    /// <summary>Draws <paramref name="sourceRect"/> of the source into a new sRGB bitmap of the given size.</summary>
    public static SKBitmap Draw(SKBitmap source, SKRectI sourceRect, int width, int height)
    {
        var info = new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul, SKColorSpace.CreateSrgb());
        var target = new SKBitmap(info);
        using var canvas = new SKCanvas(target);
        using var image = SKImage.FromBitmap(source);
        canvas.Clear(SKColors.Transparent);
        canvas.DrawImage(image, sourceRect, new SKRect(0, 0, width, height), HighQuality);
        return target;
    }

    /// <summary>Encodes as WebP. Skia writes no EXIF/XMP/GPS metadata, so the output is always clean.</summary>
    public static byte[] EncodeWebp(SKBitmap bitmap, int quality)
    {
        using var image = SKImage.FromBitmap(bitmap);
        using var data = image.Encode(SKEncodedImageFormat.Webp, quality)
                         ?? throw new InvalidOperationException("WebP encoding failed.");
        return data.ToArray();
    }
}
