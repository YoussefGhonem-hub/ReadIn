using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Reading;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The notification push job (F17) against SQL Server, run explicitly with a recording <see cref="IPushSender"/> (the
/// Testing environment has no Hangfire, so nothing sends on its own): text in the user's language, aggregation, quiet
/// hours, retries, dead tokens, stale entries, and the 20:00 streak reminder. Every run sends all pushes that are due, so
/// assertions look at this test's own devices and entries only.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class NotificationPushJobTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private static readonly DateOnly Today = DateOnly.FromDateTime(DateTime.UtcNow);

    [Fact]
    public async Task A_due_push_goes_out_once_in_the_users_language_and_new_activity_sends_the_aggregate()
    {
        var (author, token) = await UserWithDeviceAsync("ar", "كاتبة المقال");
        var (articleId, slug) = await author.Client.PublishAsync("Push me");
        var (first, _) = await UserWithDeviceAsync("en", "Ahmed");
        var (second, _) = await UserWithDeviceAsync("en", "Mona");

        await CommentAsync(first, articleId, "First comment, pushed");
        var push = new RecordingPushSender();
        await PushAsync(push, DateTime.UtcNow.AddSeconds(1));

        var sent = push.To(token).Should().ContainSingle().Subject;
        var entry = await EntryAsync(author.Id, NotificationTypes.ArticleComment);
        sent.Title.Should().Be("علّق ⁨Ahmed⁩ على مقالك");
        sent.Body.Should().Be("First comment, pushed");
        sent.CollapseKey.Should().Be($"article_comment:{articleId}", "a newer push of the same group replaces the older one");
        sent.Data.Should().BeEquivalentTo(new Dictionary<string, string>
        {
            ["type"] = "article_comment",
            ["notificationId"] = entry.Id.ToString(),
            ["link"] = $"readin://a/{slug}#comment-{entry.CommentId}",
            ["lang"] = "en",
        });
        entry.PushStatus.Should().Be(NotificationPushStatus.Sent);
        entry.PushedAt.Should().NotBeNull();

        await PushAsync(push, DateTime.UtcNow.AddSeconds(2));
        push.To(token).Should().ContainSingle("a push goes out once");

        // New activity re-arms the same entry: the aggregated text, under the same collapse key.
        await CommentAsync(second, articleId, "Second comment, aggregated");
        await PushAsync(push, DateTime.UtcNow.AddSeconds(1));
        var aggregated = push.To(token).Should().HaveCount(2).And.Subject.Last();
        aggregated.Title.Should().Be("علّق ⁨Mona⁩ وشخص آخر على مقالك");
        aggregated.Data["notificationId"].Should().Be(entry.Id.ToString());
        aggregated.CollapseKey.Should().Be(sent.CollapseKey);
    }

    [Fact]
    public async Task English_followers_are_counted_in_one_push()
    {
        var (writer, token) = await UserWithDeviceAsync("en", "Followed");
        foreach (var name in new[] { "Sara", "Omar", "Nour" })
            await (await UserWithDeviceAsync("en", name)).User.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();

        var push = new RecordingPushSender();
        await PushAsync(push, DateTime.UtcNow.AddSeconds(1));

        var sent = push.To(token).Should().ContainSingle().Subject;
        sent.Title.Should().Be("⁨Nour⁩ and 2 others started following you");
        sent.Data["link"].Should().Be($"readin://u/{writer.Me["username"]!.GetValue<string>()}/followers");
        sent.CollapseKey.Should().StartWith("new_follower:");
    }

    [Fact]
    public async Task Quiet_hours_hold_a_push_until_they_end_but_not_a_security_alert()
    {
        var (user, token) = await UserWithDeviceAsync("en", "Sleeper", quietHours: true);
        var quietEnds = await NotificationsTests.QuietNowAsync(user);
        await (await api.UserAsync()).Client.PutEmptyAsync($"/api/v1/users/{user.Id}/follow").OkJsonAsync();

        var follower = await EntryAsync(user.Id, NotificationTypes.NewFollower);
        follower.PushAfter.Should().BeCloseTo(quietEnds, TimeSpan.FromSeconds(1), "the push waits for the end of quiet hours");

        var push = new RecordingPushSender();
        var now = DateTime.UtcNow.AddSeconds(1);
        await PushAsync(push, now);
        push.To(token).Should().BeEmpty();

        var changed = await user.Client.PutAsJsonAsync("/api/v1/me/password",
            new { currentPassword = ApiFactory.TestPassword, newPassword = "Better-pass-31" }, Ct);
        changed.StatusCode.Should().Be(HttpStatusCode.OK);
        await PushAsync(push, DateTime.UtcNow.AddSeconds(1));
        var alert = push.To(token).Should().ContainSingle("security alerts ignore quiet hours").Subject;
        alert.Title.Should().Be("Security alert");
        alert.Body.Should().Be("Your password was changed. If this wasn't you, reset it now.");
        alert.Data["type"].Should().Be("security_alert");
        alert.Data["link"].Should().Be("readin://settings/account");

        await PushAsync(push, quietEnds.AddSeconds(1));
        push.To(token).Should().HaveCount(2);
        push.To(token)[^1].Data["type"].Should().Be("new_follower");
    }

    [Fact]
    public async Task Failed_sends_are_retried_three_times_and_dead_tokens_are_removed()
    {
        var (flaky, _) = await UserWithDeviceAsync();
        await (await api.UserAsync()).Client.PutEmptyAsync($"/api/v1/users/{flaky.Id}/follow").OkJsonAsync();
        var failing = new FailingDevicesPushSender();

        var t0 = DateTime.UtcNow.AddSeconds(1);
        await PushAsync(failing, t0);
        var entry = await EntryAsync(flaky.Id, NotificationTypes.NewFollower);
        (entry.PushStatus, entry.PushAttempts).Should().Be((NotificationPushStatus.Pending, 1));
        entry.PushAfter.Should().Be(t0.AddMinutes(1));

        await PushAsync(failing, t0.AddSeconds(30));
        (await EntryAsync(flaky.Id, NotificationTypes.NewFollower)).PushAttempts.Should().Be(1, "not due again yet");
        await PushAsync(failing, t0.AddMinutes(2));
        (await EntryAsync(flaky.Id, NotificationTypes.NewFollower)).PushAttempts.Should().Be(2);
        await PushAsync(failing, t0.AddMinutes(8));
        entry = await EntryAsync(flaky.Id, NotificationTypes.NewFollower);
        (entry.PushStatus, entry.PushAttempts).Should().Be((NotificationPushStatus.Failed, 3));

        var (gone, deadToken) = await UserWithDeviceAsync();
        await (await api.UserAsync()).Client.PutEmptyAsync($"/api/v1/users/{gone.Id}/follow").OkJsonAsync();
        var rejecting = new RecordingPushSender();
        rejecting.InvalidTokens.Add(deadToken);
        await PushAsync(rejecting, DateTime.UtcNow.AddSeconds(1));
        (await EntryAsync(gone.Id, NotificationTypes.NewFollower)).PushStatus.Should().Be(NotificationPushStatus.Skipped);
        (await InDbAsync(db => db.Users.Where(u => u.Id == gone.Id).SelectMany(u => u.Devices).CountAsync(Ct))).Should().Be(0);
    }

    [Fact]
    public async Task An_article_mention_pushes_the_title_and_opens_the_article_while_it_is_readable()
    {
        var (writer, _) = await UserWithDeviceAsync("en", "Mona");
        var (mentioned, token) = await UserWithDeviceAsync("ar");
        var (late, lateToken) = await UserWithDeviceAsync("en");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var (_, slug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Mentions get pushed",
            blocks: [ArticleTestKit.Inline("p1", ArticleTestKit.Text("Thanks "), ArticleTestKit.Mention(mentioned.Id, "@x"))]));
        var (goneId, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Deleted before the push",
            blocks: [ArticleTestKit.Inline("p1", ArticleTestKit.Mention(late.Id, "@y"))]));
        (await writer.Client.DeleteAsync($"/api/v1/articles/{goneId}", Ct)).EnsureSuccessStatusCode();

        var push = new RecordingPushSender();
        await PushAsync(push, DateTime.UtcNow.AddSeconds(1));

        var sent = push.To(token).Should().ContainSingle().Subject;
        var entry = await EntryAsync(mentioned.Id, NotificationTypes.Mention);
        entry.CommentId.Should().BeNull();
        sent.Title.Should().Be("أشار إليك ⁨Mona⁩ في مقال");
        sent.Body.Should().Be("Mentions get pushed", "the article's title");
        sent.CollapseKey.Should().Be("mention");
        sent.Data.Should().BeEquivalentTo(new Dictionary<string, string>
        {
            ["type"] = "mention",
            ["notificationId"] = entry.Id.ToString(),
            ["link"] = $"readin://a/{slug}",
            ["lang"] = "en",
        });
        entry.PushStatus.Should().Be(NotificationPushStatus.Sent);

        push.To(lateToken).Should().BeEmpty("the article is gone");
        (await EntryAsync(late.Id, NotificationTypes.Mention)).PushStatus.Should().Be(NotificationPushStatus.Skipped);
    }

    [Fact]
    public async Task Stale_entries_and_types_turned_off_since_are_not_pushed()
    {
        var push = new RecordingPushSender();

        var (changedMind, changedToken) = await UserWithDeviceAsync();
        await (await api.UserAsync()).Client.PutEmptyAsync($"/api/v1/users/{changedMind.Id}/follow").OkJsonAsync();
        await NotificationsTests.SetModeAsync(changedMind, "new_follower", "inApp");
        await PushAsync(push, DateTime.UtcNow.AddSeconds(1));
        push.To(changedToken).Should().BeEmpty("the type is in-app only now");
        (await EntryAsync(changedMind.Id, NotificationTypes.NewFollower)).PushStatus.Should().Be(NotificationPushStatus.Skipped);

        var (late, lateToken) = await UserWithDeviceAsync();
        await (await api.UserAsync()).Client.PutEmptyAsync($"/api/v1/users/{late.Id}/follow").OkJsonAsync();
        var stale = await EntryAsync(late.Id, NotificationTypes.NewFollower);
        await PushAsync(push, stale.UpdatedAt.AddHours(25));
        push.To(lateToken).Should().BeEmpty("a push more than 24 hours late is dropped");
        (await EntryAsync(late.Id, NotificationTypes.NewFollower)).PushStatus.Should().Be(NotificationPushStatus.Skipped);
    }

    [Fact]
    public async Task The_streak_reminder_goes_out_at_8_pm_local_to_streaks_that_need_a_read_today()
    {
        var (alive, aliveToken) = await UserWithDeviceAsync();
        var (readToday, _) = await UserWithDeviceAsync();
        var (broken, _) = await UserWithDeviceAsync();
        foreach (var user in new[] { alive, readToday, broken }) await InUtcAsync(user);
        await StatsAsync(alive.Id, streak: 3, lastRead: Today.AddDays(-1));
        await StatsAsync(readToday.Id, streak: 4, lastRead: Today);
        await StatsAsync(broken.Id, streak: 2, lastRead: Today.AddDays(-5));

        await RemindAsync(Today.ToDateTime(new TimeOnly(19, 59), DateTimeKind.Utc));
        (await RemindersAsync(alive.Id)).Should().BeEmpty("the reminder goes out at 20:00 local time");

        var at = Today.ToDateTime(new TimeOnly(20, 5), DateTimeKind.Utc);
        await RemindAsync(at);
        await RemindAsync(at.AddMinutes(5)); // the next run
        var reminder = (await RemindersAsync(alive.Id)).Should().ContainSingle("one a day").Subject;
        reminder.DedupeKey.Should().Be($"streak_reminder:{Today:yyyy-MM-dd}");
        NotificationData.Parse(reminder.Data).StreakDays.Should().Be(3);
        (await RemindersAsync(readToday.Id)).Should().BeEmpty("they read today");
        (await RemindersAsync(broken.Id)).Should().BeEmpty("there is no streak to keep");

        var item = (await alive.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications", Ct))!["items"]!.AsArray()
            .Single(i => i!["type"]!.GetValue<string>() == "streak_reminder")!;
        item["data"]!["streakDays"]!.GetValue<int>().Should().Be(3);
        item["link"]!.GetValue<string>().Should().Be("readin://me/stats");

        var push = new RecordingPushSender();
        await PushAsync(push, at.AddMinutes(1));
        var sent = push.To(aliveToken).Should().ContainSingle().Subject;
        sent.Title.Should().Be("Don't lose your streak 🔥");
        sent.Body.Should().Be("Your streak is 3 days. Read an article today to keep it going.");
    }

    [Fact]
    public void The_jobs_are_registered_and_testing_sends_nothing_on_its_own()
    {
        using var scope = api.Services.CreateScope();

        scope.ServiceProvider.GetRequiredService<NotificationPushJob>().Should().NotBeNull();
        scope.ServiceProvider.GetRequiredService<StreakReminderJob>().Should().NotBeNull();
        scope.ServiceProvider.GetRequiredService<INotificationPushSignal>().GetType().Name.Should().Be("NullNotificationPushSignal");
    }

    // ---- Helpers ----

    /// <summary>A user with a complete profile and one Android device; quiet hours off unless asked for.</summary>
    private async Task<(SignedInUser User, string Token)> UserWithDeviceAsync(string uiLanguage = "en", string? displayName = null,
        bool quietHours = false)
    {
        var user = await api.SignUpAsync(uiLanguage);
        var username = $"p_{Guid.NewGuid():N}"[..20];
        displayName ??= "Push Tester";
        (await user.Client.PutAsJsonAsync("/api/v1/me/profile/complete", new { displayName, username }, Ct)).EnsureSuccessStatusCode();
        user.Me["username"] = username;
        user.Me["displayName"] = displayName;

        var token = $"fcm-{Guid.NewGuid():N}";
        (await user.Client.PostAsJsonAsync("/api/v1/me/devices", new { token, platform = "android" }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        if (!quietHours)
        {
            (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
                new { quietHours = new { enabled = false, start = "23:00", end = "07:00" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        }
        return (user, token);
    }

    private async Task<NotificationPushRunResult> PushAsync(IPushSender sender, DateTime utcNow)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var pusher = new NotificationPusher(scope.ServiceProvider.GetRequiredService<IAppDbContext>(), sender, NullLogger<NotificationPusher>.Instance);
        return await pusher.RunAsync(utcNow, Ct);
    }

    private async Task RemindAsync(DateTime utcNow)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<StreakReminders>().RunAsync(utcNow, Ct);
    }

    private Task<Notification> EntryAsync(Guid userId, string type) =>
        InDbAsync(db => db.Notifications.AsNoTracking().SingleAsync(n => n.UserId == userId && n.Type == type, Ct));

    private Task<List<Notification>> RemindersAsync(Guid userId) =>
        InDbAsync(db => db.Notifications.AsNoTracking().Where(n => n.UserId == userId && n.Type == NotificationTypes.StreakReminder).ToListAsync(Ct));

    private static async Task InUtcAsync(SignedInUser user) =>
        (await user.Client.PutAsJsonAsync("/api/v1/me/preferences",
            new { uiLanguage = "en", articleLanguage = "en", theme = "system", timeZone = "UTC", reminderTime = "08:00" }, Ct))
        .StatusCode.Should().Be(HttpStatusCode.NoContent);

    private Task StatsAsync(Guid userId, int streak, DateOnly lastRead) => InDbAsync(async db =>
    {
        var stats = new UserStats(userId);
        stats.Apply(new StreakHistory(streak, streak, lastRead, null, []), streak, DateTime.UtcNow);
        db.UserStats.Add(stats);
        return await db.SaveChangesAsync(Ct);
    });

    private static async Task CommentAsync(SignedInUser user, Guid articleId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
    }

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> query)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    /// <summary>FCM is up, but every device fails for a reason worth retrying.</summary>
    private sealed class FailingDevicesPushSender : IPushSender
    {
        public Task<IReadOnlyList<PushOutcome>> SendAsync(IReadOnlyList<PushNotification> notifications, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<PushOutcome>>([.. notifications.Select(n => new PushOutcome(0, [], n.Tokens.Count))]);
    }
}
