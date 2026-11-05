using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Identity;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The title (headline) and the social links of a profile end to end (SPEC F14, pre-production step): PATCH /me and the
/// complete-profile step, where the title shows (cards, reader, comments, lists, profile), cache invalidation, and the
/// SuperAdmin's clear_links / clear_headline from the user's case.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ProfileTitleAndLinksTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static Task<HttpResponseMessage> PatchMeAsync(SignedInUser user, object extra)
    {
        var body = new JsonObject { ["displayName"] = user.Me["displayName"]!.GetValue<string>(), ["username"] = Username(user) };
        foreach (var (key, value) in JsonSerializerHelper.ToObject(extra)) body[key] = value?.DeepClone();
        return user.Client.PatchAsJsonAsync("/api/v1/me", body, Ct);
    }

    private static async Task PatchOkAsync(SignedInUser user, object extra)
    {
        var response = await PatchMeAsync(user, extra);
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));
    }

    private static async Task<JsonObject> MeAsync(SignedInUser user) => (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!;

    private static string[] Codes(JsonObject problem, string key) =>
        [.. problem["errors"]![key]!.AsArray().Select(c => c!.GetValue<string>())];

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> work)
    {
        using var scope = api.Services.CreateScope();
        return await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    [Fact]
    public async Task The_title_is_kept_when_omitted_and_cleared_by_null_or_blank()
    {
        var user = await api.UserAsync("Titled Writer");

        await PatchOkAsync(user, new { headline = "  مهندس برمجيات | .NET  " });
        (await MeAsync(user))["headline"]!.GetValue<string>().Should().Be("مهندس برمجيات | .NET", "trimmed, mixed text kept as written");

        await PatchOkAsync(user, new { bio = "No title change" });
        (await MeAsync(user))["headline"]!.GetValue<string>().Should().Be("مهندس برمجيات | .NET", "omitted keeps it");

        await PatchOkAsync(user, new { headline = "   " });
        (await MeAsync(user))["headline"].Should().BeNull("blank clears it");

        await PatchOkAsync(user, new { headline = "Back again" });
        await PatchOkAsync(user, new JsonObject { ["headline"] = null });
        (await MeAsync(user))["headline"].Should().BeNull("null clears it");
    }

    [Fact]
    public async Task The_title_has_one_line_of_at_most_120_characters()
    {
        var user = await api.UserAsync();

        await PatchOkAsync(user, new { headline = new string('a', 120) });
        Codes(await PatchMeAsync(user, new { headline = new string('a', 121) }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "headline")
            .Should().Equal("profile.headline_too_long");
        Codes(await PatchMeAsync(user, new { headline = "two\nlines" }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "headline")
            .Should().Equal("profile.headline_invalid");
        Codes(await PatchMeAsync(user, new { headline = "abc" + (char)0x202E + "def" }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"),
            "headline").Should().Equal("profile.headline_invalid");
        (await MeAsync(user))["headline"]!.GetValue<string>().Should().Be(new string('a', 120), "a refused change keeps the title");
    }

    [Fact]
    public async Task Completing_the_profile_takes_an_optional_title()
    {
        var withTitle = await api.SignUpAsync();
        var username = $"t_{Guid.NewGuid():N}"[..20];
        var me = await withTitle.Client.PutAsJsonAsync("/api/v1/me/profile/complete",
            new { displayName = "New Writer", username, headline = "Data Engineer" }, Ct).OkJsonAsync();
        me["headline"]!.GetValue<string>().Should().Be("Data Engineer");
        me["links"]!.AsArray().Should().BeEmpty();

        // Again without a title keeps it; a too-long one is refused like in PATCH /me.
        (await withTitle.Client.PutAsJsonAsync("/api/v1/me/profile/complete", new { displayName = "New Writer", username }, Ct).OkJsonAsync())
            ["headline"]!.GetValue<string>().Should().Be("Data Engineer");
        Codes(await withTitle.Client.PutAsJsonAsync("/api/v1/me/profile/complete",
                new { displayName = "New Writer", username, headline = new string('x', 121) }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "headline").Should().Equal("profile.headline_too_long");

        var without = await api.SignUpAsync();
        (await without.Client.PutAsJsonAsync("/api/v1/me/profile/complete",
                new { displayName = "Untitled", username = $"t_{Guid.NewGuid():N}"[..20] }, Ct).OkJsonAsync())
            ["headline"].Should().BeNull();
    }

    [Fact]
    public async Task Links_replace_the_whole_list_in_order_and_are_kept_when_omitted()
    {
        var user = await api.UserAsync();

        await PatchOkAsync(user, new
        {
            links = new object[]
            {
                new { platform = "x", url = "x.com/mona" },
                new { platform = "other", url = "https://kaggle.com/mona", label = " Kaggle " },
                new { platform = "github", url = "https://github.com/mona" },
                new { platform = "other", url = "https://dev.to/mona", label = "DEV" },
            },
        });
        var links = (await MeAsync(user))["links"]!.AsArray();
        links.ToJsonString().Should().Be(
            """[{"platform":"x","url":"https://x.com/mona","label":null},{"platform":"other","url":"https://kaggle.com/mona","label":"Kaggle"},{"platform":"github","url":"https://github.com/mona","label":null},{"platform":"other","url":"https://dev.to/mona","label":"DEV"}]""");

        await PatchOkAsync(user, new { bio = "links omitted" });
        (await MeAsync(user))["links"]!.AsArray().Should().HaveCount(4, "omitted keeps them");
        await PatchOkAsync(user, new JsonObject { ["links"] = null });
        (await MeAsync(user))["links"]!.AsArray().Should().HaveCount(4, "null keeps them too");

        await PatchOkAsync(user, new { links = new object[] { new { platform = "website", url = "https://mona.dev" } } });
        (await MeAsync(user))["links"]!.AsArray().Select(l => l!["platform"]!.GetValue<string>()).Should().Equal("website");

        await PatchOkAsync(user, new { links = Array.Empty<object>() });
        (await MeAsync(user))["links"]!.AsArray().Should().BeEmpty("[] clears them");

        // Guests see them on the profile.
        await PatchOkAsync(user, new { links = new object[] { new { platform = "linkedin", url = "https://www.linkedin.com/in/mona" } } });
        (await api.GuestClient().GetAsync($"/api/v1/users/{Username(user)}", Ct).OkJsonAsync())["links"]!.AsArray()
            .Single()!["platform"]!.GetValue<string>().Should().Be("linkedin");
    }

    [Fact]
    public async Task Every_bad_link_is_reported_under_its_own_index_and_nothing_changes()
    {
        var user = await api.UserAsync();
        await PatchOkAsync(user, new { links = new object[] { new { platform = "github", url = "https://github.com/keep" } } });

        var problem = await PatchMeAsync(user, new
        {
            links = new object[]
            {
                new { platform = "instagram", url = "https://facebook.com/mona" },
                new { platform = "x", url = "http://x.com/mona" },
                new { platform = "github", url = "https://github.com/a", label = "Code" },
                new { platform = "other", url = "https://a.com" },
                new { platform = "x", url = "https://twitter.com/again" },
                new { platform = "myspace", url = "https://myspace.com/mona" },
                new { platform = "website", url = "https://user:pass@mona.dev" },
                new { platform = "website", url = "https://" + new string('a', 495) + ".com" },
            },
        }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");

        Codes(problem, "links[0].url").Should().Equal("link.host_mismatch");
        Codes(problem, "links[1].url").Should().Equal("link.https_required");
        Codes(problem, "links[2].label").Should().Equal("link.label_not_allowed");
        Codes(problem, "links[3].label").Should().Equal("link.label_required");
        Codes(problem, "links[4].platform").Should().Equal("link.duplicate_platform");
        Codes(problem, "links[5].platform").Should().Equal("link.platform_invalid");
        Codes(problem, "links[6].url").Should().Equal("link.url_invalid");
        Codes(problem, "links[7].platform").Should().Equal(["link.duplicate_platform"], "website is one link too; only other repeats");
        Codes(problem, "links[7].url").Should().Equal("link.too_long");
        problem["errors"]!.AsObject().Select(e => e.Key).Should().HaveCount(9);

        var nine = Enumerable.Range(0, 9).Select(i => new { platform = "other", url = $"https://site{i}.com", label = $"Site {i}" }).ToArray();
        Codes(await PatchMeAsync(user, new { links = nine }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "links")
            .Should().Equal("link.too_many");

        (await MeAsync(user))["links"]!.AsArray().Single()!["url"]!.GetValue<string>().Should().Be("https://github.com/keep");
    }

    [Fact]
    public async Task The_title_shows_on_cards_the_reader_comments_lists_and_the_profile()
    {
        var writer = await api.UserAsync("Shown Writer");
        await PatchOkAsync(writer, new { headline = "Senior Full Stack .NET Engineer | .NET | Angular" });
        var (articleId, slug) = await writer.Client.PublishAsync("Where the title shows");
        var reader = await api.UserAsync("Following Reader");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        (await writer.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "From the writer" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Created);
        const string Title = "Senior Full Stack .NET Engineer | .NET | Angular";
        var guest = api.GuestClient();

        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["author"]!["headline"]!.GetValue<string>().Should().Be(Title);
        (await guest.GetAsync($"/api/v1/users/{Username(writer)}/articles", Ct).OkJsonAsync())["items"]![0]!["author"]!["headline"]!
            .GetValue<string>().Should().Be(Title);
        (await reader.Client.GetAsync("/api/v1/feed/following", Ct).OkJsonAsync())["items"]!.AsArray()
            .Single(c => c!["id"]!.GetValue<Guid>() == articleId)!["author"]!["headline"]!.GetValue<string>().Should().Be(Title);
        (await guest.GetAsync($"/api/v1/articles/{articleId}/comments", Ct).OkJsonAsync())["items"]![0]!["author"]!["headline"]!
            .GetValue<string>().Should().Be(Title);
        (await guest.GetAsync($"/api/v1/users/{reader.Id}/following", Ct).OkJsonAsync())["items"]![0]!["headline"]!
            .GetValue<string>().Should().Be(Title);
        (await guest.GetAsync($"/api/v1/users/{Username(writer)}", Ct).OkJsonAsync())["headline"]!.GetValue<string>().Should().Be(Title);

        // No title: null everywhere (the clients hide the line).
        (await guest.GetAsync($"/api/v1/users/{writer.Id}/followers", Ct).OkJsonAsync())["items"]![0]!["headline"].Should().BeNull();
    }

    [Fact]
    public async Task Changing_the_title_or_name_shows_at_once_on_cached_reader_pages()
    {
        var writer = await api.UserAsync("Cached Writer");
        await PatchOkAsync(writer, new { headline = "First title" });
        var (_, slug) = await writer.Client.PublishAsync("Cached title");
        var guest = api.GuestClient();
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["author"]!["headline"]!.GetValue<string>().Should().Be("First title");

        await PatchOkAsync(writer, new { headline = "Second title" });
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["author"]!["headline"]!.GetValue<string>()
            .Should().Be("Second title", "the writer's cached pages are dropped (SPEC F14: always the current title)");

        var renamed = new JsonObject { ["displayName"] = "Renamed Writer", ["username"] = Username(writer) };
        (await writer.Client.PatchAsJsonAsync("/api/v1/me", renamed, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["author"]!["displayName"]!.GetValue<string>().Should().Be("Renamed Writer");
    }

    [Fact]
    public async Task A_superadmin_clears_links_and_title_from_the_users_case_audited()
    {
        var writer = await api.UserAsync("Abusive Profile");
        await PatchOkAsync(writer, new
        {
            headline = "Buy followers here",
            links = new object[]
            {
                new { platform = "website", url = "https://spam.example" },
                new { platform = "other", url = "https://more-spam.example", label = "Deals" },
            },
        });
        var (_, slug) = await writer.Client.PublishAsync("Abusive profile article");
        var guest = api.GuestClient();
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["author"]!["headline"]!.GetValue<string>().Should().Be("Buy followers here");
        var reporter = await api.UserAsync();
        (await reporter.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "user", targetId = writer.Id, reason = "spam" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var admin = (await api.SuperAdminAsync()).Client;

        // The case shows both.
        var userCase = await admin.GetAsync($"/api/v1/moderation/reports/user/{writer.Id}", Ct).OkJsonAsync();
        userCase["item"]!["target"]!["author"]!["headline"]!.GetValue<string>().Should().Be("Buy followers here");
        userCase["item"]!["target"]!["links"]!.AsArray().Select(l => l!["url"]!.GetValue<string>())
            .Should().Equal("https://spam.example", "https://more-spam.example");

        // A member can't.
        await reporter.Client.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "clear_links", targetType = "user", targetId = writer.Id }, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await admin.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "clear_links", targetType = "article", targetId = writer.Id }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.action_invalid");

        (await admin.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "clear_links", targetType = "user", targetId = writer.Id, note = "Spam links." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/users/{Username(writer)}", Ct).OkJsonAsync())["links"]!.AsArray().Should().BeEmpty();
        (await guest.GetAsync($"/api/v1/users/{Username(writer)}", Ct).OkJsonAsync())["headline"]!.GetValue<string>()
            .Should().Be("Buy followers here", "clear_links leaves the title");

        (await admin.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "clear_headline", targetType = "user", targetId = writer.Id }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["author"]!["headline"].Should().BeNull("the cached reader page is dropped");
        (await MeAsync(writer))["headline"].Should().BeNull();

        // Logged with what was removed, the report resolved by the first, and audited.
        var log = (await admin.GetAsync($"/api/v1/moderation/actions?targetUserId={writer.Id}", Ct).OkJsonAsync())["items"]!.AsArray();
        log.Select(e => e!["action"]!.GetValue<string>()).Should().Equal("user.clear_headline", "user.clear_links");
        log[1]!["targetLabel"]!.GetValue<string>().Should().Be("https://spam.example https://more-spam.example");
        log[1]!["note"]!.GetValue<string>().Should().Be("Spam links.");
        log[1]!["reportsClosed"]!.GetValue<int>().Should().Be(1);
        log[0]!["targetLabel"]!.GetValue<string>().Should().Be("Buy followers here");
        log[0]!["reportsClosed"]!.GetValue<int>().Should().Be(0);
        (await admin.GetAsync($"/api/v1/moderation/reports/user/{writer.Id}", Ct).OkJsonAsync())["item"]!["status"]!.GetValue<string>()
            .Should().Be("resolved");
        (await InDbAsync(db => db.AuditLogs.CountAsync(l => l.UserId == writer.Id
                && (l.Action == AuditActions.LinksCleared || l.Action == AuditActions.HeadlineCleared), Ct)))
            .Should().Be(2);

        // Nothing left to clear: 204, nothing logged.
        (await admin.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "clear_links", targetType = "user", targetId = writer.Id }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await admin.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "clear_headline", targetType = "user", targetId = writer.Id }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await admin.GetAsync($"/api/v1/moderation/actions?targetUserId={writer.Id}", Ct).OkJsonAsync())["items"]!.AsArray().Should().HaveCount(2);
    }

    [Fact]
    public async Task Links_and_the_title_go_with_the_account()
    {
        var user = await api.UserAsync();
        await PatchOkAsync(user, new { headline = "Gone soon", links = new object[] { new { platform = "github", url = "https://github.com/gone" } } });

        (await user.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
            { Content = JsonContent.Create(new { password = ApiFactory.TestPassword }) }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await InDbAsync(db => db.Users.IgnoreQueryFilters().AnyAsync(u => u.Id == user.Id, Ct))).Should().BeFalse();
    }
}
