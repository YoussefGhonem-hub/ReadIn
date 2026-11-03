using ReadIn.Domain.Media;

namespace ReadIn.Domain.UnitTests.Media;

public sealed class MediaAssetTests
{
    private static readonly Guid OwnerId = Guid.NewGuid();

    [Fact]
    public void A_processed_image_is_ready_and_its_largest_variant_stands_in_for_the_original()
    {
        var image = MediaAsset.StartImage(OwnerId, MediaPurpose.Image, originalSizeBytes: 3_000_000);

        image.CompleteImage(4000, 3000, "LEHV6nWB2yk8", [
            new MediaVariant(1600, 1200, "/uploads/images/2026/11/a_1600.webp", 150_000),
            new MediaVariant(320, 240, "/uploads/images/2026/11/a_320.webp", 10_000),
        ]);

        image.Status.Should().Be(MediaStatus.Ready);
        image.Variants.Select(v => v.Width).Should().Equal(320, 1600);
        image.OriginalPath.Should().Be("/uploads/images/2026/11/a_1600.webp");
        image.StoredBytes.Should().Be(160_000);
        image.StoredPaths().Should().BeEquivalentTo(["/uploads/images/2026/11/a_1600.webp", "/uploads/images/2026/11/a_320.webp"]);
    }

    [Fact]
    public void An_image_cannot_have_the_document_purpose()
    {
        var act = () => MediaAsset.StartImage(OwnerId, MediaPurpose.Document, 10);

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Page_one_sets_the_document_size_and_placeholder()
    {
        var document = NewDocument(pages: 3);

        document.AddPage(1, "/p/1_400.webp", "/p/1_1080.webp", 1080, 1527, "hash-1", 50_000);

        document.Width.Should().Be(1080);
        document.Height.Should().Be(1527);
        document.BlurHash.Should().Be("hash-1");
        document.Status.Should().Be(MediaStatus.Processing);
        document.StoredBytes.Should().Be(1_000_000 + 50_000);
    }

    [Fact]
    public void A_document_is_ready_only_when_every_page_is_rendered()
    {
        var document = NewDocument(pages: 2);
        document.AddPage(1, "t1", "v1", 1080, 1527, "h", 1);

        var early = () => document.CompleteDocument("text");
        early.Should().Throw<InvalidOperationException>();

        document.AddPage(2, "t2", "v2", 1080, 1527, "h", 1);
        document.CompleteDocument("Dependency Injection");

        document.Status.Should().Be(MediaStatus.Ready);
        document.ExtractedText.Should().Be("Dependency Injection");
        document.StoredPaths().Should().BeEquivalentTo(["/uploads/documents/2026/11/d/original.pdf", "t1", "v1", "t2", "v2"]);
    }

    [Fact]
    public void A_retried_job_replaces_a_page_instead_of_duplicating_it()
    {
        var document = NewDocument(pages: 1);

        document.AddPage(1, "t1", "v1", 1080, 1527, "h", 10);
        document.AddPage(1, "t1", "v1", 1080, 1527, "h", 12);

        document.Pages.Should().ContainSingle().Which.Bytes.Should().Be(12);
    }

    [Fact]
    public void Pages_outside_the_document_are_rejected()
    {
        var document = NewDocument(pages: 2);

        var act = () => document.AddPage(3, "t", "v", 1, 1, "h", 1);

        act.Should().Throw<ArgumentOutOfRangeException>();
    }

    [Fact]
    public void Failing_records_the_reason()
    {
        var document = NewDocument(pages: 2);

        document.Fail(MediaErrors.ProcessingTimeout);

        document.Status.Should().Be(MediaStatus.Failed);
        document.FailureReason.Should().Be("media.processing_timeout");
    }

    [Fact]
    public void Document_titles_are_trimmed_and_capped()
    {
        var document = MediaAsset.StartDocument(OwnerId, "  " + new string('t', 5200) + "  ", allowDownload: false, 10, 1);

        document.Title.Should().HaveLength(MediaAsset.MaxTitleLength);
        document.AllowDownload.Should().BeFalse();
    }

    [Fact]
    public void Document_settings_require_a_title()
    {
        var document = NewDocument(pages: 1);

        document.UpdateDocumentSettings(" ", allowDownload: true).Error.Should().Be(AttachmentErrors.TitleRequired);
        document.UpdateDocumentSettings(new string('x', 5001), allowDownload: true).Error.Should().Be(AttachmentErrors.TitleTooLong);
        document.UpdateDocumentSettings(new string('x', 5000), allowDownload: true).IsSuccess.Should().BeTrue();
        document.UpdateDocumentSettings("Offshore inspection", allowDownload: true).IsSuccess.Should().BeTrue();

        document.Title.Should().Be("Offshore inspection");
        document.AllowDownload.Should().BeTrue();
    }

    private static MediaAsset NewDocument(int pages)
    {
        var document = MediaAsset.StartDocument(OwnerId, "Report", allowDownload: false, originalSizeBytes: 1_000_000, pageCount: pages);
        document.StartProcessing("/uploads/documents/2026/11/d/original.pdf");
        return document;
    }
}
