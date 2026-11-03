using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace ReadIn.Api.IntegrationTests;

[Collection(ApiCollection.Name)]
public sealed class TaxonomyAndContentTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Fields_are_seeded_from_taxonomy_and_localized()
    {
        var ar = await api.GuestClient("ar").GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct);
        var en = await api.GuestClient("en").GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct);

        ar!.Count.Should().Be(12, "the 12 software fields are enabled; medicine/engineering/public-health are not yet");
        ar.Select(f => f!["slug"]!.GetValue<string>()).Should().NotContain("medicine");
        ar[0]!["name"]!.GetValue<string>().Should().Be("أساسيات الـ AI");
        en![0]!["name"]!.GetValue<string>().Should().Be("AI Fundamentals");
    }

    [Fact]
    public async Task Topics_of_unknown_field_is_404_with_code()
    {
        var response = await api.GuestClient().GetAsync("/api/v1/fields/nope/topics", Ct);

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await Problem(response))["code"]!.GetValue<string>().Should().Be("field.not_found");
    }

    [Fact]
    public async Task Article_is_served_in_the_requested_language_with_trust_data()
    {
        var article = await api.GuestClient("ar").GetFromJsonAsync<JsonObject>(
            "/api/v1/articles/dependency-injection-in-aspnet-core?lang=ar-EG", Ct);

        article!["language"]!.GetValue<string>().Should().Be("ar-EG");
        article["title"]!.GetValue<string>().Should().StartWith("يعني إيه Dependency Injection");
        article["content"]!["language"]!.GetValue<string>().Should().Be("ar-EG");
        article["availableLanguages"]!.AsArray().Select(l => l!.GetValue<string>()).Should().BeEquivalentTo("en", "ar-EG");
        article["isReviewed"]!.GetValue<bool>().Should().BeTrue();
        article["reviewedBy"]!["username"]!.GetValue<string>().Should().Be("reviewer_dotnet");
        article["isAiAssisted"]!.GetValue<bool>().Should().BeTrue();
        article["versionBadge"]!.GetValue<string>().Should().Be(".NET 10");
        article["sources"]!.AsArray().Should().HaveCount(3);
        article["author"]!["isVerified"]!.GetValue<bool>().Should().BeTrue();
        article["publishedAt"]!.GetValue<string>().Should().EndWith("Z");
    }

    [Fact]
    public async Task Missing_translation_falls_back_to_the_source_language()
    {
        var article = await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/articles/what-is-rag", Ct);

        article!["language"]!.GetValue<string>().Should().Be("en");
    }

    [Fact]
    public async Task Unknown_article_is_404_with_localized_title()
    {
        var response = await api.GuestClient("ar").GetAsync("/api/v1/articles/does-not-exist", Ct);
        var problem = await Problem(response);

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        problem["code"]!.GetValue<string>().Should().Be("article.not_found");
        problem["title"]!.GetValue<string>().Should().Be("المقال مش موجود.");
        problem["traceId"].Should().NotBeNull();
    }

    [Fact]
    public async Task Guest_feed_pages_with_a_cursor()
    {
        var client = api.GuestClient();
        var first = await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/for-you?limit=1", Ct);
        var cursor = first!["nextCursor"]!.GetValue<string>();
        var second = await client.GetFromJsonAsync<JsonObject>($"/api/v1/feed/for-you?limit=1&cursor={cursor}", Ct);

        var slugs = new[] { first, second! }.Select(p => p["items"]![0]!["slug"]!.GetValue<string>()).ToList();
        slugs.Should().OnlyHaveUniqueItems().And.HaveCount(2);
    }

    [Fact]
    public async Task Guests_get_a_today_article()
    {
        var response = await api.GuestClient().GetAsync("/api/v1/feed/today", Ct);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    internal static async Task<JsonObject> Problem(HttpResponseMessage response) =>
        (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
}

[Collection(ApiCollection.Name)]
public sealed class AccountTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Me_requires_a_token()
    {
        var response = await api.GuestClient().GetAsync("/api/v1/me", Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>().Should().Be("auth.unauthorized");
    }

    [Fact]
    public async Task Tokens_for_another_firebase_project_are_rejected()
    {
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization = new("Bearer", ApiFactory.Token("x", "x@readin.test", projectId: "someone-elses-project"));

        (await client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Sign_in_sync_onboarding_and_preferences()
    {
        var client = api.ClientFor("it-onboarding", "onboarding.user@readin.test");

        var beforeSync = await client.GetAsync("/api/v1/me", Ct);
        beforeSync.StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await TaxonomyAndContentTests.Problem(beforeSync))["code"]!.GetValue<string>().Should().Be("user.not_synced");

        var me = await (await client.PostAsJsonAsync("/api/v1/auth/sync", new { uiLanguage = "en", timeZone = "Africa/Cairo" }, Ct))
            .Content.ReadFromJsonAsync<JsonObject>(Ct);
        me!["username"]!.GetValue<string>().Should().Be("onboarding_user");
        me["roles"]!.AsArray().Select(r => r!.GetValue<string>()).Should().Equal("Member");
        me["permissions"]!.AsArray().Select(p => p!.GetValue<string>()).Should().Contain("articles.create");
        me["onboardingCompleted"]!.GetValue<bool>().Should().BeFalse();

        var fields = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!.Select(f => f!["id"]!.GetValue<Guid>()).ToList();

        var tooFew = await client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = fields.Take(2), topicIds = Array.Empty<Guid>() }, Ct);
        tooFew.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await TaxonomyAndContentTests.Problem(tooFew))["errors"]!["interests"]![0]!.GetValue<string>().Should().Be("user.interests.min_three");

        (await client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = fields.Take(3), topicIds = Array.Empty<Guid>() }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = fields.Skip(1).Take(3), topicIds = Array.Empty<Guid>() }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent, "replacing interests must not hit concurrency errors");

        (await client.PutAsJsonAsync("/api/v1/me/preferences",
                new { uiLanguage = "ar", articleLanguage = "ar-EG", theme = "dark", timeZone = "Africa/Cairo", reminderTime = "07:30" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        var after = await client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct);
        after!["onboardingCompleted"]!.GetValue<bool>().Should().BeTrue();
        after["theme"]!.GetValue<string>().Should().Be("dark");
        after["reminderTime"]!.GetValue<string>().Should().Be("07:30");
        after["interests"]!["fieldIds"]!.AsArray().Should().HaveCount(3);

        var today = await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);
        today!["language"]!.GetValue<string>().Should().Be("ar-EG", "the pick is served in the preferred article language");
        var again = await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);
        again!["id"]!.GetValue<Guid>().Should().Be(today["id"]!.GetValue<Guid>(), "the daily pick is stable for the day");
    }

    [Fact]
    public async Task Suspended_users_get_403()
    {
        var client = api.ClientFor("demo-suspended", "suspended@readin.test");

        var response = await client.GetAsync("/api/v1/me", Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>().Should().Be("user.suspended");
    }

    [Fact]
    public async Task Seeded_reviewer_has_reviewer_permissions()
    {
        var me = await api.ClientFor("demo-reviewer-dotnet", "reviewer.dotnet@readin.test").GetFromJsonAsync<JsonObject>("/api/v1/me", Ct);

        me!["roles"]!.AsArray().Select(r => r!.GetValue<string>()).Should().BeEquivalentTo("Member", "VerifiedWriter", "Reviewer");
        me["permissions"]!.AsArray().Select(p => p!.GetValue<string>()).Should().Contain(["articles.review", "articles.publish.sensitive"]);
        me["isVerified"]!.GetValue<bool>().Should().BeTrue();
    }
}

