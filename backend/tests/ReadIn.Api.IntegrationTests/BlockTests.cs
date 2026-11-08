using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F36 Block against SQL Server: the routes and their rules, follows ending both ways, direct links (403 with an Unblock for
/// the blocker, a plain not-found for the blocked person), writes, every list both ways, comments and mentions,
/// notifications, Undo, the moderators' exemption and account deletion.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class BlockTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static Task<HttpResponseMessage> BlockAsync(HttpClient client, Guid userId) => client.PutAsync($"/api/v1/users/{userId}/block", null, Ct);

    private static Task<HttpResponseMessage> UnblockAsync(HttpClient client, Guid userId, bool restoreFollow = false) =>
        client.DeleteAsync($"/api/v1/users/{userId}/block" + (restoreFollow ? "?restoreFollow=true" : ""), Ct);

    private static Task<HttpResponseMessage> FollowAsync(HttpClient client, Guid userId) => client.PutAsync($"/api/v1/users/{userId}/follow", null, Ct);

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static async Task<JsonObject> CreatedAsync(Task<HttpResponseMessage> request)
    {
        var response = await request;
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    [Fact]
    public async Task Blocking_needs_a_session_never_targets_yourself_and_is_idempotent()
    {
        var a = await api.UserAsync("Blocker");
        var b = await api.UserAsync("Blocked");
        (await api.GuestClient().PutAsync($"/api/v1/users/{b.Id}/block", null, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await api.GuestClient().GetAsync("/api/v1/me/blocked", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        await BlockAsync(a.Client, a.Id).ProblemAsync(HttpStatusCode.BadRequest, "block.self");
        await BlockAsync(a.Client, Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await UnblockAsync(a.Client, Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");

        var first = await BlockAsync(a.Client, b.Id).OkJsonAsync();
        first.Select(p => p.Key).Should().BeEquivalentTo("userId", "isBlocked", "followRemoved");
        (first["isBlocked"]!.GetValue<bool>(), first["followRemoved"]!.GetValue<bool>()).Should().Be((true, false));
        await BlockAsync(a.Client, b.Id).OkJsonAsync();
        (await api.InDbAsync(db => db.UserBlocks.CountAsync(x => x.BlockerId == a.Id, Ct))).Should().Be(1);

        var list = await a.Client.GetAsync("/api/v1/me/blocked", Ct).OkJsonAsync();
        var item = list["items"]!.AsArray().Single()!;
        item["user"]!["id"]!.GetValue<Guid>().Should().Be(b.Id);
        item["user"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "displayName", "username", "avatarUrl", "isVerified");
        item["blockedAt"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(5));
        (await b.Client.GetAsync("/api/v1/me/blocked", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty("the blocked person isn't told");

        (await UnblockAsync(a.Client, b.Id).OkJsonAsync())["isBlocked"]!.GetValue<bool>().Should().BeFalse();
        await UnblockAsync(a.Client, b.Id).OkJsonAsync();
        (await a.Client.GetAsync("/api/v1/me/blocked", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty();
    }

    [Fact]
    public async Task At_most_1000_blocks()
    {
        var a = await api.UserAsync("Many Blocks");
        var target = await api.UserAsync("One Too Many");
        await api.InDbAsync(async db =>
        {
            var now = DateTime.UtcNow;
            var people = Enumerable.Range(0, UserBlock.MaxPerUser)
                .Select(i => User.CreateSeeded(null, $"Filler {i}", $"bf_{Guid.NewGuid():N}"[..20]))
                .ToList();
            db.Users.AddRange(people);
            await db.SaveChangesAsync(Ct);
            db.UserBlocks.AddRange(people.Select(p => new UserBlock(a.Id, p.Id, now)));
            await db.SaveChangesAsync(Ct);
        });

        await BlockAsync(a.Client, target.Id).ProblemAsync(HttpStatusCode.BadRequest, "block.limit");
    }

    [Fact]
    public async Task A_block_ends_the_follows_both_ways_and_neither_can_follow_again_with_the_blocked_person_never_told()
    {
        var a = await api.UserAsync("Follows Blocker");
        var b = await api.UserAsync("Follows Blocked");
        (await FollowAsync(a.Client, b.Id)).EnsureSuccessStatusCode();
        (await FollowAsync(b.Client, a.Id)).EnsureSuccessStatusCode();

        var state = await BlockAsync(a.Client, b.Id).OkJsonAsync();
        state["followRemoved"]!.GetValue<bool>().Should().BeTrue();
        (await api.InDbAsync(db => db.UserFollows.CountAsync(f => (f.FollowerId == a.Id && f.FolloweeId == b.Id) || (f.FollowerId == b.Id && f.FolloweeId == a.Id), Ct)))
            .Should().Be(0);

        var problem = await FollowAsync(a.Client, b.Id).ProblemAsync(HttpStatusCode.Forbidden, "block.blocked");
        problem["blockedUser"]!["id"]!.GetValue<Guid>().Should().Be(b.Id);
        problem["blockedUser"]!["username"]!.GetValue<string>().Should().Be(Username(b));
        await FollowAsync(b.Client, a.Id).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");

        // Undo restores only the blocker's own follow; theirs never comes back.
        (await UnblockAsync(a.Client, b.Id, restoreFollow: true)).EnsureSuccessStatusCode();
        (await api.InDbAsync(db => db.UserFollows.AnyAsync(f => f.FollowerId == a.Id && f.FolloweeId == b.Id, Ct))).Should().BeTrue();
        (await api.InDbAsync(db => db.UserFollows.AnyAsync(f => f.FollowerId == b.Id && f.FolloweeId == a.Id, Ct))).Should().BeFalse();
    }

    [Fact]
    public async Task Direct_links_answer_403_to_the_blocker_and_404_to_the_blocked_person_and_moderators_still_open_them()
    {
        var a = await api.UserAsync("Links Blocker");
        var b = await api.UserAsync("Links Blocked");
        var (aArticle, aSlug) = await a.Client.PublishAsync();
        var (bArticle, bSlug) = await b.Client.PublishAsync();
        var bComment = (await CreatedAsync(b.Client.PostAsJsonAsync($"/api/v1/articles/{bArticle}/comments", new { body = "B's own comment" }, Ct)))["id"]!
            .GetValue<Guid>();
        (await BlockAsync(a.Client, b.Id)).EnsureSuccessStatusCode();

        foreach (var url in new[]
                 {
                     $"/api/v1/users/{Username(b)}", $"/api/v1/users/{Username(b)}/articles", $"/api/v1/users/{Username(b)}/reposts",
                     $"/api/v1/articles/{bSlug}", $"/api/v1/articles/{bArticle}/comments", $"/api/v1/articles/{bArticle}/related",
                     $"/api/v1/articles/{bArticle}/preview", $"/api/v1/comments/{bComment}", $"/api/v1/articles/{bArticle}/reactions",
                 })
        {
            var problem = await a.Client.GetAsync(url, Ct).ProblemAsync(HttpStatusCode.Forbidden, "block.blocked");
            problem["blockedUser"]!["id"]!.GetValue<Guid>().Should().Be(b.Id, url);
        }

        await b.Client.GetAsync($"/api/v1/users/{Username(a)}", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await b.Client.GetAsync($"/api/v1/users/{Username(a)}/articles", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await b.Client.GetAsync($"/api/v1/articles/{aSlug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await b.Client.GetAsync($"/api/v1/articles/{aArticle}/comments", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // Guests see everything; a moderator who blocked someone still opens their content (a case always opens).
        (await api.GuestClient().GetAsync($"/api/v1/articles/{bSlug}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        var moderator = await api.UserWithPermissionsAsync("Blocking Moderator", Permissions.Articles.Read, Permissions.Moderation.Manage,
            Permissions.Blocks.Manage);
        (await BlockAsync(moderator.Client, b.Id)).EnsureSuccessStatusCode();
        (await moderator.Client.GetAsync($"/api/v1/articles/{bSlug}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await moderator.Client.GetAsync($"/api/v1/users/{Username(b)}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        // Unblocking opens everything again.
        (await UnblockAsync(a.Client, b.Id)).EnsureSuccessStatusCode();
        (await a.Client.GetAsync($"/api/v1/articles/{bSlug}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await b.Client.GetAsync($"/api/v1/users/{Username(a)}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Neither_reacts_saves_highlights_or_likes_on_the_others_content()
    {
        var a = await api.UserAsync("Writes Blocker");
        var b = await api.UserAsync("Writes Blocked");
        var (aArticle, _) = await a.Client.PublishAsync();
        var (bArticle, _) = await b.Client.PublishAsync();
        var aComment = (await CreatedAsync(a.Client.PostAsJsonAsync($"/api/v1/articles/{aArticle}/comments", new { body = "A writes here" }, Ct)))["id"]!
            .GetValue<Guid>();
        (await BlockAsync(a.Client, b.Id)).EnsureSuccessStatusCode();

        await a.Client.ReactAsync(bArticle, "love").ProblemAsync(HttpStatusCode.Forbidden, "block.blocked");
        await b.Client.ReactAsync(aArticle, "love").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await a.Client.PutAsync($"/api/v1/me/saved/{bArticle}", null, Ct).ProblemAsync(HttpStatusCode.Forbidden, "block.blocked");
        await b.Client.PutAsync($"/api/v1/me/saved/{aArticle}", null, Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await b.Client.PutAsync($"/api/v1/comments/{aComment}/like", null, Ct).ProblemAsync(HttpStatusCode.NotFound, "comment.not_found");
        await b.Client.PostAsJsonAsync($"/api/v1/articles/{aArticle}/highlights",
                new { language = "en", blockId = "p1", startOffset = 0, endOffset = 5, text = "Hello" }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task Lists_leave_each_other_out_both_ways()
    {
        var tag = $"Blk{Guid.NewGuid():N}"[..12];
        var a = await api.UserAsync($"{tag} Alpha");
        var b = await api.UserAsync($"{tag} Bravo");
        var c = await api.UserAsync($"{tag} Charlie");
        var (bArticle, _) = await b.Client.PublishAsync();
        var (aArticle, _) = await a.Client.PublishAsync();
        (await a.Client.PutAsync($"/api/v1/me/saved/{bArticle}", null, Ct)).EnsureSuccessStatusCode();
        // Both follow C, so each would be in C's followers list.
        (await FollowAsync(a.Client, c.Id)).EnsureSuccessStatusCode();
        (await FollowAsync(b.Client, c.Id)).EnsureSuccessStatusCode();
        (await a.Client.ReactAsync(aArticle, "love")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await b.Client.ReactAsync(aArticle, "fire")).StatusCode.Should().Be(HttpStatusCode.OK);

        (await BlockAsync(a.Client, b.Id)).EnsureSuccessStatusCode();

        // People search, both ways.
        static List<Guid> Ids(JsonObject page) => [.. page["items"]!.AsArray().Select(i => i!["id"]!.GetValue<Guid>())];
        Ids(await a.Client.GetAsync($"/api/v1/search?q={tag}&type=users", Ct).OkJsonAsync()).Should().Contain(c.Id).And.NotContain(b.Id);
        Ids(await b.Client.GetAsync($"/api/v1/search?q={tag}&type=users", Ct).OkJsonAsync()).Should().Contain(c.Id).And.NotContain(a.Id);
        Ids(await c.Client.GetAsync($"/api/v1/search?q={tag}&type=users", Ct).OkJsonAsync()).Should().Contain([a.Id, b.Id]);

        // Followers of C, and who reacted to A's article.
        Ids(await a.Client.GetAsync($"/api/v1/users/{c.Id}/followers", Ct).OkJsonAsync()).Should().Contain(a.Id).And.NotContain(b.Id);
        Ids(await b.Client.GetAsync($"/api/v1/users/{c.Id}/followers", Ct).OkJsonAsync()).Should().Contain(b.Id).And.NotContain(a.Id);
        var reactors = (await a.Client.GetAsync($"/api/v1/articles/{aArticle}/reactions", Ct).OkJsonAsync())["items"]!.AsArray()
            .Select(i => i!["user"]!["id"]!.GetValue<Guid>());
        reactors.Should().Contain(a.Id).And.NotContain(b.Id);

        // For you, both ways (the article is on the first pages of everyone else's feed).
        await AbsentFromForYouAsync(a.Client, bArticle);
        await AbsentFromForYouAsync(b.Client, aArticle);
        await c.Client.FindInForYouAsync(bArticle);

        // A's saved list keeps the save but doesn't show it.
        var saved = (await a.Client.GetAsync("/api/v1/me/saved", Ct).OkJsonAsync())["items"]!.AsArray();
        saved.Select(s => s!["article"]!["id"]!.GetValue<Guid>()).Should().NotContain(bArticle);
        (await api.InDbAsync(db => db.SavedArticles.AnyAsync(s => s.UserId == a.Id && s.ArticleId == bArticle, Ct))).Should().BeTrue();

        // Mention suggestions.
        var suggestions = (await a.Client.GetFromJsonAsync<JsonArray>($"/api/v1/users/mention-suggestions?q={Username(b)}", Ct))!;
        suggestions.Should().BeEmpty();
    }

    [Fact]
    public async Task Comments_of_a_blocked_person_leave_the_thread_or_stay_as_a_placeholder_and_mentions_lose_their_link()
    {
        var a = await api.UserAsync("Thread Reader");
        var b = await api.UserAsync("Thread Blocked");
        var c = await api.UserAsync("Thread Writer");
        var (article, slug) = await c.Client.PublishAsync();
        var lone = (await CreatedAsync(b.Client.PostAsJsonAsync($"/api/v1/articles/{article}/comments", new { body = "B alone" }, Ct)))["id"]!
            .GetValue<Guid>();
        var parent = (await CreatedAsync(b.Client.PostAsJsonAsync($"/api/v1/articles/{article}/comments", new { body = "B with a reply" }, Ct)))["id"]!
            .GetValue<Guid>();
        (await c.Client.PostAsJsonAsync($"/api/v1/comments/{parent}/replies", new { body = "C answers B" }, Ct)).EnsureSuccessStatusCode();
        (await c.Client.PostAsJsonAsync($"/api/v1/articles/{article}/comments", new { body = $"Thanks @{Username(b)}" }, Ct)).EnsureSuccessStatusCode();

        (await BlockAsync(a.Client, b.Id)).EnsureSuccessStatusCode();

        var items = (await a.Client.GetAsync($"/api/v1/articles/{article}/comments?sort=new", Ct).OkJsonAsync())["items"]!.AsArray();
        items.Select(i => i!["id"]!.GetValue<Guid>()).Should().NotContain(lone);
        var placeholder = items.Single(i => i!["id"]!.GetValue<Guid>() == parent)!;
        (placeholder["isUnavailable"]!.GetValue<bool>(), placeholder["body"], placeholder["author"]).Should().Be((true, null, null));
        placeholder["replies"]!.AsArray().Should().ContainSingle().Which!["body"]!.GetValue<string>().Should().Be("C answers B");
        var thanks = items.Single(i => i!["body"]?.GetValue<string>()?.StartsWith("Thanks") == true)!;
        thanks["mentions"]!.AsArray().Should().BeEmpty("a mention of someone you are blocked with is plain text");

        // C still sees everything, and the mention keeps its link for C.
        var forC = (await c.Client.GetAsync($"/api/v1/articles/{article}/comments?sort=new", Ct).OkJsonAsync())["items"]!.AsArray();
        forC.Select(i => i!["id"]!.GetValue<Guid>()).Should().Contain([lone, parent]);
        forC.Single(i => i!["body"]?.GetValue<string>()?.StartsWith("Thanks") == true)!["mentions"]!.AsArray().Should().ContainSingle();

        // The article itself stays readable for A (C wrote it) and has no flag for B.
        (await a.Client.GetAsync($"/api/v1/articles/{slug}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task An_article_shows_mentions_of_a_blocked_person_as_plain_text()
    {
        var a = await api.UserAsync("Mention Reader");
        var b = await api.UserAsync("Mention Blocked");
        var c = await api.UserAsync("Mention Writer");
        var fieldId = await c.Client.FieldIdAsync("dotnet");
        var document = ArticleTestKit.Document(fieldId, $"Mentions {Guid.NewGuid():N}", blocks:
        [
            ArticleTestKit.Inline("p1", ArticleTestKit.Text("Thanks to "), ArticleTestKit.Mention(b.Id, "@" + Username(b))),
        ]);
        var (_, slug) = await c.Client.WriteAndPublishAsync(document);
        (await BlockAsync(b.Client, a.Id)).EnsureSuccessStatusCode();

        var forA = await a.Client.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
        forA["unlinkedMentionIds"]!.AsArray().Select(i => i!.GetValue<Guid>()).Should().Equal(b.Id);
        var forC = await c.Client.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
        forC["unlinkedMentionIds"]!.AsArray().Should().BeEmpty();
    }

    [Fact]
    public async Task Blocking_removes_what_each_wrote_in_the_others_notifications_and_writes_no_more()
    {
        var a = await api.UserAsync("Notified Blocker");
        var b = await api.UserAsync("Notifying Blocked");
        var (aArticle, _) = await a.Client.PublishAsync();
        (await b.Client.PostAsJsonAsync($"/api/v1/articles/{aArticle}/comments", new { body = "Before the block" }, Ct)).EnsureSuccessStatusCode();
        (await FollowAsync(b.Client, a.Id)).EnsureSuccessStatusCode();
        (await api.InDbAsync(db => db.Notifications.CountAsync(n => n.UserId == a.Id && n.Actors.Any(x => x.ActorId == b.Id), Ct))).Should().BeGreaterThan(0);

        (await BlockAsync(a.Client, b.Id)).EnsureSuccessStatusCode();
        (await api.InDbAsync(db => db.NotificationActors.CountAsync(x => x.ActorId == b.Id && db.Notifications.Any(n => n.Id == x.NotificationId && n.UserId == a.Id), Ct)))
            .Should().Be(0);
        (await api.InDbAsync(db => db.Notifications.CountAsync(n => n.UserId == a.Id && n.Type == "new_follower", Ct))).Should().Be(0);

        // A third person's article: B's mention of A there is plain text and tells A nothing.
        var c = await api.UserAsync("Notified Third");
        var (cArticle, _) = await c.Client.PublishAsync();
        (await b.Client.PostAsJsonAsync($"/api/v1/articles/{cArticle}/comments", new { body = $"Hey @{Username(a)}" }, Ct)).EnsureSuccessStatusCode();
        (await api.InDbAsync(db => db.Notifications.CountAsync(n => n.UserId == a.Id && n.Type == "mention", Ct))).Should().Be(0);
    }

    [Fact]
    public async Task Deleting_either_account_deletes_the_block()
    {
        var a = await api.UserAsync("Deletes Later");
        var b = await api.UserAsync("Blocks First");
        (await BlockAsync(b.Client, a.Id)).EnsureSuccessStatusCode();
        (await a.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { password = ApiFactory.TestPassword }) }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await api.InDbAsync(db => db.UserBlocks.CountAsync(x => x.BlockedId == a.Id || x.BlockerId == a.Id, Ct))).Should().Be(0);
    }

    private static async Task AbsentFromForYouAsync(HttpClient client, Guid articleId)
    {
        string? cursor = null;
        for (var page = 0; page < 10; page++)
        {
            var feed = (await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/for-you?limit=50" + (cursor is null ? "" : $"&cursor={cursor}"), Ct))!;
            feed["items"]!.AsArray().Select(i => i!["id"]!.GetValue<Guid>()).Should().NotContain(articleId);
            cursor = feed["nextCursor"]?.GetValue<string>();
            if (cursor is null) break;
        }
    }
}
