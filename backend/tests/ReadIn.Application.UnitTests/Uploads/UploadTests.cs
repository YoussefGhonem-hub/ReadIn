using System.Text.Json;
using NSubstitute;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Uploads;
using ReadIn.Application.Features.Uploads.Commands.UploadImage;
using ReadIn.Domain.Common;

namespace ReadIn.Application.UnitTests.Uploads;

public sealed class ImageSignatureTests
{
    [Theory]
    [InlineData(new byte[] { 0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, (byte)'J', (byte)'F', (byte)'I', (byte)'F', 0, 1 }, ImageFormat.Jpeg)]
    [InlineData(new byte[] { 0x89, (byte)'P', (byte)'N', (byte)'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D }, ImageFormat.Png)]
    [InlineData(new byte[] { (byte)'R', (byte)'I', (byte)'F', (byte)'F', 1, 2, 3, 4, (byte)'W', (byte)'E', (byte)'B', (byte)'P' }, ImageFormat.Webp)]
    [InlineData(new byte[] { 0, 0, 0, 0x18, (byte)'f', (byte)'t', (byte)'y', (byte)'p', (byte)'h', (byte)'e', (byte)'i', (byte)'c' }, ImageFormat.Heic)]
    [InlineData(new byte[] { 0, 0, 0, 0x18, (byte)'f', (byte)'t', (byte)'y', (byte)'p', (byte)'m', (byte)'i', (byte)'f', (byte)'1' }, ImageFormat.Heic)]
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
            $"/uploads/avatars/2026/01/{Id}_64.webp",
            $"/uploads/avatars/2026/01/{Id}_128.webp",
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
        var json = $$"""{"blocks":[{"type":"image","src":"rdoc-asset://uploads/images/2026/11/{{Id}}_1600.webp"},{"type":"image","src":"https://api.readin.app/uploads/covers/2026/11/{{other}}_1200.webp"}]}""";

        UploadPath.FindIds(json).Should().BeEquivalentTo(Id, other);
        UploadPath.IdFromFileName($"{Id}_256.webp").Should().Be(Id);
        UploadPath.IdFromFileName(".gitkeep").Should().BeNull();
        UploadPath.IdFromFileName($"{Id}_256.webp.0a1b.tmp").Should().BeNull();
    }
}

public sealed class UploadUrlTests
{
    private const string Base = "https://api.readin.app";
    private const string Path = "/uploads/images/2026/11/0123456789abcdef0123456789abcdef_1600.webp";

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

    private readonly IAppDbContext _db = Substitute.For<IAppDbContext>();
    private readonly IFileStorage _storage = Substitute.For<IFileStorage>();
    private readonly IImageProcessor _images = Substitute.For<IImageProcessor>();
    private readonly IMediaQuota _quota = Substitute.For<IMediaQuota>();

    public UploadImageCommandHandlerTests()
    {
        _storage.GetPublicUrl(Arg.Any<string>()).Returns(call => "https://api.readin.app" + call.Arg<string>());
        _images.Process(Arg.Any<Stream>(), Arg.Any<ImageFormat>(), Arg.Any<UploadPurpose>())
            .Returns(call => Result.Success(new ProcessedImageSet(4000, 3000, "LEHV6nWB2yk8",
                [.. call.Arg<UploadPurpose>().Sizes.Select(size => new ProcessedImage(size, size, size, [1]))])));
        _quota.CheckNewUploadAsync(Arg.Any<Guid>(), Arg.Any<long>(), Arg.Any<CancellationToken>()).Returns((Error?)null);
        _quota.CheckStorageAsync(Arg.Any<Guid>(), Arg.Any<long>(), Arg.Any<CancellationToken>()).Returns((Error?)null);
    }

    private UploadImageCommandHandler Handler(params string[] permissions)
    {
        var user = Substitute.For<ICurrentUser>();
        user.UserId.Returns(Guid.NewGuid());
        user.Permissions.Returns(permissions.ToHashSet());
        return new UploadImageCommandHandler(_db, _storage, _images, user, _quota, DependencyInjection.CreateMapperConfig(), TimeProvider.System);
    }

    private static UploadImageCommand Command(string purpose, byte[] bytes, long? declaredLength = null) =>
        new(purpose, new MemoryStream(bytes), declaredLength ?? bytes.Length);

    private static byte[] Jpeg(long length)
    {
        var bytes = new byte[length];
        JpegHeader.CopyTo(bytes, 0);
        return bytes;
    }

    private List<string> SavedPaths() => _storage.ReceivedCalls()
        .Where(c => c.GetMethodInfo().Name == nameof(IFileStorage.SaveAsync))
        .Select(c => (string)c.GetArguments()[0]!)
        .ToList();

    [Fact]
    public async Task A_renamed_executable_is_rejected_before_any_processing()
    {
        byte[] exe = [0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xD8, 0xFF];

        var result = await Handler().Handle(Command("avatar", exe), Ct);

        result.Error.Should().Be(UploadErrors.UnsupportedType);
        result.Error!.Code.Should().Be("media.unsupported_type");
        _images.ReceivedCalls().Should().BeEmpty();
        _storage.ReceivedCalls().Should().BeEmpty();
    }

    [Fact]
    public async Task Ten_megabytes_is_the_limit_whatever_length_the_client_declares()
    {
        var atLimit = await Handler().Handle(Command("avatar", Jpeg(UploadLimits.MaxBytes)), Ct);
        var overLimit = await Handler().Handle(Command("avatar", Jpeg(UploadLimits.MaxBytes + 1), declaredLength: 1000), Ct);

        UploadLimits.MaxBytes.Should().Be(10 * 1024 * 1024);
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
        SavedPaths().Should().BeEmpty();
    }

    [Fact]
    public async Task A_full_quota_stops_the_upload_before_processing()
    {
        _quota.CheckNewUploadAsync(Arg.Any<Guid>(), Arg.Any<long>(), Arg.Any<CancellationToken>()).Returns(Domain.Media.MediaErrors.QuotaDaily);

        var result = await Handler().Handle(Command("avatar", Jpeg(100)), Ct);

        result.Error.Should().Be(Domain.Media.MediaErrors.QuotaDaily);
        _images.ReceivedCalls().Should().BeEmpty();
    }

    [Theory]
    [InlineData("cover")]
    [InlineData("image")]
    [InlineData("article-image")]
    public async Task Covers_and_post_images_need_the_right_to_write_articles(string purpose)
    {
        (await Handler().Handle(Command(purpose, Jpeg(100)), Ct)).Error.Should().Be(AuthErrors.Forbidden);
        (await Handler(Permissions.Articles.Create).Handle(Command(purpose, Jpeg(100)), Ct)).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task Every_width_is_saved_under_one_random_id_and_recorded_as_a_ready_asset()
    {
        var result = await Handler().Handle(Command("avatar", Jpeg(100)), Ct);

        var saved = SavedPaths();
        saved.Should().HaveCount(4).And.AllSatisfy(p => UploadPath.TryParse(p, out _).Should().BeTrue());
        saved.Select(p => p[..p.LastIndexOf('_')]).Distinct().Should().ContainSingle("every width shares one id");
        _db.MediaAssets.Received(1).Add(Arg.Is<Domain.Media.MediaAsset>(a => a.Status == Domain.Media.MediaStatus.Ready));

        var asset = result.Value;
        asset.Kind.Should().Be(Domain.Media.MediaKind.Image);
        asset.Purpose.Should().Be(Domain.Media.MediaPurpose.Avatar);
        asset.Status.Should().Be(Domain.Media.MediaStatus.Ready);
        asset.BlurHash.Should().Be("LEHV6nWB2yk8");
        asset.Variants.Select(v => v.Width).Should().Equal(64, 128, 256, 512);
        asset.Variants[^1].Url.Should().Be("https://api.readin.app" + saved[^1]).And.EndWith("_512.webp");
    }

    [Fact]
    public void Validator_rejects_unknown_purposes_and_oversized_declared_lengths()
    {
        var result = new UploadImageCommandValidator().Validate(Command("banner", [1], declaredLength: UploadLimits.MaxBytes + 1));

        result.Errors.Select(e => e.ErrorCode).Should().BeEquivalentTo("media.purpose_invalid", "media.too_large");
    }
}

public sealed class UploadPurposeWidthTests
{
    [Theory]
    [InlineData(5000, new[] { 320, 640, 1080, 1600 })]
    [InlineData(1600, new[] { 320, 640, 1080, 1600 })]
    [InlineData(1000, new[] { 320, 640, 1000 })]
    [InlineData(640, new[] { 320, 640 })]
    [InlineData(200, new[] { 200 })]
    public void Post_images_are_never_upscaled_and_never_duplicated(int width, int[] expected) =>
        UploadPurpose.ArticleImage.WidthsFor(width).Should().Equal(expected);

    [Fact]
    public void Buckets_follow_adr_0011()
    {
        UploadPurpose.Avatar.Sizes.Should().Equal(64, 128, 256, 512);
        UploadPurpose.Avatar.Square.Should().BeTrue();
        UploadPurpose.Cover.Sizes.Should().Equal(400, 800, 1200);
        UploadPurpose.ArticleImage.Sizes.Should().Equal(320, 640, 1080, 1600);
        UploadPurpose.ArticleImage.Folder.Should().Be("images");
        UploadPurpose.FromName("article-image").Should().Be(UploadPurpose.ArticleImage);
    }
}
