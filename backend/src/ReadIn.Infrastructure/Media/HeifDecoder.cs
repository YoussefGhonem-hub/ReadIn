using ImageMagick;
using SkiaSharp;

namespace ReadIn.Infrastructure.Media;

/// <summary>
/// Decodes HEIC/HEIF photos (iPhone) with Magick.NET, because SkiaSharp has no HEIF codec on Windows and Linux
/// (ADR 0011). Only ever called for files whose magic bytes are HEIF, and always with the format forced, so
/// ImageMagick never sniffs (and never runs) any other of its coders. The pixels then go through the normal Skia pipeline.
/// </summary>
internal static class HeifDecoder
{
    private static readonly MagickReadSettings Settings = new() { Format = MagickFormat.Heic };

    static HeifDecoder()
    {
        // Process-wide ImageMagick limits: a hostile file can't allocate more than this.
        ResourceLimits.Memory = 512UL * 1024 * 1024;
        ResourceLimits.Area = 8000UL * 8000;
        ResourceLimits.Width = 16000;
        ResourceLimits.Height = 16000;
    }

    /// <summary>Reads only the header: the size as stored, before any pixel is decoded.</summary>
    public static (int Width, int Height)? ReadSize(byte[] data)
    {
        try
        {
            var info = new MagickImageInfo(data, Settings);
            return ((int)info.Width, (int)info.Height);
        }
        catch (MagickException)
        {
            return null;
        }
    }

    /// <summary>Decodes to an sRGB bitmap with the HEIF transforms (rotation/mirror) applied and every profile dropped.</summary>
    public static SKBitmap? Decode(byte[] data)
    {
        try
        {
            using var image = new MagickImage(data, Settings);
            image.AutoOrient();
            if (image.GetColorProfile() is not null) image.TransformColorSpace(ColorProfiles.SRGB);
            image.Strip();

            var width = (int)image.Width;
            var height = (int)image.Height;
            using var pixels = image.GetPixelsUnsafe();
            var rgba = pixels.ToByteArray(PixelMapping.RGBA) ?? throw new MagickCorruptImageErrorException("No pixels.");

            var bitmap = new SKBitmap(new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Unpremul, SKColorSpace.CreateSrgb()));
            System.Runtime.InteropServices.Marshal.Copy(rgba, 0, bitmap.GetPixels(), Math.Min(rgba.Length, bitmap.ByteCount));
            return bitmap;
        }
        catch (MagickException)
        {
            return null;
        }
    }
}
