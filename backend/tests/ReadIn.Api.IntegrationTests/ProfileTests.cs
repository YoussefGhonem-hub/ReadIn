using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Reading;
using ReadIn.Infrastructure.Persistence;
using SkiaSharp;

namespace ReadIn.Api.IntegrationTests;

/// <summary>F14 Profile end to end: the public profile, its Articles tab, reading stats privacy and editing it.</summary>
[Collection(ApiCollection.Name)]
public sealed class ProfileTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static Task<HttpResponseMessage> ProfileAsync(HttpClient client, string username, string suffix = "") =>
        client.GetAsync($"/api/v1/users/{username}{suffix}", Ct);

    private static Task<HttpResponseMessage> PatchMeAsync(SignedInUser user, object body) =>
        user.Client.PatchAsJsonAsync("/api/v1/me", body, Ct);

    /// <summary>A PATCH /me body with the required fields; <paramref name="extra"/> adds or overrides properties.</summary>
    private static JsonObject Body(SignedInUser user, object? extra = null)
    {
        var body = new JsonObject { ["displayName"] = user.Me["displayName"]!.GetValue<string>(), ["username"] = Username(user) };
        if (extra is not null)
        {
            foreach (var (key, value) in JsonSerializerNode(extra)) body[key] = value?.DeepClone();
        }
        return body;
    }

    private static JsonObject JsonSerializerNode(object value) =>
        System.Text.Json.JsonSerializer.SerializeToNode(value, new System.Text.Json.JsonSerializerOptions(System.Text.Json.JsonSerializerDefaults.Web))!.AsObject();

    private static async Task<IReadOnlyList<Guid>> FieldIdsAsync(HttpClient client, params string[] slugs)
    {
        var fields = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!;
        return [.. slugs.Select(slug => fields.Single(f => f!["slug"]!.GetValue<string>() == slug)!["id"]!.GetValue<Guid>())];
    }

    private static async Task<JsonObject> UploadAsync(HttpClient client, string purpose, int width, int height)
    {
        using var bitmap = new SKBitmap(width, height);
        using (var canvas = new SKCanvas(bitmap)) canvas.Clear(SKColors.Teal);
        using var png = bitmap.Encode(SKEncodedImageFormat.Png, 100);

        using var form = new MultipartFormDataContent();
        form.Add(new StringContent(purpose), "purpose");
        var file = new ByteArrayContent(png.ToArray());
        file.Headers.ContentType = new MediaTypeHeaderValue("image/png");
        form.Add(file, "file", "avatar.png");
        var response = await client.PostAsync("/api/v1/uploads/images", form, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
    }

    private async Task SetReadCountAsync(Guid articleId, int reads)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        (await db.Articles.Where(a => a.Id == articleId).ExecuteUpdateAsync(set => set.SetProperty(a => a.ReadCount, reads), Ct)).Should().Be(1);
    }

    /// <summary>Earlier reading in the user's own time zone, as if they had completed one article on each of those days.</summary>
    private async Task AddReadDaysAsync(Guid userId, string timeZone, params int[] daysAgo)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var today = ReadingClock.LocalDate(DateTime.UtcNow, timeZone);
        var days = daysAgo.Select(d => ReadingDay.Seeded(userId, today.AddDays(-d), articlesRead: 1, activeSeconds: 300)).ToList();
        db.ReadingDays.AddRange(days);
        var stats = new UserStats(userId);
        stats.Rebuild(Streaks.Compute(days.Select(d => d.Date)), days.Count, days.Count * 300, DateTime.UtcNow);
        db.UserStats.Add(stats);
        await db.SaveChangesAsync(Ct);
    }

    [Fact]
    public async Task A_guest_sees_the_public_profile_without_the_phone_number()
    {
        var writer = await api.UserAsync("Mona Adel");
        var fields = await FieldIdsAsync(writer.Client, "dotnet", "databases");
        (await PatchMeAsync(writer, Body(writer, new
        {
            bio = "Backend engineer · .NET و SQL Server",
            links = new { github = "https://github.com/mona", linkedin = (string?)null, website = "https://example.com/mona" },
            expertiseFieldIds = fields,
        }))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await writer.Client.PublishAsync();

        var response = await ProfileAsync(api.GuestClient(), Username(writer));
        var raw = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.OK, raw);
        var profile = JsonNode.Parse(raw)!.AsObject();

        profile.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "displayName", "username", "avatarUrl", "avatarVariants", "isVerified", "bio", "links", "expertise", "joinedAt",
            "stats", "isMe", "isFollowing", "followsYou", "readingStatsVisible");
        profile["id"]!.GetValue<Guid>().Should().Be(writer.Id);
        profile["displayName"]!.GetValue<string>().Should().Be("Mona Adel");
        profile["bio"]!.GetValue<string>().Should().Be("Backend engineer · .NET و SQL Server");
        profile["links"]!["github"]!.GetValue<string>().Should().Be("https://github.com/mona");
        profile["links"]!["linkedin"].Should().BeNull();
        profile["links"]!["website"]!.GetValue<string>().Should().Be("https://example.com/mona");
        profile["avatarUrl"].Should().BeNull();
        profile["avatarVariants"].Should().BeNull();
        profile["isVerified"]!.GetValue<bool>().Should().BeFalse();
        profile["expertise"]!.AsArray().Select(f => f!["slug"]!.GetValue<string>()).Should().Equal("dotnet", "databases");
        profile["expertise"]![0]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "slug", "name", "icon", "color");
        profile["stats"]!["articles"]!.GetValue<int>().Should().Be(1);
        profile["isMe"]!.GetValue<bool>().Should().BeFalse();
        profile["isFollowing"]!.GetValue<bool>().Should().BeFalse();
        profile["followsYou"]!.GetValue<bool>().Should().BeFalse();
        profile["readingStatsVisible"]!.GetValue<bool>().Should().BeFalse();
        raw.Should().NotContain(writer.PhoneNumber).And.NotContain(writer.PhoneNumber[1..]).And.NotContain("phone");
    }

    [Fact]
    public async Task Usernames_match_ignoring_case_and_a_leading_at()
    {
        var writer = await api.UserAsync();

        var upper = await ProfileAsync(api.GuestClient(), "@" + Username(writer).ToUpperInvariant()).OkJsonAsync();
        var encoded = await ProfileAsync(api.GuestClient(), "%40" + Username(writer)).OkJsonAsync();

        upper["id"]!.GetValue<Guid>().Should().Be(writer.Id);
        encoded["username"]!.GetValue<string>().Should().Be(Username(writer));
        await ProfileAsync(api.GuestClient(), "no_such_user_x").ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await ProfileAsync(api.GuestClient(), "not-a-handle").ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
    }

    [Fact]
    public async Task Is_me_is_following_and_follows_you_are_relative_to_the_viewer()
    {
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();

        var asReader = await ProfileAsync(reader.Client, Username(writer)).OkJsonAsync();
        asReader["isMe"]!.GetValue<bool>().Should().BeFalse();
        asReader["isFollowing"]!.GetValue<bool>().Should().BeTrue();
        asReader["followsYou"]!.GetValue<bool>().Should().BeFalse();

        await writer.Client.PutEmptyAsync($"/api/v1/users/{reader.Id}/follow").OkJsonAsync();
        (await ProfileAsync(reader.Client, Username(writer)).OkJsonAsync())["followsYou"]!.GetValue<bool>().Should().BeTrue();

        var own = await ProfileAsync(writer.Client, Username(writer)).OkJsonAsync();
        own["isMe"]!.GetValue<bool>().Should().BeTrue();
        own["isFollowing"]!.GetValue<bool>().Should().BeFalse("never on your own profile");
        own["followsYou"]!.GetValue<bool>().Should().BeFalse("never on your own profile");
        own["readingStatsVisible"]!.GetValue<bool>().Should().BeTrue("your own stats are always visible to you");

        var asGuest = await ProfileAsync(api.GuestClient(), Username(writer)).OkJsonAsync();
        asGuest["isFollowing"]!.GetValue<bool>().Should().BeFalse();
        asGuest["followsYou"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Stats_count_published_articles_follows_and_total_reads()
    {
        var writer = await api.UserAsync();
        var first = await writer.Client.PublishAsync();
        var second = await writer.Client.PublishAsync();
        await SetReadCountAsync(first.Id, 7);
        await SetReadCountAsync(second.Id, 5);
        await writer.Client.CreateDraftAsync(ArticleTestKit.Document(
            await writer.Client.FieldIdAsync("dotnet"), "A draft that doesn't count", blocks: [ArticleTestKit.Paragraph("Not yet.")]));

        var alice = await api.UserAsync();
        var bob = await api.UserAsync();
        await alice.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        await bob.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        await writer.Client.PutEmptyAsync($"/api/v1/users/{alice.Id}/follow").OkJsonAsync();

        var stats = (await ProfileAsync(api.GuestClient(), Username(writer)).OkJsonAsync())["stats"]!;

        stats["articles"]!.GetValue<int>().Should().Be(2, "drafts are not counted");
        stats["followers"]!.GetValue<int>().Should().Be(2);
        stats["following"]!.GetValue<int>().Should().Be(1);
        stats["totalReads"]!.GetValue<int>().Should().Be(12);
    }

    [Fact]
    public async Task The_articles_tab_lists_published_cards_newest_first_with_the_viewer_state()
    {
        var writer = await api.UserAsync();
        var older = await writer.Client.PublishAsync();
        var newer = await writer.Client.PublishAsync();
        var reader = await api.UserAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/saved/{older.Id}").OkJsonAsync();

        var page = await ProfileAsync(reader.Client, Username(writer), "/articles?limit=1").OkJsonAsync();
        page["items"]!.AsArray().Should().ContainSingle().Which!["id"]!.GetValue<Guid>().Should().Be(newer.Id);
        var cursor = page["nextCursor"]!.GetValue<string>();

        var rest = await ProfileAsync(reader.Client, Username(writer), $"/articles?limit=1&cursor={cursor}").OkJsonAsync();
        var card = rest["items"]!.AsArray().Should().ContainSingle().Which!;
        card["id"]!.GetValue<Guid>().Should().Be(older.Id);
        card["isSaved"]!.GetValue<bool>().Should().BeTrue();
        card["saveCount"]!.GetValue<int>().Should().Be(1);
        card["author"]!["id"]!.GetValue<Guid>().Should().Be(writer.Id);
        rest["nextCursor"].Should().BeNull();

        var asGuest = await ProfileAsync(api.GuestClient(), Username(writer), "/articles").OkJsonAsync();
        asGuest["items"]!.AsArray().Should().HaveCount(2).And.OnlyContain(c => !c!["isSaved"]!.GetValue<bool>());
    }

    [Fact]
    public async Task Suspended_and_deleted_users_are_not_found()
    {
        foreach (var suffix in new[] { "", "/articles", "/stats", "/stats/heatmap" })
            await ProfileAsync(api.GuestClient(), "suspended", suffix).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");

        var user = await api.UserAsync();
        await ProfileAsync(api.GuestClient(), Username(user)).OkJsonAsync();
        (await user.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
        {
            Content = JsonContent.Create(new { password = ApiFactory.TestPassword }),
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        await ProfileAsync(api.GuestClient(), Username(user)).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await ProfileAsync(api.GuestClient(), Username(user), "/articles").ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
    }

    [Fact]
    public async Task The_official_account_is_shown_normally()
    {
        var official = await ProfileAsync(api.GuestClient(), "readin").OkJsonAsync();

        official["isVerified"]!.GetValue<bool>().Should().BeTrue();
        official["avatarUrl"]!.GetValue<string>().Should().EndWith("_256.webp");
        official["avatarVariants"]!.AsObject().Select(v => v.Key).Should().Equal("64", "128", "256", "512");
        official["stats"]!["articles"]!.GetValue<int>().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task Reading_stats_are_private_until_the_user_makes_them_public()
    {
        var owner = await api.UserAsync();
        await AddReadDaysAsync(owner.Id, "Africa/Cairo", 1, 2, 3);
        var stranger = await api.UserAsync();

        foreach (var client in new[] { api.GuestClient(), stranger.Client })
        {
            await ProfileAsync(client, Username(owner), "/stats").ProblemAsync(HttpStatusCode.Forbidden, "profile.stats_private");
            await ProfileAsync(client, Username(owner), "/stats/heatmap").ProblemAsync(HttpStatusCode.Forbidden, "profile.stats_private");
        }
        (await ProfileAsync(owner.Client, Username(owner), "/stats").OkJsonAsync())["totalArticles"]!.GetValue<int>().Should().Be(3, "always visible to yourself");
        (await owner.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["privacy"]!["publicReadingStats"]!.GetValue<bool>().Should().BeFalse("the default");

        (await owner.Client.PutAsJsonAsync("/api/v1/me/privacy", new { publicReadingStats = true }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await owner.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["privacy"]!["publicReadingStats"]!.GetValue<bool>().Should().BeTrue();
        (await ProfileAsync(api.GuestClient(), Username(owner)).OkJsonAsync())["readingStatsVisible"]!.GetValue<bool>().Should().BeTrue();
        var stats = await ProfileAsync(api.GuestClient(), Username(owner), "/stats").OkJsonAsync();
        stats["totalArticles"]!.GetValue<int>().Should().Be(3);
        stats["streak"]!["current"]!.GetValue<int>().Should().Be(3);
        stats["streak"]!["today"]!.GetValue<string>().Should().Be(ReadingClock.LocalDate(DateTime.UtcNow, "Africa/Cairo").ToString("yyyy-MM-dd"));
        var heatmap = await ProfileAsync(stranger.Client, Username(owner), "/stats/heatmap?days=30").OkJsonAsync();
        heatmap["days"]!.AsArray().Count(d => d!["articles"]!.GetValue<int>() == 1).Should().Be(3);

        (await owner.Client.PutAsJsonAsync("/api/v1/me/privacy", new { publicReadingStats = false }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await ProfileAsync(api.GuestClient(), Username(owner), "/stats").ProblemAsync(HttpStatusCode.Forbidden, "profile.stats_private");
        await owner.Client.PutAsJsonAsync("/api/v1/me/privacy", new { }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        await api.GuestClient().PutAsJsonAsync("/api/v1/me/privacy", new { publicReadingStats = true }, Ct).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
    }

    [Fact]
    public async Task Stats_use_the_profile_owner_time_zone()
    {
        var owner = await api.UserAsync();
        const string farEast = "Pacific/Kiritimati"; // UTC+14: often a different date than the viewer's
        (await owner.Client.PutAsJsonAsync("/api/v1/me/preferences", new
        {
            uiLanguage = "en", articleLanguage = "en", theme = "system", timeZone = farEast, reminderTime = "08:00",
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await owner.Client.PutAsJsonAsync("/api/v1/me/privacy", new { publicReadingStats = true }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var stats = await ProfileAsync(api.GuestClient(), Username(owner), "/stats").OkJsonAsync();
        var heatmap = await ProfileAsync(api.GuestClient(), Username(owner), "/stats/heatmap").OkJsonAsync();

        var ownerToday = ReadingClock.LocalDate(DateTime.UtcNow, farEast).ToString("yyyy-MM-dd");
        stats["streak"]!["today"]!.GetValue<string>().Should().Be(ownerToday);
        heatmap["to"]!.GetValue<string>().Should().Be(ownerToday);
    }

    [Fact]
    public async Task An_avatar_upload_is_stored_as_its_256_variant_with_every_size_on_the_profile()
    {
        var user = await api.UserAsync();
        var upload = await UploadAsync(user.Client, "avatar", 900, 600);
        var assetId = upload["id"]!.GetValue<Guid>();

        (await PatchMeAsync(user, Body(user, new { avatarAssetId = assetId }))).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var me = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!;
        var avatarUrl = me["avatarUrl"]!.GetValue<string>();
        avatarUrl.Should().StartWith(ApiFactory.PublicBaseUrl + "/uploads/avatars/").And.EndWith("_256.webp");
        var profile = await ProfileAsync(api.GuestClient(), Username(user)).OkJsonAsync();
        profile["avatarUrl"]!.GetValue<string>().Should().Be(avatarUrl);
        var variants = profile["avatarVariants"]!.AsObject();
        variants.Select(v => v.Key).Should().Equal("64", "128", "256", "512");
        variants.Select(v => v.Value!.GetValue<string>()).Should().Equal(
            upload["variants"]!.AsArray().Select(v => v!["url"]!.GetValue<string>()));
        variants["256"]!.GetValue<string>().Should().Be(avatarUrl);

        // Saving without avatar fields keeps it; an explicit null removes it.
        (await PatchMeAsync(user, Body(user, new { bio = "Still here" }))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["avatarUrl"]!.GetValue<string>().Should().Be(avatarUrl);
        var remove = Body(user);
        remove["avatarAssetId"] = null;
        (await PatchMeAsync(user, remove)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["avatarUrl"].Should().BeNull();
        (await ProfileAsync(api.GuestClient(), Username(user)).OkJsonAsync())["avatarVariants"].Should().BeNull();
        (await api.GuestClient().GetAsync(new Uri(avatarUrl).AbsolutePath, Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound, "the removed avatar's files are deleted");
    }

    [Fact]
    public async Task A_small_avatar_fills_every_size_without_upscaling()
    {
        var user = await api.UserAsync();
        var upload = await UploadAsync(user.Client, "avatar", 200, 300);

        (await PatchMeAsync(user, Body(user, new { avatarAssetId = upload["id"]!.GetValue<Guid>() }))).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var variants = (await ProfileAsync(api.GuestClient(), Username(user)).OkJsonAsync())["avatarVariants"]!.AsObject();
        variants["64"]!.GetValue<string>().Should().EndWith("_64.webp");
        variants["128"]!.GetValue<string>().Should().EndWith("_128.webp");
        variants["256"]!.GetValue<string>().Should().EndWith("_200.webp");
        variants["512"]!.GetValue<string>().Should().EndWith("_200.webp");
    }

    [Fact]
    public async Task Only_your_own_avatar_uploads_can_become_the_avatar()
    {
        var user = await api.UserAsync();
        var other = await api.UserAsync();
        var foreign = await UploadAsync(other.Client, "avatar", 300, 300);
        var ownCover = await UploadAsync(user.Client, "cover", 1200, 500);

        // Someone else's avatar, your own cover (not an avatar), and an id that doesn't exist.
        foreach (var assetId in new[] { foreign["id"]!.GetValue<Guid>(), ownCover["id"]!.GetValue<Guid>(), Guid.NewGuid() })
        {
            var problem = await PatchMeAsync(user, Body(user, new { avatarAssetId = assetId }))
                .ProblemAsync(HttpStatusCode.BadRequest, "profile.avatar_invalid");
            problem["errors"]!["avatarAssetId"]![0]!.GetValue<string>().Should().Be("profile.avatar_invalid");
        }
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["avatarUrl"].Should().BeNull("nothing was saved");
    }

    [Fact]
    public async Task Expertise_keeps_the_order_and_allows_at_most_five_known_fields()
    {
        var user = await api.UserAsync();
        var fields = await FieldIdsAsync(user.Client, "dotnet", "frontend", "mobile", "databases", "security", "devops-cloud");

        (await PatchMeAsync(user, Body(user, new { expertiseFieldIds = new[] { fields[2], fields[0], fields[1] } }))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await ExpectExpertiseAsync("mobile", "dotnet", "frontend");

        (await PatchMeAsync(user, Body(user, new { expertiseFieldIds = new[] { fields[1], fields[3], fields[2] } }))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await ExpectExpertiseAsync("frontend", "databases", "mobile");

        (await PatchMeAsync(user, Body(user, new { bio = "Omitted expertise is unchanged" }))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await ExpectExpertiseAsync("frontend", "databases", "mobile");

        var six = await PatchMeAsync(user, Body(user, new { expertiseFieldIds = fields })).ProblemAsync(HttpStatusCode.BadRequest, "profile.expertise_invalid");
        six["errors"]!["expertiseFieldIds"]![0]!.GetValue<string>().Should().Be("profile.expertise_invalid");
        await PatchMeAsync(user, Body(user, new { expertiseFieldIds = new[] { fields[0], Guid.NewGuid() } }))
            .ProblemAsync(HttpStatusCode.BadRequest, "profile.expertise_invalid");
        await ExpectExpertiseAsync("frontend", "databases", "mobile");

        (await PatchMeAsync(user, Body(user, new { expertiseFieldIds = Array.Empty<Guid>() }))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await ExpectExpertiseAsync();

        async Task ExpectExpertiseAsync(params string[] slugs) =>
            (await ProfileAsync(api.GuestClient(), Username(user)).OkJsonAsync())["expertise"]!.AsArray()
                .Select(f => f!["slug"]!.GetValue<string>()).Should().Equal(slugs);
    }

    [Fact]
    public async Task Existing_profile_validation_still_applies()
    {
        var user = await api.UserAsync();
        var taken = await api.UserAsync();

        await PatchMeAsync(user, Body(user, new { username = Username(taken) })).ProblemAsync(HttpStatusCode.Conflict, "user.username_taken");
        var invalid = await PatchMeAsync(user, Body(user, new { displayName = "x", bio = new string('b', 301), links = new { github = "http://github.com/x" } }))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        invalid["errors"]!.AsObject().Select(e => e.Key).Should().BeEquivalentTo("displayName", "bio", "links.gitHub");
    }

    [Fact]
    public async Task Demo_writers_have_rich_profiles()
    {
        var reviewer = await ProfileAsync(api.GuestClient(), "reviewer_dotnet").OkJsonAsync();

        reviewer["isVerified"]!.GetValue<bool>().Should().BeTrue();
        reviewer["bio"]!.GetValue<string>().Should().NotBeNullOrWhiteSpace();
        reviewer["links"]!["linkedin"]!.GetValue<string>().Should().StartWith("https://");
        reviewer["expertise"]!.AsArray().Select(f => f!["slug"]!.GetValue<string>()).Should().Equal("dotnet", "software-architecture", "databases");
        reviewer["avatarVariants"]!.AsObject().Select(v => v.Key).Should().Equal("64", "128", "256", "512");
        reviewer["readingStatsVisible"]!.GetValue<bool>().Should().BeTrue("about a third of the demo users have public stats");
        (await ProfileAsync(api.GuestClient(), "reader2").OkJsonAsync())["readingStatsVisible"]!.GetValue<bool>().Should().BeFalse();
        (await ProfileAsync(api.GuestClient(), "reader10").OkJsonAsync())["avatarUrl"].Should().BeNull();
    }

    [Fact]
    public async Task The_openapi_document_describes_the_profile_endpoints()
    {
        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();

        var paths = document["paths"]!.AsObject().Select(p => p.Key).ToList();
        paths.Should().Contain(["/api/v1/users/{username}", "/api/v1/users/{username}/articles", "/api/v1/users/{username}/stats",
            "/api/v1/users/{username}/stats/heatmap", "/api/v1/me/privacy"]);
        var request = document["components"]!["schemas"]!["UpdateProfileRequest"]!["properties"]!.AsObject().Select(p => p.Key);
        request.Should().BeEquivalentTo("displayName", "username", "bio", "links", "avatarAssetId", "avatarUrl", "expertiseFieldIds");
        document["components"]!["schemas"]!["ProfileDto"]!["properties"]!.AsObject().Select(p => p.Key).Should().NotContain("phoneNumber");
    }

    [Fact]
    public async Task The_phone_number_never_appears_in_profile_responses()
    {
        var owner = await api.UserAsync();
        var reader = await api.UserAsync();
        await owner.Client.PublishAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/users/{owner.Id}/follow").OkJsonAsync();
        (await owner.Client.PutAsJsonAsync("/api/v1/me/privacy", new { publicReadingStats = true }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        string[] urls =
        [
            $"/api/v1/users/{Username(owner)}", $"/api/v1/users/{Username(owner)}/articles", $"/api/v1/users/{Username(owner)}/stats",
            $"/api/v1/users/{Username(owner)}/stats/heatmap", $"/api/v1/users/{owner.Id}/followers", $"/api/v1/users/{reader.Id}/following",
        ];
        foreach (var client in new[] { api.GuestClient(), reader.Client, owner.Client })
        {
            foreach (var url in urls)
            {
                var response = await client.GetAsync(url, Ct);
                var body = await response.Content.ReadAsStringAsync(Ct);
                response.StatusCode.Should().Be(HttpStatusCode.OK, $"{url}: {body}");
                foreach (var phone in new[] { owner.PhoneNumber, reader.PhoneNumber })
                    body.Should().NotContain(phone[1..], $"{url} must not leak a phone number (SPEC §9.5)");
                body.Should().NotContain("phoneNumber");
            }
        }
    }
}
