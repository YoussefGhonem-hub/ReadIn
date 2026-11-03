using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure.Storage;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.Media;

/// <summary>The image half of the media pipeline (ADR 0011) on real files: HEIC, EXIF/GPS, widths, BlurHash.</summary>
public sealed class MediaImageTests
{
    private readonly SkiaImageProcessor _processor = new();

    private ProcessedImageSet Process(string fixture, UploadPurpose purpose)
    {
        var bytes = MediaFixtures.Read(fixture);
        var format = ImageSignatures.Detect(bytes.AsSpan(0, ImageSignatures.HeaderLength));
        format.Should().NotBeNull($"{fixture} must be recognized by its magic bytes");

        var result = _processor.Process(new MemoryStream(bytes), format!.Value, purpose);
        result.IsSuccess.Should().BeTrue(result.Error?.Code);
        return result.Value;
    }

    private static SKBitmap Decode(ProcessedImage image)
    {
        using var codec = SKCodec.Create(SKData.CreateCopy(image.Content));
        codec.EncodedFormat.Should().Be(SKEncodedImageFormat.Webp);
        return SKBitmap.Decode(image.Content);
    }

    [Theory]
    [InlineData("exif-rotated.jpg", ImageFormat.Jpeg)]
    [InlineData("small.png", ImageFormat.Png)]
    [InlineData("medium.webp", ImageFormat.Webp)]
    [InlineData("sample.heic", ImageFormat.Heic)]
    public void Fixtures_are_recognized_by_their_magic_bytes(string fixture, ImageFormat expected) =>
        ImageSignatures.Detect(MediaFixtures.Read(fixture).AsSpan(0, ImageSignatures.HeaderLength)).Should().Be(expected);

    [Fact]
    public void A_real_heic_photo_is_decoded_and_stored_as_webp()
    {
        var set = Process("sample.heic", UploadPurpose.ArticleImage);

        (set.Width, set.Height).Should().Be((640, 480));
        set.Variants.Select(v => (v.Width, v.Height)).Should().Equal((320, 240), (640, 480));
        foreach (var variant in set.Variants)
        {
            using var bitmap = Decode(variant);
            bitmap.Width.Should().Be(variant.Width);
        }
    }

    [Fact]
    public void Exif_orientation_is_applied_and_gps_and_camera_tags_are_stripped()
    {
        var original = MediaFixtures.Read("exif-rotated.jpg");
        MediaFixtures.Contains(original, "ReadInTestCam").Should().BeTrue("the fixture carries camera tags");

        var set = Process("exif-rotated.jpg", UploadPurpose.ArticleImage);

        // Stored 1200 × 800 with orientation 6 (rotate 90° clockwise): the photo is 800 × 1200.
        (set.Width, set.Height).Should().Be((800, 1200));
        set.Variants.Select(v => (v.Width, v.Height)).Should().Equal((320, 480), (640, 960), (800, 1200));

        // The red marker was at the stored top-left corner; after the rotation it is at the top-right.
        using var largest = Decode(set.Variants[^1]);
        var topRight = largest.GetPixel(largest.Width - 20, 20);
        topRight.Red.Should().BeGreaterThan(200);
        topRight.Green.Should().BeLessThan(60);

        foreach (var variant in set.Variants)
        {
            MediaFixtures.Contains(variant.Content, "ReadInTestCam").Should().BeFalse();
            MediaFixtures.Contains(variant.Content, "Exif").Should().BeFalse();
            MediaFixtures.Contains(variant.Content, "GPS").Should().BeFalse();
        }
    }

    [Fact]
    public void Small_images_keep_their_own_width_as_the_only_variant()
    {
        var set = Process("small.png", UploadPurpose.ArticleImage);

        set.Variants.Select(v => v.Size).Should().Equal(200);
        set.Variants.Single().Height.Should().Be(150);
    }

    [Fact]
    public void Mid_size_images_stop_at_their_own_width()
    {
        Process("medium.webp", UploadPurpose.ArticleImage).Variants.Select(v => v.Size).Should().Equal(320, 640, 1000);
    }

    [Fact]
    public void Every_image_gets_a_blurhash_placeholder()
    {
        foreach (var fixture in new[] { "exif-rotated.jpg", "small.png", "medium.webp", "sample.heic" })
            Process(fixture, UploadPurpose.ArticleImage).BlurHash.Should().HaveLength(28, fixture);
    }

    [Fact]
    public void Webp_is_encoded_at_quality_78() => SkiaImageProcessor.WebpQuality.Should().Be(78);

    [Fact]
    public void Avatars_are_square_and_their_size_is_the_square_side()
    {
        var set = Process("medium.webp", UploadPurpose.Avatar);

        (set.Width, set.Height).Should().Be((700, 700));
        set.Variants.Select(v => (v.Width, v.Height)).Should().Equal((64, 64), (128, 128), (256, 256), (512, 512));
    }

    [Fact]
    public void A_heic_with_the_wrong_content_is_rejected()
    {
        var notReallyHeic = MediaFixtures.Read("sample.heic")[..40];

        _processor.Process(new MemoryStream(notReallyHeic), ImageFormat.Heic, UploadPurpose.ArticleImage)
            .Error.Should().Be(UploadErrors.InvalidImage);
    }
}
