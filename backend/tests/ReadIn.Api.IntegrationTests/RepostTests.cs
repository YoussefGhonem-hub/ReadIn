using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Api.Errors;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F29 Repost end to end (SPEC F29, contract "Reposts"): the toggle, the caption ("repost with your thoughts") and
/// <c>GET</c> of your repost, the Following feed with its labels and a stable cursor, the profile's Reposts tab, the
/// <c>article_reposted</c> notification, the live counter, mutes, account deletion and the counters rebuild.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class RepostTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static Task<JsonObject> RepostAsync(SignedInUser user, Guid articleId) =>
        user.Client.PutEmptyAsync($"/api/v1/articles/{articleId}/repost").OkJsonAsync();

    private static Task<JsonObject> UndoAsync(SignedInUser user, Guid articleId) =>
        user.Client.DeleteAsync($"/api/v1/articles/{articleId}/repost", Ct).OkJsonAsync();

    /// <summary>PUT with a JSON body, e.g. <c>new { caption = "..." }</c>.</summary>
    private static Task<HttpResponseMessage> PutRepostAsync(SignedInUser user, Guid articleId, object body) =>
        user.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/repost", body, Ct);

    private static Task<JsonObject> RepostWithAsync(SignedInUser user, Guid articleId, object body) =>
        PutRepostAsync(user, articleId, body).OkJsonAsync();

    private static Task<JsonObject> StateAsync(SignedInUser user, Guid articleId) =>
        user.Client.GetAsync($"/api/v1/articles/{articleId}/repost", Ct).OkJsonAsync();

    private static string? Caption(JsonNode? holder) => holder!["caption"]?.GetValue<string>();

    private static async Task<List<JsonObject>> FollowingAsync(SignedInUser user, int limit = 50)
    {
        var items = new List<JsonObject>();
        string? cursor = null;
        do
        {
            var page = await user.Client.GetAsync($"/api/v1/feed/following?limit={limit}&cursor={Uri.EscapeDataString(cursor ?? "")}", Ct).OkJsonAsync();
            items.AddRange(page["items"]!.AsArray().Select(i => i!.AsObject()));
            cursor = page["nextCursor"]?.GetValue<string>();
        } while (cursor is not null);
        return items;
    }

    private static Guid Id(JsonNode card) => card["id"]!.GetValue<Guid>();

    private static Task FollowAsync(SignedInUser follower, SignedInUser writer) =>
        follower.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> work)
    {
        using var scope = api.Services.CreateScope();
        return await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    private static async Task<JsonArray> NotificationsAsync(SignedInUser user) =>
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications?limit=50", Ct))!["items"]!.AsArray();

    [Fact]
    public async Task A_repost_toggles_idempotently_and_its_count_reaches_cards_details_and_live()
    {
        var author = await api.UserAsync("Reposted Author");
        var (articleId, slug) = await author.Client.PublishAsync("Repost me");
        var reader = await api.UserAsync("Reposter");
        var second = await api.UserAsync("Second Reposter");

        var state = await RepostAsync(reader, articleId);
        state.ToJsonString().Should().Be("""{"repostCount":1,"isReposted":true,"caption":null}""");
        (await RepostAsync(reader, articleId)).ToJsonString().Should().Be("""{"repostCount":1,"isReposted":true,"caption":null}""", "a second repost changes nothing");
        (await RepostAsync(second, articleId))["repostCount"]!.GetValue<int>().Should().Be(2);

        var details = await reader.Client.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
        (details["repostCount"]!.GetValue<int>(), details["isReposted"]!.GetValue<bool>()).Should().Be((2, true));
        details["repostedBy"].Should().BeNull("the reader never carries a repost label");
        var guestDetails = await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
        (guestDetails["repostCount"]!.GetValue<int>(), guestDetails["isReposted"]!.GetValue<bool>()).Should().Be((2, false));
        var card = (await author.Client.GetAsync($"/api/v1/users/{Username(author)}/articles", Ct).OkJsonAsync())["items"]![0]!;
        (card["repostCount"]!.GetValue<int>(), card["isReposted"]!.GetValue<bool>()).Should().Be((2, false));
        card["repostedBy"].Should().BeNull();

        (await UndoAsync(reader, articleId)).ToJsonString().Should().Be("""{"repostCount":1,"isReposted":false,"caption":null}""");
        (await UndoAsync(reader, articleId)).ToJsonString().Should().Be("""{"repostCount":1,"isReposted":false,"caption":null}""", "undo is idempotent");

        (await InDbAsync(db => db.Articles.Where(a => a.Id == articleId).Select(a => a.RepostCount).SingleAsync(Ct))).Should().Be(1);
        var live = api.Realtime.CountersFor(articleId);
        live.Select(c => c.RepostCount).Should().Equal([1, 2, 1], "each committed change republishes the recounted total");
    }

    [Fact]
    public async Task Own_articles_guests_and_articles_readers_cant_open_are_refused()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();

        await author.Client.PutEmptyAsync($"/api/v1/articles/{articleId}/repost").ProblemAsync(HttpStatusCode.BadRequest, "repost.own_article");
        (await UndoAsync(author, articleId))["isReposted"]!.GetValue<bool>().Should().BeFalse("undo on your own article just answers the state");
        (await api.GuestClient().PutAsync($"/api/v1/articles/{articleId}/repost", null, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await api.GuestClient().DeleteAsync($"/api/v1/articles/{articleId}/repost", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await reader.Client.PutEmptyAsync($"/api/v1/articles/{Guid.NewGuid()}/repost").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // A draft can't be reposted.
        var draft = (await author.Client.CreateDraftAsync(ArticleTestKit.Document(await author.Client.FieldIdAsync("dotnet"), "Draft only")))["id"]!.GetValue<Guid>();
        await reader.Client.PutEmptyAsync($"/api/v1/articles/{draft}/repost").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // Hidden by a moderator: not found for readers.
        await RepostAsync(reader, articleId);
        var admin = (await api.SuperAdminAsync()).Client;
        (await admin.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "article", targetId = articleId, note = "Spam" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        await reader.Client.PutEmptyAsync($"/api/v1/articles/{articleId}/repost").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await (await api.UserAsync()).Client.PutEmptyAsync($"/api/v1/articles/{articleId}/repost").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // Deleted by its author: not found.
        var (deleted, _) = await author.Client.PublishAsync();
        (await author.Client.DeleteAsync($"/api/v1/articles/{deleted}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await reader.Client.PutEmptyAsync($"/api/v1/articles/{deleted}/repost").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task Members_hold_the_repost_permission()
    {
        var member = await api.UserAsync();
        (await member.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["permissions"]!.AsArray()
            .Select(p => p!.GetValue<string>()).Should().Contain("reposts.create");
    }

    [Fact]
    public async Task The_following_feed_places_each_article_once_at_its_newest_followed_repost_labeled()
    {
        var viewer = await api.UserAsync("Feed Viewer");
        var followedAuthor = await api.UserAsync("Followed Author");
        var reposter = await api.UserAsync("Followed Reposter");
        var secondReposter = await api.UserAsync("Second Followed Reposter");
        var stranger = await api.UserAsync("Unfollowed Author");
        var unfollowedReposter = await api.UserAsync("Unfollowed Reposter");
        await FollowAsync(viewer, followedAuthor);
        await FollowAsync(viewer, reposter);
        await FollowAsync(viewer, secondReposter);

        var (strangers, _) = await stranger.Client.PublishAsync("Stranger's article");
        var (followedOld, _) = await followedAuthor.Client.PublishAsync("Followed author, reposted later");
        var (unrelated, _) = await stranger.Client.PublishAsync("Reposted only by someone you don't follow");
        await RepostAsync(reposter, strangers);
        await RepostAsync(unfollowedReposter, unrelated);
        await RepostAsync(unfollowedReposter, followedOld);
        await RepostAsync(reposter, followedOld);
        var (followedNew, _) = await followedAuthor.Client.PublishAsync("Followed author, not reposted");
        await RepostAsync(secondReposter, strangers);

        var feed = await FollowingAsync(viewer);
        feed.Select(Id).Should().Equal([strangers, followedNew, followedOld], "each once, at the later of publish and the newest followed repost");

        var top = feed[0]["repostedBy"]!;
        top["user"]!["id"]!.GetValue<Guid>().Should().Be(secondReposter.Id, "the newest followed reposter is named");
        top["user"]!["displayName"]!.GetValue<string>().Should().Be("Second Followed Reposter");
        top["user"]!["username"]!.GetValue<string>().Should().Be(Username(secondReposter));
        top["othersCount"]!.GetValue<int>().Should().Be(1, "the other writer you follow who reposted it; unfollowed ones don't count");
        top["repostedAt"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
        top.AsObject().Select(p => p.Key).Should().Equal("user", "othersCount", "repostedAt", "caption");
        top["caption"].Should().BeNull("reposted without thoughts");

        feed[1]["repostedBy"].Should().BeNull("the followed author's own post, placed by its publish");
        var moved = feed[2]["repostedBy"]!;
        moved["user"]!["id"]!.GetValue<Guid>().Should().Be(reposter.Id, "a followed repost after the publish moves it up, labeled");
        moved["othersCount"]!.GetValue<int>().Should().Be(0);

        // Undoing the repost takes it back to its publish time, unlabeled.
        await UndoAsync(reposter, followedOld);
        var after = await FollowingAsync(viewer);
        after.Select(Id).Should().Equal([strangers, followedNew, followedOld]);
        after[2]["repostedBy"].Should().BeNull();
        await UndoAsync(secondReposter, strangers);
        await UndoAsync(reposter, strangers);
        (await FollowingAsync(viewer)).Select(Id).Should().NotContain(strangers, "no followed writer reposts it any more");
    }

    [Fact]
    public async Task Paging_the_following_feed_never_repeats_or_skips_an_item()
    {
        var viewer = await api.UserAsync();
        var writer = await api.UserAsync();
        var reposter = await api.UserAsync();
        var other = await api.UserAsync();
        await FollowAsync(viewer, writer);
        await FollowAsync(viewer, reposter);

        var expected = new List<Guid>();
        for (var i = 0; i < 4; i++)
        {
            expected.Add((await writer.Client.PublishAsync($"Paged own {i}")).Id);
            var (otherId, _) = await other.Client.PublishAsync($"Paged repost {i}");
            await RepostAsync(reposter, otherId);
            expected.Add(otherId);
        }
        // Reposting the writer's first article moves it to the top.
        await RepostAsync(reposter, expected[0]);
        var order = expected.Skip(1).Reverse().Prepend(expected[0]).ToList();

        foreach (var limit in new[] { 1, 2, 3 })
        {
            (await FollowingAsync(viewer, limit)).Select(Id).Should().Equal(order, $"pages of {limit}");
        }
    }

    [Fact]
    public async Task Reposts_of_muted_writers_fields_and_show_less_articles_and_your_own_dont_appear()
    {
        var viewer = await api.UserAsync();
        var reposter = await api.UserAsync();
        var muted = await api.UserAsync("Muted Writer");
        var writer = await api.UserAsync();
        await FollowAsync(viewer, reposter);

        var (byMuted, _) = await muted.Client.PublishAsync("By a muted writer");
        var (inMutedField, _) = await writer.Client.PublishAsync("In a muted field", field: "databases");
        var (showLess, _) = await writer.Client.PublishAsync("Shown less");
        var (mine, _) = await viewer.Client.PublishAsync("The viewer's own");
        var (kept, _) = await writer.Client.PublishAsync("Kept article");
        foreach (var id in new[] { byMuted, inMutedField, showLess, mine, kept }) await RepostAsync(reposter, id);

        (await viewer.Client.PutEmptyAsync($"/api/v1/users/{muted.Id}/mute")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await viewer.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{await viewer.Client.FieldIdAsync("databases")}")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await viewer.Client.PutEmptyAsync($"/api/v1/articles/{showLess}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await FollowingAsync(viewer)).Select(Id).Should().Equal(kept);

        // A writer you mute stops placing anything: muting ends the follow.
        (await viewer.Client.PutEmptyAsync($"/api/v1/users/{reposter.Id}/mute")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await FollowingAsync(viewer)).Should().BeEmpty();
    }

    [Fact]
    public async Task Hidden_and_deleted_articles_drop_out_of_the_feed_and_the_reposts_tab()
    {
        var viewer = await api.UserAsync();
        var reposter = await api.UserAsync();
        var writer = await api.UserAsync();
        await FollowAsync(viewer, reposter);
        var (hidden, _) = await writer.Client.PublishAsync("To be hidden");
        var (deleted, _) = await writer.Client.PublishAsync("To be deleted");
        var (kept, _) = await writer.Client.PublishAsync("Stays visible");
        foreach (var id in new[] { hidden, deleted, kept }) await RepostAsync(reposter, id);

        var admin = (await api.SuperAdminAsync()).Client;
        (await admin.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "article", targetId = hidden, note = "x" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await writer.Client.DeleteAsync($"/api/v1/articles/{deleted}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await FollowingAsync(viewer)).Select(Id).Should().Equal(kept);
        (await api.GuestClient().GetAsync($"/api/v1/users/{Username(reposter)}/reposts", Ct).OkJsonAsync())["items"]!.AsArray()
            .Select(c => Id(c!)).Should().Equal(kept);
    }

    [Fact]
    public async Task The_reposts_tab_lists_a_users_reposts_newest_first_with_the_label()
    {
        var reposter = await api.UserAsync("Tab Owner");
        var writer = await api.UserAsync();
        var (first, _) = await writer.Client.PublishAsync("Reposted first");
        var (second, _) = await writer.Client.PublishAsync("Reposted second");
        var (third, _) = await writer.Client.PublishAsync("Reposted third");
        await RepostAsync(reposter, second);
        await RepostAsync(reposter, first);
        await RepostAsync(reposter, third);
        await UndoAsync(reposter, third);
        var guest = api.GuestClient();

        var page = await guest.GetAsync($"/api/v1/users/@{Username(reposter).ToUpperInvariant()}/reposts?limit=1", Ct).OkJsonAsync();
        var items = page["items"]!.AsArray();
        Id(items.Single()!).Should().Be(first, "newest repost first, not newest article");
        var label = items[0]!["repostedBy"]!;
        label["user"]!["id"]!.GetValue<Guid>().Should().Be(reposter.Id);
        label["othersCount"]!.GetValue<int>().Should().Be(0);
        items[0]!["author"]!["id"]!.GetValue<Guid>().Should().Be(writer.Id, "the card is the original post");
        items[0]!["isReposted"]!.GetValue<bool>().Should().BeFalse("guests");

        var next = await guest.GetAsync($"/api/v1/users/{Username(reposter)}/reposts?limit=1&cursor={Uri.EscapeDataString(page["nextCursor"]!.GetValue<string>())}", Ct)
            .OkJsonAsync();
        next["items"]!.AsArray().Select(c => Id(c!)).Should().Equal(second);
        next["nextCursor"].Should().BeNull();

        (await reposter.Client.GetAsync($"/api/v1/users/{Username(reposter)}/reposts", Ct).OkJsonAsync())["items"]!.AsArray()
            .Should().OnlyContain(c => c!["isReposted"]!.GetValue<bool>());
        await guest.GetAsync("/api/v1/users/nobody_here_404/reposts", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        (await (await api.UserAsync()).Client.GetAsync($"/api/v1/users/{Username(writer)}/reposts", Ct).OkJsonAsync())["items"]!.AsArray()
            .Should().BeEmpty("the empty state");
    }

    [Fact]
    public async Task The_author_hears_about_reposts_aggregated_once_per_reposter()
    {
        var author = await api.UserAsync("Notified Author");
        var (articleId, slug) = await author.Client.PublishAsync("Repost notifications");
        var first = await api.UserAsync("First Reposter");
        var second = await api.UserAsync("Second Reposter");
        var muted = await api.UserAsync("Muted Reposter");
        (await author.Client.PutEmptyAsync($"/api/v1/users/{muted.Id}/mute")).StatusCode.Should().Be(HttpStatusCode.OK);

        await RepostAsync(first, articleId);
        var entry = (await NotificationsAsync(author)).Should().ContainSingle().Subject!;
        entry["type"]!.GetValue<string>().Should().Be("article_reposted");
        entry["actor"]!["id"]!.GetValue<Guid>().Should().Be(first.Id);
        entry["actorCount"]!.GetValue<int>().Should().Be(1);
        entry["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId);
        entry["comment"].Should().BeNull();
        entry["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}");

        await RepostAsync(second, articleId);
        var both = (await NotificationsAsync(author)).Should().ContainSingle("reposts aggregate per article").Subject!;
        both["actorCount"]!.GetValue<int>().Should().Be(2);
        both["actor"]!["id"]!.GetValue<Guid>().Should().Be(second.Id);

        await UndoAsync(first, articleId);
        await RepostAsync(first, articleId);
        await RepostAsync(muted, articleId);
        var again = (await NotificationsAsync(author)).Should().ContainSingle().Subject!;
        again["actorCount"]!.GetValue<int>().Should().Be(2, "undoing and reposting again is not news, and a muted reposter tells nothing");
        again["updatedAt"]!.GetValue<DateTime>().Should().Be(both["updatedAt"]!.GetValue<DateTime>());

        // Once the entry is read, a reposter the author already heard about stays quiet.
        (await author.Client.PostAsync($"/api/v1/me/notifications/{again["id"]!.GetValue<Guid>()}/read", null, Ct)).StatusCode
            .Should().Be(HttpStatusCode.NoContent);
        await UndoAsync(second, articleId);
        await RepostAsync(second, articleId);
        (await NotificationsAsync(author)).Should().ContainSingle();

        // The type has its own setting: off writes nothing.
        var quiet = await api.UserAsync();
        var (quietArticle, _) = await quiet.Client.PublishAsync();
        (await quiet.Client.GetAsync("/api/v1/me/notification-settings", Ct).OkJsonAsync())["types"]!["article_reposted"]!.GetValue<string>()
            .Should().Be("all");
        await NotificationsTests.SetModeAsync(quiet, "article_reposted", "off");
        await RepostAsync(first, quietArticle);
        (await NotificationsAsync(quiet)).Should().BeEmpty();
    }

    [Fact]
    public async Task Deleting_the_reposters_account_removes_the_repost_and_recounts()
    {
        var author = await api.UserAsync();
        var (articleId, slug) = await author.Client.PublishAsync();
        var leaving = await api.UserAsync("Leaving Reposter");
        var staying = await api.UserAsync();
        await RepostAsync(leaving, articleId);
        await RepostAsync(staying, articleId);

        (await leaving.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
            { Content = JsonContent.Create(new { password = ApiFactory.TestPassword }) }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await InDbAsync(db => db.Reposts.CountAsync(r => r.ArticleId == articleId, Ct))).Should().Be(1);
        (await InDbAsync(db => db.Articles.Where(a => a.Id == articleId).Select(a => a.RepostCount).SingleAsync(Ct))).Should().Be(1);
        api.Realtime.CountersFor(articleId)[^1].RepostCount.Should().Be(1);
        (await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["repostCount"]!.GetValue<int>().Should().Be(1);
        (await NotificationsAsync(author)).Single()!["actorCount"]!.GetValue<int>().Should().Be(1, "the deleted reposter is gone as an actor");
    }

    [Fact]
    public async Task A_repost_with_thoughts_keeps_them_trimmed_with_unified_line_breaks()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var (blank, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();

        var state = await RepostWithAsync(reader, articleId, new { caption = "  \r\nرأيي في المقال:\r\nuseful for .NET devs  \r\n" });
        Caption(state).Should().Be("رأيي في المقال:\nuseful for .NET devs");
        (state["repostCount"]!.GetValue<int>(), state["isReposted"]!.GetValue<bool>()).Should().Be((1, true));
        (await InDbAsync(db => db.Reposts.Where(r => r.ArticleId == articleId).Select(r => r.Caption).SingleAsync(Ct)))
            .Should().Be("رأيي في المقال:\nuseful for .NET devs");

        // Only spaces and line breaks: no caption.
        Caption(await RepostWithAsync(reader, blank, new { caption = " \r\n\t " })).Should().BeNull();
        (await InDbAsync(db => db.Reposts.Where(r => r.ArticleId == blank).Select(r => r.Caption).SingleAsync(Ct))).Should().BeNull();
    }

    [Fact]
    public async Task Editing_the_thoughts_keeps_the_reposts_time_count_and_single_notification()
    {
        var author = await api.UserAsync("Thoughtful Author");
        var (articleId, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();

        await RepostWithAsync(reader, articleId, new { caption = "First take" });
        var createdAt = await InDbAsync(db => db.Reposts.Where(r => r.ArticleId == articleId).Select(r => r.CreatedAt).SingleAsync(Ct));
        var entry = (await NotificationsAsync(author)).Should().ContainSingle().Subject!;
        var published = api.Realtime.CountersFor(articleId).Count;

        (await RepostWithAsync(reader, articleId, new { caption = "Second take" })).ToJsonString()
            .Should().Be("""{"repostCount":1,"isReposted":true,"caption":"Second take"}""");
        await RepostWithAsync(reader, articleId, new { caption = "" });
        await RepostAsync(reader, articleId);

        (await InDbAsync(db => db.Reposts.Where(r => r.ArticleId == articleId).Select(r => r.CreatedAt).SingleAsync(Ct)))
            .Should().Be(createdAt, "the repost keeps its first time");
        (await InDbAsync(db => db.Articles.Where(a => a.Id == articleId).Select(a => a.RepostCount).SingleAsync(Ct))).Should().Be(1);
        api.Realtime.CountersFor(articleId).Should().HaveCount(published, "an edit raises nothing, so nothing is recounted");

        var after = (await NotificationsAsync(author)).Should().ContainSingle("an edit sends no new notification").Subject!;
        after["id"]!.GetValue<Guid>().Should().Be(entry["id"]!.GetValue<Guid>());
        after["actorCount"]!.GetValue<int>().Should().Be(1);
        after["updatedAt"]!.GetValue<DateTime>().Should().Be(entry["updatedAt"]!.GetValue<DateTime>());
    }

    [Fact]
    public async Task A_missing_or_null_caption_keeps_it_and_an_empty_one_clears_it()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var (other, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();

        Caption(await RepostWithAsync(reader, articleId, new { caption = "Keep me" })).Should().Be("Keep me");
        Caption(await RepostAsync(reader, articleId)).Should().Be("Keep me", "no body");
        Caption(await RepostWithAsync(reader, articleId, new { })).Should().Be("Keep me", "no caption member");
        Caption(await RepostWithAsync(reader, articleId, new { caption = (string?)null })).Should().Be("Keep me", "a null caption");
        Caption(await RepostWithAsync(reader, articleId, new { caption = "Changed my mind" })).Should().Be("Changed my mind");

        (await RepostWithAsync(reader, articleId, new { caption = "" })).ToJsonString()
            .Should().Be("""{"repostCount":1,"isReposted":true,"caption":null}""", "an empty caption clears it and the repost stays");
        Caption(await StateAsync(reader, articleId)).Should().BeNull();

        // On a new repost, a null caption is none.
        (await RepostWithAsync(reader, other, new { caption = (string?)null })).ToJsonString()
            .Should().Be("""{"repostCount":1,"isReposted":true,"caption":null}""");
    }

    [Fact]
    public async Task Thoughts_over_500_characters_are_refused_and_change_nothing()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();
        var longest = new string('ع', 500);

        var problem = await PutRepostAsync(reader, articleId, new { caption = longest + "!" }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        problem["errors"]!["caption"]!.AsArray().Select(c => c!.GetValue<string>()).Should().Equal("repost.caption_too_long");
        (await StateAsync(reader, articleId))["isReposted"]!.GetValue<bool>().Should().BeFalse("nothing was reposted");

        // 500 characters after trimming fit.
        Caption(await RepostWithAsync(reader, articleId, new { caption = $"  \r\n{longest}\r\n  " })).Should().Be(longest);

        // Too long on an existing repost keeps its caption.
        await PutRepostAsync(reader, articleId, new { caption = $"{longest}\r\nmore" }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        Caption(await StateAsync(reader, articleId)).Should().Be(longest);

        // The title clients fall back to.
        ErrorMessages.Title("repost.caption_too_long", "ar").Should().Be("رأيك لازم يكون 500 حرف أو أقل.");
        ErrorMessages.Title("repost.caption_too_long", "en").Should().Be("Your thoughts must be 500 characters or fewer.");
    }

    [Fact]
    public async Task Get_answers_your_repost_with_its_caption()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();
        var other = await api.UserAsync();

        (await StateAsync(reader, articleId)).ToJsonString().Should().Be("""{"repostCount":0,"isReposted":false,"caption":null}""");
        await RepostWithAsync(other, articleId, new { caption = "Someone else's thoughts" });
        (await StateAsync(reader, articleId)).ToJsonString()
            .Should().Be("""{"repostCount":1,"isReposted":false,"caption":null}""", "another reposter's caption is never yours");

        await RepostWithAsync(reader, articleId, new { caption = "Mine\r\ntoo" });
        (await StateAsync(reader, articleId)).ToJsonString().Should().Be("""{"repostCount":2,"isReposted":true,"caption":"Mine\ntoo"}""");
        (await StateAsync(author, articleId)).ToJsonString().Should().Be("""{"repostCount":2,"isReposted":false,"caption":null}""", "your own article");

        (await api.GuestClient().GetAsync($"/api/v1/articles/{articleId}/repost", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await reader.Client.GetAsync($"/api/v1/articles/{Guid.NewGuid()}/repost", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // Hidden by a moderator: not found for readers, as the article itself.
        var admin = (await api.SuperAdminAsync()).Client;
        (await admin.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "article", targetId = articleId, note = "Spam" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        await reader.Client.GetAsync($"/api/v1/articles/{articleId}/repost", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task Undoing_a_repost_deletes_its_caption()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();

        await RepostWithAsync(reader, articleId, new { caption = "Gone with it" });
        (await UndoAsync(reader, articleId)).ToJsonString().Should().Be("""{"repostCount":0,"isReposted":false,"caption":null}""");
        (await StateAsync(reader, articleId)).ToJsonString().Should().Be("""{"repostCount":0,"isReposted":false,"caption":null}""");
        (await InDbAsync(db => db.Reposts.AnyAsync(r => r.ArticleId == articleId, Ct))).Should().BeFalse();

        Caption(await RepostAsync(reader, articleId)).Should().BeNull("reposting again starts without the old thoughts");
    }

    [Fact]
    public async Task Labels_carry_the_named_reposters_thoughts_on_the_following_feed_and_the_reposts_tab()
    {
        var viewer = await api.UserAsync();
        var first = await api.UserAsync("First Thinker");
        var second = await api.UserAsync("Second Thinker");
        var writer = await api.UserAsync();
        await FollowAsync(viewer, first);
        await FollowAsync(viewer, second);
        var (articleId, _) = await writer.Client.PublishAsync("Worth a thought");
        var (plain, _) = await writer.Client.PublishAsync("Reposted without thoughts");

        await RepostWithAsync(first, articleId, new { caption = "رأي الأول\r\nfirst's thoughts" });
        await RepostWithAsync(second, articleId, new { caption = "Second's thoughts" });
        await RepostAsync(first, plain);

        var feed = await FollowingAsync(viewer);
        feed.Select(Id).Should().Equal([plain, articleId]);
        Caption(feed[0]["repostedBy"]).Should().BeNull("a repost without thoughts");
        var label = feed[1]["repostedBy"]!;
        label["user"]!["id"]!.GetValue<Guid>().Should().Be(second.Id);
        label["othersCount"]!.GetValue<int>().Should().Be(1);
        Caption(label).Should().Be("Second's thoughts", "only the named reposter's thoughts show");

        // Editing the thoughts changes the label, not the item's place.
        await RepostWithAsync(second, articleId, new { caption = "Second's thoughts, edited" });
        var edited = await FollowingAsync(viewer);
        edited.Select(Id).Should().Equal([plain, articleId]);
        Caption(edited[1]["repostedBy"]).Should().Be("Second's thoughts, edited");
        edited[1]["repostedBy"]!["repostedAt"]!.GetValue<DateTime>().Should().Be(label["repostedAt"]!.GetValue<DateTime>());

        // When the named reposter undoes, the next one is named with their own thoughts.
        await UndoAsync(second, articleId);
        var next = (await FollowingAsync(viewer)).Single(c => Id(c) == articleId)["repostedBy"]!;
        next["user"]!["id"]!.GetValue<Guid>().Should().Be(first.Id);
        next["othersCount"]!.GetValue<int>().Should().Be(0);
        Caption(next).Should().Be("رأي الأول\nfirst's thoughts");

        // The Reposts tab: the owner's thoughts on each card.
        var tab = (await api.GuestClient().GetAsync($"/api/v1/users/{Username(first)}/reposts", Ct).OkJsonAsync())["items"]!.AsArray();
        tab.Select(c => Id(c!)).Should().Equal(plain, articleId);
        Caption(tab[0]!["repostedBy"]).Should().BeNull();
        Caption(tab[1]!["repostedBy"]).Should().Be("رأي الأول\nfirst's thoughts");
        tab[1]!["repostedBy"]!.AsObject().Select(p => p.Key).Should().Equal("user", "othersCount", "repostedAt", "caption");
    }

    [Fact]
    public async Task The_counters_rebuild_includes_reposts()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var reposter = await api.UserAsync();
        await RepostAsync(reposter, articleId);
        await InDbAsync(db => db.Articles.Where(a => a.Id == articleId).ExecuteUpdateAsync(s => s.SetProperty(a => a.RepostCount, 42), Ct));

        var superAdmin = await api.SeedUserClientAsync(ApiFactory.SuperAdminPhone);
        (await superAdmin.PostAsync("/api/v1/admin/realtime/rebuild-counters", null, Ct).OkJsonAsync())["articleCount"]!.GetValue<int>()
            .Should().BeGreaterThan(0);

        (await InDbAsync(db => db.Articles.Where(a => a.Id == articleId).Select(a => a.RepostCount).SingleAsync(Ct))).Should().Be(1);
        api.Realtime.CountersFor(articleId)[^1].RepostCount.Should().Be(1);
    }
}
