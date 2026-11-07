using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using NSubstitute;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.UnitTests.Storage;

/// <summary>The private store of SPEC F19: never inside the web root or the uploads folder, plain relative paths only.</summary>
public sealed class LocalPrivateFileStorageTests : IDisposable
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private readonly string _contentRoot = Path.Combine(Path.GetTempPath(), "readin-private-tests", Guid.NewGuid().ToString("N"));

    public LocalPrivateFileStorageTests() => Directory.CreateDirectory(_contentRoot);

    public void Dispose() => Directory.Delete(_contentRoot, recursive: true);

    private LocalPrivateFileStorage Storage(string privatePath = "App_Data/private", string uploadsPath = "wwwroot/uploads", string? webRoot = null)
    {
        var environment = Substitute.For<IWebHostEnvironment>();
        environment.ContentRootPath.Returns(_contentRoot);
        environment.WebRootPath.Returns(webRoot ?? Path.Combine(_contentRoot, "wwwroot"));
        return new LocalPrivateFileStorage(
            Options.Create(new StorageOptions { PrivatePath = privatePath, UploadsPath = uploadsPath, PublicBaseUrl = "https://api.readin.app" }),
            environment);
    }

    private static MemoryStream Bytes(params byte[] bytes) => new(bytes);

    [Fact]
    public void The_default_folder_is_App_Data_private_next_to_the_app()
    {
        new StorageOptions().PrivatePath.Should().Be("App_Data/private");
        Storage().RootPath.Should().Be(Path.Combine(_contentRoot, "App_Data", "private"));
    }

    [Fact]
    public void An_absolute_folder_outside_the_app_is_supported()
    {
        var outside = Path.Combine(_contentRoot, "..", Path.GetFileName(_contentRoot) + "-data", "private");

        Storage(outside).RootPath.Should().Be(Path.GetFullPath(outside));
    }

    [Theory]
    [InlineData("wwwroot")]
    [InlineData("wwwroot/private")]
    [InlineData("wwwroot/uploads/private")]
    [InlineData("./wwwroot/../wwwroot/x")]
    [InlineData(".")] // the content root holds wwwroot
    public void Startup_refuses_a_folder_that_overlaps_the_web_root(string privatePath)
    {
        var create = () => Storage(privatePath);

        create.Should().Throw<InvalidOperationException>().WithMessage("*Storage:PrivatePath*web root*");
    }

    [Fact]
    public void Startup_refuses_a_folder_inside_a_custom_web_root()
    {
        var create = () => Storage("public-files/private", webRoot: Path.Combine(_contentRoot, "public-files"));

        create.Should().Throw<InvalidOperationException>().WithMessage("*web root*");
    }

    [Fact]
    public void Startup_refuses_a_folder_that_overlaps_the_uploads_folder()
    {
        var data = Path.Combine(_contentRoot, "..", Path.GetFileName(_contentRoot) + "-data");
        var uploads = Path.Combine(data, "uploads");

        var inside = () => Storage(Path.Combine(uploads, "private"), uploadsPath: uploads);
        var same = () => Storage(uploads, uploadsPath: uploads);
        var around = () => Storage(data, uploadsPath: uploads);
        var beside = () => Storage(Path.Combine(data, "private"), uploadsPath: uploads);

        inside.Should().Throw<InvalidOperationException>().WithMessage("*Storage:PrivatePath*uploads folder*Storage:UploadsPath*");
        same.Should().Throw<InvalidOperationException>().WithMessage("*uploads folder*");
        around.Should().Throw<InvalidOperationException>().WithMessage("*uploads folder*", "a parent of the uploads folder overlaps it too");
        beside.Should().NotThrow("a sibling of the uploads folder is fine");
    }

    [Fact]
    public void A_missing_setting_fails_fast()
    {
        var create = () => Storage(" ");

        create.Should().Throw<InvalidOperationException>().WithMessage("*Storage:PrivatePath*");
    }

    [Theory]
    [InlineData("")]
    [InlineData("/verification/a.pdf")]
    [InlineData("../appsettings.json")]
    [InlineData("verification/../../appsettings.json")]
    [InlineData("verification/./a.pdf")]
    [InlineData("verification//a.pdf")]
    [InlineData(@"verification\..\..\appsettings.json")]
    [InlineData("C:/Windows/win.ini")]
    [InlineData("verification/a.pdf\0.png")]
    public async Task Path_traversal_is_blocked(string relativePath)
    {
        var storage = Storage();

        storage.Invoking(s => s.Resolve(relativePath)).Should().Throw<ArgumentException>();
        await storage.Awaiting(s => s.SaveAsync(relativePath, Bytes(1), Ct)).Should().ThrowAsync<ArgumentException>();
        await storage.Awaiting(s => s.OpenReadAsync(relativePath, Ct)).Should().ThrowAsync<ArgumentException>();
        await storage.Awaiting(s => s.DeleteAsync(relativePath, Ct)).Should().ThrowAsync<ArgumentException>();
        Directory.EnumerateFiles(_contentRoot, "*", SearchOption.AllDirectories).Should().BeEmpty("nothing was written anywhere");
    }

    [Fact]
    public async Task Files_are_saved_read_never_overwritten_and_deleted()
    {
        var storage = Storage();
        const string path = "verification/0195f3a0-0000-7000-8000-000000000001.pdf";

        await storage.SaveAsync(path, Bytes(1, 2, 3), Ct);
        await storage.Awaiting(s => s.SaveAsync(path, Bytes(9), Ct)).Should().ThrowAsync<IOException>();

        var file = storage.Resolve(path);
        file.Should().Be(Path.Combine(_contentRoot, "App_Data", "private", "verification", "0195f3a0-0000-7000-8000-000000000001.pdf"));
        Directory.GetFiles(Path.GetDirectoryName(file)!).Should().ContainSingle("the temporary file is renamed, not left behind");
        await using (var read = await storage.OpenReadAsync(path, Ct))
        {
            using var copy = new MemoryStream();
            await read.CopyToAsync(copy, Ct);
            copy.ToArray().Should().Equal(1, 2, 3);
        }
        storage.EnumerateFiles("verification").Select(f => f.RelativePath).Should().Equal(path);

        await storage.DeleteAsync(path, Ct);
        await storage.DeleteAsync(path, Ct);
        File.Exists(file).Should().BeFalse();
        await storage.Awaiting(s => s.OpenReadAsync(path, Ct)).Should().ThrowAsync<FileNotFoundException>();
    }

    [Fact]
    public void Startup_check_creates_the_folders_and_leaves_no_probe()
    {
        var storage = Storage();

        storage.EnsureWritable();

        // Verification proofs (F19) and support screenshots (F35).
        Directory.GetDirectories(storage.RootPath).Select(Path.GetFileName).Should().BeEquivalentTo("verification", "support");
        Directory.GetFiles(storage.RootPath).Should().BeEmpty();
        Directory.Exists(Path.Combine(_contentRoot, "wwwroot")).Should().BeFalse("nothing is created in the web root");
    }

    [Fact]
    public async Task Support_screenshots_live_in_one_folder_per_message_that_goes_with_its_last_file()
    {
        var storage = Storage();
        var first = "support/0195f3a0-0000-7000-8000-000000000001/1.png";
        var second = "support/0195f3a0-0000-7000-8000-000000000001/2.webp";
        var other = "support/0195f3a0-0000-7000-8000-000000000002/1.jpg";
        foreach (var path in new[] { first, second, other }) await storage.SaveAsync(path, Bytes(1), Ct);

        storage.EnumerateFiles("support").Should().BeEmpty("the files are one level down");
        storage.EnumerateFiles("support", recursive: true).Select(f => f.RelativePath).Should().BeEquivalentTo(first, second, other);

        var folder = Path.GetDirectoryName(storage.Resolve(first))!;
        await storage.DeleteAsync(first, Ct);
        Directory.Exists(folder).Should().BeTrue("its other screenshot is still there");
        await storage.DeleteAsync(second, Ct);
        Directory.Exists(folder).Should().BeFalse("an empty message folder goes");
        Directory.Exists(Path.Combine(storage.RootPath, "support")).Should().BeTrue("the kind's folder stays");
        storage.EnumerateFiles("support", recursive: true).Select(f => f.RelativePath).Should().Equal(other);
    }
}
