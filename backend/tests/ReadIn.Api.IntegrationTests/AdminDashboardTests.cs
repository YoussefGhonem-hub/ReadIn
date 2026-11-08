using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Admin;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Reading;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F23 console badge and dashboard against SQL Server: who may ask, the badge counts per permission, the period's numbers
/// and the previous period's, the charts, the top lists, the content pipeline, and the 60-second cache. Tests share one
/// database, so every number is checked as a change on fresh data.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminDashboardTests(ApiFactory api)
{
    private const string DashboardTag = "admin-dashboard";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task The_badge_and_the_dashboard_are_for_the_console_only()
    {
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/summary");
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/dashboard");
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/dashboard?period=30d");

        var admin = await api.SuperAdminAsync();
        var summary = await admin.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync();
        summary.Select(p => p.Key).Should().BeEquivalentTo("openReports", "openTickets", "pendingVerifications", "total", "openReportsOver24h"); // F22
        // F35: the tickets waiting for support (Open).
        summary["openTickets"]!.GetValue<int>().Should().Be(
            await api.InDbAsync(db => db.SupportTickets.CountAsync(t => t.Status == Domain.Support.SupportTicketStatus.Open, Ct)));

        foreach (var period in AdminPeriods.All)
        {
            var dashboard = await admin.Client.GetAsync($"/api/v1/admin/dashboard?period={period}", Ct).OkJsonAsync();
            dashboard.Select(p => p.Key).Should().BeEquivalentTo(
                "period", "timeZone", "from", "to", "fromDate", "toDate", "generatedAt", "cards", "charts", "topArticles", "topWriters",
                "missedSearches", "streakRetention", "contentPipeline");
            dashboard["period"]!.GetValue<string>().Should().Be(period);
            dashboard["timeZone"]!.GetValue<string>().Should().Be("Africa/Cairo");
            dashboard["cards"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo(
                "articlesPublished", "newUsers", "activeReaders", "reads", "comments", "reactions", "reposts", "openReports", "openTickets",
                "pendingVerifications", "suspendedNow", "openReportsOver24h"); // openReportsOver24h: F22 store requirements
            dashboard["cards"]!["newUsers"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("value", "previous", "phone", "google", "apple");
            dashboard["cards"]!["reads"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("value", "previous");
            dashboard["charts"]!.AsArray().Should().HaveCount(30);
        }

        // Without a period it is today's.
        (await admin.Client.GetAsync("/api/v1/admin/dashboard", Ct).OkJsonAsync())["period"]!.GetValue<string>().Should().Be("today");
    }

    [Theory]
    [InlineData("week")]
    [InlineData("1d")]
    [InlineData("90d")]
    public async Task An_unknown_period_is_a_validation_error(string period)
    {
        var admin = await api.SuperAdminAsync();
        var problem = await admin.Client.GetAsync($"/api/v1/admin/dashboard?period={period}", Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        problem["errors"]!["period"]!.AsArray().Select(c => c!.GetValue<string>()).Should().Equal("validation.invalid");
    }

    [Fact]
    public async Task The_badge_counts_what_each_permission_opens()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("Badge Author");
        var reporter = await api.UserAsync("Badge Reporter");
        var (articleId, _) = await author.Client.PublishAsync();
        var before = await admin.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync();

        (await reporter.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "article", targetId = articleId, reason = "spam" }, Ct))
            .EnsureSuccessStatusCode();
        // A second report on the same target is the same case: the badge counts targets.
        (await admin.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "article", targetId = articleId, reason = "other" }, Ct))
            .EnsureSuccessStatusCode();

        var after = await admin.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync();
        after["openReports"]!.GetValue<int>().Should().Be(before["openReports"]!.GetValue<int>() + 1);
        after["pendingVerifications"]!.GetValue<int>().Should().Be(before["pendingVerifications"]!.GetValue<int>());
        after["total"]!.GetValue<int>().Should().Be(
            after["openReports"]!.GetValue<int>() + after["openTickets"]!.GetValue<int>() + after["pendingVerifications"]!.GetValue<int>());
        after["total"]!.GetValue<int>().Should().Be(before["total"]!.GetValue<int>() + 1);

        // An account with the console but none of the queues sees no counts.
        var consoleOnly = await api.UserWithPermissionsAsync("Console Only", "admin.access");
        var bare = await consoleOnly.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync();
        (bare["openReports"], bare["openTickets"], bare["pendingVerifications"]).Should().Be((null, null, null));
        bare["total"]!.GetValue<int>().Should().Be(0);
        var dashboard = await consoleOnly.Client.GetAsync("/api/v1/admin/dashboard", Ct).OkJsonAsync();
        (dashboard["cards"]!["openReports"], dashboard["cards"]!["openTickets"], dashboard["cards"]!["pendingVerifications"])
            .Should().Be((null, null, null));
    }

    [Fact]
    public async Task The_dashboard_counts_the_period_and_the_previous_one()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("Dashboard Author");
        var window = await WindowAsync(AdminPeriods.Today);
        await api.DropCacheAsync(DashboardTag);
        var before = await DashboardAsync(admin.Client, AdminPeriods.Today);
        var yesterdayBefore = await DashboardAsync(admin.Client, AdminPeriods.Yesterday);

        var (articleId, slug) = await author.Client.PublishAsync($"Dashboard top article {Guid.NewGuid():N}");
        var readers = new List<SignedInUser>();
        for (var i = 0; i < 12; i++) readers.Add(await api.SignUpAsync());
        var now = DateTime.UtcNow;
        await api.InDbAsync(async db =>
        {
            foreach (var reader in readers) db.ReadingProgress.Add(ReadingProgress.SeededCompleted(reader.Id, articleId, "en", 120, now));
            // A read in the previous period: yesterday, just after midnight.
            db.ReadingProgress.Add(ReadingProgress.SeededCompleted(admin.Id, articleId, "en", 120, window.PreviousFromUtc.AddSeconds(1)));
            await db.SaveChangesAsync(Ct);
        });
        (await admin.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "A comment for the dashboard" }, Ct))
            .EnsureSuccessStatusCode();
        (await admin.Client.ReactAsync(articleId, "insightful")).EnsureSuccessStatusCode();
        await admin.Client.PutEmptyAsync($"/api/v1/articles/{articleId}/repost").OkJsonAsync();

        // Cached: the period's numbers don't move for 60 seconds.
        var cached = await DashboardAsync(admin.Client, AdminPeriods.Today);
        cached["generatedAt"]!.GetValue<DateTime>().Should().Be(before["generatedAt"]!.GetValue<DateTime>());
        Value(cached, "reads").Should().Be(Value(before, "reads"));

        await api.DropCacheAsync(DashboardTag);
        var after = await DashboardAsync(admin.Client, AdminPeriods.Today);
        int Delta(string card) => Value(after, card) - Value(before, card);
        Delta("articlesPublished").Should().Be(1);
        Delta("newUsers").Should().Be(12);
        (Card(after, "newUsers", "phone") - Card(before, "newUsers", "phone")).Should().Be(12);
        (Card(after, "newUsers", "google") - Card(before, "newUsers", "google")).Should().Be(0);
        (Card(after, "newUsers", "apple") - Card(before, "newUsers", "apple")).Should().Be(0);
        Delta("reads").Should().Be(12);
        Delta("activeReaders").Should().Be(12);
        Delta("comments").Should().Be(1);
        Delta("reactions").Should().Be(1);
        Delta("reposts").Should().Be(1);

        var localNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Africa/Cairo"));
        if (localNow.TimeOfDay > TimeSpan.FromMinutes(2))
        {
            // Yesterday just after midnight is in today's previous period, and in yesterday.
            (Card(after, "reads", "previous") - Card(before, "reads", "previous")).Should().Be(1);
            var yesterdayAfter = await DashboardAsync(admin.Client, AdminPeriods.Yesterday);
            (Value(yesterdayAfter, "reads") - Value(yesterdayBefore, "reads")).Should().Be(1);
        }

        after["fromDate"]!.GetValue<string>().Should().Be(after["toDate"]!.GetValue<string>());
        var charts = after["charts"]!.AsArray();
        charts[^1]!["date"]!.GetValue<string>().Should().Be(after["toDate"]!.GetValue<string>());
        DateOnly.Parse(charts[0]!["date"]!.GetValue<string>()).Should().Be(DateOnly.Parse(after["toDate"]!.GetValue<string>()).AddDays(-29));
        charts[^1]!["newUsers"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(12);
        charts[^1]!["activeReaders"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(12);
        charts[^1]!["articlesPublished"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(1);

        // Top lists: most reads first; this article (12 reads today) is in them unless ten others have as many.
        var top = after["topArticles"]!.AsArray();
        top.Count.Should().BeLessThanOrEqualTo(10);
        top.Select(a => a!["reads"]!.GetValue<int>()).Should().BeInDescendingOrder();
        var ours = top.FirstOrDefault(a => a!["id"]!.GetValue<Guid>() == articleId);
        if (ours is null)
        {
            top.Should().HaveCount(10);
            top[^1]!["reads"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(12);
        }
        else
        {
            ours.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "slug", "title", "language", "author", "field", "publishedAt", "reads");
            ours["reads"]!.GetValue<int>().Should().Be(12);
            ours["slug"]!.GetValue<string>().Should().Be(slug);
            ours["title"]!.GetValue<string>().Should().StartWith("Dashboard top article");
            ours["author"]!["username"]!.GetValue<string>().Should().Be(author.Me["username"]!.GetValue<string>());
            ours["field"]!["slug"]!.GetValue<string>().Should().Be("dotnet");
        }
        var writers = after["topWriters"]!.AsArray();
        writers.Select(w => w!["reads"]!.GetValue<int>()).Should().BeInDescendingOrder();
        var writer = writers.FirstOrDefault(w => w!["writer"]!["id"]!.GetValue<Guid>() == author.Id);
        if (writer is not null) (writer["reads"]!.GetValue<int>(), writer["articles"]!.GetValue<int>()).Should().Be((12, 1));
        else writers[^1]!["reads"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(12);

        var retention = after["streakRetention"]!.AsObject();
        retention["kept"]!.GetValue<int>().Should().BeInRange(0, retention["cohort"]!.GetValue<int>());
        if (retention["cohort"]!.GetValue<int>() == 0) retention["rate"].Should().BeNull();
        else retention["rate"]!.GetValue<double>().Should().BeInRange(0, 1);
    }

    [Fact]
    public async Task The_state_cards_are_read_per_caller_after_the_cache()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("State Card Author");
        var spammer = await api.UserAsync("State Card Spammer");
        var (articleId, _) = await author.Client.PublishAsync();
        await api.DropCacheAsync(DashboardTag);
        var before = await DashboardAsync(admin.Client, AdminPeriods.Last7Days);

        (await admin.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "article", targetId = articleId, reason = "spam" }, Ct))
            .EnsureSuccessStatusCode();
        await admin.Client.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "suspend", targetType = "user", targetId = spammer.Id, note = "Spam account", durationDays = 7 }, Ct).NoContentAsync();

        var after = await DashboardAsync(admin.Client, AdminPeriods.Last7Days);
        after["generatedAt"]!.GetValue<DateTime>().Should().Be(before["generatedAt"]!.GetValue<DateTime>()); // still cached
        after["cards"]!["openReports"]!.GetValue<int>().Should().Be(before["cards"]!["openReports"]!.GetValue<int>() + 1);
        after["cards"]!["suspendedNow"]!.GetValue<int>().Should().Be(before["cards"]!["suspendedNow"]!.GetValue<int>() + 1);
        after["cards"]!["openTickets"]!.GetValue<int>().Should().Be(before["cards"]!["openTickets"]!.GetValue<int>());
    }

    [Fact]
    public async Task The_content_pipeline_counts_the_folders_and_the_official_articles()
    {
        var admin = await api.SuperAdminAsync();
        await api.DropCacheAsync(DashboardTag);
        var pipeline = (await DashboardAsync(admin.Client, AdminPeriods.Today))["contentPipeline"]!.AsObject();

        pipeline.Select(p => p.Key).Should().BeEquivalentTo("folders", "seeded", "published", "lastSeedRunAt");
        var root = Path.Combine(AppContext.BaseDirectory, "fixtures", "content", "articles");
        pipeline["folders"]!.GetValue<int>().Should().Be(Directory.EnumerateFiles(root, "meta.json", SearchOption.AllDirectories).Count());
        var (seeded, published) = await api.InDbAsync(async db => (
            await db.Articles.CountAsync(a => a.Author != null && a.Author.IsSystemAccount, Ct),
            await db.Articles.Visible().CountAsync(a => a.Author != null && a.Author.IsSystemAccount, Ct)));
        (pipeline["seeded"]!.GetValue<int>(), pipeline["published"]!.GetValue<int>()).Should().Be((seeded, published));
        seeded.Should().BePositive();
        pipeline["lastSeedRunAt"]!.GetValue<DateTime>().Should().BeBefore(DateTime.UtcNow);
    }

    private async Task<AdminWindow> WindowAsync(string period)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return scope.ServiceProvider.GetRequiredService<AdminClock>().Window(period);
    }

    private static Task<JsonObject> DashboardAsync(HttpClient client, string period) =>
        client.GetAsync($"/api/v1/admin/dashboard?period={period}", Ct).OkJsonAsync();

    private static int Value(JsonObject dashboard, string card) => Card(dashboard, card, "value");

    private static int Card(JsonObject dashboard, string card, string key) => dashboard["cards"]![card]![key]!.GetValue<int>();
}
