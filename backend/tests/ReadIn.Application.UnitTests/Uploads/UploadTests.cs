using System.Text.Json;
using NSubstitute;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Uploads.Commands.UploadImage;
using ReadIn.Domain.Common;

namespace ReadIn.Application.UnitTests.Uploads;

public sealed class ImageSignatureTests
{
    [Theory]
    [InlineData(new byte[] { 0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, (byte)'J', (byte)'F', (byte)'I', (byte)'F', 0, 1 }, ImageFormat.Jpeg)]
    [InlineData(new byte[] { 0x89, (byte)'P', (byte)'N', (byte)'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D }, ImageFormat.Png)]
    [InlineData(new byte[] { (byte)'R', (byte)'I', (byte)'F', (byte)'F', 1, 2, 3, 4, (byte)'W', (byte)'E', (byte)'B', (byte)'P' }, ImageFormat.Webp)]
    public void Supported_formats_are_recognized_by_their_magic_bytes(byte[] header, ImageFormat expected) =>
        ImageSignatures.Detect(header).Should().Be(expected);

    [Theory]
    [InlineData(new byte[] { 0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00 })] // .exe (MZ)
    [InlineData(new byte[] { 0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0, 0, 0 })]                   // GIF89a
    [InlineData(new byte[] { (byte)'<', (byte)'s', (byte)'v', (byte)'g', (byte)' ', 0, 0, 0, 0, 0, 0, 0 })] // SVG
    [InlineData(new byte[] { (byte)'R', (byte)'I', (byte)'F', (byte)'F', 1, 2, 3, 4, (byte)'W', (byte)'A', (byte)'V', (byte)'E' })] // WAV
    [InlineData(new byte[] { 0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37, 0, 0, 0, 0 })]             // %PDF
    [InlineData(new byte[] { 0xFF, 0xD8 })]                                                              // too short
    [InlineData(new byte[0])]
    public void Anything_else_is_rejected(byte[] header) =>
        ImageSignatures.Detect(header).Should().BeNull();
}

public sealed class UploadPathTests
{
    private const string Id = "0123456789abcdef0123456789abcdef";

    [Fact]
    public void Paths_follow_the_purpose_year_month_layout()
    {
        var path = UploadPath.Create(UploadPurpose.Cover, new DateTime(2026, 11, 3, 0, 0, 0, DateTimeKind.Utc), Guid.Parse(Id), 1200);

        path.Value.Should().Be($"/uploads/covers/2026/11/{Id}_1200.webp");
    }

    [Fact]
    public void Every_size_of_an_avatar_shares_the_id()
    {
        UploadPath.TryParse($"/uploads/avatars/2026/01/{Id}_512.webp", out var path).Should().BeTrue();

        path!.Purpose.Should().Be(UploadPurpose.Avatar);
        path.Variants.Select(v => v.Value).Should().Equal(
            $"/uploads/avatars/2026/01/{Id}_256.webp",
            $"/uploads/avatars/2026/01/{Id}_512.webp");
    }

    [Theory]
    [InlineData("https://lh3.googleusercontent.com/a/photo.jpg")]
    [InlineData("/uploads/avatars/2026/11/../../../appsettings.json")]
    [InlineData("/uploads/avatars/2026/11/" + Id + "_512.webp\n")]
    [InlineData("/uploads/avatars/2026/13/" + Id + "_512.webp")]
    [InlineData("/uploads/unknown/2026/11/" + Id + "_512.webp")]
    [InlineData("/uploads/avatars/2026/11/" + Id + ".webp")]
    [InlineData("/uploads/avatars/2026/11/" + Id + "_512.png")]
    [InlineData("/uploads/avatars/2026/11/NOT-A-GUID_512.webp")]
    [InlineData("")]
    [InlineData(null)]
    public void Anything_but_a_stored_upload_path_is_not_parsed(string? value) =>
        UploadPath.TryParse(value, out _).Should().BeFalse();

    [Fact]
    public void Ids_are_found_in_paths_urls_and_rdoc_json()
    {
        var other = new string('f', 32);
        var json = $$"""{"blocks":[{"type":"image","src":"rdoc-asset://uploads/articles/2026/11/{{Id}}_1600.webp"},{"type":"image","src":"https://api.readin.app/uploads/covers/2026/11/{{other}}_1200.webp"}]}""";

        UploadPath.FindIds(json).Should().BeEquivalentTo(Id, other);
        UploadPath.IdFromFileName($"{Id}_256.webp").Should().Be(Id);
        UploadPath.IdFromFileName(".gitkeep").Should().BeNull();
        UploadPath.IdFromFileName($"{Id}_256.webp.0a1b.tmp").Should().BeNull();
    }
}

public sealed class UploadUrlTests
{
    private const string Base = "https://api.readin.app";
    private const string Path = "/uploads/articles/2026/11/0123456789abcdef0123456789abcdef_1600.webp";

    private static IFileStorage Storage()
    {
        var storage = Substitute.For<IFileStorage>();
        storage.GetPublicUrl(Arg.Any<string>()).Returns(call => Base + call.Arg<string>());
        return storage;
    }

    [Fact]
    public void Stored_paths_become_absolute_urls_and_external_urls_pass_through()
    {
        var storage = Storage();

        storage.ToPublicUrl(Path).Should().Be(Base + Path);
        storage.ToPublicUrl("https://lh3.googleusercontent.com/a/photo.jpg").Should().Be("https://lh3.googleusercontent.com/a/photo.jpg");
        storage.ToPublicUrl(null).Should().BeNull();
    }

    [Fact]
    public void Our_own_upload_urls_are_stored_as_relative_paths()
    {
        var storage = Storage();

        storage.ToStoredValue(Base + Path).Should().Be(Path);
        storage.ToStoredValue(Path).Should().Be(Path);
        storage.ToStoredValue("https://evil.example" + Path).Should().Be("https://evil.example" + Path, "another host is an external URL");
        storage.ToStoredValue("  ").Should().BeNull();
    }

    [Fact]
    public void Rdoc_image_sources_are_served_absolute_and_stored_as_assets()
    {
        var storage = Storage();
        var stored = $$"""{"version":1,"language":"en","blocks":[{"id":"i1","type":"image","src":"rdoc-asset:/{{Path}}","darkSrc":"https://example.com/d.png","alt":"x"}]}""";

        var served = storage.ToPublicContent(stored);
        served.GetProperty("blocks")[0].GetProperty("src").GetString().Should().Be(Base + Path);
        served.GetProperty("blocks")[0].GetProperty("darkSrc").GetString().Should().Be("https://example.com/d.png");

        var roundTrip = storage.ToStoredContent(served);
        roundTrip.GetProperty("blocks")[0].GetProperty("src").GetString().Should().Be("rdoc-asset:/" + Path);
        roundTrip.GetProperty("blocks")[0].GetProperty("darkSrc").GetString().Should().Be("https://example.com/d.png");
    }

    [Fact]
    public void Text_that_only_looks_like_an_image_source_is_left_alone()
    {
        var content = JsonSerializer.SerializeToElement(new
        {
            blocks = new object[] { new { type = "paragraph", content = new[] { new { type = "text", text = Base + Path } } } },
        });

        Storage().ToStoredContent(content).GetRawText().Should().Be(content.GetRawText());
    }
}

public sealed class UploadImageCommandHandlerTests
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private static readonly byte[] JpegHeader = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, (byte)'J', (byte)'F', (byte)'I', (byte)'F', 0, 1];

    private readonly IFileStorage _storage = Substitute.For<IFileStorage>();
    private readonly IImageProcessor _images = Substitute.For<IImageProcessor>();

    public UploadImageCommandHandlerTests()
    {
        _storage.GetPublicUrl(Arg.Any<string>()).Returns(call => "https://api.readin.app" + call.Arg<string>());
        _images.Process(Arg.Any<Stream>(), Arg.Any<ImageFormat>(), Arg.Any<UploadPurpose>())
            .Returns(call => Result.Success<IReadOnlyList<ProcessedImage>>(
                [.. call.Arg<UploadPurpose>().Sizes.Select(size => new ProcessedImage(size, size, size, [1]))]));
    }

    private UploadImageCommandHandler Handler(params string[] permissions)
    {
        var user = Substitute.For<ICurrentUser>();
        user.Permissions.Returns(permissions.ToHashSet());
        return new UploadImageCommandHandler(_storage, _images, user, TimeProvider.System);
    }

    private static UploadImageCommand Command(string purpose, byte[] bytes, long? declaredLength = null) =>
        new(purpose, new MemoryStream(bytes), declaredLength ?? bytes.Length);

    private static byte[] Jpeg(long length)
    {
        var bytes = new byte[length];
        JpegHeader.CopyTo(bytes, 0);
        return bytes;
    }

    [Fact]
    public async Task A_renamed_executable_is_rejected_before_any_processing()
    {
        byte[] exe = [0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xD8, 0xFF];

        var result = await Handler().Handle(Command("avatar", exe), Ct);

        result.Error.Should().Be(UploadErrors.UnsupportedType);
        _images.ReceivedCalls().Should().BeEmpty();
        _storage.ReceivedCalls().Should().BeEmpty();
    }

    [Fact]
    public async Task Five_megabytes_is_the_limit_whatever_length_the_client_declares()
    {
        var atLimit = await Handler().Handle(Command("avatar", Jpeg(UploadLimits.MaxBytes)), Ct);
        var overLimit = await Handler().Handle(Command("avatar", Jpeg(UploadLimits.MaxBytes + 1), declaredLength: 1000), Ct);

        atLimit.IsSuccess.Should().BeTrue();
        overLimit.Error.Should().Be(UploadErrors.TooLarge);
    }

    [Fact]
    public async Task Empty_files_are_rejected() =>
        (await Handler().Handle(Command("avatar", []), Ct)).Error.Should().Be(UploadErrors.Empty);

    [Fact]
    public async Task Processor_errors_are_returned_and_nothing_is_stored()
    {
        _images.Process(Arg.Any<Stream>(), Arg.Any<ImageFormat>(), Arg.Any<UploadPurpose>()).Returns(UploadErrors.DimensionsTooLarge);

        var result = await Handler().Handle(Command("avatar", Jpeg(100)), Ct);

        result.Error.Should().Be(UploadErrors.DimensionsTooLarge);
        _storage.ReceivedCalls().Where(c => c.GetMethodInfo().Name == nameof(IFileStorage.SaveAsync)).Should().BeEmpty();
    }

    [Theory]
    [InlineData("cover")]
    [InlineData("article-image")]
    public async Task Covers_and_article_images_need_the_right_to_write_articles(string purpose)
    {
        (await Handler().Handle(Command(purpose, Jpeg(100)), Ct)).Error.Should().Be(AuthErrors.Forbidden);
        (await Handler(Permissions.Articles.Create).Handle(Command(purpose, Jpeg(100)), Ct)).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task Every_size_is_saved_under_a_random_name_and_the_largest_is_returned()
    {
        var result = await Handler().Handle(Command("avatar", Jpeg(100)), Ct);

        var saved = _storage.ReceivedCalls()
            .Where(c => c.GetMethodInfo().Name == nameof(IFileStorage.SaveAsync))
            .Select(c => (string)c.GetArguments()[0]!)
            .ToList();
        saved.Should().HaveCount(2).And.AllSatisfy(p => UploadPath.TryParse(p, out _).Should().BeTrue());
        saved.Select(p => p[..^"_256.webp".Length]).Distinct().Should().ContainSingle("both sizes share one id");

        var upload = result.Value;
        upload.Purpose.Should().Be("avatar");
        upload.Path.Should().Be(saved[1]).And.EndWith("_512.webp");
        upload.Url.Should().Be("https://api.readin.app" + upload.Path);
        (upload.Width, upload.Height).Should().Be((512, 512));
        upload.Variants.Select(v => v.Size).Should().Equal(256, 512);
    }

    [Fact]
    public void Validator_rejects_unknown_purposes_and_oversized_declared_lengths()
    {
        var result = new UploadImageCommandValidator().Validate(Command("banner", [1], declaredLength: UploadLimits.MaxBytes + 1));

        result.Errors.Select(e => e.ErrorCode).Should().BeEquivalentTo("upload.purpose_invalid", "upload.too_large");
    }
}
