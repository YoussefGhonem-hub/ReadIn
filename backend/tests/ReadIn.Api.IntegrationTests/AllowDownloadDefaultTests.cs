using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// "Allow download" is on by default for a new PDF (SPEC F26, pre-production step): the API takes <c>true</c> when the
/// upload omits it, the writer can still turn it off, and readers then get <c>canDownload</c> and the download itself.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AllowDownloadDefaultTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static byte[] Pdf() => File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "normal-12-pages.pdf"));

    private static async Task<JsonObject> UploadAsync(HttpClient client, bool? allowDownload)
    {
        using var form = new MultipartFormDataContent();
        var file = new ByteArrayContent(Pdf());
        file.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/pdf");
        form.Add(file, "file", "Cheat sheet.pdf");
        if (allowDownload is { } allow) form.Add(new StringContent(allow ? "true" : "false"), "allowDownload");
        var response = await client.PostAsync("/api/v1/uploads/documents", form, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Accepted, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
    }

    [Fact]
    public async Task A_pdf_uploaded_without_the_setting_allows_download_and_the_writer_can_turn_it_off()
    {
        var writer = await api.UserAsync();

        (await UploadAsync(writer.Client, allowDownload: null))["allowDownload"]!.GetValue<bool>().Should().BeTrue("on by default");
        (await UploadAsync(writer.Client, allowDownload: false))["allowDownload"]!.GetValue<bool>().Should().BeFalse();
        (await UploadAsync(writer.Client, allowDownload: true))["allowDownload"]!.GetValue<bool>().Should().BeTrue();
    }

    [Fact]
    public async Task A_reader_downloads_a_default_pdf_of_a_published_post()
    {
        var writer = await api.UserAsync();
        var assetId = (await UploadAsync(writer.Client, allowDownload: null))["id"]!.GetValue<Guid>();
        var articleId = (await writer.Client.CreateDraftAsync(ArticleTestKit.Document(await writer.Client.FieldIdAsync("dotnet"), "Default download")))["id"]!
            .GetValue<Guid>();
        // The draft attachment leaves allowDownload out: the asset's value (on) is kept.
        (await writer.Client.SetDraftAttachmentsAsync(articleId, new { mediaAssetId = assetId, order = 0, title = "Cheat sheet" })).StatusCode
            .Should().Be(HttpStatusCode.OK);
        var published = await writer.Client.PublishCurrentAsync(articleId);
        var slug = await published.PublishedSlugAsync();

        var reader = await api.UserAsync();
        var document = (await reader.Client.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["attachments"]!["document"]!;
        (document["allowDownload"]!.GetValue<bool>(), document["canDownload"]!.GetValue<bool>()).Should().Be((true, true));

        var download = await reader.Client.GetAsync(document["downloadUrl"]!.GetValue<string>(), Ct);
        download.StatusCode.Should().Be(HttpStatusCode.OK);
        download.Content.Headers.ContentType!.MediaType.Should().Be("application/pdf");
        download.Content.Headers.ContentDisposition!.DispositionType.Should().Be("attachment");
    }
}