[Collection(ApiCollection.Name)]
public sealed class WritingTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static object Content(string text) => new
    {
        version = 1,
        language = "en",
        blocks = new object[]
        {
            new { id = "p1", type = "paragraph", content = new[] { new { type = "text", text } } },
            new { id = "c1", type = "callout", variant = "tip", content = new[] { new { type = "text", text = "A tip." } } },
        },
    };

    [Fact]
    public async Task Guests_cannot_write()
    {
        var response = await api.GuestClient().PostAsJsonAsync("/api/v1/articles", new { }, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Member_creates_and_publishes_an_article()
    {
        var client = api.ClientFor("it-writer", "it.writer@readin.test");
        await client.PostAsJsonAsync("/api/v1/auth/sync", new { }, Ct);
        var dotnet = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Single(f => f!["slug"]!.GetValue<string>() == "dotnet")!["id"]!.GetValue<Guid>();

        var noSources = await client.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = dotnet, language = "en", title = "Records in C# without sources",
            content = Content("Records are great."), isAiAssisted = false,
        }, Ct);
        var draftId = (await noSources.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
        var publishWithoutSources = await client.PostAsync($"/api/v1/articles/{draftId}/publish", null, Ct);
        publishWithoutSources.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await TaxonomyAndContentTests.Problem(publishWithoutSources))["code"]!.GetValue<string>().Should().Be("article.sources_required");

        var created = await client.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = dotnet, language = "en", title = "Records in C#: value equality made easy",
            content = Content("Records give you value equality. ‮"),
            tags = new[] { "C#", "c#", "Records" },
            sources = new[] { new { title = "Records — Microsoft Learn", url = "https://learn.microsoft.com/dotnet/csharp/fundamentals/types/records" } },
            isAiAssisted = false,
        }, Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created);
        var id = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();

        (await client.PostAsync($"/api/v1/articles/{id}/publish", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var article = await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/articles/records-in-csharp-value-equality-made-easy", Ct);
        article!["tags"]!.AsArray().Select(t => t!.GetValue<string>()).Should().BeEquivalentTo("C#", "Records");
        article["isReviewed"]!.GetValue<bool>().Should().BeFalse("published without review shows no Reviewed badge");
        article["content"]!["blocks"]![0]!["content"]![0]!["text"]!.GetValue<string>().Should().NotContain("‮");
    }

    [Fact]
    public async Task Others_cannot_publish_my_article()
    {
        var author = api.ClientFor("it-author-2", "author.two@readin.test");
        var other = api.ClientFor("it-other", "other.user@readin.test");
        await author.PostAsJsonAsync("/api/v1/auth/sync", new { }, Ct);
        await other.PostAsJsonAsync("/api/v1/auth/sync", new { }, Ct);
        var field = (await author.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))![0]!["id"]!.GetValue<Guid>();

        var created = await author.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = field, language = "en", title = "Ownership matters here", content = Content("Mine."), isAiAssisted = false,
            sources = new[] { new { title = "Source", url = "https://example.com/source" } },
        }, Ct);
        var id = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();

        var response = await other.PostAsync($"/api/v1/articles/{id}/publish", null, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>().Should().Be("article.not_owner");
    }

    [Fact]
    public async Task Invalid_rdoc_is_rejected_with_details()
    {
        var client = api.ClientFor("it-writer-3", "writer.three.it@readin.test");
        await client.PostAsJsonAsync("/api/v1/auth/sync", new { }, Ct);
        var field = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))![0]!["id"]!.GetValue<Guid>();

        var response = await client.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = field, language = "en", title = "Raw HTML is never allowed",
            content = JsonSerializer.Deserialize<JsonElement>("""{ "version": 1, "language": "en", "blocks": [{ "id": "x", "type": "html", "html": "<script>alert(1)</script>" }] }"""),
            isAiAssisted = false,
        }, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var problem = await TaxonomyAndContentTests.Problem(response);
        problem["code"]!.GetValue<string>().Should().Be("article.content_invalid");
        problem["errors"]!.AsObject().Should().NotBeEmpty();
    }
}
