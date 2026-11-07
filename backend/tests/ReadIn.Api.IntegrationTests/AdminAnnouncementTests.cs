using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Announcements of the admin console (SPEC F23) against SQL Server: who they reach (a field's readers, a language's
/// readers, not the sender, not who turned them off), one a day, the test to yourself, the entries and pushes they become,
/// validation and the audit log. Tests share one database and "one a day": each send first deletes today's announcement.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminAnnouncementTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Every_announcement_route_is_for_notifications_broadcast_only()
    {
        var body = Body(audience: new { type = "all" });
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/announcements");
        await api.AssertAdminOnlyAsync(HttpMethod.Post, "/api/v1/admin/announcements/preview", body);
        await api.AssertAdminOnlyAsync(HttpMethod.Post, "/api/v1/admin/announcements/test", body);
        await api.AssertAdminOnlyAsync(HttpMethod.Post, "/api/v1/admin/announcements", body);

        // A staff role holding only notifications.broadcast may use them.
        var broadcaster = await api.UserWithPermissionsAsync("Broadcaster", "notifications.broadcast");
        await broadcaster.Client.GetAsync("/api/v1/admin/announcements", Ct).OkJsonAsync();
        await broadcaster.Client.PostAsJsonAsync("/api/v1/admin/announcements/preview", body, Ct).OkJsonAsync();
    }

    [Fact]
    public async Task The_text_the_audience_and_the_link_are_checked()
    {
        var admin = await api.SuperAdminAsync();
        const string url = "/api/v1/admin/announcements/preview";

        var empty = await admin.Client.PostAsJsonAsync(url, new { }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        empty["errors"]!.AsObject().Select(e => e.Key).Should().BeEquivalentTo("titleAr", "titleEn", "bodyAr", "bodyEn", "audience");
        empty["errors"]!["titleAr"]!.AsArray().Select(c => c!.GetValue<string>()).Should().Equal("validation.required");

        var tooLong = await admin.Client.PostAsJsonAsync(url,
                Body(titleEn: new string('x', 61), bodyAr: "  " + new string('ب', 181) + "  ", audience: new { type = "all" }), Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        tooLong["errors"]!.AsObject().Select(e => e.Key).Should().BeEquivalentTo("titleEn", "bodyAr");
        tooLong["errors"]!["titleEn"]!.AsArray().Select(c => c!.GetValue<string>()).Should().Equal("validation.max_length");
        // 60 / 180 after trimming are fine.
        await admin.Client.PostAsJsonAsync(url, Body(titleEn: $"  {new string('x', 60)}  ", bodyEn: new string('y', 180), audience: new { type = "all" }), Ct)
            .OkJsonAsync();

        (await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "everyone" }), Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!["audience.type"]!.AsArray()
            .Select(c => c!.GetValue<string>()).Should().Equal("validation.invalid");
        (await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "language", language = "fr" }), Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!["audience.language"].Should().NotBeNull();
        (await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "field" }), Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!["audience.fieldId"].Should().NotBeNull();
        (await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "all" }, link: new { type = "video", id = Guid.NewGuid() }), Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!["link.type"].Should().NotBeNull();

        await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "field", fieldId = Guid.NewGuid() }), Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
        await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "all" }, link: new { type = "article", id = Guid.NewGuid() }), Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "announcement.link_invalid");
        await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "all" }, link: new { type = "path", id = Guid.NewGuid() }), Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "announcement.link_invalid");

        // An article readers can open and a published path are fine.
        var (articleId, _) = await (await api.UserAsync("Linked Writer")).Client.PublishAsync("An article worth announcing");
        await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "all" }, link: new { type = "article", id = articleId }), Ct).OkJsonAsync();
        var pathId = await api.InDbAsync(db => db.LearningPaths.Where(p => p.IsPublished).Select(p => p.Id).FirstAsync(Ct));
        await admin.Client.PostAsJsonAsync(url, Body(audience: new { type = "all" }, link: new { type = "path", id = pathId }), Ct).OkJsonAsync();
    }

    [Fact]
    public async Task The_preview_counts_a_fields_readers_and_a_languages_readers_but_not_the_sender_or_who_turned_it_off()
    {
        var admin = await api.SuperAdminAsync();
        var (field, others) = await FieldsAsync(admin.Client);
        var byField = Body(audience: new { type = "field", fieldId = field });
        var english = Body(audience: new { type = "language", language = "en" });

        var before = await PreviewAsync(admin.Client, byField);
        var beforeEnglish = await PreviewAsync(admin.Client, english);
        before["canSend"]!.GetValue<bool>().Should().Be(before["nextAllowedAt"] is null);

        // Follows the field itself, with a device: a recipient and a push.
        var fieldReader = await api.UserAsync("Field Reader");
        await FollowAsync(fieldReader.Client, [field, .. others]);
        await DeviceAsync(fieldReader.Client);
        // Follows only topics of the field: a reader of the field too, but no device.
        var topicReader = await api.UserAsync("Topic Reader");
        var topics = (await topicReader.Client.GetFromJsonAsync<JsonArray>($"/api/v1/fields/{await SlugAsync(admin.Client, field)}/topics", Ct))!
            .Take(3).Select(t => t!["id"]!.GetValue<Guid>()).ToList();
        (await topicReader.Client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = others, topicIds = topics }, Ct)).EnsureSuccessStatusCode();
        // Turned announcements off: not counted.
        var silent = await api.UserAsync("No Announcements");
        await FollowAsync(silent.Client, [field, .. others]);
        await NotificationsTests.SetModeAsync(silent, "announcement", "off");
        // In-app only: counted, without a push.
        var inApp = await api.UserAsync("In App Reader");
        await FollowAsync(inApp.Client, [field, .. others]);
        await DeviceAsync(inApp.Client);
        await NotificationsTests.SetModeAsync(inApp, "announcement", "inApp");
        // The sender follows it too but never counts.
        await FollowAsync(admin.Client, [field, .. others]);

        var after = await PreviewAsync(admin.Client, byField);
        (after["recipientCount"]!.GetValue<int>() - before["recipientCount"]!.GetValue<int>()).Should().Be(3);
        (after["pushCount"]!.GetValue<int>() - before["pushCount"]!.GetValue<int>()).Should().Be(1);

        // A reader whose article language is English.
        var englishReader = await api.UserAsync("English Reader");
        (await englishReader.Client.PutAsJsonAsync("/api/v1/me/preferences",
            new { uiLanguage = "en", articleLanguage = "en", theme = "system", timeZone = "UTC", reminderTime = "08:00" }, Ct)).EnsureSuccessStatusCode();
        var afterEnglish = await PreviewAsync(admin.Client, english);
        (afterEnglish["recipientCount"]!.GetValue<int>() - beforeEnglish["recipientCount"]!.GetValue<int>()).Should().Be(1);

        // A suspended reader is no recipient.
        await api.InDbAsync(async db =>
        {
            var user = await db.Users.SingleAsync(u => u.Id == fieldReader.Id, Ct);
            user.Suspend(null);
            await db.SaveChangesAsync(Ct);
        });
        (await PreviewAsync(admin.Client, byField))["recipientCount"]!.GetValue<int>().Should().Be(after["recipientCount"]!.GetValue<int>() - 1);
    }

    [Fact]
    public async Task Sending_writes_an_entry_per_recipient_pushes_it_and_allows_one_a_day()
    {
        await ClearTodayAsync();
        var admin = await api.SuperAdminAsync();
        var (field, others) = await FieldsAsync(admin.Client);
        var (articleId, slug) = await (await api.UserAsync("Announced Writer")).Client.PublishAsync("Read this, everyone", language: "en");

        var arabicReader = await UserInAsync("ar", "قارئ عربي");
        await FollowAsync(arabicReader.Client, [field, .. others]);
        var token = await DeviceAsync(arabicReader.Client);
        await NoQuietHoursAsync(arabicReader);
        var englishReader = await UserInAsync("en", "English Field Reader");
        await FollowAsync(englishReader.Client, [field, .. others]);
        var silent = await api.UserAsync("Silent Field Reader");
        await FollowAsync(silent.Client, [field, .. others]);
        await NotificationsTests.SetModeAsync(silent, "announcement", "off");
        await FollowAsync(admin.Client, [field, .. others]);

        var sent = await admin.Client.PostAsJsonAsync("/api/v1/admin/announcements", Body(
            titleAr: "مقال جديد", titleEn: "A new article", bodyAr: "اقرأه الآن.", bodyEn: "Read it now.",
            audience: new { type = "field", fieldId = field }, link: new { type = "article", id = articleId }), Ct);
        var sentBody = await sent.Content.ReadAsStringAsync(Ct);
        sent.StatusCode.Should().Be(HttpStatusCode.Accepted, sentBody);
        var dto = JsonNode.Parse(sentBody)!.AsObject();
        dto.Select(p => p.Key).Should().BeEquivalentTo("id", "titleAr", "titleEn", "bodyAr", "bodyEn", "link", "audience", "status", "recipientCount",
            "sentBy", "createdAt", "completedAt");
        var id = dto["id"]!.GetValue<Guid>();
        // Hangfire is off in tests: the outbox wrote the entries before the answer.
        dto["status"]!.GetValue<string>().Should().Be("sent");
        dto["recipientCount"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(2);
        dto["link"]!["slug"]!.GetValue<string>().Should().Be(slug);
        dto["audience"]!["type"]!.GetValue<string>().Should().Be("field");
        dto["audience"]!["field"]!["id"]!.GetValue<Guid>().Should().Be(field);
        dto["sentBy"]!["id"]!.GetValue<Guid>().Should().Be(admin.Id);

        // Each reader gets it in their UI language, linking to the article; the sender and who turned it off don't.
        var arabicEntry = await EntryAsync(arabicReader.Client);
        arabicEntry["data"]!["title"]!.GetValue<string>().Should().Be("مقال جديد");
        arabicEntry["data"]!["body"]!.GetValue<string>().Should().Be("اقرأه الآن.");
        arabicEntry["data"]!["announcementId"]!.GetValue<Guid>().Should().Be(id);
        arabicEntry["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}");
        arabicEntry["actor"].Should().BeNull();
        var englishEntry = await EntryAsync(englishReader.Client, "en");
        englishEntry["data"]!["title"]!.GetValue<string>().Should().Be("A new article");
        (await EntriesAsync(admin.Id)).Should().Be(0);
        (await EntriesAsync(silent.Id)).Should().Be(0);

        // The push job sends it in the reader's language, collapsing on the announcement.
        var push = new RecordingPushSender();
        await PushAsync(push);
        var pushed = push.To(token).Should().ContainSingle().Subject;
        (pushed.Title, pushed.Body).Should().Be(("مقال جديد", "اقرأه الآن."));
        pushed.CollapseKey.Should().Be($"announcement:{id}");
        pushed.Data["type"].Should().Be("announcement");
        pushed.Data["announcementId"].Should().Be(id.ToString());
        pushed.Data["link"].Should().Be($"readin://a/{slug}");
        pushed.Data["lang"].Should().Be("en");

        // Audited, with the announcement as the target.
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a =>
            a.Action == AuditActions.AnnouncementSent && a.ActorId == admin.Id && a.TargetType == AuditTargets.Announcement && a.TargetId == id, Ct)))
            .Should().Be(1);

        // One a day.
        await admin.Client.PostAsJsonAsync("/api/v1/admin/announcements", Body(audience: new { type = "all" }), Ct)
            .ProblemAsync(HttpStatusCode.TooManyRequests, "announcement.limit");
        var list = await admin.Client.GetAsync("/api/v1/admin/announcements", Ct).OkJsonAsync();
        list["canSend"]!.GetValue<bool>().Should().BeFalse();
        list["nextAllowedAt"]!.GetValue<DateTime>().Should().BeAfter(DateTime.UtcNow);
        list["items"]![0]!["id"]!.GetValue<Guid>().Should().Be(id);
        (await PreviewAsync(admin.Client, Body(audience: new { type = "all" })))["canSend"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task A_send_to_nobody_is_refused_and_takes_no_days_slot()
    {
        await ClearTodayAsync();
        var admin = await api.SuperAdminAsync();
        // A field nobody follows, made for this test and disabled again after it (so it leaves no trace in public lists).
        var field = Field.CreateByAdmin($"test-empty-{Guid.NewGuid():N}"[..30], "حقل فارغ", "Empty field", "code", "primary", 9999, false, false,
            isEnabled: true, DateTime.UtcNow);
        await api.InDbAsync(async db =>
        {
            db.Fields.Add(field);
            await db.SaveChangesAsync(Ct);
        });
        try
        {
            await admin.Client.PostAsJsonAsync("/api/v1/admin/announcements", Body(audience: new { type = "field", fieldId = field.Id }), Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "announcement.no_recipients");
            (await admin.Client.GetAsync("/api/v1/admin/announcements", Ct).OkJsonAsync())["canSend"]!.GetValue<bool>().Should().BeTrue();
        }
        finally
        {
            await api.InDbAsync(db => db.Fields.Where(f => f.Id == field.Id).ExecuteUpdateAsync(set => set.SetProperty(f => f.IsEnabled, false), Ct));
        }
    }

    [Fact]
    public async Task A_test_comes_to_the_sender_alone_at_once_and_is_not_the_days_announcement()
    {
        await ClearTodayAsync();
        var admin = await api.SuperAdminAsync();
        var token = await DeviceAsync(admin.Client);
        // Announcements off and quiet hours all day: a test still comes now.
        await NotificationsTests.SetModeAsync(admin, "announcement", "off");
        (await admin.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { quietHours = new { enabled = true, start = "00:00", end = "23:59" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var pathId = await api.InDbAsync(db => db.LearningPaths.Where(p => p.IsPublished).Select(p => p.Id).FirstAsync(Ct));
        var pathSlug = await api.InDbAsync(db => db.LearningPaths.Where(p => p.Id == pathId).Select(p => p.Slug).FirstAsync(Ct));

        await admin.Client.PostAsJsonAsync("/api/v1/admin/announcements/test",
                Body(titleEn: "Testing", bodyEn: "Only you see this.", audience: new { type = "all" }, link: new { type = "path", id = pathId }), Ct)
            .NoContentAsync();

        var entry = await EntryAsync(admin.Client, "en");
        entry["data"]!["title"]!.GetValue<string>().Should().Be("Testing");
        entry["data"]!["body"]!.GetValue<string>().Should().Be("Only you see this.");
        entry["link"]!.GetValue<string>().Should().Be($"readin://paths/{pathSlug}");

        var push = new RecordingPushSender();
        await PushAsync(push);
        push.To(token).Should().ContainSingle().Which.Data["link"].Should().Be($"readin://paths/{pathSlug}");

        (await api.InDbAsync(db => db.Announcements.CountAsync(a => a.SentById == admin.Id, Ct))).Should().Be(0);
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.AnnouncementTested && a.ActorId == admin.Id, Ct)))
            .Should().Be(1);
        (await admin.Client.GetAsync("/api/v1/admin/announcements", Ct).OkJsonAsync())["canSend"]!.GetValue<bool>().Should().BeTrue();
    }

    [Fact]
    public async Task Announcements_are_a_setting_of_their_own()
    {
        var user = await api.UserAsync();
        var settings = await user.Client.GetAsync("/api/v1/me/notification-settings", Ct).OkJsonAsync();
        settings["types"]!.AsObject().Select(t => t.Key).Should().Contain("announcement").And.HaveCount(10);
        await NotificationsTests.SetModeAsync(user, "announcement", "inApp");
        (await user.Client.GetAsync("/api/v1/me/notification-settings", Ct).OkJsonAsync())["types"]!["announcement"]!.GetValue<string>()
            .Should().Be("inApp");
    }

    // ---- helpers ----

    private static object Body(
        string titleAr = "إعلان", string titleEn = "Announcement", string bodyAr = "نص الإعلان.", string bodyEn = "The announcement's text.",
        object? audience = null, object? link = null) =>
        new { titleAr, titleEn, bodyAr, bodyEn, audience, link };

    /// <summary>A user whose UI language (the push's language) is <paramref name="uiLanguage"/>.</summary>
    private async Task<SignedInUser> UserInAsync(string uiLanguage, string displayName)
    {
        var user = await api.SignUpAsync(uiLanguage);
        (await user.Client.PutAsJsonAsync("/api/v1/me/profile/complete",
            new { displayName, username = $"a_{Guid.NewGuid():N}"[..20] }, Ct)).EnsureSuccessStatusCode();
        return user;
    }

    private static Task<JsonObject> PreviewAsync(HttpClient client, object body) =>
        client.PostAsJsonAsync("/api/v1/admin/announcements/preview", body, Ct).OkJsonAsync();

    /// <summary>The last enabled field (the audience) and two others (interests need three).</summary>
    /// <summary>The last enabled field with at least 3 topics (the topic reader follows 3 of them), and two others.</summary>
    private static async Task<(Guid Field, Guid[] Others)> FieldsAsync(HttpClient client)
    {
        var fields = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!;
        var ids = fields.Select(f => f!["id"]!.GetValue<Guid>()).ToList();
        var field = fields.Last(f => f!["topicCount"]!.GetValue<int>() >= 3)!["id"]!.GetValue<Guid>();
        return (field, [.. ids.Where(id => id != field).Take(2)]);
    }

    private static async Task<string> SlugAsync(HttpClient client, Guid fieldId) =>
        (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!.Single(f => f!["id"]!.GetValue<Guid>() == fieldId)!["slug"]!.GetValue<string>();

    private static async Task FollowAsync(HttpClient client, Guid[] fieldIds) =>
        (await client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds, topicIds = Array.Empty<Guid>() }, Ct)).EnsureSuccessStatusCode();

    private static async Task<string> DeviceAsync(HttpClient client)
    {
        var token = $"fcm-{Guid.NewGuid():N}";
        (await client.PostAsJsonAsync("/api/v1/me/devices", new { token, platform = "android" }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        return token;
    }

    private static async Task NoQuietHoursAsync(SignedInUser user) =>
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { quietHours = new { enabled = false, start = "23:00", end = "07:00" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

    private static async Task<JsonObject> EntryAsync(HttpClient client, string uiLanguage = "ar")
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/me/notifications?limit=50");
        request.Headers.AcceptLanguage.ParseAdd(uiLanguage);
        var page = await client.SendAsync(request, Ct).OkJsonAsync();
        return page["items"]!.AsArray().Where(i => i!["type"]!.GetValue<string>() == "announcement").Should().ContainSingle().Subject!.AsObject();
    }

    private Task<int> EntriesAsync(Guid userId) =>
        api.InDbAsync(db => db.Notifications.CountAsync(n => n.UserId == userId && n.Type == NotificationTypes.Announcement, Ct));

    private Task ClearTodayAsync() => api.InDbAsync(db => db.Announcements.ExecuteDeleteAsync(Ct));

    private async Task PushAsync(IPushSender sender)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var pusher = new NotificationPusher(scope.ServiceProvider.GetRequiredService<IAppDbContext>(), sender, NullLogger<NotificationPusher>.Instance);
        await pusher.RunAsync(DateTime.UtcNow.AddSeconds(1), Ct);
    }
}
