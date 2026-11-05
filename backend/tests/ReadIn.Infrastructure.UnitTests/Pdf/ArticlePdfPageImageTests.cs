using PDFtoImage;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// The first page of each stress fixture compared with its approved image (SPEC §27: one Arabic and one English; the
/// file is always light). Rendered at 50 dpi in grey so the check is about the layout (logo, title, meta, disclaimer,
/// cover, direction), not anti-aliasing. To approve a deliberate change, set <c>READIN_PDF_BASELINES_DIR</c> to
/// <c>backend/tests/ReadIn.Infrastructure.UnitTests/Pdf/baselines</c>, run the test, and look at the new images.
/// </summary>
[Collection(ArticlePdfCollection.Name)]
public sealed class ArticlePdfPageImageTests(ArticlePdfFixture fixture)
{
    private const int Dpi = 50;

    /// <summary>A pixel differs when its grey level moves by more than this (0–255).</summary>
    private const int PixelTolerance = 48;

    /// <summary>The share of pixels that may differ: room for glyph rasterization, not for a moved block.</summary>
    private const double AllowedShare = 0.01;

    [Theory]
    [InlineData("ar-EG")]
    [InlineData("en")]
    public void The_first_page_looks_like_its_approved_image(string language)
    {
        var name = $"pdf-stress.{language}.page1.png";
        using var actual = Render(fixture.Pdf(language));

        if (Environment.GetEnvironmentVariable("READIN_PDF_BASELINES_DIR") is { Length: > 0 } approve)
        {
            Directory.CreateDirectory(approve);
            Save(actual, Path.Combine(approve, name));
            return;
        }

        var baselinePath = Path.Combine(AppContext.BaseDirectory, "Pdf", "baselines", name);
        File.Exists(baselinePath).Should().BeTrue($"{name} is approved (see the class summary to create it)");
        using var baseline = SKBitmap.Decode(baselinePath);

        actual.Width.Should().Be(baseline.Width);
        actual.Height.Should().Be(baseline.Height);
        var differing = 0;
        for (var y = 0; y < actual.Height; y++)
        {
            for (var x = 0; x < actual.Width; x++)
            {
                if (Math.Abs(actual.GetPixel(x, y).Red - baseline.GetPixel(x, y).Red) > PixelTolerance) differing++;
            }
        }

        var share = differing / (double)(actual.Width * actual.Height);
        if (share > AllowedShare)
        {
            var output = Path.Combine(Path.GetTempPath(), "readin-pdf-baselines");
            Directory.CreateDirectory(output);
            Save(actual, Path.Combine(output, name));
        }
        share.Should().BeLessThanOrEqualTo(AllowedShare,
            $"page 1 matches {name} (the new image is in {Path.Combine(Path.GetTempPath(), "readin-pdf-baselines")} when it doesn't)");
    }

    /// <summary>Page 1 in grey levels (the red channel of a grey image).</summary>
    private static SKBitmap Render(byte[] pdf)
    {
#pragma warning disable CA1416 // the tests run on Windows and Linux
        using var page = Conversion.ToImage(pdf, 0, options: new RenderOptions(Dpi: Dpi, BackgroundColor: SKColors.White));
#pragma warning restore CA1416
        var grey = new SKBitmap(page.Width, page.Height, SKColorType.Rgba8888, SKAlphaType.Opaque);
        for (var y = 0; y < page.Height; y++)
        {
            for (var x = 0; x < page.Width; x++)
            {
                var c = page.GetPixel(x, y);
                var level = (byte)Math.Round(0.299 * c.Red + 0.587 * c.Green + 0.114 * c.Blue);
                grey.SetPixel(x, y, new SKColor(level, level, level));
            }
        }
        return grey;
    }

    private static void Save(SKBitmap bitmap, string path)
    {
        using var png = bitmap.Encode(SKEncodedImageFormat.Png, 100);
        File.WriteAllBytes(path, png.ToArray());
    }
}
