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
        var created = await author.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = await author.FieldIdAsync(field), language, title,
            content = new
            {
                version = 1, language,
                blocks = new object[] { new { id = "p1", type = "paragraph", dir = "auto", content = new[] { new { type = "text", text = "Reactions, saves and follows." } } } },
            },
            sources = new[] { new { title = "ReadIn", url = "https://readin.app" } },
            isAiAssisted = false,
        }, Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created, await created.Content.ReadAsStringAsync(Ct));
        var body = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
        var id = body["id"]!.GetValue<Guid>();
        (await author.PostAsync($"/api/v1/articles/{id}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        return (id, body["slug"]!.GetValue<string>());
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
