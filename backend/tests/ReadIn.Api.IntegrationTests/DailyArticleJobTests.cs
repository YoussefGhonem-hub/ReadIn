using System.Collections.Concurrent;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Reading;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The daily-article job (F07) against SQL Server: it picks 30 minutes before the reminder time, "sends" one push at the
/// reminder time through a recording <see cref="IPushSender"/>, and <c>GET /feed/today</c> serves the same pick. Users are in
/// UTC with a noon reminder, and each run gets an explicit time on today's UTC date, so the job and the real clock of
/// <c>/feed/today</c> agree on the date.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class DailyArticleJobTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private static readonly DateOnly Today = DateOnly.FromDateTime(DateTime.UtcNow);

    private readonly RecordingPushSender _push = new();

    private static DateTime TodayAt(int hour, int minute) => Today.ToDateTime(new TimeOnly(hour, minute), DateTimeKind.Utc);

    [Fact]
    public async Task The_job_picks_before_the_reminder_pushes_once_at_it_and_today_serves_the_same_article()
    {
        var (user, token) = await ReaderWithDeviceAsync("ar");

        await RunAsync(TodayAt(11, 29));
        (await PickAsync(user.Id)).Should().BeNull("the pick is made 30 minutes before the 12:00 reminder");

        await RunAsync(TodayAt(11, 30));
        var pick = await PickAsync(user.Id);
        pick.Should().NotBeNull();
        pick!.NotifiedAt.Should().BeNull();
        _push.To(token).Should().BeEmpty("the push waits for the reminder time");

        await RunAsync(TodayAt(12, 0));
        await RunAsync(TodayAt(12, 0)); // a retried run
        await RunAsync(TodayAt(12, 5));

        var push = _push.To(token).Should().ContainSingle("the push goes out once a day").Subject;
        push.Title.Should().Be("مقال اليوم جاهز ☕");
        push.Data["type"].Should().Be("daily_article");
        push.Data["articleId"].Should().Be(pick.ArticleId.ToString());
        (await PickAsync(user.Id))!.NotifiedAt.Should().Be(TodayAt(12, 0));

        var today = await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);
        today!["id"]!.GetValue<Guid>().Should().Be(pick.ArticleId, "the pushed article is the hero card");
        push.Data["slug"].Should().Be(today["slug"]!.GetValue<string>());
        push.Data["link"].Should().Be($"readin://a/{today["slug"]!.GetValue<string>()}");
        push.Body.Should().Be(today["title"]!.GetValue<string>(), "the body is the title of the version the user reads");
    }

    [Fact]
    public async Task A_pick_made_by_today_before_the_job_is_the_one_that_gets_pushed()
    {
        var (user, token) = await ReaderWithDeviceAsync("en");

        var today = await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);
        await RunAsync(TodayAt(11, 30));
        await RunAsync(TodayAt(12, 0));

        var push = _push.To(token).Should().ContainSingle().Subject;
        push.Title.Should().Be("Today's article is ready ☕");
        push.Data["articleId"].Should().Be(today!["id"]!.GetValue<Guid>().ToString());
    }

    [Fact]
    public async Task Changing_the_reminder_time_moves_the_next_pick_and_push()
    {
        var (user, token) = await ReaderWithDeviceAsync("en");
        await SetPreferencesAsync(user, "en", reminder: "18:45");

        await RunAsync(TodayAt(12, 0));
        (await PickAsync(user.Id)).Should().BeNull("the new reminder is 18:45");

        await RunAsync(TodayAt(18, 15));
        (await PickAsync(user.Id)).Should().NotBeNull();
        await RunAsync(TodayAt(18, 45));
        _push.To(token).Should().ContainSingle();
    }

    [Fact]
    public async Task Dead_tokens_are_removed_and_a_failed_push_is_retried_on_the_next_run()
    {
        var (user, good) = await ReaderWithDeviceAsync("en");
        var dead = $"dead-{Guid.NewGuid():N}";
        (await user.Client.PostAsJsonAsync("/api/v1/me/devices", new { token = dead, platform = "web" }, Ct)).EnsureSuccessStatusCode();
        _push.InvalidTokens.Add(dead);
        _push.FailOnce.Add(good); // FCM unavailable for the only working device

        await RunAsync(TodayAt(12, 0));
        _push.To(good).Should().BeEmpty();
        (await PickAsync(user.Id))!.NotifiedAt.Should().BeNull("nothing reached a device, so the claim was released");
        (await DeviceTokensAsync(user.Id)).Should().Equal(good);

        await RunAsync(TodayAt(12, 5));
        _push.To(good).Should().ContainSingle();
        (await PickAsync(user.Id))!.NotifiedAt.Should().Be(TodayAt(12, 5));
    }

    [Fact]
    public async Task A_push_missed_by_more_than_two_hours_is_dropped_but_the_hero_card_is_picked()
    {
        var (user, token) = await ReaderWithDeviceAsync("en");

        await RunAsync(TodayAt(14, 1));

        (await PickAsync(user.Id)).Should().NotBeNull();
        _push.To(token).Should().BeEmpty();
    }

    [Fact]
    public async Task Users_without_devices_and_suspended_users_are_skipped()
    {
        var noDevice = await api.SignUpAsync();
        await SetPreferencesAsync(noDevice, "en");
        var (suspended, token) = await ReaderWithDeviceAsync("en");
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            (await db.Users.SingleAsync(u => u.Id == suspended.Id, Ct)).Suspend(until: null);
            await db.SaveChangesAsync(Ct);
        }

        await RunAsync(TodayAt(12, 0));

        (await PickAsync(noDevice.Id)).Should().BeNull("GET /feed/today picks for them on demand");
        (await PickAsync(suspended.Id)).Should().BeNull();
        _push.To(token).Should().BeEmpty();
    }

    [Fact]
    public async Task No_push_for_an_article_already_read_today()
    {
        var (user, token) = await ReaderWithDeviceAsync("en");
        await RunAsync(TodayAt(11, 30));
        var pick = (await PickAsync(user.Id))!;

        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var progress = new ReadingProgress(user.Id, pick.ArticleId, "en", TodayAt(11, 38));
            progress.Record("en", 100, null, activeSecondsDelta: 120, TodayAt(11, 40)).CompletedNow.Should().BeTrue();
            db.ReadingProgress.Add(progress);
            await db.SaveChangesAsync(Ct);
        }

        await RunAsync(TodayAt(12, 0));

        _push.To(token).Should().BeEmpty("\"today's article is ready\" would be noise");
    }

    [Fact]
    public void The_job_is_registered_and_testing_logs_pushes_instead_of_sending_them()
    {
        using var scope = api.Services.CreateScope();

        scope.ServiceProvider.GetRequiredService<DailyArticleJob>().Should().NotBeNull();
        scope.ServiceProvider.GetRequiredService<IPushSender>().GetType().Name.Should().Be("LoggingPushSender", "FCM has no emulator");
    }

    // ---- F17: the notification center entry, the user's mode and quiet hours ----

    [Fact]
    public async Task The_push_carries_its_notification_center_entry_written_once_a_day()
    {
        var (user, token) = await ReaderWithDeviceAsync("en");

        await RunAsync(TodayAt(11, 30));
        await RunAsync(TodayAt(12, 0));
        await RunAsync(TodayAt(12, 5));

        var push = _push.To(token).Should().ContainSingle().Subject;
        var entries = await DailyEntriesAsync(user.Id);
        var entry = entries.Should().ContainSingle("one entry per local date").Subject;
        push.Data["notificationId"].Should().Be(entry.Id.ToString());
        entry.PushStatus.Should().Be(NotificationPushStatus.None, "this job sends the push itself; the push job leaves the entry alone");
        entry.ArticleId.Should().Be((await PickAsync(user.Id))!.ArticleId);

        var center = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications", Ct))!["items"]!.AsArray();
        var item = center.Should().ContainSingle(i => i!["type"]!.GetValue<string>() == "daily_article").Subject!;
        item["id"]!.GetValue<Guid>().Should().Be(entry.Id);
        item["link"]!.GetValue<string>().Should().Be(push.Data["link"]);
        item["article"]!["slug"]!.GetValue<string>().Should().Be(push.Data["slug"]);
        item["isRead"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task In_app_only_writes_the_entry_without_a_push_and_off_writes_nothing()
    {
        var (inApp, inAppToken) = await ReaderWithDeviceAsync("en");
        var (off, offToken) = await ReaderWithDeviceAsync("en");
        await SetDailyModeAsync(inApp, "inApp");
        await SetDailyModeAsync(off, "off");

        await RunAsync(TodayAt(11, 30));
        await RunAsync(TodayAt(12, 0));
        await RunAsync(TodayAt(12, 5));

        _push.To(inAppToken).Should().BeEmpty();
        (await DailyEntriesAsync(inApp.Id)).Should().ContainSingle();
        (await PickAsync(inApp.Id))!.NotifiedAt.Should().Be(TodayAt(12, 0), "the entry is the notification, so the day is done");

        _push.To(offToken).Should().BeEmpty();
        (await DailyEntriesAsync(off.Id)).Should().BeEmpty();
        (await PickAsync(off.Id)).Should().NotBeNull("the hero card is picked either way");
    }

    [Fact]
    public async Task Quiet_hours_hold_the_push_until_they_end_within_the_late_window()
    {
        var (user, token) = await ReaderWithDeviceAsync("en");
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
                new { quietHours = new { enabled = true, start = "11:00", end = "12:30" } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        await RunAsync(TodayAt(11, 30));
        await RunAsync(TodayAt(12, 0));
        _push.To(token).Should().BeEmpty("12:00 UTC is inside the user's quiet hours");
        (await DailyEntriesAsync(user.Id)).Should().ContainSingle("the entry is there anyway");
        (await PickAsync(user.Id))!.NotifiedAt.Should().BeNull();

        await RunAsync(TodayAt(12, 30));
        _push.To(token).Should().ContainSingle();
        (await DailyEntriesAsync(user.Id)).Should().ContainSingle();
    }

    /// <summary>One job run in its own scope, like Hangfire, with the recording sender.</summary>
    private async Task RunAsync(DateTime utcNow)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var delivery = new DailyArticleDelivery(
            scope.ServiceProvider.GetRequiredService<IAppDbContext>(),
            scope.ServiceProvider.GetRequiredService<DailyArticlePicker>(),
            _push,
            scope.ServiceProvider.GetRequiredService<NotificationWriter>(),
            NullLogger<DailyArticleDelivery>.Instance);
        await delivery.RunAsync(utcNow, Ct);
    }

    private static async Task SetDailyModeAsync(SignedInUser user, string mode) =>
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new Dictionary<string, string> { ["daily_article"] = mode } }, Ct))
        .StatusCode.Should().Be(HttpStatusCode.NoContent);

    private async Task<List<Notification>> DailyEntriesAsync(Guid userId)
    {
        using var scope = api.Services.CreateScope();
        return await scope.ServiceProvider.GetRequiredService<AppDbContext>().Notifications.AsNoTracking()
            .Where(n => n.UserId == userId && n.Type == NotificationTypes.DailyArticle)
            .ToListAsync(Ct);
    }

    /// <summary>A new reader in UTC with a 12:00 reminder, three interests and one Android device.</summary>
    private async Task<(SignedInUser User, string Token)> ReaderWithDeviceAsync(string uiLanguage)
    {
        var user = await api.SignUpAsync(uiLanguage);
        await SetPreferencesAsync(user, uiLanguage);

        var fields = (await user.Client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Select(f => f!["id"]!.GetValue<Guid>()).Take(3).ToList();
        (await user.Client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = fields, topicIds = Array.Empty<Guid>() }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        var token = $"fcm-{Guid.NewGuid():N}";
        (await user.Client.PostAsJsonAsync("/api/v1/me/devices", new { token, platform = "android" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        return (user, token);
    }

    private static async Task SetPreferencesAsync(SignedInUser user, string uiLanguage, string reminder = "12:00") =>
        (await user.Client.PutAsJsonAsync("/api/v1/me/preferences",
            new { uiLanguage, articleLanguage = "ar-EG", theme = "system", timeZone = "UTC", reminderTime = reminder }, Ct))
        .StatusCode.Should().Be(HttpStatusCode.NoContent);

    private async Task<DailyPick?> PickAsync(Guid userId)
    {
        using var scope = api.Services.CreateScope();
        return await scope.ServiceProvider.GetRequiredService<AppDbContext>().DailyPicks.AsNoTracking()
            .SingleOrDefaultAsync(p => p.UserId == userId && p.Date == Today, Ct);
    }

    private async Task<List<string>> DeviceTokensAsync(Guid userId)
    {
        using var scope = api.Services.CreateScope();
        return await scope.ServiceProvider.GetRequiredService<AppDbContext>().Users
            .Where(u => u.Id == userId).SelectMany(u => u.Devices.Select(d => d.Token)).ToListAsync(Ct);
    }
}

/// <summary>Records what would go to FCM; tokens can be made to fail permanently (invalid) or once (FCM unavailable).</summary>
internal sealed class RecordingPushSender : IPushSender
{
    private readonly ConcurrentQueue<PushNotification> _sent = new();

    public HashSet<string> InvalidTokens { get; } = [];
    public HashSet<string> FailOnce { get; } = [];

    public IReadOnlyList<PushNotification> To(string token) => _sent.Where(n => n.Tokens.Contains(token)).ToList();

    public Task<IReadOnlyList<PushOutcome>> SendAsync(IReadOnlyList<PushNotification> notifications, CancellationToken cancellationToken = default)
    {
        var outcomes = new List<PushOutcome>(notifications.Count);
        foreach (var notification in notifications)
        {
            var invalid = notification.Tokens.Where(InvalidTokens.Contains).ToList();
            var failed = notification.Tokens.Where(FailOnce.Remove).ToList();
            var delivered = notification.Tokens.Except(invalid).Except(failed).ToList();
            if (delivered.Count > 0) _sent.Enqueue(notification with { Tokens = delivered });
            outcomes.Add(new PushOutcome(delivered.Count, invalid, failed.Count));
        }
        return Task.FromResult<IReadOnlyList<PushOutcome>>(outcomes);
    }
}
