using ReadIn.Infrastructure.Media;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.Media;

public sealed class BlurHashEncoderTests
{
    private const string Characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~";

    /// <summary>The pattern the expected values were computed for with the `blurhash` npm package (2.0.5).</summary>
    private static byte[] Pattern(int width, int height)
    {
        var rgba = new byte[width * height * 4];
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var i = (y * width + x) * 4;
                rgba[i] = (byte)(x * 32 % 256);
                rgba[i + 1] = (byte)(y * 40 % 256);
                rgba[i + 2] = (byte)((x + y) * 20 % 256);
                rgba[i + 3] = 255;
            }
        }
        return rgba;
    }

    /// <summary>
    /// Exact matches where the two official encoders agree. The C encoder (the reference we follow) quantizes the AC
    /// terms against their largest <em>absolute</em> value; the npm encoder against the largest signed value. Both are
    /// valid hashes for every decoder, they only differ when the largest-magnitude AC term is negative.
    /// </summary>
    [Theory]
    [InlineData(6, 8, 3, 4, "TbBY1@CFSIqaV_a~dIeZfRudXga{")]
    [InlineData(8, 6, 1, 1, "00F=al")]
    public void Matches_the_npm_encoder_where_both_references_agree(int width, int height, int componentsX, int componentsY, string expected) =>
        BlurHashEncoder.Encode(Pattern(width, height), width, height, componentsX, componentsY).Should().Be(expected);

    [Theory]
    [InlineData(8, 6, 4, 3, "LDF=al3tWk^+_O9#b0rFd;e[fSe.")]
    [InlineData(6, 8, 4, 3, "LEBY1@4AN.?^y@M+Wtm,dGd}fSd]")]
    [InlineData(8, 6, 3, 4, "TEF=al3ta[_OE8b0d;e[fS~qF:a_")]
    public void Size_flag_and_average_color_match_the_npm_encoder(int width, int height, int componentsX, int componentsY, string npm)
    {
        var hash = BlurHashEncoder.Encode(Pattern(width, height), width, height, componentsX, componentsY);

        hash.Should().HaveLength(npm.Length);
        hash[0].Should().Be(npm[0]);
        hash[2..6].Should().Be(npm[2..6], "the DC term is the average color");
    }

    [Theory]
    [InlineData(8, 6, 4, 3, "LDF=al3tWk^+_O9#b0rFd;e[fSe.")]
    [InlineData(6, 8, 4, 3, "LEBY1@4AN.?^y@M+Wtm,dGd}fSd]")]
    [InlineData(8, 6, 3, 4, "TEF=al3ta[_OE8b0d;e[fS~qF:a_")]
    [InlineData(6, 8, 3, 4, "TbBY1@CFSIqaV_a~dIeZfRudXga{")]
    public void Decodes_at_least_as_close_to_the_image_as_the_npm_hash(int width, int height, int componentsX, int componentsY, string npm)
    {
        var pixels = Pattern(width, height);
        var hash = BlurHashEncoder.Encode(pixels, width, height, componentsX, componentsY);

        double Error(byte[] decoded) =>
            Enumerable.Range(0, width * height * 4).Where(i => i % 4 != 3).Average(i => Math.Abs(decoded[i] - pixels[i]));

        Error(Decode(hash, width, height)).Should().BeLessThanOrEqualTo(Error(Decode(npm, width, height)) + 0.5);
    }

    [Fact]
    public void Landscape_bitmaps_get_a_4x3_hash_and_portrait_ones_3x4()
    {
        using var landscape = new SKBitmap(400, 300);
        using var portrait = new SKBitmap(300, 400);
        landscape.Erase(SKColors.SeaGreen);
        portrait.Erase(SKColors.SeaGreen);

        // 4 chars of header + DC, then 2 per AC component.
        BlurHashEncoder.Encode(landscape).Should().HaveLength(6 + 2 * (4 * 3 - 1)).And.StartWith("L");
        BlurHashEncoder.Encode(portrait).Should().HaveLength(6 + 2 * (3 * 4 - 1)).And.StartWith("T");
    }

    /// <summary>The reference decoder (woltapp/blurhash), as the clients run it.</summary>
    private static byte[] Decode(string hash, int width, int height)
    {
        int Base83(string s) => s.Aggregate(0, (value, c) => value * 83 + Characters.IndexOf(c));
        double ToLinear(int v) => v / 255.0 <= 0.04045 ? v / 255.0 / 12.92 : Math.Pow((v / 255.0 + 0.055) / 1.055, 2.4);
        byte ToSrgb(double v)
        {
            v = Math.Clamp(v, 0, 1);
            return (byte)(v <= 0.0031308 ? Math.Truncate(v * 12.92 * 255 + 0.5) : Math.Truncate((1.055 * Math.Pow(v, 1 / 2.4) - 0.055) * 255 + 0.5));
        }
        double SignPow(double v, double e) => Math.Sign(v) * Math.Pow(Math.Abs(v), e);

        var sizeFlag = Base83(hash[..1]);
        var (ny, nx) = (sizeFlag / 9 + 1, sizeFlag % 9 + 1);
        var maximum = (Base83(hash[1..2]) + 1) / 166.0;
        var colors = new (double R, double G, double B)[nx * ny];
        var dc = Base83(hash[2..6]);
        colors[0] = (ToLinear(dc >> 16), ToLinear((dc >> 8) & 255), ToLinear(dc & 255));
        for (var i = 1; i < colors.Length; i++)
        {
            var ac = Base83(hash.Substring(4 + i * 2, 2));
            colors[i] = (SignPow((ac / 361 - 9) / 9.0, 2) * maximum, SignPow((ac / 19 % 19 - 9) / 9.0, 2) * maximum, SignPow((ac % 19 - 9) / 9.0, 2) * maximum);
        }

        var pixels = new byte[width * height * 4];
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                double r = 0, g = 0, b = 0;
                for (var j = 0; j < ny; j++)
                {
                    for (var i = 0; i < nx; i++)
                    {
                        var basis = Math.Cos(Math.PI * x * i / width) * Math.Cos(Math.PI * y * j / height);
                        var color = colors[i + j * nx];
                        r += color.R * basis;
                        g += color.G * basis;
                        b += color.B * basis;
                    }
                }
                var p = (y * width + x) * 4;
                (pixels[p], pixels[p + 1], pixels[p + 2], pixels[p + 3]) = (ToSrgb(r), ToSrgb(g), ToSrgb(b), 255);
            }
        }
        return pixels;
    }
}
