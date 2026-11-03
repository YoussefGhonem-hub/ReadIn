using Microsoft.Extensions.Logging.Abstractions;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Media;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.Media;

/// <summary>PDF validation and rendering (ADR 0011) on the committed fixtures.</summary>
public sealed class PdfDocumentTests
{
    private readonly PdfInspector _inspector = new();
    private readonly PdfRenderer _renderer = new(NullLogger<PdfRenderer>.Instance);

    [Fact]
    public void A_normal_pdf_is_accepted_with_its_page_count()
    {
        var info = _inspector.Inspect(MediaFixtures.Read("normal-12-pages.pdf"));

        info.IsSuccess.Should().BeTrue();
        info.Value.PageCount.Should().Be(12);
    }

    [Fact]
    public void A_password_protected_pdf_is_rejected() =>
        _inspector.Inspect(MediaFixtures.Read("encrypted.pdf")).Error.Should().Be(MediaErrors.PdfEncrypted);

    [Fact]
    public void A_corrupted_pdf_is_rejected() =>
        _inspector.Inspect(MediaFixtures.Read("corrupted.pdf")).Error.Should().Be(MediaErrors.PdfCorrupted);

    [Fact]
    public void The_page_count_of_a_101_page_pdf_is_reported_for_the_limit_check() =>
        _inspector.Inspect(MediaFixtures.Read("too-many-pages-101.pdf")).Value.PageCount.Should().Be(101);

    [Theory]
    [InlineData(new byte[] { 0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00 })]                 // .exe renamed to .pdf
    [InlineData(new byte[] { 0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46 })]                 // a JPEG
    [InlineData(new byte[] { 0x20, 0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E })]                 // " %PDF-" not at offset 0
    public void Anything_that_does_not_start_with_the_pdf_magic_bytes_is_rejected(byte[] bytes) =>
        _inspector.Inspect(bytes).Error.Should().Be(MediaErrors.UnsupportedType);

    [Fact]
    public void Pages_render_to_a_1080_view_and_a_400_thumb_with_a_blurhash()
    {
        var page = _renderer.Render(MediaFixtures.Read("normal-12-pages.pdf"), pageNo: 1);

        (page.Width, page.Height).Should().Be((1080, 1527), "A4 portrait at 1080 px wide");
        using var view = SKBitmap.Decode(page.View);
        using var thumb = SKBitmap.Decode(page.Thumb);
        (view.Width, view.Height).Should().Be((1080, 1527));
        thumb.Width.Should().Be(400);
        page.BlurHash.Should().HaveLength(28).And.StartWith("T", "pages are portrait: 3×4 components");
        MediaFixtures.Contains(page.View, "RIFF").Should().BeTrue("pages are stored as WebP");
    }

    [Fact]
    public void Text_is_extracted_from_every_page_for_search()
    {
        var text = _renderer.ExtractText(MediaFixtures.Read("normal-12-pages.pdf"), CancellationToken.None);

        text.Should().Contain("readinmarker1").And.Contain("readinmarker7").And.Contain("readinmarker12").And.Contain("Dependency Injection");
    }

    [Theory]
    [InlineData(595.28f, 841.89f, 1080, 1527)] // A4 portrait
    [InlineData(841.89f, 595.28f, 1080, 764)]  // A4 landscape
    [InlineData(72f, 72f, 200, 200)]           // a 1-inch page: capped at 200 DPI, not blown up to 1080
    [InlineData(100f, 10_000f, 43, 4320)]      // absurdly tall: capped at 4320 px high
    [InlineData(14_400f, 100f, 1080, 8)]       // absurdly wide
    public void Render_sizes_are_capped_so_a_malicious_page_cannot_exhaust_memory(float width, float height, int expectedWidth, int expectedHeight) =>
        PdfRenderer.TargetSize(width, height).Should().Be((expectedWidth, expectedHeight));

    [Fact]
    public void A_page_without_a_size_is_an_error()
    {
        var act = () => PdfRenderer.TargetSize(0, 100);

        act.Should().Throw<InvalidOperationException>();
    }
}
