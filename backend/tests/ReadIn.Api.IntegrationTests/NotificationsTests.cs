using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Notifications;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F17 Notifications against SQL Server: every producer end to end (follow, comment, reply, mention, reactions milestone,
/// publish, security change, moderation notice), the center's endpoints, the settings and what account deletion leaves.
/// Pushes are covered in <see cref="NotificationPushJobTests"/> and the daily article in <see cref="DailyArticleJobTests"/>.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class NotificationsTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    // ---- Producers ----

    [Fact]
    public async Task Followers_of_one_day_are_one_entry_and_following_again_is_not_news()
    {
        var writer = await api.UserAsync("Followed Writer");
        var first = await api.UserAsync("First Follower");
        var second = await api.UserAsync("Second Follower");

        await first.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        var one = (await ListAsync(writer)).Should().ContainSingle().Subject!;
        one["type"]!.GetValue<string>().Should().Be("new_follower");
        one["actorCount"]!.GetValue<int>().Should().Be(1);
        one["actor"]!["id"]!.GetValue<Guid>().Should().Be(first.Id);
        one["link"]!.GetValue<string>().Should().Be($"readin://u/{Username(first)}", "one follower opens their profile");
        api.Realtime.NotificationsFor(writer.Id)[^1].Unread.Should().Be(1, "the badge is published after the write");

        await second.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        var both = (await ListAsync(writer)).Should().ContainSingle("the day's followers aggregate").Subject!;
        both["id"]!.GetValue<Guid>().Should().Be(one["id"]!.GetValue<Guid>());
        both["actorCount"]!.GetValue<int>().Should().Be(2);
        both["actor"]!["id"]!.GetValue<Guid>().Should().Be(second.Id, "the latest actor is shown");
        both["actor"]!["displayName"]!.GetValue<string>().Should().Be("Second Follower");
        both["link"]!.GetValue<string>().Should().Be($"readin://u/{Username(writer)}/followers");
        both["article"].Should().BeNull();
        both["comment"].Should().BeNull();
        both["data"]!.AsObject().Should().BeEmpty();

        (await first.Client.DeleteAsync($"/api/v1/users/{writer.Id}/follow", Ct)).EnsureSuccessStatusCode();
        await first.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        var again = (await ListAsync(writer)).Should().ContainSingle().Subject!;
        again["actorCount"]!.GetValue<int>().Should().Be(2);
        again["updatedAt"]!.GetValue<DateTime>().Should().Be(both["updatedAt"]!.GetValue<DateTime>(), "following again the same day is not news");
    }

    [Fact]
    public async Task A_comment_tells_each_person_once_with_mentions_first_and_comments_aggregate_per_article()
    {
        var author = await api.UserAsync("Article Author");
        var (articleId, slug) = await author.Client.PublishAsync("Comment notifications");
        var mentioner = await api.UserAsync("Mentioner");
        var mentioned = await api.UserAsync("Mentioned Reader");
        var second = await api.UserAsync("Second Commenter");
        var third = await api.UserAsync("Third Commenter");

        // Mentions the author and another reader: both get a mention, the author no "commented on your article" for it.
        var mentioning = await CommentAsync(mentioner, articleId, $"@{Username(author)} و @{Username(mentioned)} شوفوا ده");
        var authorEntries = await ListAsync(author);
        var mention = authorEntries.Should().ContainSingle().Subject!;
        mention["type"]!.GetValue<string>().Should().Be("mention");
        mention["comment"]!["id"]!.GetValue<Guid>().Should().Be(mentioning);
        mention["comment"]!["parentId"].Should().BeNull();
        mention["comment"]!["excerpt"]!.GetValue<string>().Should().StartWith("@");
        mention["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId);
        mention["article"]!["slug"]!.GetValue<string>().Should().Be(slug);
        mention["article"]!["title"]!.GetValue<string>().Should().Be("Comment notifications");
        mention["article"]!["language"]!.GetValue<string>().Should().Be("en");
        mention["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}#comment-{mentioning}");
        (await ListAsync(mentioned)).Should().ContainSingle().Which!["type"]!.GetValue<string>().Should().Be("mention");
        (await ListAsync(mentioner)).Should().BeEmpty("nobody is told about their own comment");

        // Two more comments: one "commented on your article" entry with both.
        await CommentAsync(second, articleId, "Second comment here");
        var last = await CommentAsync(third, articleId, "Third comment here");
        authorEntries = await ListAsync(author);
        authorEntries.Should().HaveCount(2);
        var comments = authorEntries[0]!;
        comments["type"]!.GetValue<string>().Should().Be("article_comment");
        comments["actorCount"]!.GetValue<int>().Should().Be(2);
        comments["actor"]!["id"]!.GetValue<Guid>().Should().Be(third.Id);
        comments["comment"]!["id"]!.GetValue<Guid>().Should().Be(last, "an aggregated entry points at the latest comment");
        comments["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}#comment-{last}");

        // A reply tells the author of the comment it answers (not the article's author).
        var reply = await ReplyAsync(second, mentioning, "A reply to the mentioner");
        var replied = (await ListAsync(mentioner)).Should().ContainSingle().Subject!;
        replied["type"]!.GetValue<string>().Should().Be("comment_reply");
        replied["comment"]!["id"]!.GetValue<Guid>().Should().Be(reply);
        replied["comment"]!["parentId"]!.GetValue<Guid>().Should().Be(mentioning);
        (await ListAsync(author)).Should().HaveCount(2, "the article's author isn't told about replies");

        // An edit tells only users it mentions for the first time.
        var late = await api.UserAsync("Late Mention");
        (await mentioner.Client.PatchAsJsonAsync($"/api/v1/comments/{mentioning}",
            new { body = $"@{Username(author)} و @{Username(mentioned)} و @{Username(late)} شوفوا ده" }, Ct)).EnsureSuccessStatusCode();
        (await ListAsync(late)).Should().ContainSingle().Which!["type"]!.GetValue<string>().Should().Be("mention");
        (await ListAsync(mentioned)).Should().ContainSingle("already told about this comment");
        (await ListAsync(author)).Should().HaveCount(2);

        // A deleted comment drops out of the center; the entry isn't rewritten.
        (await mentioner.Client.DeleteAsync($"/api/v1/comments/{mentioning}", Ct)).EnsureSuccessStatusCode();
        (await ListAsync(mentioned)).Should().BeEmpty();
        (await UnreadAsync(mentioned)).Should().Be(0);
    }

    [Fact]
    public async Task The_tenth_reaction_is_a_milestone_told_once()
    {
        var author = await api.UserAsync();
        var (articleId, slug) = await author.Client.PublishAsync();
        var readers = new List<SignedInUser>();
        for (var i = 0; i < 10; i++) readers.Add(await api.UserAsync());

        for (var i = 0; i < 9; i++) await readers[i].Client.ReactAsync(articleId, "love").OkJsonAsync();
        (await ListAsync(author)).Should().BeEmpty();

        await readers[9].Client.ReactAsync(articleId, "fire").OkJsonAsync();
        var milestone = (await ListAsync(author)).Should().ContainSingle().Subject!;
        milestone["type"]!.GetValue<string>().Should().Be("reactions_milestone");
        milestone["data"]!["threshold"]!.GetValue<int>().Should().Be(10);
        milestone["actor"].Should().BeNull();
        milestone["actorCount"]!.GetValue<int>().Should().Be(0);
        milestone["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}");

        // Dropping under 10 and crossing again tells nothing new.
        (await readers[9].Client.DeleteAsync($"/api/v1/articles/{articleId}/reaction", Ct)).EnsureSuccessStatusCode();
        await readers[9].Client.ReactAsync(articleId, "insightful").OkJsonAsync();
        await readers[0].Client.ReactAsync(articleId, "mindBlown").OkJsonAsync();
        (await ListAsync(author)).Should().ContainSingle();
    }

    [Fact]
    public async Task Publishing_tells_the_writers_followers_once()
    {
        var writer = await api.UserAsync("Prolific Writer");
        var follower = await api.UserAsync();
        await follower.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();

        var (articleId, slug) = await writer.Client.PublishAsync("Fresh from a followed writer");
        var entry = (await ListAsync(follower)).Should().ContainSingle().Subject!;
        entry["type"]!.GetValue<string>().Should().Be("followed_writer_article");
        entry["actor"]!["id"]!.GetValue<Guid>().Should().Be(writer.Id);
        entry["article"]!["title"]!.GetValue<string>().Should().Be("Fresh from a followed writer");
        entry["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}");

        // An update of the published article raises no event.
        (await writer.Client.PublishCurrentAsync(articleId)).EnsureSuccessStatusCode();
        (await ListAsync(follower)).Should().ContainSingle();
    }

    [Fact]
    public async Task A_security_change_alerts_the_owner_at_once_even_in_quiet_hours()
    {
        var user = await api.UserAsync();
        await QuietNowAsync(user);

        var changed = await user.Client.PutAsJsonAsync("/api/v1/me/password",
            new { currentPassword = ApiFactory.TestPassword, newPassword = "Better-pass-31" }, Ct);
        // The change signs the old access token out; the response carries this device's new one.
        var client = api.ClientWithToken((await ApiFactory.ReadSessionAsync(changed))["accessToken"]!.GetValue<string>());

        var alert = (await ListAsync(client)).Should().ContainSingle().Subject!;
        alert["type"]!.GetValue<string>().Should().Be("security_alert");
        alert["data"]!["securityChange"]!.GetValue<string>().Should().Be("passwordChanged");
        alert["link"]!.GetValue<string>().Should().Be("readin://settings/account");
        var row = await InDbAsync(db => db.Notifications.AsNoTracking().SingleAsync(n => n.UserId == user.Id, Ct));
        row.PushStatus.Should().Be(NotificationPushStatus.Pending);
        row.PushAfter.Should().Be(row.CreatedAt, "security alerts ignore quiet hours");
    }

    [Fact]
    public async Task A_moderation_notice_is_an_entry_that_opens_the_article_or_the_center()
    {
        var author = await api.UserAsync();
        var (articleId, slug) = await author.Client.PublishAsync("Hidden by the moderators");
        var moderator = (await api.SuperAdminAsync("Test Moderator")).Client;

        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "warn", targetType = "user", targetId = author.Id, note = "Be kind." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "hide", targetType = "article", targetId = articleId, note = "No sources." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var entries = await ListAsync(author);
        entries.Should().HaveCount(2).And.OnlyContain(e => e!["type"]!.GetValue<string>() == "moderation_notice");
        var hidden = entries.Single(e => e!["article"] is not null)!;
        hidden["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId, "the hidden article stays in its notice");
        hidden["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}");
        hidden["actor"].Should().BeNull("moderators stay anonymous");
        entries.Single(e => e!["article"] is null)!["link"]!.GetValue<string>().Should().Be("readin://notifications");
    }

    // ---- The center ----

    [Fact]
    public async Task Seen_clears_the_badge_read_marks_one_and_read_all_the_rest()
    {
        var user = await api.UserAsync();
        foreach (var _ in Enumerable.Range(0, 3))
            await (await api.UserAsync()).Client.PutEmptyAsync($"/api/v1/users/{user.Id}/follow").OkJsonAsync();
        var other = await api.UserAsync();
        await user.Client.PutEmptyAsync($"/api/v1/users/{other.Id}/follow").OkJsonAsync();
        var commenter = await api.UserAsync();
        var (articleId, _) = await user.Client.PublishAsync();
        await CommentAsync(commenter, articleId, $"@{Username(user)} hello");
        await CommentAsync(other, articleId, "Another comment");

        var entries = await ListAsync(user);
        entries.Should().HaveCount(3, "followers, a mention and a comment");
        (await UnreadAsync(user)).Should().Be(3);

        (await user.Client.PostAsync("/api/v1/me/notifications/seen", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await UnreadAsync(user)).Should().Be(0);
        api.Realtime.NotificationsFor(user.Id)[^1].Unread.Should().Be(0, "the other devices' badge follows");
        (await ListAsync(user)).Should().OnlyContain(e => !e!["isRead"]!.GetValue<bool>(), "entries stay unread until opened");

        var first = entries[0]!["id"]!.GetValue<Guid>();
        (await user.Client.PostAsync($"/api/v1/me/notifications/{first}/read", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.PostAsync($"/api/v1/me/notifications/{first}/read", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await ListAsync(user)).Count(e => e!["isRead"]!.GetValue<bool>()).Should().Be(1);
        await other.Client.PostAsync($"/api/v1/me/notifications/{first}/read", null, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "notification.not_found");
        await user.Client.PostAsync($"/api/v1/me/notifications/{Guid.NewGuid()}/read", null, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "notification.not_found");

        (await user.Client.PostAsync("/api/v1/me/notifications/read-all", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await ListAsync(user)).Should().OnlyContain(e => e!["isRead"]!.GetValue<bool>());

        // New activity on a read entry starts a new one.
        await CommentAsync(commenter, articleId, "More comments");
        (await UnreadAsync(user)).Should().Be(1);
    }

    [Fact]
    public async Task The_center_pages_by_latest_activity()
    {
        var user = await api.UserAsync();
        var writers = new List<SignedInUser>();
        for (var i = 0; i < 3; i++)
        {
            var writer = await api.UserAsync($"Writer {i}");
            await user.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
            writers.Add(writer);
        }
        foreach (var writer in writers) await writer.Client.PublishAsync();

        var page = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications?limit=2", Ct))!;
        page["items"]!.AsArray().Should().HaveCount(2);
        page["items"]![0]!["actor"]!["id"]!.GetValue<Guid>().Should().Be(writers[2].Id, "latest activity first");
        var cursor = page["nextCursor"]!.GetValue<string>();
        var rest = (await user.Client.GetFromJsonAsync<JsonObject>($"/api/v1/me/notifications?limit=2&cursor={cursor}", Ct))!;
        rest["items"]!.AsArray().Should().ContainSingle().Which!["actor"]!["id"]!.GetValue<Guid>().Should().Be(writers[0].Id);
        rest["nextCursor"].Should().BeNull();

        (await api.GuestClient().GetAsync("/api/v1/me/notifications", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task A_deleted_actor_shows_as_deleted_user_and_their_follow_entry_drops_out()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var leaving = await api.UserAsync();
        await leaving.Client.PutEmptyAsync($"/api/v1/users/{author.Id}/follow").OkJsonAsync();
        await CommentAsync(leaving, articleId, "A comment that stays after its author leaves");
        (await ListAsync(author)).Should().HaveCount(2);

        (await leaving.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
        {
            Content = JsonContent.Create(new { password = ApiFactory.TestPassword }),
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var entry = (await ListAsync(author)).Should().ContainSingle("the follow is gone with the account").Subject!;
        entry["type"]!.GetValue<string>().Should().Be("article_comment");
        entry["actor"].Should().BeNull("shown as \"Deleted user\"");
        entry["actorCount"]!.GetValue<int>().Should().Be(0);
    }

    [Fact]
    public async Task Deleting_a_writer_removes_notifications_about_their_deleted_articles()
    {
        var writer = await api.UserAsync();
        var follower = await api.UserAsync();
        await follower.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        var (articleId, _) = await writer.Client.PublishAsync();
        await CommentAsync(follower, articleId, "A comment on an article that goes");
        (await writer.Client.DeleteAsync($"/api/v1/articles/{articleId}", Ct)).EnsureSuccessStatusCode();
        (await InDbAsync(db => db.Notifications.CountAsync(n => n.ArticleId == articleId, Ct))).Should().Be(2);

        (await writer.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
        {
            Content = JsonContent.Create(new { password = ApiFactory.TestPassword }),
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await InDbAsync(db => db.Notifications.CountAsync(n => n.ArticleId == articleId, Ct))).Should().Be(0);
        (await InDbAsync(db => db.Articles.IgnoreQueryFilters().AnyAsync(a => a.Id == articleId, Ct))).Should().BeFalse();
    }

    // ---- Settings ----

    [Fact]
    public async Task Settings_default_to_all_with_quiet_hours_and_change_partially()
    {
        var user = await api.UserAsync();

        var defaults = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notification-settings", Ct))!;
        defaults["quietHours"]!["enabled"]!.GetValue<bool>().Should().BeTrue();
        defaults["quietHours"]!["start"]!.GetValue<string>().Should().Be("23:00");
        defaults["quietHours"]!["end"]!.GetValue<string>().Should().Be("07:00");
        var types = defaults["types"]!.AsObject();
        types.Select(t => t.Key).Should().BeEquivalentTo(NotificationTypes.Configurable);
        types.Should().OnlyContain(t => t.Value!.GetValue<string>() == "all");

        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new
        {
            quietHours = new { enabled = false, start = "22:30", end = "06:15" },
            types = new Dictionary<string, string> { ["new_follower"] = "off", ["mention"] = "inApp" },
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { types = new Dictionary<string, string> { ["daily_article"] = "inApp" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var changed = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notification-settings", Ct))!;
        changed["quietHours"]!.ToJsonString().Should().Be("""{"enabled":false,"start":"22:30","end":"06:15"}""");
        changed["types"]!["new_follower"]!.GetValue<string>().Should().Be("off");
        changed["types"]!["mention"]!.GetValue<string>().Should().Be("inApp");
        changed["types"]!["daily_article"]!.GetValue<string>().Should().Be("inApp");
        changed["types"]!["article_comment"]!.GetValue<string>().Should().Be("all");

        // Back to all: the sparse row goes.
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { types = new Dictionary<string, string> { ["mention"] = "all" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await InDbAsync(db => db.UserNotificationSettings.Where(s => s.UserId == user.Id).Select(s => s.Type).ToListAsync(Ct)))
            .Should().BeEquivalentTo(["new_follower", "daily_article"]);
    }

    [Theory]
    [InlineData("""{"types":{"security_alert":"off"}}""", "notification.type_invalid")]
    [InlineData("""{"types":{"moderation_notice":"inApp"}}""", "notification.type_invalid")]
    [InlineData("""{"types":{"no_such_type":"all"}}""", "notification.type_invalid")]
    [InlineData("""{"types":{"mention":"loud"}}""", "notification.mode_invalid")]
    [InlineData("""{"types":{"mention":"2"}}""", "notification.mode_invalid")]
    [InlineData("""{"quietHours":{"enabled":true,"start":"25:00","end":"07:00"}}""", "notification.quiet_hours_invalid")]
    [InlineData("""{"quietHours":{"enabled":true,"start":"22:00","end":"22:00"}}""", "notification.quiet_hours_invalid")]
    [InlineData("""{"quietHours":{"enabled":true,"start":"10pm","end":"07:00"}}""", "notification.quiet_hours_invalid")]
    public async Task Invalid_settings_are_refused_and_change_nothing(string body, string code)
    {
        var user = await api.UserAsync();

        await user.Client.PutAsync("/api/v1/me/notification-settings", new StringContent(body, System.Text.Encoding.UTF8, "application/json"), Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, code);
        (await InDbAsync(db => db.UserNotificationSettings.AnyAsync(s => s.UserId == user.Id, Ct))).Should().BeFalse();
    }

    [Fact]
    public async Task Off_writes_nothing_and_in_app_writes_the_entry_without_a_push()
    {
        var quiet = await api.UserAsync();
        var inApp = await api.UserAsync();
        await SetModeAsync(quiet, "new_follower", "off");
        await SetModeAsync(inApp, "new_follower", "inApp");
        var follower = await api.UserAsync();

        await follower.Client.PutEmptyAsync($"/api/v1/users/{quiet.Id}/follow").OkJsonAsync();
        await follower.Client.PutEmptyAsync($"/api/v1/users/{inApp.Id}/follow").OkJsonAsync();

        (await ListAsync(quiet)).Should().BeEmpty();
        (await ListAsync(inApp)).Should().ContainSingle();
        (await InDbAsync(db => db.Notifications.AsNoTracking().SingleAsync(n => n.UserId == inApp.Id, Ct)))
            .PushStatus.Should().Be(NotificationPushStatus.None);
    }

    // ---- Demo data ----

    [Fact]
    public async Task The_demo_seeder_fills_the_center_locally_without_pushes_and_replaces_its_own_entries()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var seeder = new DemoNotificationsSeeder(db, TimeProvider.System);
        seeder.AppliesTo(new TestEnvironment("Testing")).Should().BeFalse("only Development gets demo notifications");
        seeder.AppliesTo(new TestEnvironment("Development")).Should().BeTrue();

        try
        {
            (await seeder.SeedAsync(Ct)).Should().BeTrue();
            var first = await DemoEntriesAsync(db);
            (await seeder.SeedAsync(Ct)).Should().BeTrue();
            var second = await DemoEntriesAsync(db);

            second.Should().HaveSameCount(first, "a re-run replaces its entries").And.OnlyContain(n => n.PushStatus == NotificationPushStatus.None);
            var reader1 = await db.Users.AsNoTracking().Where(u => u.Email == "reader1@readin.test").Select(u => u.Id).SingleAsync(Ct);
            var writer1 = await db.Users.AsNoTracking().Where(u => u.Email == "writer1@readin.test").Select(u => u.Id).SingleAsync(Ct);
            second.Where(n => n.UserId == reader1).Select(n => n.Type).Should().Contain(
            [
                NotificationTypes.CommentReply, NotificationTypes.Mention, NotificationTypes.FollowedWriterArticle, NotificationTypes.DailyArticle,
                NotificationTypes.StreakReminder, NotificationTypes.SecurityAlert,
            ]);
            second.Where(n => n.UserId == writer1).Select(n => n.Type).Should().Contain(
                [NotificationTypes.ArticleComment, NotificationTypes.ReactionsMilestone, NotificationTypes.NewFollower]);
            var demoIds = second.Select(n => n.Id).ToList();
            (await db.NotificationActors.CountAsync(a => demoIds.Contains(a.NotificationId) && a.ActorId == reader1, Ct))
                .Should().BeGreaterThanOrEqualTo(2, "reader1 commented on and follows writer1");

            var center = (await (await api.SeedUserClientAsync(ApiFactory.Reader1Phone))
                .GetFromJsonAsync<JsonObject>("/api/v1/me/notifications?limit=50", Ct))!["items"]!.AsArray();
            center.Select(i => i!["type"]!.GetValue<string>()).Should().Contain(["comment_reply", "mention", "streak_reminder"]);
        }
        finally
        {
            await db.Notifications.Where(n => n.DedupeKey != null && n.DedupeKey.StartsWith("demo:")).ExecuteDeleteAsync(Ct);
        }
    }

    private static Task<List<Notification>> DemoEntriesAsync(AppDbContext db) =>
        db.Notifications.AsNoTracking().Where(n => n.DedupeKey != null && n.DedupeKey.StartsWith("demo:")).ToListAsync(Ct);

    private sealed class TestEnvironment(string name) : Microsoft.Extensions.Hosting.IHostEnvironment
    {
        public string EnvironmentName { get; set; } = name;
        public string ApplicationName { get; set; } = "ReadIn.Api";
        public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
        public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; } =
            new Microsoft.Extensions.FileProviders.NullFileProvider();
    }

    // ---- Helpers ----

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static Task<JsonArray> ListAsync(SignedInUser user) => ListAsync(user.Client);

    private static async Task<JsonArray> ListAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications?limit=50", Ct))!["items"]!.AsArray();

    private static async Task<int> UnreadAsync(SignedInUser user) =>
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications/unread-count", Ct))!["unread"]!.GetValue<int>();

    private static async Task<Guid> CommentAsync(SignedInUser user, Guid articleId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
    }

    private static async Task<Guid> ReplyAsync(SignedInUser user, Guid commentId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/comments/{commentId}/replies", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
    }

    internal static async Task SetModeAsync(SignedInUser user, string type, string mode) =>
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { types = new Dictionary<string, string> { [type] = mode } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

    /// <summary>Quiet hours from an hour ago to an hour from now in the user's time zone (Africa/Cairo for test users).</summary>
    /// <returns>When they end, in UTC.</returns>
    internal static async Task<DateTime> QuietNowAsync(SignedInUser user)
    {
        var cairo = TimeZoneInfo.FindSystemTimeZoneById("Africa/Cairo");
        var local = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, cairo);
        local = local.AddSeconds(-local.Second).AddMilliseconds(-local.Millisecond);
        var start = TimeOnly.FromDateTime(local.AddHours(-1));
        var end = TimeOnly.FromDateTime(local.AddHours(1));
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { quietHours = new { enabled = true, start = start.ToString("HH:mm"), end = end.ToString("HH:mm") } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        return TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(local.AddHours(1), DateTimeKind.Unspecified), cairo);
    }

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> query)
    {
        using var scope = api.Services.CreateScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }
}
