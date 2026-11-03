using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;
using SkiaSharp;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Uploads end to end: multipart → WebP on disk → served from /uploads (SPEC §24, ADR 0010).</summary>
[Collection(ApiCollection.Name)]
public sealed class UploadTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static byte[] Png(int width, int height)
    {
        using var bitmap = new SKBitmap(width, height);
        using (var canvas = new SKCanvas(bitmap)) canvas.Clear(SKColors.SeaGreen);
        using var data = bitmap.Encode(SKEncodedImageFormat.Png, 100);
        return data.ToArray();
    }

    private async Task<(HttpClient Client, JsonObject Me)> SignedInAsync()
    {
        var user = await api.SignUpAsync();
        return (user.Client, user.Me);
    }

    private static async Task<HttpResponseMessage> PostUploadAsync(HttpClient client, string purpose, byte[] bytes, string fileName = "photo.png")
    {
        using var form = new MultipartFormDataContent();
        form.Add(new StringContent(purpose), "purpose");
        var file = new ByteArrayContent(bytes);
        file.Headers.ContentType = new MediaTypeHeaderValue("image/png");
        form.Add(file, "file", fileName);
        return await client.PostAsync("/api/v1/uploads/images", form, Ct);
    }

    private static async Task<JsonObject> UploadAsync(HttpClient client, string purpose, byte[] bytes)
    {
        var response = await PostUploadAsync(client, purpose, bytes);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
    }

    /// <summary>Relative paths of every stored width, smallest first (the DTO carries absolute URLs).</summary>
    private static IEnumerable<string> PathsOf(JsonObject upload) =>
        upload["variants"]!.AsArray().Select(v => new Uri(v!["url"]!.GetValue<string>()).AbsolutePath);

    /// <summary>The largest width: what avatarUrl / coverUrl / RDoc image sources point at.</summary>
    private static string PathOf(JsonObject upload) => PathsOf(upload).Last();

    private static string UrlOf(JsonObject upload) => upload["variants"]!.AsArray().Last()!["url"]!.GetValue<string>();

    private string OnDisk(string relativePath) =>
        Path.Combine(api.UploadsPath, relativePath["/uploads/".Length..].Replace('/', Path.DirectorySeparatorChar));

    private Task<HttpResponseMessage> GetFileAsync(string pathOrUrl) =>
        api.GuestClient().GetAsync(pathOrUrl.StartsWith('/') ? pathOrUrl : new Uri(pathOrUrl).PathAndQuery, Ct);

    private async Task UpdateAvatarAsync(HttpClient client, JsonObject me, string? avatarUrl, string? bio = null)
    {
        var response = await client.PatchAsJsonAsync("/api/v1/me", new
        {
            displayName = "Upload Tester",
            username = me["username"]!.GetValue<string>(),
            bio,
            avatarUrl,
        }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));
    }

    [Fact]
    public async Task Upload_is_stored_as_webp_and_served_with_safe_headers()
    {
        var (client, _) = await SignedInAsync();

        var response = await PostUploadAsync(client, "avatar", Png(800, 600), fileName: "../../../appsettings.json.png");

        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var upload = (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
        var path = PathOf(upload);
        path.Should().MatchRegex(@"^/uploads/avatars/\d{4}/\d{2}/[0-9a-f]{32}_512\.webp$", "a random name, never the client's");
        UrlOf(upload).Should().Be(ApiFactory.PublicBaseUrl + path);
        (upload["width"]!.GetValue<int>(), upload["height"]!.GetValue<int>()).Should().Be((600, 600), "the square crop of 800 × 600");
        upload["status"]!.GetValue<string>().Should().Be("ready");
        PathsOf(upload).Should().HaveCount(4).And.OnlyContain(p => File.Exists(OnDisk(p)));
        response.Headers.Location!.ToString().Should().Be($"/api/v1/uploads/{upload["id"]}");

        using var request = new HttpRequestMessage(HttpMethod.Get, path);
        request.Headers.Add("Origin", "https://readin.app");
        var file = await api.GuestClient().SendAsync(request, Ct);

        file.StatusCode.Should().Be(HttpStatusCode.OK);
        file.Content.Headers.ContentType!.MediaType.Should().Be("image/webp");
        file.Headers.GetValues("X-Content-Type-Options").Should().Equal("nosniff");
        file.Headers.CacheControl!.ToString().Should().Be("public, max-age=31536000, immutable");
        file.Headers.GetValues("Content-Security-Policy").Single().Should().StartWith("default-src 'none'");
        file.Headers.GetValues("Access-Control-Allow-Origin").Should().Equal("https://readin.app");
        var bytes = await file.Content.ReadAsByteArrayAsync(Ct);
        System.Text.Encoding.ASCII.GetString(bytes, 8, 4).Should().Be("WEBP");
    }

    [Fact]
    public async Task Non_images_and_guests_are_rejected()
    {
        var (client, _) = await SignedInAsync();
        byte[] exe = [0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00];
        var filesBefore = Directory.EnumerateFiles(api.UploadsPath, "*", SearchOption.AllDirectories).Count();

        var renamedExe = await PostUploadAsync(client, "avatar", exe, fileName: "holiday.jpg");
        var badPurpose = await PostUploadAsync(client, "banner", Png(10, 10));
        var guest = await PostUploadAsync(api.GuestClient(), "avatar", Png(10, 10));

        renamedExe.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await TaxonomyAndContentTests.Problem(renamedExe))["code"]!.GetValue<string>().Should().Be("media.unsupported_type");
        badPurpose.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await TaxonomyAndContentTests.Problem(badPurpose))["errors"]!["purpose"]![0]!.GetValue<string>().Should().Be("media.purpose_invalid");
        guest.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        Directory.EnumerateFiles(api.UploadsPath, "*", SearchOption.AllDirectories).Should().HaveCount(filesBefore);
    }

    [Fact]
    public async Task Replacing_an_avatar_deletes_the_old_files()
    {
        var (client, me) = await SignedInAsync();
        var first = await UploadAsync(client, "avatar", Png(300, 300));
        await UpdateAvatarAsync(client, me, PathOf(first));

        var afterFirst = await client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct);
        var served = afterFirst!["avatarUrl"]!.GetValue<string>();
        served.Should().Be(UrlOf(first), "clients get the absolute URL");

        // Saving the profile with the URL it was given keeps the same avatar and deletes nothing.
        await UpdateAvatarAsync(client, me, served, bio: "Hello");
        PathsOf(first).Should().OnlyContain(p => File.Exists(OnDisk(p)));

        var second = await UploadAsync(client, "avatar", Png(400, 400));
        await UpdateAvatarAsync(client, me, PathOf(second));

        PathsOf(first).Should().OnlyContain(p => !File.Exists(OnDisk(p)), "both sizes of the replaced avatar are gone");
        PathsOf(second).Should().OnlyContain(p => File.Exists(OnDisk(p)));
        (await client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["avatarUrl"]!.GetValue<string>()
            .Should().Be(UrlOf(second));
        (await GetFileAsync(PathOf(first))).StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Avatars_must_be_avatar_uploads()
    {
        var (client, me) = await SignedInAsync();
        var cover = await UploadAsync(client, "cover", Png(1300, 500));

        var response = await client.PatchAsJsonAsync("/api/v1/me", new
        {
            displayName = "Upload Tester", username = me["username"]!.GetValue<string>(), avatarUrl = PathOf(cover),
        }, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await TaxonomyAndContentTests.Problem(response))["errors"]!["avatarUrl"]![0]!.GetValue<string>().Should().Be("validation.url");
    }

    [Fact]
    public async Task Article_cover_and_images_are_stored_relative_and_served_absolute()
    {
        var (client, _) = await SignedInAsync();
        var cover = await UploadAsync(client, "cover", Png(2400, 1200));
        var image = await UploadAsync(client, "article-image", Png(1000, 500));
        var dotnet = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Single(f => f!["slug"]!.GetValue<string>() == "dotnet")!["id"]!.GetValue<Guid>();

        var created = await client.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = dotnet, language = "en", title = "Images live next to the API",
            coverUrl = PathOf(cover),
            content = new
            {
                version = 1, language = "en",
                blocks = new object[]
                {
                    new { id = "p1", type = "paragraph", content = new[] { new { type = "text", text = "A diagram follows." } } },
                    // The absolute (http) URL from the upload response is accepted and stored as rdoc-asset://.
                    new { id = "i1", type = "image", src = UrlOf(image), alt = "Diagram" },
                },
            },
            sources = new[] { new { title = "Static files", url = "https://learn.microsoft.com/aspnet/core/fundamentals/static-files" } },
            isAiAssisted = false,
        }, Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created, await created.Content.ReadAsStringAsync(Ct));
        var id = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
        (await client.PostAsync($"/api/v1/articles/{id}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var stored = await db.Articles.AsNoTracking().Include(a => a.Translations).SingleAsync(a => a.Id == id, Ct);
            stored.CoverUrl.Should().Be(PathOf(cover), "the database keeps the relative path");
            stored.Translations.Single().ContentJson.Should().Contain("rdoc-asset:/" + PathOf(image))
                .And.NotContain(ApiFactory.PublicBaseUrl);

            var article = await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{stored.Slug}", Ct);
            article!["coverUrl"]!.GetValue<string>().Should().Be(UrlOf(cover));
            article["content"]!["blocks"]![1]!["src"]!.GetValue<string>().Should().Be(UrlOf(image));
        }
    }

    [Fact]
    public async Task Orphan_cleanup_deletes_only_old_unreferenced_files()
    {
        var (client, me) = await SignedInAsync();
        var avatar = await UploadAsync(client, "avatar", Png(300, 300));
        var inDraft = await UploadAsync(client, "article-image", Png(500, 300));
        var orphan = await UploadAsync(client, "avatar", Png(300, 300));
        var fresh = await UploadAsync(client, "cover", Png(1300, 500));
        await UpdateAvatarAsync(client, me, PathOf(avatar));

        var field = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))![0]!["id"]!.GetValue<Guid>();
        (await client.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = field, language = "en", title = "A draft that keeps its image",
            content = new
            {
                version = 1, language = "en",
                blocks = new object[] { new { id = "i1", type = "image", src = "rdoc-asset:/" + PathOf(inDraft), alt = "Kept" } },
            },
            isAiAssisted = false,
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.Created);

        var stray = Path.Combine(api.UploadsPath, "avatars", "notes.txt");
        await File.WriteAllTextAsync(stray, "not ours", Ct);
        var leftoverTemp = OnDisk(PathOf(orphan)) + ".0123.tmp";
        await File.WriteAllBytesAsync(leftoverTemp, [1], Ct);

        var twoDaysAgo = DateTime.UtcNow.AddDays(-2);
        foreach (var file in new[] { avatar, inDraft, orphan }.SelectMany(PathsOf).Select(OnDisk).Append(stray).Append(leftoverTemp))
            File.SetLastWriteTimeUtc(file, twoDaysAgo);

        using (var scope = api.Services.CreateScope())
        {
            // A live MediaAssets row protects its files (ADR 0011); age the rows too, so the media cleanup removes the unused one.
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var aged = new[] { avatar, inDraft, orphan }.Select(u => u["id"]!.GetValue<Guid>()).ToList();
            await db.MediaAssets.Where(m => aged.Contains(m.Id)).ExecuteUpdateAsync(s => s.SetProperty(m => m.CreatedAt, twoDaysAgo), Ct);

            await scope.ServiceProvider.GetRequiredService<OrphanedUploadsCleanupJob>().RunAsync(Ct);
            (await db.MediaAssets.AnyAsync(m => m.Id == orphan["id"]!.GetValue<Guid>(), Ct)).Should().BeFalse("its row goes with its files");
        }

        PathsOf(orphan).Should().OnlyContain(p => !File.Exists(OnDisk(p)), "old and unreferenced");
        File.Exists(leftoverTemp).Should().BeFalse("an interrupted write is cleaned up too");
        PathsOf(avatar).Should().OnlyContain(p => File.Exists(OnDisk(p)), "referenced by a user");
        PathsOf(inDraft).Should().OnlyContain(p => File.Exists(OnDisk(p)), "referenced by a draft's content");
        PathsOf(fresh).Should().OnlyContain(p => File.Exists(OnDisk(p)), "younger than 24 hours");
        File.Exists(stray).Should().BeTrue("files that don't follow the upload naming are never touched");
    }

    [Fact]
    public async Task Only_webp_files_are_served_from_uploads()
    {
        var planted = new Dictionary<string, string>
        {
            ["evil.html"] = "<script>alert(1)</script>",
            ["covers/x.png"] = "png",
            ["covers/2026/11/run.js"] = "alert(1)",
            ["avatars/logo.svg"] = "<svg onload=alert(1)>",
            ["notes.txt"] = "text",
            ["covers/2026/11/page.webp.html"] = "<b>x</b>",
            ["covers/2026/11/deep/nested/control.webp"] = "RIFF....WEBP",
        };
        foreach (var (relative, text) in planted)
        {
            var file = Path.Combine(api.UploadsPath, relative.Replace('/', Path.DirectorySeparatorChar));
            Directory.CreateDirectory(Path.GetDirectoryName(file)!);
            await File.WriteAllTextAsync(file, text, Ct);
        }

        foreach (var relative in planted.Keys.Where(k => !k.EndsWith(".webp", StringComparison.Ordinal)))
            (await GetFileAsync("/uploads/" + relative)).StatusCode.Should().Be(HttpStatusCode.NotFound, relative);

        (await GetFileAsync("/uploads/covers/2026/11/missing_1200.webp")).StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await GetFileAsync("/uploads/")).StatusCode.Should().Be(HttpStatusCode.NotFound, "no directory listing");

        var control = await GetFileAsync("/uploads/covers/2026/11/deep/nested/control.webp");
        control.StatusCode.Should().Be(HttpStatusCode.OK, ".webp is served at any depth");
        control.Content.Headers.ContentType!.MediaType.Should().Be("image/webp");
    }
}
