using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Reading;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The "read" rule (SPEC F04) and streaks and reading stats (SPEC F08, ADR 0013) through the API. Real time can't be
/// skipped, so tests move the previous report's time back in SQL instead of waiting 30 seconds.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ReadingTests(ApiFactory api)
{
    private const string TimeZone = "Africa/Cairo"; // what SignUpAsync registers
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Guests_cant_report_progress()
    {
        var article = await PublishedArticleAsync();

        var response = await api.GuestClient().PutAsJsonAsync(Progress(article.Id), Report(80, 40), Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Progress_on_an_unknown_article_is_not_found()
    {
        var user = await api.SignUpAsync();

        var response = await user.Client.PutAsJsonAsync(Progress(Guid.NewGuid()), Report(80, 40), Ct);

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await ProblemCodeAsync(response)).Should().Be("article.not_found");
    }

    [Fact]
    public async Task Invalid_reports_are_rejected()
    {
        var user = await api.SignUpAsync();
        var article = await PublishedArticleAsync();

        var response = await user.Client.PutAsJsonAsync(Progress(article.Id), new { language = "fr", percent = 150, activeSecondsDelta = -1 }, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Reading_70_percent_for_30_seconds_completes_the_article_and_starts_a_streak()
    {
        var user = await api.SignUpAsync();
        var article = await PublishedArticleAsync();

        var opened = await ReportAsync(user, article.Id, percent: 0, seconds: 0);
        opened["completed"]!.GetValue<bool>().Should().BeFalse();

        var tooSoon = await ReportAsync(user, article.Id, percent: 90, seconds: 40);
        tooSoon["completedNow"]!.GetValue<bool>().Should().BeFalse("no time passed on the server since the first report");

        await MoveLastReportBackAsync(user.Id, article.Id, TimeSpan.FromSeconds(40));
        var read = await ReportAsync(user, article.Id, percent: 90, seconds: 35);

        read["completedNow"]!.GetValue<bool>().Should().BeTrue();
        read["milestone"].Should().BeNull();
        var streak = read["streak"]!.AsObject();
        streak["current"]!.GetValue<int>().Should().Be(1);
        streak["readToday"]!.GetValue<bool>().Should().BeTrue();
        streak["today"]!.GetValue<string>().Should().Be(Today().ToString("yyyy-MM-dd"));

        var again = await ReportAsync(user, article.Id, percent: 100, seconds: 0);
        again["completedNow"]!.GetValue<bool>().Should().BeFalse("an article is completed once");
        again["completed"]!.GetValue<bool>().Should().BeTrue();

        var stats = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/stats", Ct))!;
        stats["totalArticles"]!.GetValue<int>().Should().Be(1);
        stats["articlesThisWeek"]!.GetValue<int>().Should().Be(1);
        stats["articlesThisMonth"]!.GetValue<int>().Should().Be(1);
        stats["minutesRead"]!.GetValue<int>().Should().Be(1, "35 seconds round to one minute");
        stats["streak"]!["current"]!.GetValue<int>().Should().Be(1);
        stats["topFields"]!.AsArray().Should().ContainSingle()
            .Which!["id"]!.GetValue<Guid>().Should().Be(article.FieldId);

        var heatmap = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/stats/heatmap", Ct))!;
        heatmap["to"]!.GetValue<string>().Should().Be(Today().ToString("yyyy-MM-dd"));
        heatmap["days"]!.AsArray().Should().ContainSingle()
            .Which!["articles"]!.GetValue<int>().Should().Be(1);

        await WaitForAsync(async () =>
            {
                var (readCount, completions) = await ReadCountsAsync(article.Id);
                return completions > 0 && readCount == completions;
            },
            "the outbox recomputes Articles.ReadCount from completed reads");
    }

    [Fact]
    public async Task The_seventh_day_in_a_row_is_a_milestone()
    {
        var user = await api.SignUpAsync();
        await AddReadDaysAsync(user.Id, daysAgo: [1, 2, 3, 4, 5, 6]);

        var read = await CompleteAsync(user, await PublishedArticleAsync());

        read["streak"]!["current"]!.GetValue<int>().Should().Be(7);
        read["streak"]!["longest"]!.GetValue<int>().Should().Be(7);
        read["milestone"]!.GetValue<int>().Should().Be(7);
    }

    [Fact]
    public async Task Missing_yesterday_is_covered_by_a_freeze_when_reading_today()
    {
        var user = await api.SignUpAsync();
        await AddReadDaysAsync(user.Id, daysAgo: [2, 3, 4]);

        var before = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/stats", Ct))!["streak"]!.AsObject();
        before["current"]!.GetValue<int>().Should().Be(3);
        before["freezePending"]!.GetValue<bool>().Should().BeTrue();

        var read = await CompleteAsync(user, await PublishedArticleAsync());
        read["streak"]!["current"]!.GetValue<int>().Should().Be(4);
        read["streak"]!["freezeAvailable"]!.GetValue<bool>().Should().BeFalse("one freeze per rolling 7 days");

        var heatmap = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/stats/heatmap", Ct))!;
        var frozen = heatmap["days"]!.AsArray().Where(d => d!["frozen"]!.GetValue<bool>()).ToList();
        frozen.Should().ContainSingle().Which!["date"]!.GetValue<string>().Should().Be(Today().AddDays(-1).ToString("yyyy-MM-dd"));
    }

    [Fact]
    public async Task Two_missed_days_reset_the_streak_but_keep_the_longest()
    {
        var user = await api.SignUpAsync();
        await AddReadDaysAsync(user.Id, daysAgo: [3, 4, 5, 6, 7]);

        var before = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/stats", Ct))!["streak"]!.AsObject();
        before["current"]!.GetValue<int>().Should().Be(0);

        var read = await CompleteAsync(user, await PublishedArticleAsync());
        read["streak"]!["current"]!.GetValue<int>().Should().Be(1);
        read["streak"]!["longest"]!.GetValue<int>().Should().Be(5);
    }

    [Fact]
    public async Task Stats_need_a_signed_in_user_and_start_empty()
    {
        (await api.GuestClient().GetAsync("/api/v1/me/stats", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        var user = await api.SignUpAsync();
        var stats = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/stats", Ct))!;

        stats["totalArticles"]!.GetValue<int>().Should().Be(0);
        stats["streak"]!["current"]!.GetValue<int>().Should().Be(0);
        stats["streak"]!["freezeAvailable"]!.GetValue<bool>().Should().BeTrue();
        stats["topFields"]!.AsArray().Should().BeEmpty();
    }

    [Fact]
    public async Task Demo_readers_get_consistent_reading_history()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var reader1 = await db.Users.AsNoTracking().Where(u => u.Email == "reader1@readin.test").Select(u => u.Id).SingleAsync(Ct);

        var days = await db.ReadingDays.AsNoTracking().Where(d => d.UserId == reader1).ToListAsync(Ct);
        var completed = await db.ReadingProgress.AsNoTracking().CountAsync(r => r.UserId == reader1 && r.CompletedAt != null, Ct);
        var stats = await db.UserStats.AsNoTracking().SingleAsync(s => s.UserId == reader1, Ct);

        days.Should().NotBeEmpty();
        days.Sum(d => d.ArticlesRead).Should().Be(completed).And.Be(stats.TotalArticles);
        stats.LastReadDate.Should().Be(Today().AddDays(-1), "reader1's streak ends yesterday (SPEC §18.3)");
        Streaks.StatusOn(stats.History, Today()).ReadToday.Should().BeFalse();
    }

    private static string Progress(Guid articleId) => $"/api/v1/articles/{articleId}/progress";

    private static object Report(int percent, int seconds, string language = "en") =>
        new { language, percent, lastPosition = $"p{percent}", activeSecondsDelta = seconds };

    private static DateOnly Today() => ReadingClock.LocalDate(DateTime.UtcNow, TimeZone);

    private async Task<JsonObject> ReportAsync(SignedInUser user, Guid articleId, int percent, int seconds)
    {
        var response = await user.Client.PutAsJsonAsync(Progress(articleId), Report(percent, seconds), Ct);
        return await ApiFactory.ReadSessionAsync(response);
    }

    /// <summary>Opens the article, lets 40 seconds pass and reports reading it to the end.</summary>
    private async Task<JsonObject> CompleteAsync(SignedInUser user, (Guid Id, Guid FieldId) article)
    {
        await ReportAsync(user, article.Id, percent: 0, seconds: 0);
        await MoveLastReportBackAsync(user.Id, article.Id, TimeSpan.FromSeconds(40));
        var read = await ReportAsync(user, article.Id, percent: 100, seconds: 40);
        read["completedNow"]!.GetValue<bool>().Should().BeTrue();
        return read;
    }

    private async Task<(Guid Id, Guid FieldId)> PublishedArticleAsync()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var article = await db.Articles.AsNoTracking()
            .Where(a => a.Status == ArticleStatus.Published)
            .OrderBy(a => a.PublishedAt)
            .Select(a => new { a.Id, a.FieldId })
            .FirstAsync(Ct);
        return (article.Id, article.FieldId);
    }

    private async Task MoveLastReportBackAsync(Guid userId, Guid articleId, TimeSpan by)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var seconds = -by.TotalSeconds;
        var moved = await db.ReadingProgress
            .Where(r => r.UserId == userId && r.ArticleId == articleId)
            .ExecuteUpdateAsync(set => set.SetProperty(r => r.UpdatedAt, r => r.UpdatedAt.AddSeconds(seconds)), Ct);
        moved.Should().Be(1);
    }

    /// <summary>Earlier reading, as if the user had completed one article on each of those local days.</summary>
    private async Task AddReadDaysAsync(Guid userId, int[] daysAgo)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var today = Today();
        var days = daysAgo.Select(d => ReadingDay.Seeded(userId, today.AddDays(-d), articlesRead: 1, activeSeconds: 300)).ToList();
        db.ReadingDays.AddRange(days);

        var stats = new UserStats(userId);
        stats.Rebuild(Streaks.Compute(days.Select(d => d.Date)), days.Count, days.Count * 300, DateTime.UtcNow);
        db.UserStats.Add(stats);
        await db.SaveChangesAsync(Ct);
    }

    private async Task<(int ReadCount, int Completions)> ReadCountsAsync(Guid articleId)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var readCount = await db.Articles.AsNoTracking().Where(a => a.Id == articleId).Select(a => a.ReadCount).SingleAsync(Ct);
        var completions = await db.ReadingProgress.AsNoTracking().CountAsync(r => r.ArticleId == articleId && r.CompletedAt != null, Ct);
        return (readCount, completions);
    }

    private static async Task WaitForAsync(Func<Task<bool>> condition, string because)
    {
        for (var i = 0; i < 50; i++)
        {
            if (await condition()) return;
            await Task.Delay(100, Ct);
        }
        (await condition()).Should().BeTrue(because);
    }

    private static async Task<string?> ProblemCodeAsync(HttpResponseMessage response) =>
        (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))?["code"]?.GetValue<string>();
}
