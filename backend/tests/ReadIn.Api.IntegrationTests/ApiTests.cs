using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Feed;
using ReadIn.Infrastructure.Persistence;

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
        article.ContainsKey("reviewedBy").Should().BeFalse("there is no review (ADR 0015)");
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
    public async Task For_you_lists_your_interests_first_then_everything_else_without_repeats_or_gaps()
    {
        string[] interests = ["software-architecture", "devops-cloud", "security"];
        var reader = await api.SignUpAsync();
        var fieldIds = new List<Guid>();
        foreach (var slug in interests) fieldIds.Add(await reader.Client.FieldIdAsync(slug));
        (await reader.Client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds, topicIds = Array.Empty<Guid>() }, Ct))
            .EnsureSuccessStatusCode();

        // One article in the reader's interests, then a newer one outside them. Software architecture: no other test
        // publishes there (Today's tests count on devops-cloud and security staying as they are).
        var writer = (await api.SignUpAsync()).Client;
        var (inside, _) = await writer.PublishAsync(field: "software-architecture");
        var (outside, _) = await writer.PublishAsync(field: "frontend");

        var everything = await ScanForYouAsync(api.GuestClient(), 50);
        var feed = await ScanForYouAsync(reader.Client, 50);

        feed.Select(c => c.Id).Should().OnlyHaveUniqueItems()
            .And.BeEquivalentTo(everything.Select(c => c.Id), "every published article is in For you, once");
        var tiers = feed.Select(c => interests.Contains(c.Field) ? 0 : 1).ToList();
        tiers.Should().Contain(0).And.Contain(1).And.BeInAscendingOrder("the articles in your interests come first");
        // Each group is ranked (ADR 0020, ForYouRankingTests checks the formula): the order the ranking gives at the
        // snapshot the scroll's cursors carry (small pages, so there are cursors).
        var snapshots = new List<DateTime>();
        (await ScanForYouAsync(reader.Client, 2, snapshots)).Select(c => c.Id).Should().Equal(feed.Select(c => c.Id));
        snapshots.Should().NotBeEmpty().And.Subject.Distinct().Should().ContainSingle("every page of one scroll ranks against one snapshot");
        foreach (var tier in new[] { 0, 1 })
        {
            var group = feed.Where((_, i) => tiers[i] == tier).Select(c => c.Id).ToList();
            (await RankedAsync(group, snapshots[0])).Should().Equal(group, "each group is ranked");
        }
        feed.FindIndex(c => c.Id == inside).Should().BeLessThan(feed.FindIndex(c => c.Id == outside));
        everything.FindIndex(c => c.Id == outside).Should().BeLessThan(everything.FindIndex(c => c.Id == inside),
            "for guests, neither has a boost, so the newer one ranks first");

        // Pages that end exactly where the interests end, pages that cross that boundary, and small pages.
        var interesting = tiers.Count(t => t == 0);
        foreach (var limit in new[] { interesting, interesting + 1, 2, 7 }.Where(l => l is >= 1 and <= 50).Distinct())
        {
            (await ScanForYouAsync(reader.Client, limit)).Select(c => c.Id).Should()
                .Equal(feed.Select(c => c.Id), $"pages of {limit} list the same feed");
        }
    }

    [Fact]
    public async Task Field_refs_say_whether_the_field_is_sensitive()
    {
        // Public Health is sensitive (health disclaimer, SPEC F04) and disabled in the fixture: enabled for this test only.
        var fieldId = await SetFieldEnabledAsync("public-health", true);
        try
        {
            var writer = (await api.SignUpAsync()).Client;
            var (id, slug) = await writer.WriteAndPublishAsync(ArticleTestKit.Document(fieldId, "Washing your hands, explained"));
            var guest = api.GuestClient();

            var article = (await guest.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!;
            article["field"]!["isSensitive"]!.GetValue<bool>().Should().BeTrue("the reader shows the health disclaimer");
            var card = (await guest.GetFromJsonAsync<JsonObject>("/api/v1/feed/for-you?field=public-health&limit=50", Ct))!["items"]!
                .AsArray().Single(c => c!["id"]!.GetValue<Guid>() == id)!;
            card["field"]!["isSensitive"]!.GetValue<bool>().Should().BeTrue();
            var mine = (await writer.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=published", Ct))!["items"]!
                .AsArray().Single(a => a!["id"]!.GetValue<Guid>() == id)!;
            mine["field"]!["isSensitive"]!.GetValue<bool>().Should().BeTrue();
        }
        finally
        {
            await SetFieldEnabledAsync("public-health", false);
        }

        var other = (await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/articles/dependency-injection-in-aspnet-core", Ct))!;
        other["field"]!["isSensitive"]!.GetValue<bool>().Should().BeFalse();
        other["topic"]!["isSensitive"]!.GetValue<bool>().Should().BeFalse("a topic carries its field's flag");
    }

    private sealed record FeedCard(Guid Id, string Field, DateTime PublishedAt);

    /// <summary>Pages through For you to the end; <paramref name="snapshots"/> collects each cursor's snapshot time.</summary>
    private static async Task<List<FeedCard>> ScanForYouAsync(HttpClient client, int limit, List<DateTime>? snapshots = null)
    {
        var cards = new List<FeedCard>();
        string? cursor = null;
        do
        {
            var page = (await client.GetFromJsonAsync<JsonObject>(
                $"/api/v1/feed/for-you?limit={limit}" + (cursor is null ? "" : $"&cursor={cursor}"), Ct))!;
            cards.AddRange(page["items"]!.AsArray().Select(c => new FeedCard(
                c!["id"]!.GetValue<Guid>(), c["field"]!["slug"]!.GetValue<string>(), c["publishedAt"]!.GetValue<DateTime>())));
            cursor = page["nextCursor"]?.GetValue<string>();
            if (RankedCursor.Decode(cursor) is { } ranked) snapshots?.Add(ranked.Snapshot);
        }
        while (cursor is not null && cards.Count < 10_000);
        return cards;
    }

    /// <summary><paramref name="ids"/> in the order the For you ranking gives them at <paramref name="snapshot"/>.</summary>
    private async Task<List<Guid>> RankedAsync(IReadOnlyList<Guid> ids, DateTime snapshot)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        return await db.Articles.AsNoTracking().Where(a => ids.Contains(a.Id)).RankedAt(db, snapshot).Best().Select(r => r.Id).ToListAsync(Ct);
    }

    private async Task<Guid> SetFieldEnabledAsync(string slug, bool enabled)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var field = await db.Fields.SingleAsync(f => f.Slug == slug, Ct);
        field.Update(field.NameAr, field.NameEn, field.Icon, field.Color, field.SortOrder, field.IsSensitive, field.RequiresSources, enabled);
        await db.SaveChangesAsync(Ct);
        return field.Id;
    }

    [Fact]
    public async Task Guests_get_a_today_article()
    {
        var response = await api.GuestClient().GetAsync("/api/v1/feed/today", Ct);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Theory]
    [InlineData("ar", "ar-EG", "يعني إيه RAG")]
    [InlineData("en", "en", "What is RAG")]
    public async Task Guest_cards_come_in_the_ui_language(string uiLanguage, string language, string title)
    {
        // Only the fixtures live in ai-fundamentals and on the official account, so what-is-rag is on the first page.
        var client = api.GuestClient(uiLanguage);
        var feed = await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/for-you?field=ai-fundamentals&limit=50", Ct);
        var profile = await client.GetFromJsonAsync<JsonObject>("/api/v1/users/readin/articles?limit=50", Ct);

        foreach (var page in new[] { feed!, profile! })
        {
            var card = page["items"]!.AsArray().Single(c => c!["slug"]!.GetValue<string>() == "what-is-rag")!;
            card["language"]!.GetValue<string>().Should().Be(language);
            card["title"]!.GetValue<string>().Should().StartWith(title);
        }
    }

    [Fact]
    public async Task A_guest_today_card_is_in_egyptian_arabic_when_the_ui_is_arabic_and_a_translation_exists()
    {
        var client = api.GuestClient("ar");
        var card = await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);
        var arabic = await client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{card!["slug"]!.GetValue<string>()}?lang=ar-EG", Ct);

        card["language"]!.GetValue<string>().Should().Be(arabic!["language"]!.GetValue<string>());
    }

    internal static async Task<JsonObject> Problem(HttpResponseMessage response) =>
        (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
}

