using System.Text;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure.Storage;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.Storage;

public sealed class SkiaImageProcessorTests
{
    private static readonly string[] AllowedWebpChunks = ["VP8 ", "VP8L", "VP8X", "ALPH"];

    private readonly SkiaImageProcessor _processor = new();

    private IReadOnlyList<ProcessedImage> Process(byte[] bytes, ImageFormat format, UploadPurpose purpose) =>
        ProcessSet(bytes, format, purpose).Variants;

    private ProcessedImageSet ProcessSet(byte[] bytes, ImageFormat format, UploadPurpose purpose)
    {
        var result = _processor.Process(new MemoryStream(bytes), format, purpose);
        result.IsSuccess.Should().BeTrue(result.Error?.Code);
        return result.Value;
    }

    private static SKSizeI DecodedSize(ProcessedImage image)
    {
        using var codec = SKCodec.Create(SKData.CreateCopy(image.Content));
        codec.EncodedFormat.Should().Be(SKEncodedImageFormat.Webp);
        return codec.Info.Size;
    }

    [Fact]
    public void Avatars_are_center_cropped_to_64_128_256_and_512_squares()
    {
        var images = Process(TestImages.Encode(1000, 600, SKEncodedImageFormat.Jpeg), ImageFormat.Jpeg, UploadPurpose.Avatar);

        images.Select(i => (i.Size, i.Width, i.Height)).Should().Equal((64, 64, 64), (128, 128, 128), (256, 256, 256), (512, 512, 512));
        images.Select(DecodedSize).Should().Equal(new SKSizeI(64, 64), new SKSizeI(128, 128), new SKSizeI(256, 256), new SKSizeI(512, 512));
    }

    [Fact]
    public void Covers_keep_their_aspect_ratio_at_400_800_and_1200_wide()
    {
        var images = Process(TestImages.Encode(3000, 1000, SKEncodedImageFormat.Png), ImageFormat.Png, UploadPurpose.Cover);

        images.Select(i => (i.Size, i.Width, i.Height)).Should().Equal((400, 400, 133), (800, 800, 267), (1200, 1200, 400));
        DecodedSize(images[^1]).Should().Be(new SKSizeI(1200, 400));
    }

    [Fact]
    public void Post_images_get_320_640_1080_and_1600_wide_variants()
    {
        var set = ProcessSet(TestImages.Encode(4000, 3000, SKEncodedImageFormat.Webp), ImageFormat.Webp, UploadPurpose.ArticleImage);

        set.Variants.Select(i => (i.Width, i.Height)).Should().Equal((320, 240), (640, 480), (1080, 810), (1600, 1200));
        (set.Width, set.Height).Should().Be((4000, 3000), "the original size is reported for the aspect ratio");
    }

    [Fact]
    public void Small_images_are_never_upscaled()
    {
        var article = Process(TestImages.Encode(800, 600, SKEncodedImageFormat.Png), ImageFormat.Png, UploadPurpose.ArticleImage);
        var avatar = Process(TestImages.Encode(300, 200, SKEncodedImageFormat.Png), ImageFormat.Png, UploadPurpose.Avatar);

        article.Select(i => (i.Size, i.Width, i.Height)).Should().Equal([(320, 320, 240), (640, 640, 480), (800, 800, 600)], "800 px is the largest variant, named by its real width");
        avatar.Select(i => (i.Width, i.Height)).Should().Equal((64, 64), (128, 128), (200, 200));
    }

    [Fact]
    public void Exif_metadata_is_stripped_and_the_orientation_is_applied()
    {
        const string secret = "GPS-30.0444N-31.2357E-SERIAL-XYZ";
        // Orientation 6: the camera was turned 90° clockwise, so the stored 300 × 150 pixels show a 150 × 300 photo.
        var jpeg = TestImages.JpegWithExif(300, 150, orientation: 6, secret);
        Encoding.ASCII.GetString(jpeg).Should().Contain(secret, "the fixture must really carry the metadata");

        var image = Process(jpeg, ImageFormat.Jpeg, UploadPurpose.ArticleImage).Single();

        (image.Width, image.Height).Should().Be((150, 300));
        Encoding.ASCII.GetString(image.Content).Should().NotContain(secret).And.NotContain("Exif");
        TestImages.WebpChunks(image.Content).Should().OnlyContain(c => AllowedWebpChunks.Contains(c), "no EXIF, XMP or ICCP chunk");
    }

    [Fact]
    public void Output_carries_no_metadata_chunks_for_any_input_format()
    {
        foreach (var (format, encoded) in new[]
                 {
                     (ImageFormat.Jpeg, SKEncodedImageFormat.Jpeg),
                     (ImageFormat.Png, SKEncodedImageFormat.Png),
                     (ImageFormat.Webp, SKEncodedImageFormat.Webp),
                 })
        {
            var images = Process(TestImages.Encode(640, 480, encoded), format, UploadPurpose.Avatar);

            images.SelectMany(i => TestImages.WebpChunks(i.Content)).Should().OnlyContain(c => AllowedWebpChunks.Contains(c));
        }
    }

    [Fact]
    public void Images_wider_than_8000_pixels_are_rejected()
    {
        var result = _processor.Process(
            new MemoryStream(TestImages.Encode(UploadLimits.MaxDimension + 1, 10, SKEncodedImageFormat.Png)), ImageFormat.Png, UploadPurpose.Cover);

        result.Error.Should().Be(UploadErrors.DimensionsTooLarge);
    }

    [Fact]
    public void Images_exactly_8000_pixels_wide_are_accepted()
    {
        var result = _processor.Process(
            new MemoryStream(TestImages.Encode(UploadLimits.MaxDimension, 10, SKEncodedImageFormat.Png)), ImageFormat.Png, UploadPurpose.Cover);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void A_decompression_bomb_is_rejected_from_its_header_alone()
    {
        // 50 000 × 50 000 RGBA would need ~10 GB; the file itself is a few dozen bytes.
        var bomb = TestImages.PngClaiming(50_000, 50_000);
        bomb.Length.Should().BeLessThan(200);

        var result = _processor.Process(new MemoryStream(bomb), ImageFormat.Png, UploadPurpose.ArticleImage);

        result.Error.Should().Be(UploadErrors.DimensionsTooLarge);
    }

    [Fact]
    public void A_renamed_executable_is_not_an_image()
    {
        byte[] exe = [0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00];

        var result = _processor.Process(new MemoryStream(exe), ImageFormat.Jpeg, UploadPurpose.Avatar);

        result.Error.Should().Be(UploadErrors.InvalidImage);
    }

    [Fact]
    public void Content_must_match_the_format_detected_from_the_magic_bytes()
    {
        var png = TestImages.Encode(64, 64, SKEncodedImageFormat.Png);

        _processor.Process(new MemoryStream(png), ImageFormat.Jpeg, UploadPurpose.Avatar).Error.Should().Be(UploadErrors.InvalidImage);
    }

    [Fact]
    public void Truncated_images_are_rejected()
    {
        var jpeg = TestImages.Encode(400, 400, SKEncodedImageFormat.Jpeg);

        var result = _processor.Process(new MemoryStream(jpeg[..(jpeg.Length / 3)]), ImageFormat.Jpeg, UploadPurpose.Avatar);

        result.Error.Should().Be(UploadErrors.InvalidImage);
    }
}
