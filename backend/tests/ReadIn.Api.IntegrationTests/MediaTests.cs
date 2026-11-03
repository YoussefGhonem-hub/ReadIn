using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Media;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Media pipeline end to end (ADR 0011): images, PDFs, attachments, downloads, static-file rules, cleanup.</summary>
[Collection(ApiCollection.Name)]
public sealed class MediaTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static byte[] Fixture(string name) => File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", name));

    private async Task<(HttpClient Client, Guid UserId)> SignedInAsync(string uiLanguage = "en")
    {
        var user = await api.SignUpAsync(uiLanguage);
        return (user.Client, user.Id);
    }

    private static async Task<HttpResponseMessage> PostFileAsync(HttpClient client, string endpoint, byte[] bytes, string fileName,
        IDictionary<string, string>? fields = null)
    {
        using var form = new MultipartFormDataContent();
        foreach (var (name, value) in fields ?? new Dictionary<string, string>()) form.Add(new StringContent(value), name);
        var file = new ByteArrayContent(bytes);
        file.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
        form.Add(file, "file", fileName);
        return await client.PostAsync($"/api/v1/uploads/{endpoint}", form, Ct);
    }

    private static async Task<JsonObject> UploadImageAsync(HttpClient client, string fixture = "medium.webp")
    {
        var response = await PostFileAsync(client, "images", Fixture(fixture), fixture, new Dictionary<string, string> { ["purpose"] = "image" });
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
    }

    private static async Task<JsonObject> UploadDocumentAsync(HttpClient client, bool allowDownload = false, string fixture = "normal-12-pages.pdf")
    {
        var response = await PostFileAsync(client, "documents", Fixture(fixture), "Offshore Inspection Report.pdf",
            new Dictionary<string, string> { ["allowDownload"] = allowDownload ? "true" : "false" });
        response.StatusCode.Should().Be(HttpStatusCode.Accepted, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
    }

    private static async Task<JsonObject> GetAssetAsync(HttpClient client, JsonObject asset) =>
        (await client.GetFromJsonAsync<JsonObject>($"/api/v1/uploads/{asset["id"]}", Ct))!;

    private async Task<(Guid Id, string Slug)> CreateDraftAsync(HttpClient client, string title)
    {
        var dotnet = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Single(f => f!["slug"]!.GetValue<string>() == "dotnet")!;
        dotnet["requiresSources"]!.GetValue<bool>().Should().BeTrue();

        var created = await client.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = dotnet["id"]!.GetValue<Guid>(), language = "en", title,
            content = new
            {
                version = 1, language = "en",
                blocks = new object[] { new { id = "p1", type = "paragraph", dir = "auto", content = new[] { new { type = "text", text = "A post with media." } } } },
            },
            sources = new[] { new { title = "ReadIn", url = "https://readin.app" } },
            isAiAssisted = false,
        }, Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created, await created.Content.ReadAsStringAsync(Ct));
        var body = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
        return (body["id"]!.GetValue<Guid>(), body["slug"]!.GetValue<string>());
    }

    private static Task<HttpResponseMessage> SetAttachmentsAsync(HttpClient client, Guid articleId, params object[] items) =>
        client.PutAsJsonAsync($"/api/v1/articles/{articleId}/attachments", new { items }, Ct);

    private string OnDisk(string urlOrPath)
    {
        var path = urlOrPath.StartsWith('/') ? urlOrPath : new Uri(urlOrPath).AbsolutePath;
        return Path.Combine(api.UploadsPath, path["/uploads/".Length..].Replace('/', Path.DirectorySeparatorChar));
    }

    private static string Code(JsonObject problem) => problem["code"]!.GetValue<string>();

    [Fact]
    public async Task An_image_upload_creates_variants_on_disk_whose_urls_work()
    {
        var (client, _) = await SignedInAsync();

        var asset = await UploadImageAsync(client, "exif-rotated.jpg");

        asset["kind"]!.GetValue<string>().Should().Be("image");
        asset["status"]!.GetValue<string>().Should().Be("ready");
        (asset["width"]!.GetValue<int>(), asset["height"]!.GetValue<int>()).Should().Be((800, 1200), "EXIF orientation applied");
        asset["blurHash"]!.GetValue<string>().Should().HaveLength(28);
        var variants = asset["variants"]!.AsArray();
        variants.Select(v => v!["width"]!.GetValue<int>()).Should().Equal(320, 640, 800);

        foreach (var variant in variants)
        {
            var url = variant!["url"]!.GetValue<string>();
            url.Should().MatchRegex(@"^http://localhost/uploads/images/\d{4}/\d{2}/[0-9a-f]{32}_\d+\.webp$");
            File.Exists(OnDisk(url)).Should().BeTrue();
            new FileInfo(OnDisk(url)).Length.Should().Be(variant["bytes"]!.GetValue<long>());

            var served = await api.GuestClient().GetAsync(new Uri(url).PathAndQuery, Ct);
            served.StatusCode.Should().Be(HttpStatusCode.OK);
            served.Content.Headers.ContentType!.MediaType.Should().Be("image/webp");
            var bytes = await served.Content.ReadAsByteArrayAsync(Ct);
            System.Text.Encoding.ASCII.GetString(bytes).Should().NotContain("ReadInTestCam").And.NotContain("Exif");
        }

        (await GetAssetAsync(client, asset))["id"]!.GetValue<Guid>().Should().Be(asset["id"]!.GetValue<Guid>());
    }

    [Fact]
    public async Task A_heic_photo_is_accepted_and_converted()
    {
        var (client, _) = await SignedInAsync();

        var asset = await UploadImageAsync(client, "sample.heic");

        asset["variants"]!.AsArray().Select(v => v!["width"]!.GetValue<int>()).Should().Equal(320, 640);
    }

    [Fact]
    public async Task A_twelve_page_pdf_is_rendered_in_the_background_page_one_first()
    {
        var (client, _) = await SignedInAsync();

        var accepted = await UploadDocumentAsync(client);

        accepted["kind"]!.GetValue<string>().Should().Be("document");
        accepted["pageCount"]!.GetValue<int>().Should().Be(12);
        accepted["title"]!.GetValue<string>().Should().Be("Offshore Inspection Report", "pre-filled from the file name");

        // Hangfire is off in tests, so the job ran inline in its own scope; the API reports the finished state.
        var asset = await GetAssetAsync(client, accepted);
        asset["status"]!.GetValue<string>().Should().Be("ready");
        asset["pagesReady"]!.GetValue<int>().Should().Be(12);
        var pages = asset["pages"]!.AsArray();
        pages.Select(p => p!["pageNo"]!.GetValue<int>()).Should().Equal(Enumerable.Range(1, 12));
        (asset["width"]!.GetValue<int>(), asset["height"]!.GetValue<int>()).Should().Be((1080, 1527));
        asset["blurHash"]!.GetValue<string>().Should().NotBeNullOrEmpty();

        var files = pages.SelectMany(p => new[] { p!["thumbUrl"]!.GetValue<string>(), p["viewUrl"]!.GetValue<string>() }).Select(OnDisk).ToList();
        files.Should().HaveCount(24).And.OnlyContain(f => File.Exists(f), "12 pages × 2 sizes");
        pages[0]!["thumbUrl"]!.GetValue<string>().Should().MatchRegex(@"/uploads/documents/\d{4}/\d{2}/[0-9a-f]{32}/pages/1_400\.webp$");

        // Pages are written one after another, page 1 first.
        var firstPage = File.GetLastWriteTimeUtc(files[1]);
        files.Skip(2).Should().OnlyContain(f => File.GetLastWriteTimeUtc(f) >= firstPage);

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var stored = await db.MediaAssets.AsNoTracking().SingleAsync(m => m.Id == accepted["id"]!.GetValue<Guid>(), Ct);
        stored.ExtractedText.Should().Contain("readinmarker7").And.Contain("dependency injection", "normalized for search");
    }

    [Fact]
    public async Task The_job_saves_page_one_before_any_other_page()
    {
        var (client, userId) = await SignedInAsync();
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var storage = scope.ServiceProvider.GetRequiredService<IFileStorage>();

        var asset = MediaAsset.StartDocument(userId, "Order", false, Fixture("normal-12-pages.pdf").Length, pageCount: 12);
        var path = DocumentPath.Create(DateTime.UtcNow, Guid.NewGuid());
        await storage.SaveAsync(path.Original, new MemoryStream(Fixture("normal-12-pages.pdf")), Ct);
        asset.StartProcessing(path.Original);
        db.MediaAssets.Add(asset);
        await db.SaveChangesAsync(Ct);

        var recorder = new RecordingStorage(storage);
        var job = ActivatorUtilities.CreateInstance<DocumentProcessingJob>(scope.ServiceProvider, (IFileStorage)recorder);
        await job.RunAsync(asset.Id, Ct);

        recorder.Saved.Take(2).Should().Equal(path.Page(1, 400), path.Page(1, 1080));
        recorder.Saved.Should().HaveCount(24);
        (await client.GetFromJsonAsync<JsonObject>($"/api/v1/uploads/{asset.Id}", Ct))!["status"]!.GetValue<string>().Should().Be("ready");
    }

    [Theory]
    [InlineData("encrypted.pdf", "media.pdf_encrypted")]
    [InlineData("corrupted.pdf", "media.pdf_corrupted")]
    [InlineData("too-many-pages-101.pdf", "media.pdf_too_many_pages")]
    [InlineData("exif-rotated.jpg", "media.unsupported_type")]
    public async Task Bad_pdfs_are_rejected_before_anything_is_stored(string fixture, string code)
    {
        var (client, _) = await SignedInAsync();
        var before = Directory.Exists(api.UploadsPath) ? Directory.EnumerateFiles(api.UploadsPath, "*.pdf", SearchOption.AllDirectories).Count() : 0;

        var response = await PostFileAsync(client, "documents", Fixture(fixture), "renamed.pdf");

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        Code((await TaxonomyAndContentTests.Problem(response))).Should().Be(code);
        Directory.EnumerateFiles(api.UploadsPath, "*.pdf", SearchOption.AllDirectories).Should().HaveCount(before);
    }

    [Fact]
    public async Task The_password_error_is_translated()
    {
        var (client, _) = await SignedInAsync(uiLanguage: "ar");

        var response = await PostFileAsync(client, "documents", Fixture("encrypted.pdf"), "secret.pdf");

        (await TaxonomyAndContentTests.Problem(response))["title"]!.GetValue<string>()
            .Should().Be("الملف ده عليه باسورد، ارفعه من غير باسورد.");
    }

    [Fact]
    public async Task Images_become_attachments_and_show_in_the_feed_and_reader()
    {
        var (client, _) = await SignedInAsync();
        var images = new[] { await UploadImageAsync(client), await UploadImageAsync(client, "small.png"), await UploadImageAsync(client, "sample.heic") };
        var (articleId, slug) = await CreateDraftAsync(client, "Three images from the rig");

        var missingAlt = await SetAttachmentsAsync(client, articleId,
            new { mediaAssetId = images[0]["id"], order = 0, altText = "Rig" },
            new { mediaAssetId = images[1]["id"], order = 1 });
        missingAlt.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        Code(await TaxonomyAndContentTests.Problem(missingAlt)).Should().Be("attachments.alt_text_required");

        var ok = await SetAttachmentsAsync(client, articleId,
            new { mediaAssetId = images[2]["id"], order = 2, altText = "Deck", caption = "Advancing Offshore Inspection Solutions" },
            new { mediaAssetId = images[0]["id"], order = 0, altText = "Rig" },
            new { mediaAssetId = images[1]["id"], order = 1, altText = "Crane" });
        ok.StatusCode.Should().Be(HttpStatusCode.NoContent, await ok.Content.ReadAsStringAsync(Ct));
        (await client.PostAsync($"/api/v1/articles/{articleId}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var article = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!;
        var attachments = article["attachments"]!;
        attachments["kind"]!.GetValue<string>().Should().Be("images");
        attachments["document"].Should().BeNull();
        var shown = attachments["images"]!.AsArray();
        shown.Select(i => i!["altText"]!.GetValue<string>()).Should().Equal("Rig", "Crane", "Deck");
        shown[2]!["caption"]!.GetValue<string>().Should().Be("Advancing Offshore Inspection Solutions");
        shown[0]!["variants"]!.AsArray().Select(v => v!["width"]!.GetValue<int>()).Should().Equal(320, 640, 1000);
        shown[0]!["blurHash"]!.GetValue<string>().Should().HaveLength(28);

        var feed = (await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/for-you?field=dotnet&limit=50", Ct))!;
        var card = feed["items"]!.AsArray().Single(c => c!["slug"]!.GetValue<string>() == slug)!;
        card["attachments"]!["images"]!.AsArray().Should().HaveCount(3);
    }

    [Fact]
    public async Task Images_and_a_pdf_cannot_be_mixed_and_an_asset_belongs_to_one_post()
    {
        var (client, _) = await SignedInAsync();
        var image = await UploadImageAsync(client);
        var document = await UploadDocumentAsync(client);
        var (first, _) = await CreateDraftAsync(client, "Mixing is not allowed");
        var (second, _) = await CreateDraftAsync(client, "Stealing is not allowed");

        var mixed = await SetAttachmentsAsync(client, first,
            new { mediaAssetId = image["id"], order = 0, altText = "Rig" },
            new { mediaAssetId = document["id"], order = 1, title = "Report" });
        Code(await TaxonomyAndContentTests.Problem(mixed)).Should().Be("attachments.mixed_kinds");

        (await SetAttachmentsAsync(client, first, new { mediaAssetId = image["id"], order = 0, altText = "Rig" }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var reused = await SetAttachmentsAsync(client, second, new { mediaAssetId = image["id"], order = 0, altText = "Rig" });
        Code(await TaxonomyAndContentTests.Problem(reused)).Should().Be("media.in_use");

        var (other, _) = await SignedInAsync();
        var foreign = await SetAttachmentsAsync(client, second,
            new { mediaAssetId = (await UploadImageAsync(other))["id"], order = 0, altText = "Not mine" });
        Code(await TaxonomyAndContentTests.Problem(foreign)).Should().Be("attachments.asset_not_found");
        (await other.GetAsync($"/api/v1/uploads/{image["id"]}", Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound, "only the owner polls an upload");
    }

    [Fact]
    public async Task Downloads_follow_the_author_switch_and_the_owner_and_moderators_always_can()
    {
        var (author, _) = await SignedInAsync();
        var document = await UploadDocumentAsync(author, allowDownload: false);
        var (articleId, slug) = await CreateDraftAsync(author, "A report to download");
        (await SetAttachmentsAsync(author, articleId, new { mediaAssetId = document["id"], order = 0, title = "Inspection Report 2026" }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var url = $"/api/v1/documents/{document["id"]}/download";

        (await api.GuestClient().GetAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound, "not published yet");
        var ownerDraft = await author.GetAsync(url, Ct);
        ownerDraft.StatusCode.Should().Be(HttpStatusCode.OK, "the owner always can");

        (await author.PostAsync($"/api/v1/articles/{articleId}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var denied = await api.GuestClient().GetAsync(url, Ct);
        denied.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        Code(await TaxonomyAndContentTests.Problem(denied)).Should().Be("media.download_not_allowed");

        var guestView = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["attachments"]!["document"]!;
        guestView["canDownload"]!.GetValue<bool>().Should().BeFalse();
        guestView["downloadUrl"]!.GetValue<string>().Should().Be("http://localhost" + url);
        guestView["pages"]!.AsArray().Should().HaveCount(12, "the reader gets every page");
        (await author.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["attachments"]!["document"]!["canDownload"]!
            .GetValue<bool>().Should().BeTrue("the cached copy is personalized for the author");

        var (moderator, moderatorId) = await SignedInAsync();
        await GrantAsync(moderatorId, RoleIds.Moderator);
        (await moderator.GetAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        (await SetAttachmentsAsync(author, articleId, new { mediaAssetId = document["id"], order = 0, title = "Inspection Report 2026", allowDownload = true }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var allowed = await api.GuestClient().GetAsync(url, Ct);
        allowed.StatusCode.Should().Be(HttpStatusCode.OK);
        allowed.Content.Headers.ContentType!.MediaType.Should().Be("application/pdf");
        allowed.Content.Headers.ContentDisposition!.DispositionType.Should().Be("attachment");
        allowed.Content.Headers.ContentDisposition.FileName!.Trim('"').Should().Be("Inspection Report 2026.pdf");
        allowed.Headers.GetValues("X-Content-Type-Options").Should().Equal("nosniff");
        allowed.Headers.GetValues("Content-Security-Policy").Should().Equal("sandbox");
        (await allowed.Content.ReadAsByteArrayAsync(Ct)).Should().Equal(Fixture("normal-12-pages.pdf"), "the ORIGINAL file");

        var feedCard = (await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/feed/for-you?field=dotnet&limit=50", Ct))!["items"]!
            .AsArray().Single(c => c!["slug"]!.GetValue<string>() == slug)!;
        feedCard["attachments"]!["document"]!["pages"]!.AsArray().Should().HaveCount(10, "feed cards carry at most 10 page thumbs");
        feedCard["attachments"]!["document"]!["canDownload"]!.GetValue<bool>().Should().BeTrue();
    }

    [Fact]
    public async Task A_pdf_is_never_served_as_a_static_file()
    {
        var (client, _) = await SignedInAsync();
        var asset = await GetAssetAsync(client, await UploadDocumentAsync(client));
        var thumb = new Uri(asset["pages"]![0]!["thumbUrl"]!.GetValue<string>()).AbsolutePath;
        var original = thumb[..thumb.IndexOf("/pages/", StringComparison.Ordinal)] + "/original.pdf";
        File.Exists(OnDisk(original)).Should().BeTrue();

        (await api.GuestClient().GetAsync(original, Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await client.GetAsync(original, Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound, "not even for the owner");
        (await api.GuestClient().GetAsync(thumb, Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "rendered pages are plain WebP");
    }

    [Fact]
    public async Task Deleting_media_respects_attachments_and_deleting_the_article_removes_them()
    {
        var (client, _) = await SignedInAsync();
        var loose = await UploadImageAsync(client);
        var attached = await UploadDocumentAsync(client);
        var (articleId, _) = await CreateDraftAsync(client, "A post that will be deleted");
        (await SetAttachmentsAsync(client, articleId, new { mediaAssetId = attached["id"], order = 0, title = "Report" }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var attachedFiles = (await GetAssetAsync(client, attached))["pages"]!.AsArray()
            .Select(p => OnDisk(p!["viewUrl"]!.GetValue<string>())).ToList();

        (await client.DeleteAsync($"/api/v1/uploads/{loose["id"]}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        loose["variants"]!.AsArray().Should().OnlyContain(v => !File.Exists(OnDisk(v!["url"]!.GetValue<string>())));

        var inUse = await client.DeleteAsync($"/api/v1/uploads/{attached["id"]}", Ct);
        Code(await TaxonomyAndContentTests.Problem(inUse)).Should().Be("media.in_use");

        (await client.DeleteAsync($"/api/v1/articles/{articleId}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.GetAsync($"/api/v1/uploads/{attached["id"]}", Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound);
        attachedFiles.Should().OnlyContain(f => !File.Exists(f));
    }

    [Fact]
    public async Task Orphan_cleanup_deletes_unattached_assets_older_than_a_day()
    {
        var (client, _) = await SignedInAsync();
        var abandoned = await UploadDocumentAsync(client);
        var attached = await UploadDocumentAsync(client);
        var fresh = await UploadImageAsync(client);
        var (articleId, _) = await CreateDraftAsync(client, "A draft keeps its document");
        (await SetAttachmentsAsync(client, articleId, new { mediaAssetId = attached["id"], order = 0, title = "Kept" }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var abandonedFiles = (await GetAssetAsync(client, abandoned))["pages"]!.AsArray()
            .Select(p => OnDisk(p!["thumbUrl"]!.GetValue<string>())).ToList();

        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var aged = new[] { abandoned["id"]!.GetValue<Guid>(), attached["id"]!.GetValue<Guid>() };
            await db.MediaAssets.Where(m => aged.Contains(m.Id)).ExecuteUpdateAsync(s => s.SetProperty(m => m.CreatedAt, DateTime.UtcNow.AddDays(-2)), Ct);
            await scope.ServiceProvider.GetRequiredService<OrphanedUploadsCleanupJob>().RunAsync(Ct);
        }

        (await client.GetAsync($"/api/v1/uploads/{abandoned["id"]}", Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound);
        abandonedFiles.Should().OnlyContain(f => !File.Exists(f), "the pages go with the asset");
        (await client.GetAsync($"/api/v1/uploads/{attached["id"]}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "attached to a draft");
        (await client.GetAsync($"/api/v1/uploads/{fresh["id"]}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "younger than 24 hours");
    }

    [Fact]
    public async Task Quotas_stop_uploads_with_a_clear_error()
    {
        var (daily, dailyId) = await SignedInAsync();
        var (storageFull, storageId) = await SignedInAsync();
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            for (var i = 0; i < 50; i++) db.MediaAssets.Add(ReadyImage(dailyId, bytes: 1));
            db.MediaAssets.Add(ReadyImage(storageId, bytes: 200L * 1024 * 1024));
            await db.SaveChangesAsync(Ct);
        }

        var tooMany = await PostFileAsync(daily, "images", Fixture("small.png"), "small.png");
        var tooBig = await PostFileAsync(storageFull, "documents", Fixture("normal-12-pages.pdf"), "doc.pdf");

        tooMany.StatusCode.Should().Be(HttpStatusCode.Conflict);
        Code(await TaxonomyAndContentTests.Problem(tooMany)).Should().Be("media.quota_daily");
        tooBig.StatusCode.Should().Be(HttpStatusCode.Conflict);
        Code(await TaxonomyAndContentTests.Problem(tooBig)).Should().Be("media.quota_storage");

        static MediaAsset ReadyImage(Guid owner, long bytes)
        {
            var asset = MediaAsset.StartImage(owner, MediaPurpose.Image, bytes);
            asset.CompleteImage(10, 10, "00F=al", [new MediaVariant(10, 10, $"/uploads/images/2026/11/{Guid.NewGuid():N}_10.webp", bytes)]);
            return asset;
        }
    }

    [Fact]
    public async Task A_post_can_be_only_attachments_with_line_breaks_in_its_text()
    {
        var (client, _) = await SignedInAsync();
        var image = await UploadImageAsync(client);
        var dotnet = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!.Single(f => f!["slug"]!.GetValue<string>() == "dotnet")!;

        // What the web and mobile composers send: no body at all, or paragraphs with hardBreak nodes.
        foreach (var blocks in new[]
                 {
                     Array.Empty<object>(),
                     [new { id = "p1", type = "paragraph", dir = "auto", content = new object[] { new { type = "text", text = "سطر أول" }, new { type = "hardBreak" }, new { type = "text", text = "Second line" } } }],
                 })
        {
            var created = await client.PostAsJsonAsync("/api/v1/articles", new
            {
                fieldId = dotnet["id"]!.GetValue<Guid>(), language = "ar-EG", title = $"Composer post {blocks.Length}",
                content = new { version = 1, language = "ar-EG", blocks },
                sources = new[] { new { title = "ReadIn", url = "https://readin.app" } },
                isAiAssisted = false,
            }, Ct);
            created.StatusCode.Should().Be(HttpStatusCode.Created, await created.Content.ReadAsStringAsync(Ct));
            var id = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();

            if (blocks.Length == 0)
            {
                (await SetAttachmentsAsync(client, id, new { mediaAssetId = image["id"], order = 0, altText = "Only a photo" }))
                    .StatusCode.Should().Be(HttpStatusCode.NoContent);
            }
            (await client.PostAsync($"/api/v1/articles/{id}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        }
    }

    [Fact]
    public async Task Alt_text_captions_and_document_titles_take_5000_characters()
    {
        var (client, _) = await SignedInAsync();
        var image = await UploadImageAsync(client);
        var document = await UploadDocumentAsync(client);
        var (imagePost, imageSlug) = await CreateDraftAsync(client, "A photo with a long description");
        var (documentPost, documentSlug) = await CreateDraftAsync(client, "A document with a long title");
        var alt = string.Concat(Enumerable.Repeat("وصف طويل للصورة. ", 400))[..5000];
        var caption = new string('c', 5000);
        var title = new string('ت', 5000);

        var tooLong = await SetAttachmentsAsync(client, imagePost, new { mediaAssetId = image["id"], order = 0, altText = alt + "x" });
        var problem = await TaxonomyAndContentTests.Problem(tooLong);
        Code(problem).Should().Be("validation.failed");
        problem["errors"]!.ToJsonString().Should().Contain("attachments.alt_text_too_long");

        (await SetAttachmentsAsync(client, imagePost, new { mediaAssetId = image["id"], order = 0, altText = alt, caption }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await SetAttachmentsAsync(client, documentPost, new { mediaAssetId = document["id"], order = 0, title }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.PostAsync($"/api/v1/articles/{imagePost}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.PostAsync($"/api/v1/articles/{documentPost}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var shownImage = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{imageSlug}", Ct))!["attachments"]!["images"]![0]!;
        shownImage["altText"]!.GetValue<string>().Should().Be(alt.Trim());
        shownImage["caption"]!.GetValue<string>().Should().Be(caption);
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{documentSlug}", Ct))!["attachments"]!["document"]!["title"]!
            .GetValue<string>().Should().Be(title);
    }

    [Fact]
    public async Task Demo_posts_with_media_are_seeded_locally()
    {
        var photos = (await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/articles/demo-media-angular-workshop", Ct))!;
        var document = (await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/articles/demo-media-clean-architecture-pdf", Ct))!;

        photos["attachments"]!["images"]!.AsArray().Should().HaveCount(3);
        photos["attachments"]!["images"]![0]!["variants"]!.AsArray().Select(v => v!["width"]!.GetValue<int>()).Should().Equal(320, 640, 1080, 1600);
        document["attachments"]!["document"]!["pageCount"]!.GetValue<int>().Should().Be(12);
        document["attachments"]!["document"]!["canDownload"]!.GetValue<bool>().Should().BeTrue();
    }

    private async Task GrantAsync(Guid userId, Guid roleId)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var user = await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == userId, Ct);
        user.GrantRole(roleId);
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>Records the order in which files are saved.</summary>
    private sealed class RecordingStorage(IFileStorage inner) : IFileStorage
    {
        public List<string> Saved { get; } = [];

        public Task SaveAsync(string relativePath, Stream content, CancellationToken cancellationToken = default)
        {
            Saved.Add(relativePath);
            return inner.SaveAsync(relativePath, content, cancellationToken);
        }

        public Task<Stream> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default) => inner.OpenReadAsync(relativePath, cancellationToken);
        public Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default) => inner.DeleteAsync(relativePath, cancellationToken);
        public string GetPublicUrl(string relativePath) => inner.GetPublicUrl(relativePath);
    }
}
