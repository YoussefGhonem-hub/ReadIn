using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Application.Features.Notifications;
using ReadIn.Application.Features.Notifications.EventHandlers;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Notifications;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The official @readin account's new articles (contract-v1 "The official @readin account's articles, grouped per day"):
/// one <c>followed_writer_article</c> entry per follower per day that counts them, one push for a batch, the profile link
/// from two articles, and a new entry once the day's entry was read. The account is a test writer made a system account
/// for the test (and made a member again after it), so the real @readin account and its followers stay as they are.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class OfficialAccountNotificationTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task The_official_accounts_articles_of_a_day_are_one_entry_and_one_push_per_follower()
    {
        var account = await api.UserAsync("ReadIn");
        var username = account.Me["username"]!.GetValue<string>();
        var (arabic, arabicToken) = await FollowerWithDeviceAsync(account, "ar");
        var (_, englishToken) = await FollowerWithDeviceAsync(account, "en");
        await SetSystemAccountAsync(account.Id, true);
        try
        {
            var (_, firstSlug) = await account.Client.PublishAsync("Official article one");
            var one = (await ListAsync(arabic)).Should().ContainSingle().Subject!;
            one["type"]!.GetValue<string>().Should().Be("followed_writer_article");
            one["data"]!["articleCount"]!.GetValue<int>().Should().Be(1);
            one["link"]!.GetValue<string>().Should().Be($"readin://a/{firstSlug}", "one article opens it");

            var started = DateTime.UtcNow;
            var (second, _) = await account.Client.PublishAsync("Official article two");
            var (third, _) = await account.Client.PublishAsync("Official article three");

            var day = (await ListAsync(arabic)).Should().ContainSingle("the day's articles are one entry").Subject!;
            day["id"]!.GetValue<Guid>().Should().Be(one["id"]!.GetValue<Guid>());
            day["data"]!["articleCount"]!.GetValue<int>().Should().Be(3);
            day["article"]!["id"]!.GetValue<Guid>().Should().Be(third, "the newest article is shown");
            (day["actor"]!["id"]!.GetValue<Guid>(), day["actorCount"]!.GetValue<int>()).Should().Be((account.Id, 1));
            day["link"]!.GetValue<string>().Should().Be($"readin://u/{username}", "several articles open the account's profile");
            day["isRead"]!.GetValue<bool>().Should().BeFalse();

            var entry = await EntryAsync(arabic.Id);
            entry.GroupKey.Should().Be(OfficialArticles.GroupKey(account.Id, DailySchedule.LocalDate(DateTime.UtcNow, "Africa/Cairo")));
            entry.PushStatus.Should().Be(NotificationPushStatus.Pending);
            entry.PushAfter.Should().BeOnOrAfter(started + OfficialArticles.PushDelay, "the push waits for the batch to end");

            // A retried event (the outbox delivers at least once) changes nothing.
            await RedeliverAsync(new ArticlePublishedDomainEvent(second, account.Id, Guid.Empty, "ignored"));
            var retried = await EntryAsync(arabic.Id);
            (retried.UpdatedAt, retried.Data).Should().Be((entry.UpdatedAt, entry.Data));

            // One push per follower, once the batch is over, in their language.
            var push = new RecordingPushSender();
            await PushAsync(push, DateTime.UtcNow.AddMinutes(1));
            push.To(arabicToken).Should().BeEmpty("it waits 10 minutes after the latest article");
            await PushAsync(push, DateTime.UtcNow + OfficialArticles.PushDelay + TimeSpan.FromMinutes(1));
            var sent = push.To(arabicToken).Should().ContainSingle().Subject;
            (sent.Title, sent.Body).Should().Be(("نشر ⁨ReadIn⁩ 3 مقالات جديدة", "Official article three"));
            sent.CollapseKey.Should().Be(entry.GroupKey);
            sent.Data.Should().BeEquivalentTo(new Dictionary<string, string>
            {
                ["type"] = "followed_writer_article",
                ["notificationId"] = entry.Id.ToString(),
                ["link"] = $"readin://u/{username}",
            }, "a profile link has no article language");
            push.To(englishToken).Should().ContainSingle().Which.Title.Should().Be("⁨ReadIn⁩ published 3 new articles");

            // Once read, the next article starts a new entry of its own.
            (await arabic.Client.PostAsync($"/api/v1/me/notifications/{entry.Id}/read", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
            var (fourth, fourthSlug) = await account.Client.PublishAsync("Official article four");
            var entries = await ListAsync(arabic);
            entries.Should().HaveCount(2);
            entries[0]!["article"]!["id"]!.GetValue<Guid>().Should().Be(fourth);
            entries[0]!["data"]!["articleCount"]!.GetValue<int>().Should().Be(1);
            entries[0]!["link"]!.GetValue<string>().Should().Be($"readin://a/{fourthSlug}");
            entries[1]!["data"]!["articleCount"]!.GetValue<int>().Should().Be(3);
        }
        finally
        {
            await SetSystemAccountAsync(account.Id, false);
        }
    }

    [Fact]
    public async Task A_follower_who_turned_the_type_off_gets_nothing_and_other_writers_still_give_one_entry_per_article()
    {
        var account = await api.UserAsync("ReadIn");
        var writer = await api.UserAsync("Ordinary Writer");
        var (off, _) = await FollowerWithDeviceAsync(account, "en");
        await off.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        (await off.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new { followed_writer_article = "off" } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var (reader, _) = await FollowerWithDeviceAsync(account, "en");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        await SetSystemAccountAsync(account.Id, true);
        try
        {
            await account.Client.PublishAsync("Official article A");
            await account.Client.PublishAsync("Official article B");
            await writer.Client.PublishAsync("Ordinary article A");
            await writer.Client.PublishAsync("Ordinary article B");

            (await ListAsync(off)).Should().BeEmpty("the followed_writer_article setting covers the official account too");
            var entries = await ListAsync(reader);
            entries.Where(e => e!["actor"]!["id"]!.GetValue<Guid>() == writer.Id).Should().HaveCount(2, "other writers: one entry per article")
                .And.OnlyContain(e => e!["data"]!["articleCount"] == null);
            entries.Where(e => e!["actor"]!["id"]!.GetValue<Guid>() == account.Id).Should().ContainSingle()
                .Which!["data"]!["articleCount"]!.GetValue<int>().Should().Be(2);
        }
        finally
        {
            await SetSystemAccountAsync(account.Id, false);
        }
    }

    // ---- Helpers ----

    /// <summary>A follower of <paramref name="account"/> with one Android device and quiet hours off (time zone Africa/Cairo).</summary>
    private async Task<(SignedInUser User, string Token)> FollowerWithDeviceAsync(SignedInUser account, string uiLanguage)
    {
        var user = await api.SignUpAsync(uiLanguage);
        var token = $"fcm-{Guid.NewGuid():N}";
        (await user.Client.PostAsJsonAsync("/api/v1/me/devices", new { token, platform = "android" }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { quietHours = new { enabled = false, start = "23:00", end = "07:00" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.PutAsJsonAsync("/api/v1/me/preferences",
            new { uiLanguage, articleLanguage = "en", theme = "system", timeZone = "Africa/Cairo", reminderTime = "08:00" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        await user.Client.PutEmptyAsync($"/api/v1/users/{account.Id}/follow").OkJsonAsync();
        return (user, token);
    }

    private Task SetSystemAccountAsync(Guid userId, bool system) => InDbAsync(db =>
        db.Users.IgnoreQueryFilters().Where(u => u.Id == userId).ExecuteUpdateAsync(s => s.SetProperty(u => u.IsSystemAccount, system), Ct));

    private static async Task<List<JsonNode?>> ListAsync(SignedInUser user) =>
        [.. (await user.Client.GetAsync("/api/v1/me/notifications?limit=50", Ct).OkJsonAsync())["items"]!.AsArray()];

    private Task<Notification> EntryAsync(Guid userId) => InDbAsync(db => db.Notifications.AsNoTracking()
        .Where(n => n.UserId == userId && n.Type == NotificationTypes.FollowedWriterArticle)
        .OrderByDescending(n => n.UpdatedAt)
        .FirstAsync(Ct));

    private async Task RedeliverAsync(ArticlePublishedDomainEvent domainEvent)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await ActivatorUtilities.CreateInstance<FollowedWriterArticleNotificationHandler>(scope.ServiceProvider).Handle(domainEvent, Ct);
    }

    private async Task PushAsync(IPushSender sender, DateTime utcNow)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var pusher = new NotificationPusher(scope.ServiceProvider.GetRequiredService<IAppDbContext>(), sender, NullLogger<NotificationPusher>.Instance);
        await pusher.RunAsync(utcNow, Ct);
    }

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> query)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }
}
