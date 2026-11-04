using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Writing articles through the editor API (F05): a draft document, autosave and publish.</summary>
internal static class ArticleTestKit
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    public static object Paragraph(string text, string id = "p1") =>
        new { id, type = "paragraph", dir = "auto", content = new[] { new { type = "text", text } } };

    /// <summary>A paragraph of inline nodes (<see cref="Text"/>, <see cref="Mention"/>).</summary>
    public static object Inline(string id, params object[] content) => new { id, type = "paragraph", dir = "auto", content };

    public static object Text(string text) => new { type = "text", text };

    /// <summary>An RDoc <c>mention</c> inline node (SPEC §13.3).</summary>
    public static object Mention(Guid userId, string text) => new { type = "mention", userId, text };

    public static readonly object[] OneSource = [new { title = "ReadIn", url = "https://readin.app" }];

    /// <summary>An editor document with one language version (<c>ArticleDraftDocument</c>).</summary>
    public static JsonObject Document(
        Guid? fieldId,
        string title,
        string language = "en",
        object[]? blocks = null,
        object[]? sources = null,
        string[]? tags = null,
        string? coverUrl = null,
        object[]? attachments = null,
        bool isAiAssisted = false) =>
        JsonSerializerHelper.ToObject(new
        {
            sourceLanguage = language,
            translations = new[]
            {
                new { language, title, subtitle = (string?)null, content = new { version = 1, language, blocks = blocks ?? [Paragraph("Body.")] } },
            },
            fieldId,
            topicId = (Guid?)null,
            tags = tags ?? [],
            sources = sources ?? OneSource,
            coverUrl,
            versionBadge = (string?)null,
            isAiAssisted,
            attachments = attachments ?? [],
        });

    /// <summary>POST /articles; returns the <c>ArticleEditDto</c>.</summary>
    public static async Task<JsonObject> CreateDraftAsync(this HttpClient client, JsonObject document)
    {
        var response = await client.PostAsJsonAsync("/api/v1/articles", document, Ct);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    public static Task<HttpResponseMessage> SaveDraftAsync(this HttpClient client, Guid articleId, int baseVersion, JsonObject document) =>
        client.PutAsJsonAsync($"/api/v1/articles/{articleId}/draft", new { baseVersion, document }, Ct);

    public static Task<HttpResponseMessage> PublishDraftAsync(this HttpClient client, Guid articleId, int baseVersion) =>
        client.PostAsJsonAsync($"/api/v1/articles/{articleId}/publish", new { baseVersion }, Ct);

    /// <summary>GET /articles/{id}/edit.</summary>
    public static async Task<JsonObject> EditAsync(this HttpClient client, Guid articleId) =>
        (await client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/edit", Ct))!;

    /// <summary>Creates the draft and publishes it; returns its id and reader slug.</summary>
    public static async Task<(Guid Id, string Slug)> WriteAndPublishAsync(this HttpClient client, JsonObject document)
    {
        var draft = await client.CreateDraftAsync(document);
        var id = draft["id"]!.GetValue<Guid>();
        var published = await client.PublishDraftAsync(id, draft["version"]!.GetValue<int>());
        var body = await published.Content.ReadAsStringAsync(Ct);
        published.StatusCode.Should().Be(HttpStatusCode.OK, body);
        return (id, JsonNode.Parse(body)!["slug"]!.GetValue<string>());
    }

    /// <summary>Replaces the working copy's attachments (they go live with the next publish).</summary>
    public static async Task<HttpResponseMessage> SetDraftAttachmentsAsync(this HttpClient client, Guid articleId, params object[] items)
    {
        var edit = await client.EditAsync(articleId);
        var document = edit["document"]!.AsObject();
        document["attachments"] = JsonSerializerHelper.ToNode(items);
        return await client.SaveDraftAsync(articleId, edit["version"]!.GetValue<int>(), document);
    }

    /// <summary>Publishes the current working copy.</summary>
    public static async Task<HttpResponseMessage> PublishCurrentAsync(this HttpClient client, Guid articleId) =>
        await client.PublishDraftAsync(articleId, (await client.EditAsync(articleId))["version"]!.GetValue<int>());

    public static async Task<string> PublishedSlugAsync(this HttpResponseMessage published)
    {
        var body = await published.Content.ReadAsStringAsync(Ct);
        published.StatusCode.Should().Be(HttpStatusCode.OK, body);
        return JsonNode.Parse(body)!["slug"]!.GetValue<string>();
    }

    public static IEnumerable<string> ProblemCodes(this JsonObject edit) =>
        edit["checks"]!["problems"]!.AsArray().Select(p => p!["code"]!.GetValue<string>());
}

internal static class JsonSerializerHelper
{
    private static readonly System.Text.Json.JsonSerializerOptions Web = new(System.Text.Json.JsonSerializerDefaults.Web);

    public static JsonObject ToObject(object value) => ToNode(value)!.AsObject();

    public static JsonNode? ToNode(object value) => System.Text.Json.JsonSerializer.SerializeToNode(value, Web);
}
