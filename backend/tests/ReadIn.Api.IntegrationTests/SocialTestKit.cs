using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Helpers for the F10/F12/F13 tests: fresh writers and articles, so every count is exact.</summary>
internal static class SocialTestKit
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    /// <summary>A signed-in user with a completed profile and a unique @username.</summary>
    public static async Task<SignedInUser> UserAsync(this ApiFactory api, string displayName = "Social Tester")
    {
        var user = await api.SignUpAsync();
        var username = $"s_{Guid.NewGuid():N}"[..20];
        (await user.Client.PutAsJsonAsync("/api/v1/me/profile/complete", new { displayName, username }, Ct)).EnsureSuccessStatusCode();
        user.Me["username"] = username;
        user.Me["displayName"] = displayName;
        return user;
    }

    public static async Task<Guid> FieldIdAsync(this HttpClient client, string slug) =>
        (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Single(f => f!["slug"]!.GetValue<string>() == slug)!["id"]!.GetValue<Guid>();

    /// <summary>Creates and publishes an article as <paramref name="author"/>.</summary>
    public static async Task<(Guid Id, string Slug)> PublishAsync(
        this HttpClient author, string? title = null, string field = "dotnet", string language = "en")
    {
        title ??= $"Social test {Guid.NewGuid():N}";
        return await author.WriteAndPublishAsync(ArticleTestKit.Document(
            await author.FieldIdAsync(field), title, language, [ArticleTestKit.Paragraph("Reactions, saves and follows.")]));
    }

    public static async Task<JsonObject> OkJsonAsync(this Task<HttpResponseMessage> request)
    {
        var response = await request;
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.OK, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    public static async Task<JsonArray> OkArrayAsync(this Task<HttpResponseMessage> request)
    {
        var response = await request;
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.OK, body);
        return JsonNode.Parse(body)!.AsArray();
    }

    /// <summary>Asserts the status and the ProblemDetails <c>code</c>, and returns the problem.</summary>
    public static async Task<JsonObject> ProblemAsync(this Task<HttpResponseMessage> request, HttpStatusCode status, string code)
    {
        var response = await request;
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(status, body);
        var problem = JsonNode.Parse(body)!.AsObject();
        problem["code"]!.GetValue<string>().Should().Be(code);
        return problem;
    }

    public static Task<HttpResponseMessage> PutEmptyAsync(this HttpClient client, string url) => client.PutAsync(url, null, Ct);

    public static Task<HttpResponseMessage> ReactAsync(this HttpClient client, Guid articleId, string? type) =>
        client.PutAsJsonAsync($"/api/v1/articles/{articleId}/reaction", new { type }, Ct);

    /// <summary>Pages through the For you feed until the article shows up.</summary>
    public static async Task<JsonObject> FindInForYouAsync(this HttpClient client, Guid articleId)
    {
        string? cursor = null;
        for (var page = 0; page < 20; page++)
        {
            var url = "/api/v1/feed/for-you?limit=50" + (cursor is null ? "" : $"&cursor={cursor}");
            var feed = (await client.GetFromJsonAsync<JsonObject>(url, Ct))!;
            var card = feed["items"]!.AsArray().FirstOrDefault(c => c!["id"]!.GetValue<Guid>() == articleId);
            if (card is not null) return card.AsObject();
            cursor = feed["nextCursor"]?.GetValue<string>();
            if (cursor is null) break;
        }
        throw new InvalidOperationException($"Article {articleId} is not in the For you feed.");
    }

    public static (int Insightful, int Love, int Fire, int MindBlown) Counts(this JsonNode reactions) => (
        reactions["insightful"]!.GetValue<int>(),
        reactions["love"]!.GetValue<int>(),
        reactions["fire"]!.GetValue<int>(),
        reactions["mindBlown"]!.GetValue<int>());
}
