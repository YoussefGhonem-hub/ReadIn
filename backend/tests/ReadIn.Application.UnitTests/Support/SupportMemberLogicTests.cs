using ReadIn.Application.Features.Support;
using ReadIn.Domain.Support;

namespace ReadIn.Application.UnitTests.Support;

/// <summary>
/// SPEC F35 member-side rules: screenshots by their bytes (JPEG, PNG, WebP; ≤ 3; ≤ 5 MB; never empty), the text lengths
/// counted after trimming, and the one-line excerpt of the lists.
/// </summary>
public sealed class SupportMemberLogicTests
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static readonly byte[] Png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D, 0x49, 0x48, 0x44, 0x52];
    private static readonly byte[] Jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A, 0x46, 0x49, 0x46, 0, 1, 1, 0, 0, 1];
    private static readonly byte[] Webp = [.. "RIFF"u8, 0x24, 0, 0, 0, .. "WEBPVP8 "u8];
    private static readonly byte[] Gif = [.. "GIF89a"u8, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0];
    private static readonly byte[] Pdf = [.. "%PDF-1.7\n"u8, 0, 0, 0, 0, 0, 0, 0];

    private static SupportScreenshotUpload Upload(byte[] bytes) => new(new MemoryStream(bytes));

    [Fact]
    public void Screenshots_are_recognized_by_their_bytes()
    {
        SupportScreenshotFormat.Detect(Png).Should().Be(SupportScreenshotFormat.Png);
        SupportScreenshotFormat.Detect(Jpeg).Should().Be(SupportScreenshotFormat.Jpeg);
        SupportScreenshotFormat.Detect(Webp).Should().Be(SupportScreenshotFormat.Webp);
        SupportScreenshotFormat.Detect(Gif).Should().BeNull();
        SupportScreenshotFormat.Detect(Pdf).Should().BeNull("a PDF proof is fine for F19, not for a screenshot");
        SupportScreenshotFormat.Detect([]).Should().BeNull();
    }

    [Fact]
    public async Task Up_to_three_images_of_at_most_5_MB_pass_the_check()
    {
        var ok = await SupportScreenshots.CheckAsync([Upload(Png), Upload(Jpeg), Upload(Webp)], Ct);
        ok.Value.Select(f => f.Format.ContentType).Should().Equal("image/png", "image/jpeg", "image/webp");

        (await SupportScreenshots.CheckAsync([Upload(Png), Upload(Png), Upload(Png), Upload(Png)], Ct)).Error
            .Should().Be(SupportErrors.TooManyAttachments);
        (await SupportScreenshots.CheckAsync([Upload(Png), Upload(Gif)], Ct)).Error.Should().Be(SupportErrors.AttachmentInvalid);
        (await SupportScreenshots.CheckAsync([Upload([])], Ct)).Error.Should().Be(SupportErrors.AttachmentInvalid);

        byte[] tooBig = [.. Png, .. new byte[SupportAttachment.MaxBytes]];
        (await SupportScreenshots.CheckAsync([Upload(tooBig)], Ct)).Error.Should().Be(SupportErrors.AttachmentInvalid);
        byte[] justRight = [.. Png, .. new byte[SupportAttachment.MaxBytes - Png.Length]];
        (await SupportScreenshots.CheckAsync([Upload(justRight)], Ct)).IsSuccess.Should().BeTrue();

        (await SupportScreenshots.CheckAsync([], Ct)).Value.Should().BeEmpty();
    }

    [Theory]
    [InlineData("  Hello  ", 5, 120, true)]
    [InlineData(" Hi ", 5, 120, false)]
    [InlineData("   ", 5, 120, true)] // blank is "missing": the required rule reports it
    [InlineData(null, 5, 120, true)]
    public void Lengths_count_after_trimming(string? text, int min, int max, bool fits) =>
        SupportText.Fits(text, min, max).Should().Be(fits);

    [Fact]
    public void An_excerpt_is_one_line_of_at_most_140_characters()
    {
        SupportText.Excerpt("First line\n\n  second   line").Should().Be("First line second line");

        var excerpt = SupportText.Excerpt(new string('a', 300));
        excerpt.Should().HaveLength(140).And.EndWith("…");
        SupportText.Excerpt(new string('b', 140)).Should().Be(new string('b', 140));
    }
}
