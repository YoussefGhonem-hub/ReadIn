using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Admin;
using ReadIn.Application.Features.Search;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F23 / §22 searches with no results against SQL Server: what <c>GET /search</c> records (a first page of articles with no
/// field or reading-time filter that found nothing), as-you-type prefixes dropped, counted per day, language and query with
/// no user id, and listed on the dashboard.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class SearchMissTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task A_search_that_finds_nothing_is_counted_per_query_and_listed_on_the_dashboard()
    {
        var query = Unique("zqxmiss");
        foreach (var _ in Enumerable.Range(0, 3))
        {
            var searcher = await api.SignUpAsync();
            await searcher.Client.GetAsync($"/api/v1/search?q={query}", Ct).OkJsonAsync();
        }
        await FlushAsync();

        var row = await MissAsync(query);
        row.Should().NotBeNull();
        (row!.Count, row.Language, row.Date).Should().Be((3, "en", await TodayAsync()));

        var admin = await api.SuperAdminAsync();
        await api.DropCacheAsync("admin-dashboard");
        var dashboard = await admin.Client.GetAsync("/api/v1/admin/dashboard?period=today", Ct).OkJsonAsync();
        var listed = dashboard["missedSearches"]!.AsArray().Single(m => m!["query"]!.GetValue<string>() == query)!.AsObject();
        listed.Select(p => p.Key).Should().BeEquivalentTo("query", "language", "count");
        (listed["language"]!.GetValue<string>(), listed["count"]!.GetValue<int>()).Should().Be(("en", 3));
    }

    [Fact]
    public async Task Prefixes_typed_on_the_way_are_dropped()
    {
        var user = await api.SignUpAsync();
        var word = Unique("zqxtype");
        await user.Client.GetAsync($"/api/v1/search?q={word[..9]}", Ct).OkJsonAsync();
        await user.Client.GetAsync($"/api/v1/search?q={word[..12]}", Ct).OkJsonAsync();
        await user.Client.GetAsync($"/api/v1/search?q={word}", Ct).OkJsonAsync();
        await user.Client.GetAsync($"/api/v1/search?q={word}", Ct).OkJsonAsync(); // Enter after typing: the same search
        await FlushAsync();

        (await MissAsync(word[..9])).Should().BeNull();
        (await MissAsync(word[..12])).Should().BeNull();
        (await MissAsync(word))!.Count.Should().Be(1);
    }

    [Fact]
    public async Task An_arabic_query_is_counted_as_arabic_normalized()
    {
        var user = await api.SignUpAsync();
        var letters = "زقطظغضصث";
        var random = new Random();
        var arabic = "أزق" + new string(Enumerable.Range(0, 10).Select(_ => letters[random.Next(letters.Length)]).ToArray());
        await user.Client.GetAsync($"/api/v1/search?q={Uri.EscapeDataString(arabic)}", Ct).OkJsonAsync();
        await FlushAsync();

        // Stored normalized like SearchText (§22): أ → ا.
        var row = await MissAsync("ا" + arabic[1..]);
        row.Should().NotBeNull();
        row!.Language.Should().Be("ar");
    }

    [Fact]
    public async Task Filtered_paged_found_and_other_searches_are_not_counted()
    {
        var user = await api.SignUpAsync();
        var author = await api.UserAsync("Miss Author");
        var title = Unique("zqxfound");
        await author.Client.PublishAsync($"{title} article");

        var filtered = Unique("zqxfield");
        var timed = Unique("zqxtime");
        var paged = Unique("zqxpage");
        var people = Unique("zqxusers");
        await user.Client.GetAsync($"/api/v1/search?q={filtered}&field=dotnet", Ct).OkJsonAsync();
        await user.Client.GetAsync($"/api/v1/search?q={timed}&minMinutes=1", Ct).OkJsonAsync();
        await user.Client.GetAsync($"/api/v1/search?q={paged}&cursor=bzoyMA", Ct).OkJsonAsync();
        await user.Client.GetAsync($"/api/v1/search?q={people}&type=users", Ct).OkJsonAsync();
        // Full-text indexing is asynchronous: wait until the article is found, then that search isn't a miss.
        var found = new JsonObject();
        for (var i = 0; i < 40; i++)
        {
            found = await user.Client.GetAsync($"/api/v1/search?q={title}", Ct).OkJsonAsync();
            if (found["items"]!.AsArray().Count > 0) break;
            await Task.Delay(250, Ct);
        }
        found["items"]!.AsArray().Should().NotBeEmpty();
        await FlushAsync();

        foreach (var query in new[] { filtered, timed, paged, people, title }) (await MissAsync(query)).Should().BeNull(query);
    }

    /// <summary>Counts every miss still held, as the background flusher does after 30 seconds.</summary>
    private Task FlushAsync() => api.InScopeAsync(async services =>
        await services.GetRequiredService<SearchMissWriter>().WriteAsync(services.GetRequiredService<SearchMissBuffer>().TakeAll(), Ct));

    private Task<Domain.Admin.SearchMiss?> MissAsync(string query) =>
        api.InDbAsync(db => db.SearchMisses.AsNoTracking().FirstOrDefaultAsync(m => m.Query == query, Ct));

    private async Task<DateOnly> TodayAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        return scope.ServiceProvider.GetRequiredService<AdminClock>().Today;
    }

    /// <summary>A query nothing matches: a prefix and 12 random lower-case letters.</summary>
    private static string Unique(string prefix)
    {
        var random = new Random();
        return prefix + new string(Enumerable.Range(0, 12).Select(_ => (char)('a' + random.Next(26))).ToArray());
    }
}
