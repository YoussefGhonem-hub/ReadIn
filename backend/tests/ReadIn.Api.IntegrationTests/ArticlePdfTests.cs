using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles.Pdf;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Infrastructure.Persistence;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Tokens;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// <c>GET /articles/{id}/pdf</c> (SPEC F33): your own published or archived article, its published version, one language
/// per file, with safe download headers and the limits of the spec. Printed by the real headless Chromium.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ArticlePdfTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static Task<HttpResponseMessage> PdfAsync(HttpClient client, Guid articleId, string? lang = null) =>
        client.GetAsync($"/api/v1/articles/{articleId}/pdf{(lang is null ? string.Empty : "?lang=" + Uri.EscapeDataString(lang))}", Ct);

    private static async Task<PdfDocument> OpenAsync(HttpResponseMessage response)
    {
        var body = await response.Content.ReadAsByteArrayAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.OK, System.Text.Encoding.UTF8.GetString(body));
        return PdfDocument.Open(body);
    }

    /// <summary>The name in <c>filename*</c> (RFC 5987), as clients read it.</summary>
    private static string FileName(HttpResponseMessage response)
    {
        var header = response.Content.Headers.ContentDisposition!;
        header.DispositionType.Should().Be("attachment");
        header.FileName.Should().Be("readin-article.pdf", "the ASCII fallback");
        header.FileNameStar.Should().NotBeNull();
        return header.FileNameStar!;
    }

    private async Task<(SignedInUser Writer, Guid Id, string Slug)> PublishedAsync(string title = "Exporting Span<T> as a PDF", string language = "en")
    {
        var writer = await api.UserAsync("PDF Writer");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var (id, slug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, title, language,
            [ArticleTestKit.Paragraph(language == "en" ? "The published words." : "الكلام المنشور.")]));
        return (writer, id, slug);
    }

    private async Task InDbAsync(Func<AppDbContext, Task> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    [Fact]
    public async Task The_author_downloads_the_article_as_a_pdf_with_safe_headers_and_its_file_name()
    {
        var (writer, id, slug) = await PublishedAsync();

        var response = await PdfAsync(writer.Client, id);

        using var pdf = await OpenAsync(response);
        response.Content.Headers.ContentType!.MediaType.Should().Be("application/pdf");
        response.Headers.GetValues("X-Content-Type-Options").Should().Equal("nosniff");
        response.Headers.CacheControl!.Private.Should().BeTrue();
        response.Headers.CacheControl.NoStore.Should().BeTrue();
        response.Content.Headers.GetValues("Content-Disposition").Single()
            .Should().Be($"attachment; filename=\"readin-article.pdf\"; filename*=UTF-8''{slug}-en.pdf");
        FileName(response).Should().Be($"{slug}-en.pdf");
        pdf.Information.Title.Should().Be("Exporting Span<T> as a PDF");
        pdf.Information.Author.Should().Be("PDF Writer");
        ((StringToken)pdf.Structure.Catalog.CatalogDictionary.Data["Lang"]).Data.Should().Be("en");
        string.Concat(pdf.GetPages().Select(p => p.Text)).Should().Contain("The published words.");
    }

    [Fact]
    public async Task An_arabic_article_is_printed_in_arabic_with_its_language_in_the_file_name()
    {
        var (writer, id, slug) = await PublishedAsync("التصدير بالعربي من غير ولا كلمة إنجليزي", "ar-EG");

        var response = await PdfAsync(writer.Client, id);

        using var pdf = await OpenAsync(response);
        FileName(response).Should().Be($"{slug}-ar-EG.pdf");
        ((StringToken)pdf.Structure.Catalog.CatalogDictionary.Data["Lang"]).Data.Should().Be("ar-EG");
        pdf.Information.Title.Should().Be("التصدير بالعربي من غير ولا كلمة إنجليزي");
    }

    [Theory]
    [InlineData("الذكاء-الاصطناعي-ar-EG.pdf", "%D8%A7%D9%84%D8%B0%D9%83%D8%A7%D8%A1-%D8%A7%D9%84%D8%A7%D8%B5%D8%B7%D9%86%D8%A7%D8%B9%D9%8A-ar-EG.pdf")]
    [InlineData("clean-code-en.pdf", "clean-code-en.pdf")]
    [InlineData("a b'(c)-en.pdf", "a%20b%27%28c%29-en.pdf")]
    public void Any_slug_survives_as_an_rfc_5987_file_name(string fileName, string encoded)
    {
        var header = Endpoints.ArticlePdfEndpoints.ContentDisposition(fileName);

        header.Should().Be($"attachment; filename=\"readin-article.pdf\"; filename*=UTF-8''{encoded}");
        ContentDispositionHeaderValue.Parse(header).FileNameStar.Should().Be(fileName);
    }

    [Fact]
    public async Task Only_the_author_gets_a_pdf_everyone_else_gets_not_found()
    {
        var (_, id, _) = await PublishedAsync();
        var reader = await api.UserAsync("Reader");
        var moderator = await api.UserAsync("PDF Moderator");
        await InDbAsync(async db =>
        {
            (await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == moderator.Id, Ct)).GrantRole(RoleIds.Moderator);
            await db.SaveChangesAsync(Ct);
        });
        await using (var scope = api.Services.CreateAsyncScope())
            await scope.ServiceProvider.GetRequiredService<IUserAccessService>().InvalidateAsync(moderator.Id, Ct);

        await PdfAsync(reader.Client, id).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await PdfAsync(moderator.Client, id).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await PdfAsync(reader.Client, Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await PdfAsync(api.GuestClient(), id).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
    }

    [Fact]
    public async Task Drafts_and_deleted_articles_have_no_pdf_but_archived_ones_do()
    {
        var (writer, id, _) = await PublishedAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, "Never published"));

        await PdfAsync(writer.Client, draft["id"]!.GetValue<Guid>()).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        await InDbAsync(db => db.Articles.Where(a => a.Id == id).ExecuteUpdateAsync(s => s.SetProperty(a => a.Status, ArticleStatus.Archived), Ct));
        using (var archived = await OpenAsync(await PdfAsync(writer.Client, id))) archived.NumberOfPages.Should().BePositive();

        (await writer.Client.DeleteAsync($"/api/v1/articles/{id}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await PdfAsync(writer.Client, id).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task The_published_version_is_printed_even_with_unpublished_changes()
    {
        var (writer, id, _) = await PublishedAsync("The published title");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var edit = await writer.Client.EditAsync(id);
        await writer.Client.SaveDraftAsync(id, edit["version"]!.GetValue<int>(),
            ArticleTestKit.Document(field, "A title nobody has seen", blocks: [ArticleTestKit.Paragraph("Unpublished words.")])).OkJsonAsync();

        using var pdf = await OpenAsync(await PdfAsync(writer.Client, id));

        pdf.Information.Title.Should().Be("The published title");
        var text = string.Concat(pdf.GetPages().Select(p => p.Text));
        text.Should().Contain("The published words.").And.NotContain("Unpublished words.");
    }

    [Fact]
    public async Task Each_language_version_is_its_own_pdf_and_my_articles_lists_the_published_ones()
    {
        var writer = await api.UserAsync("Two Languages");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var document = ArticleTestKit.Document(field, "الـ PDF بلغتين", "ar-EG", [ArticleTestKit.Paragraph("النسخة العربي.")]);
        document["translations"]!.AsArray().Add(JsonNode.Parse("""
            { "language": "en", "title": "A PDF in two languages", "subtitle": null,
              "content": { "version": 1, "language": "en", "blocks": [{ "id": "p1", "type": "paragraph", "content": [{ "type": "text", "text": "The English version." }] }] } }
            """));
        var (id, slug) = await writer.Client.WriteAndPublishAsync(document);

        var mine = (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=published", Ct))!["items"]!.AsArray()
            .Single(a => a!["id"]!.GetValue<Guid>() == id)!;
        mine["publishedLanguages"]!.AsArray().Select(l => l!.GetValue<string>()).Should().Equal("ar-EG", "en");

        var english = await PdfAsync(writer.Client, id, "en");
        using (var pdf = await OpenAsync(english)) pdf.Information.Title.Should().Be("A PDF in two languages");
        FileName(english).Should().Be($"{slug}-en.pdf");

        foreach (var fallback in new string?[] { null, "fr", "ar" })
        {
            var source = await PdfAsync(writer.Client, id, fallback);
            using var pdf = await OpenAsync(source);
            pdf.Information.Title.Should().Be("الـ PDF بلغتين", $"lang={fallback ?? "(none)"} prints the source language");
            FileName(source).Should().Be($"{slug}-ar-EG.pdf");
        }
    }

    [Fact]
    public async Task My_articles_lists_only_published_languages()
    {
        var (writer, id, _) = await PublishedAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, "Still a draft"));
        var edit = await writer.Client.EditAsync(id);
        var twoLanguages = ArticleTestKit.Document(field, "Exporting Span<T> as a PDF");
        twoLanguages["translations"]!.AsArray().Add(JsonNode.Parse("""
            { "language": "ar-EG", "title": "ترجمة لسه ما اتنشرتش", "subtitle": null,
              "content": { "version": 1, "language": "ar-EG", "blocks": [{ "id": "p1", "type": "paragraph", "content": [{ "type": "text", "text": "عربي." }] }] } }
            """));
        await writer.Client.SaveDraftAsync(id, edit["version"]!.GetValue<int>(), twoLanguages).OkJsonAsync();

        var published = (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=published", Ct))!["items"]!.AsArray().Single()!;
        var drafts = (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=draft", Ct))!["items"]!.AsArray().Single()!;

        published["publishedLanguages"]!.AsArray().Select(l => l!.GetValue<string>()).Should().Equal(["en"], "a language only in the working copy isn't printable yet");
        drafts["id"]!.GetValue<Guid>().Should().Be(draft["id"]!.GetValue<Guid>());
        drafts["publishedLanguages"]!.AsArray().Should().BeEmpty();
    }

    [Fact]
    public async Task An_article_hidden_by_moderators_has_no_pdf()
    {
        var (writer, id, _) = await PublishedAsync();
        await InDbAsync(db => db.Articles.Where(a => a.Id == id).ExecuteUpdateAsync(s => s.SetProperty(a => a.HiddenAt, DateTime.UtcNow), Ct));

        var problem = await PdfAsync(writer.Client, id).ProblemAsync(HttpStatusCode.Conflict, "article.pdf_hidden");

        problem["title"]!.GetValue<string>().Should().Be("Moderators hid this article, so it can't be downloaded as a PDF.");
    }

    [Fact]
    public async Task Ten_requests_an_hour_per_user_then_429()
    {
        var writer = await api.SignUpAsync("ar");
        var other = await api.UserAsync("Other Writer");

        for (var i = 0; i < 10; i++) await PdfAsync(writer.Client, Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        var limited = await PdfAsync(writer.Client, Guid.NewGuid()).ProblemAsync(HttpStatusCode.TooManyRequests, "article.pdf_limit");
        limited["title"]!.GetValue<string>().Should().Be("حمّلت PDFs كتير الساعة دي. حاول تاني بعد شوية.");
        // The limit is per user.
        await PdfAsync(other.Client, Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Theory]
    [InlineData("article.pdf_busy", HttpStatusCode.ServiceUnavailable)]
    [InlineData("article.pdf_failed", HttpStatusCode.InternalServerError)]
    public async Task A_busy_or_failed_build_answers_with_its_code(string code, HttpStatusCode status)
    {
        var (writer, id, _) = await PublishedAsync();
        var error = code == "article.pdf_busy" ? ArticlePdfErrors.Busy : ArticlePdfErrors.Failed;
        await using var host = api.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.Replace(ServiceDescriptor.Singleton<IArticlePdfRenderer>(new FailingRenderer(error)))));
        var client = host.CreateClient();
        client.DefaultRequestHeaders.Authorization = writer.Client.DefaultRequestHeaders.Authorization;

        await PdfAsync(client, id).ProblemAsync(status, code);
    }

    [Fact]
    public async Task Pictures_come_from_the_uploads_folder_and_are_printed()
    {
        var writer = await api.UserAsync("Picture Writer");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var image = await UploadAsync(writer.Client, "image");
        var cover = await UploadAsync(writer.Client, "cover");
        var (id, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Pictures in a PDF",
            blocks:
            [
                ArticleTestKit.Paragraph("Before the picture."),
                new { id = "img", type = "image", src = image, alt = "A test picture", caption = "PictureCaption under it" },
            ],
            coverUrl: cover));

        using var pdf = await OpenAsync(await PdfAsync(writer.Client, id));

        pdf.GetPages().SelectMany(p => p.GetImages()).Count(i => i.BoundingBox.Width > 100)
            .Should().BeGreaterThanOrEqualTo(2, "the cover and the image block, read from disk and inlined");
        string.Concat(pdf.GetPages().Select(p => p.Text)).Should().Contain("PictureCaption under it");
    }

    [Fact]
    public async Task The_web_can_read_the_file_name_across_origins()
    {
        var (writer, id, _) = await PublishedAsync();
        using var request = new HttpRequestMessage(HttpMethod.Get, $"/api/v1/articles/{id}/pdf");
        request.Headers.Add("Origin", "https://readin.app");

        using var response = await writer.Client.SendAsync(request, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        response.Headers.GetValues("Access-Control-Expose-Headers").Single().Should().Contain("Content-Disposition");
    }

    [Fact]
    public async Task OpenApi_documents_the_pdf_endpoint()
    {
        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();

        var get = document["paths"]!["/api/v1/articles/{id}/pdf"]!["get"]!;
        get.ToJsonString().Should().Contain("application/pdf").And.Contain("\"name\":\"lang\"");
    }

    private static async Task<string> UploadAsync(HttpClient client, string purpose)
    {
        using var form = new MultipartFormDataContent { { new StringContent(purpose), "purpose" } };
        var file = new ByteArrayContent(await File.ReadAllBytesAsync(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "medium.webp"), Ct));
        file.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
        form.Add(file, "file", "medium.webp");
        var response = await client.PostAsync("/api/v1/uploads/images", form, Ct);
        var body = await response.Content.ReadFromJsonAsync<JsonObject>(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body?.ToJsonString());
        return body!["variants"]!.AsArray()[0]!["url"]!.GetValue<string>();
    }

    private sealed class FailingRenderer(Error error) : IArticlePdfRenderer
    {
        public Task<Result<byte[]>> RenderAsync(ArticlePdfDocument document, CancellationToken cancellationToken) =>
            Task.FromResult<Result<byte[]>>(error);
    }
}
