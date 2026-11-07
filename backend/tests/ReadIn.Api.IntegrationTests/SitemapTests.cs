using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;

namespace ReadIn.Api.IntegrationTests;

/// <summary>SPEC §23: GET /sitemap lists what a guest can open, the data behind the web's /sitemap.xml.</summary>
[Collection(ApiCollection.Name)]
public sealed class SitemapTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task The_sitemap_lists_only_what_a_guest_can_open_with_one_entry_per_language_version()
    {
        var writer = await api.UserAsync("Sitemap Writer");
        var moderator = (await api.SuperAdminAsync("Sitemap Moderator")).Client;
        // A field no other test publishes in or pages through: articles here can't push another test's article off the
        // first page of a field feed (MediaTests reads the first 50 of dotnet's For you).
        var field = await writer.Client.FieldIdAsync("history-culture");
        var u = $"zs{Guid.NewGuid():N}"[..10];

        var (english, englishSlug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"English {u}", tags: [$"seen {u}"]));
        var (_, arabicSlug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"مقال {u}", language: "ar-EG"));
        var (hidden, hiddenSlug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Hidden {u}", tags: [$"gone {u}"]));

        var created = await writer.Client.PostAsJsonAsync("/api/v1/me/categories", new { name = $"Cat {u}" }, Ct);
        var createdBody = await created.Content.ReadAsStringAsync(Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created, createdBody);
        var category = JsonNode.Parse(createdBody)!;
        (await writer.Client.PutAsJsonAsync($"/api/v1/articles/{english}/category", new { categoryId = category["id"]!.GetValue<Guid>() }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        // Hiding clears the cached sitemap with the feed, so the category set above shows too.
        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "article", targetId = hidden, note = "Test." }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        var sitemap = await api.GuestClient().GetAsync("/api/v1/sitemap", Ct).OkJsonAsync();

        var articles = sitemap["articles"]!.AsArray()
            .Select(a => (Slug: a!["slug"]!.GetValue<string>(), Language: a["language"]!.GetValue<string>()))
            .ToList();
        articles.Should().Contain((englishSlug, "en")).And.Contain((arabicSlug, "ar-EG"));
        articles.Where(a => a.Slug == englishSlug).Should().ContainSingle("one entry per language version");
        articles.Select(a => a.Slug).Should().NotContain(hiddenSlug, "a hidden article is a 404 for guests");
        sitemap["articles"]!.AsArray().Should().AllSatisfy(a => a!["lastModified"]!.GetValue<DateTime>().Should().BeAfter(DateTime.MinValue));

        var username = writer.Me["username"]!.GetValue<string>();
        Strings(sitemap, "writers", "username").Should().Contain(username)
            .And.NotContain((await moderator.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["username"]!.GetValue<string>(),
                "a profile without articles isn't listed");

        sitemap["categories"]!.AsArray()
            .Select(c => (c!["username"]!.GetValue<string>(), c["slug"]!.GetValue<string>()))
            .Should().Contain((username, category["slug"]!.GetValue<string>()));

        Strings(sitemap, "tags", "slug").Should().Contain($"seen-{u}").And.NotContain($"gone-{u}", "its only article is hidden");
        Strings(sitemap, "fields", "slug").Should().Contain("history-culture").And.Contain("dotnet");
    }

    private static IEnumerable<string> Strings(JsonObject sitemap, string list, string property) =>
        sitemap[list]!.AsArray().Select(item => item![property]!.GetValue<string>());
}