[Collection(ApiCollection.Name)]
public sealed class AccountTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Profile_links_are_an_ordered_array_with_the_contract_keys()
    {
        var user = await api.SignUpAsync();
        var patch = new HttpRequestMessage(HttpMethod.Patch, "/api/v1/me")
        {
            Content = JsonContent.Create(new
            {
                displayName = "Links Test",
                username = user.Me["username"]!.GetValue<string>(),
                links = new object[]
                {
                    new { platform = "linkedin", url = "https://www.linkedin.com/in/readin" },
                    new { platform = "github", url = "https://github.com/readin" },
                    new { platform = "other", url = "https://readin.app", label = "ReadIn" },
                },
            }),
        };
        (await user.Client.SendAsync(patch, Ct)).EnsureSuccessStatusCode();

        var links = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["links"]!.AsArray();
        links.Select(l => l!.AsObject().Select(p => p.Key)).Should().AllSatisfy(keys => keys.Should().Equal("platform", "url", "label"));
        links.Select(l => l!["platform"]!.GetValue<string>()).Should().Equal("linkedin", "github", "other");
        links[2]!["label"]!.GetValue<string>().Should().Be("ReadIn");
        links[0]!["label"].Should().BeNull();
    }

    [Fact]
    public async Task Me_requires_a_token()
    {
        var response = await api.GuestClient().GetAsync("/api/v1/me", Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>().Should().Be("auth.unauthorized");
    }

    [Fact]
    public async Task Sign_up_complete_profile_onboarding_and_preferences()
    {
        var user = await api.SignUpAsync();
        var client = user.Client;

        user.Me["phoneNumber"]!.GetValue<string>().Should().Be(user.PhoneNumber);
        user.Me["username"]!.GetValue<string>().Should().StartWith("reader_");
        user.Me["isProfileComplete"]!.GetValue<bool>().Should().BeFalse();
        user.Me["hasRecoveryPin"]!.GetValue<bool>().Should().BeTrue();
        user.Me["mustSetRecoveryPin"]!.GetValue<bool>().Should().BeFalse();
        user.Me["mustChangePassword"]!.GetValue<bool>().Should().BeFalse();
        user.Me["roles"]!.AsArray().Select(r => r!.GetValue<string>()).Should().Equal("Member");
        user.Me["permissions"]!.AsArray().Select(p => p!.GetValue<string>()).Should().Contain("articles.create");
        user.Me["onboardingCompleted"]!.GetValue<bool>().Should().BeFalse();

        var username = $"onboarding_{Guid.NewGuid():N}"[..20];
        var check = await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/users/username-available?u={username}", Ct);
        check!["available"]!.GetValue<bool>().Should().BeTrue();
        var taken = await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/users/username-available?u=reader_dotnet_nope!", Ct);
        taken!["valid"]!.GetValue<bool>().Should().BeFalse();

        var completed = await client.PutAsJsonAsync("/api/v1/me/profile/complete", new { displayName = "Onboarding User", username }, Ct);
        completed.StatusCode.Should().Be(HttpStatusCode.OK);
        var profile = await completed.Content.ReadFromJsonAsync<JsonObject>(Ct);
        profile!["isProfileComplete"]!.GetValue<bool>().Should().BeTrue();
        profile["username"]!.GetValue<string>().Should().Be(username);
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/users/username-available?u={username}", Ct))!["available"]!
            .GetValue<bool>().Should().BeFalse();

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
    public async Task Suspended_users_cannot_sign_in()
    {
        var response = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/login",
            new { phoneNumber = ApiFactory.SuspendedPhone, password = ApiFactory.DemoPassword }, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>().Should().Be("user.suspended");
    }

    [Fact]
    public async Task The_seeded_dotnet_writer_is_a_verified_member_with_no_review_permissions()
    {
        var me = await (await api.SeedUserClientAsync(ApiFactory.ReviewerPhone)).GetFromJsonAsync<JsonObject>("/api/v1/me", Ct);

        me!["roles"]!.AsArray().Select(r => r!.GetValue<string>()).Should().Equal(["Member"], "Verified is a badge, not a role (SPEC §10.1)");
        me["displayName"]!.GetValue<string>().Should().Be(".NET Writer");
        var permissions = me["permissions"]!.AsArray().Select(p => p!.GetValue<string>()).ToList();
        permissions.Should().Contain("articles.create");
        permissions.Should().NotContain(["articles.review", "articles.publish.sensitive"], "there is no review (ADR 0015)");
        me["isVerified"]!.GetValue<bool>().Should().BeTrue();
        me["isProfileComplete"]!.GetValue<bool>().Should().BeTrue();
        me["hasRecoveryPin"]!.GetValue<bool>().Should().BeTrue();
    }
}

[Collection(ApiCollection.Name)]
public sealed class WritingTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Guests_cannot_write()
    {
        var response = await api.GuestClient().PostAsJsonAsync("/api/v1/articles", new { }, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Member_creates_and_publishes_an_article()
    {
        var client = (await api.SignUpAsync()).Client;
        var dotnet = await client.FieldIdAsync("dotnet");

        var draft = await client.CreateDraftAsync(ArticleTestKit.Document(dotnet, "Records in C# without sources",
            blocks: [ArticleTestKit.Paragraph("Records are great.")], sources: []));
        var draftId = draft["id"]!.GetValue<Guid>();
        draft.ProblemCodes().Should().Equal("article.sources_required");
        var publishWithoutSources = await client.PublishDraftAsync(draftId, draft["version"]!.GetValue<int>());
        publishWithoutSources.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await TaxonomyAndContentTests.Problem(publishWithoutSources))["code"]!.GetValue<string>().Should().Be("article.sources_required");

        var created = await client.CreateDraftAsync(ArticleTestKit.Document(dotnet, "Records in C#: value equality made easy",
            blocks: [ArticleTestKit.Paragraph("Records give you value equality. ‮")],
            tags: ["C#", "c#", "Records"],
            sources: [new { title = "Records — Microsoft Learn", url = "https://learn.microsoft.com/dotnet/csharp/fundamentals/types/records" }]));
        var published = await client.PublishDraftAsync(created["id"]!.GetValue<Guid>(), created["version"]!.GetValue<int>());
        (await published.PublishedSlugAsync()).Should().Be("records-in-csharp-value-equality-made-easy");

        var article = await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/articles/records-in-csharp-value-equality-made-easy", Ct);
        article!["tags"]!.AsArray().Select(t => t!["name"]!.GetValue<string>()).Should().BeEquivalentTo("C#", "Records");
        article.ContainsKey("isReviewed").Should().BeFalse("there is no review (ADR 0015)");
        article["content"]!["blocks"]![0]!["content"]![0]!["text"]!.GetValue<string>().Should().NotContain("‮");
    }

    [Fact]
    public async Task Others_cannot_see_or_publish_my_article()
    {
        var author = (await api.SignUpAsync()).Client;
        var other = (await api.SignUpAsync()).Client;
        var field = (await author.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))![0]!["id"]!.GetValue<Guid>();
        var draft = await author.CreateDraftAsync(ArticleTestKit.Document(field, "Ownership matters here", blocks: [ArticleTestKit.Paragraph("Mine.")]));
        var id = draft["id"]!.GetValue<Guid>();

        var response = await other.PublishDraftAsync(id, draft["version"]!.GetValue<int>());

        response.StatusCode.Should().Be(HttpStatusCode.NotFound, "someone else's draft does not exist for you");
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>().Should().Be("article.not_found");
        (await other.GetAsync($"/api/v1/articles/{id}/edit", Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Invalid_rdoc_is_saved_as_a_draft_but_never_published()
    {
        var client = (await api.SignUpAsync()).Client;
        var field = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))![0]!["id"]!.GetValue<Guid>();
        var document = ArticleTestKit.Document(field, "Raw HTML is never allowed");
        document["translations"]![0]!["content"] = JsonNode.Parse(
            """{ "version": 1, "language": "en", "blocks": [{ "id": "p1", "type": "paragraph", "content": [{ "type": "text", "text": "Fine." }] }, { "id": "x", "type": "html", "html": "<script>alert(1)</script>" }] }""");

        var draft = await client.CreateDraftAsync(document);

        var problem = draft["checks"]!["problems"]!.AsArray().Should().ContainSingle().Which!;
        problem["code"]!.GetValue<string>().Should().Be("article.content_invalid");
        problem["blockId"]!.GetValue<string>().Should().Be("x", "the client can point at the block the schema rejected");
        var publish = await client.PublishDraftAsync(draft["id"]!.GetValue<Guid>(), draft["version"]!.GetValue<int>());
        publish.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var body = await TaxonomyAndContentTests.Problem(publish);
        body["code"]!.GetValue<string>().Should().Be("article.content_invalid");
        body["problems"]!.AsArray().Should().ContainSingle();
    }
}
