using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using NSubstitute;
using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.UnitTests.Storage;

public sealed class WwwrootFileStorageTests : IDisposable
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private readonly string _contentRoot = Path.Combine(Path.GetTempPath(), "readin-storage-tests", Guid.NewGuid().ToString("N"));

    public WwwrootFileStorageTests() => Directory.CreateDirectory(_contentRoot);

    public void Dispose() => Directory.Delete(_contentRoot, recursive: true);

    private WwwrootFileStorage Storage(string uploadsPath = "wwwroot/uploads", string publicBaseUrl = "https://api.readin.app")
    {
        var environment = Substitute.For<IHostEnvironment>();
        environment.ContentRootPath.Returns(_contentRoot);
        return new WwwrootFileStorage(Options.Create(new StorageOptions { UploadsPath = uploadsPath, PublicBaseUrl = publicBaseUrl }), environment);
    }

    private static MemoryStream Bytes(params byte[] bytes) => new(bytes);

    [Fact]
    public void Relative_upload_paths_resolve_below_the_content_root()
    {
        var storage = Storage();

        storage.RootPath.Should().Be(Path.Combine(_contentRoot, "wwwroot", "uploads"));
        storage.Resolve("/uploads/covers/2026/11/a_1200.webp")
            .Should().Be(Path.Combine(_contentRoot, "wwwroot", "uploads", "covers", "2026", "11", "a_1200.webp"));
    }

    [Fact]
    public void An_absolute_uploads_path_outside_the_app_folder_is_supported()
    {
        var outside = Path.Combine(_contentRoot, "..", Path.GetFileName(_contentRoot) + "-data", "uploads");

        Storage(outside).RootPath.Should().Be(Path.GetFullPath(outside));
    }

    [Theory]
    [InlineData("/uploads/covers/2026/11/a_1200.webp", "https://api.readin.app/uploads/covers/2026/11/a_1200.webp")]
    [InlineData("/uploads/avatars/2026/01/b_256.webp", "https://api.readin.app/uploads/avatars/2026/01/b_256.webp")]
    public void Public_urls_are_built_from_the_configured_base_url(string relativePath, string expected)
    {
        Storage().GetPublicUrl(relativePath).Should().Be(expected);
        Storage(publicBaseUrl: "https://api.readin.app/").GetPublicUrl(relativePath).Should().Be(expected, "a trailing slash is ignored");
    }

    [Fact]
    public void Changing_the_domain_changes_every_url_without_touching_stored_paths()
    {
        const string stored = "/uploads/covers/2026/11/a_1200.webp";

        Storage(publicBaseUrl: "https://cdn.readin.example").GetPublicUrl(stored)
            .Should().Be("https://cdn.readin.example/uploads/covers/2026/11/a_1200.webp");
    }

    [Theory]
    [InlineData("")]
    [InlineData("not-a-url")]
    [InlineData("ftp://api.readin.app")]
    public void A_missing_or_invalid_public_base_url_fails_fast(string publicBaseUrl)
    {
        var create = () => Storage(publicBaseUrl: publicBaseUrl);

        create.Should().Throw<InvalidOperationException>().WithMessage("*Storage:PublicBaseUrl*");
    }

    [Theory]
    [InlineData("../appsettings.json")]
    [InlineData("/appsettings.json")]
    [InlineData("uploads/covers/a.webp")]
    [InlineData("/uploads/")]
    [InlineData("/uploads/../appsettings.json")]
    [InlineData("/uploads/covers/../../appsettings.json")]
    [InlineData("/uploads/covers/./a.webp")]
    [InlineData("/uploads/covers//a.webp")]
    [InlineData(@"/uploads/covers\..\..\appsettings.json")]
    [InlineData("/uploads/C:/Windows/win.ini")]
    [InlineData("/uploads/covers/a.webp\0.png")]
    [InlineData("/uploadsx/a.webp")]
    public async Task Path_traversal_is_blocked(string relativePath)
    {
        var storage = Storage();

        storage.Invoking(s => s.Resolve(relativePath)).Should().Throw<ArgumentException>();
        storage.Invoking(s => s.GetPublicUrl(relativePath)).Should().Throw<ArgumentException>();
        await storage.Awaiting(s => s.SaveAsync(relativePath, Bytes(1), Ct)).Should().ThrowAsync<ArgumentException>();
        await storage.Awaiting(s => s.DeleteAsync(relativePath, Ct)).Should().ThrowAsync<ArgumentException>();
        Directory.Exists(_contentRoot).Should().BeTrue();
        Directory.EnumerateFiles(_contentRoot, "*", SearchOption.AllDirectories).Should().BeEmpty("nothing was written anywhere");
    }

    [Fact]
    public async Task Saved_files_appear_complete_and_deleting_twice_is_harmless()
    {
        var storage = Storage();
        const string path = "/uploads/avatars/2026/11/0123456789abcdef0123456789abcdef_256.webp";

        await storage.SaveAsync(path, Bytes(1, 2, 3), Ct);

        var file = storage.Resolve(path);
        (await File.ReadAllBytesAsync(file, Ct)).Should().Equal(1, 2, 3);
        Directory.GetFiles(Path.GetDirectoryName(file)!).Should().ContainSingle("the temporary file is renamed, not left behind");

        await storage.DeleteAsync(path, Ct);
        await storage.DeleteAsync(path, Ct);
        await storage.DeleteAsync("/uploads/never/existed/x_1.webp", Ct);
        File.Exists(file).Should().BeFalse();
    }

    [Fact]
    public async Task Files_are_never_overwritten()
    {
        var storage = Storage();
        const string path = "/uploads/covers/2026/11/0123456789abcdef0123456789abcdef_1200.webp";
        await storage.SaveAsync(path, Bytes(1), Ct);

        await storage.Awaiting(s => s.SaveAsync(path, Bytes(2), Ct)).Should().ThrowAsync<IOException>();

        (await File.ReadAllBytesAsync(storage.Resolve(path), Ct)).Should().Equal(1);
    }

    [Fact]
    public async Task Enumeration_lists_relative_paths_at_any_depth()
    {
        var storage = Storage();
        await storage.SaveAsync("/uploads/covers/2026/11/a_1200.webp", Bytes(1), Ct);
        await storage.SaveAsync("/uploads/documents/2026/11/x/pages/1_400.webp", Bytes(1), Ct);

        storage.EnumerateFiles().Select(f => f.RelativePath).Should().BeEquivalentTo(
            "/uploads/covers/2026/11/a_1200.webp", "/uploads/documents/2026/11/x/pages/1_400.webp");
    }

    [Fact]
    public void Startup_check_creates_the_purpose_folders()
    {
        var storage = Storage();

        storage.EnsureWritable();

        Directory.GetDirectories(storage.RootPath).Select(Path.GetFileName)
            .Should().BeEquivalentTo(UploadPurpose.All.Select(p => p.Folder));
        Directory.GetFiles(storage.RootPath).Should().BeEmpty("the write probe is removed");
    }
}
