using System.Text;
using SkiaSharp;

namespace ReadIn.Infrastructure.Media;

/// <summary>
/// BlurHash encoder (https://github.com/woltapp/blurhash, MIT), ported from the reference TypeScript implementation so
/// the strings decode identically with the <c>blurhash</c> npm package (web) and <c>flutter_blurhash</c> (mobile).
/// Clients use the hash as the loading placeholder of every image and PDF page (ADR 0011).
/// </summary>
public static class BlurHashEncoder
{
    private const string Characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~";

    /// <summary>Encodes a bitmap; it is downscaled to at most 32 px first, which is plenty for a 4×3 hash.</summary>
    public static string Encode(SKBitmap bitmap)
    {
        var (componentsX, componentsY) = bitmap.Width >= bitmap.Height ? (4, 3) : (3, 4);
        var scale = Math.Min(1f, 32f / Math.Max(bitmap.Width, bitmap.Height));
        var info = new SKImageInfo(
            Math.Max(1, (int)Math.Round(bitmap.Width * scale)),
            Math.Max(1, (int)Math.Round(bitmap.Height * scale)),
            SKColorType.Rgba8888,
            SKAlphaType.Unpremul);

        using var small = new SKBitmap(info);
        using (var canvas = new SKCanvas(small))
        using (var image = SKImage.FromBitmap(bitmap))
        {
            canvas.Clear(SKColors.White);
            canvas.DrawImage(image, new SKRect(0, 0, info.Width, info.Height), new SKSamplingOptions(SKFilterMode.Linear, SKMipmapMode.Linear));
        }

        return Encode(small.GetPixelSpan(), info.Width, info.Height, componentsX, componentsY);
    }

    /// <summary>Encodes RGBA8888 pixels (alpha ignored), row-major.</summary>
    public static string Encode(ReadOnlySpan<byte> rgba, int width, int height, int componentsX, int componentsY)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(componentsX, 1);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(componentsX, 9);
        ArgumentOutOfRangeException.ThrowIfLessThan(componentsY, 1);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(componentsY, 9);
        if (rgba.Length < width * height * 4) throw new ArgumentException("Not enough pixel data.", nameof(rgba));

        var linear = new double[width * height * 3];
        for (var i = 0; i < width * height; i++)
        {
            linear[i * 3] = SrgbToLinear(rgba[i * 4]);
            linear[i * 3 + 1] = SrgbToLinear(rgba[i * 4 + 1]);
            linear[i * 3 + 2] = SrgbToLinear(rgba[i * 4 + 2]);
        }

        var factors = new (double R, double G, double B)[componentsX * componentsY];
        for (var y = 0; y < componentsY; y++)
        {
            for (var x = 0; x < componentsX; x++)
            {
                double normalisation = x == 0 && y == 0 ? 1 : 2;
                double r = 0, g = 0, b = 0;
                for (var j = 0; j < height; j++)
                {
                    var cosY = Math.Cos(Math.PI * y * j / height);
                    for (var i = 0; i < width; i++)
                    {
                        var basis = normalisation * Math.Cos(Math.PI * x * i / width) * cosY;
                        var p = (j * width + i) * 3;
                        r += basis * linear[p];
                        g += basis * linear[p + 1];
                        b += basis * linear[p + 2];
                    }
                }
                var scale = 1.0 / (width * height);
                factors[y * componentsX + x] = (r * scale, g * scale, b * scale);
            }
        }

        var hash = new StringBuilder();
        Encode83(componentsX - 1 + (componentsY - 1) * 9, 1, hash);

        double maximumValue;
        if (factors.Length > 1)
        {
            var actualMaximum = factors.Skip(1).Max(f => Math.Max(Math.Abs(f.R), Math.Max(Math.Abs(f.G), Math.Abs(f.B))));
            var quantisedMaximum = (int)Math.Floor(Math.Max(0, Math.Min(82, Math.Floor(actualMaximum * 166 - 0.5))));
            maximumValue = (quantisedMaximum + 1) / 166.0;
            Encode83(quantisedMaximum, 1, hash);
        }
        else
        {
            maximumValue = 1;
            Encode83(0, 1, hash);
        }

        var dc = factors[0];
        Encode83((LinearToSrgb(dc.R) << 16) + (LinearToSrgb(dc.G) << 8) + LinearToSrgb(dc.B), 4, hash);
        foreach (var ac in factors.Skip(1))
            Encode83(EncodeAc(ac.R, maximumValue) * 19 * 19 + EncodeAc(ac.G, maximumValue) * 19 + EncodeAc(ac.B, maximumValue), 2, hash);

        return hash.ToString();
    }

    private static int EncodeAc(double value, double maximumValue) =>
        (int)Math.Floor(Math.Max(0, Math.Min(18, Math.Floor(SignPow(value / maximumValue, 0.5) * 9 + 9.5))));

    private static double SignPow(double value, double exponent) => Math.Sign(value) * Math.Pow(Math.Abs(value), exponent);

    private static double SrgbToLinear(byte value)
    {
        var v = value / 255.0;
        return v <= 0.04045 ? v / 12.92 : Math.Pow((v + 0.055) / 1.055, 2.4);
    }

    private static int LinearToSrgb(double value)
    {
        var v = Math.Max(0, Math.Min(1, value));
        return v <= 0.0031308
            ? (int)Math.Truncate(v * 12.92 * 255 + 0.5)
            : (int)Math.Truncate((1.055 * Math.Pow(v, 1 / 2.4) - 0.055) * 255 + 0.5);
    }

    private static void Encode83(int value, int length, StringBuilder hash)
    {
        for (var i = 1; i <= length; i++)
        {
            var digit = value / (int)Math.Pow(83, length - i) % 83;
            hash.Append(Characters[digit]);
        }
    }
}
