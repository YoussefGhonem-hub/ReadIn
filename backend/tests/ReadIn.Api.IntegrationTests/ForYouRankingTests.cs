using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Models;
using ReadIn.Domain.Taxonomy;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The For you ranking (ADR 0020, contract-v1 "For you ranking"): freshness + popularity + the Verified badge inside each
/// group, pages that stay put while scores move, old cursors that still work, and the badge as Today's tie-break. Each
/// test works in fields of its own (disabled again afterwards), so the lists it checks are exact.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ForYouRankingTests(ApiFactory api) : IAsyncLifetime
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private readonly List<Guid> _fields = [];

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    public async ValueTask DisposeAsync()
    {
        if (_fields.Count == 0) return;
        await WithDbAsync(async db =>
        {
            foreach (var field in await db.Fields.Where(f => _fields.Contains(f.Id)).ToListAsync())
                field.Update(field.NameAr, field.NameEn, field.Icon, field.Color, field.SortOrder, field.IsSensitive, field.RequiresSources, isEnabled: false);
            await db.SaveChangesAsync();
        });
        await ClearCachesAsync();
    }

    [Fact]
    public async Task Each_group_ranks_freshness_with_other_peoples_engagement_and_the_verified_badge()
    {
        var (fieldId, slug) = await NewFieldAsync();
        var writer = await api.UserAsync("Ranked Writer");
        var verified = await api.UserAsync("Verified Writer");
        await VerifyAsync(verified.Id);
        var reader = await api.UserAsync("Ranking Reader");

        var oldest = await PublishAsync(writer, fieldId);
        var liked = await PublishAsync(writer, fieldId);
        var plain = await PublishAsync(writer, fieldId);
        var badge = await PublishAsync(verified, fieldId);

        // One reaction by someone else: about 8.7 hours up (less than the badge's day). The writer's own doesn't count.
        await reader.Client.ReactAsync(liked, "insightful").OkJsonAsync();
        await writer.Client.ReactAsync(oldest, "love").OkJsonAsync();

        var url = $"/api/v1/feed/for-you?field={slug}&limit=50";
        (await ScanAsync(api.GuestClient(), url)).Should().Equal([badge, liked, plain, oldest],
            "a verified writer's article ranks a day newer, a reaction a few hours, the author's own reaction nothing");
        (await ScanAsync(reader.Client, url)).Should().Equal([badge, liked, plain, oldest], "signed in, the same group is ranked the same");

        // A save on top (E = 2 + 6 = 8, about 1.14 days) beats the badge on the next first page.
        (await reader.Client.PutEmptyAsync($"/api/v1/me/saved/{liked}")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await ScanAsync(api.GuestClient(), url)).Should().Equal([liked, badge, plain, oldest]);
    }

    [Fact]
    public async Task A_scroll_keeps_its_order_while_scores_move_and_later_articles_wait_for_the_next_first_page()
    {
        var (fieldId, slug) = await NewFieldAsync();
        var writer = await api.UserAsync("Steady Writer");
        var reader = await api.UserAsync("Steady Reader");
        var a1 = await PublishAsync(writer, fieldId);
        var a2 = await PublishAsync(writer, fieldId);
        var a3 = await PublishAsync(writer, fieldId);
        var a4 = await PublishAsync(writer, fieldId);
        var guest = api.GuestClient();
        var url = $"/api/v1/feed/for-you?field={slug}&limit=2";

        var first = await PageAsync(guest, url, cursor: null);
        first.Ids.Should().Equal(a4, a3);
        RankedCursor.Decode(first.Next).Should().NotBeNull("the cursor carries the scroll's snapshot");

        // While the user reads page 1: a1 gets popular enough to top the feed, and a new article comes out.
        await reader.Client.ReactAsync(a1, "fire").OkJsonAsync();
        (await reader.Client.PutEmptyAsync($"/api/v1/me/saved/{a1}")).StatusCode.Should().Be(HttpStatusCode.OK);
        var a5 = await PublishAsync(writer, fieldId);

        var second = await PageAsync(guest, url, first.Next);
        second.Ids.Should().Equal([a2, a1], "the scroll ranks against its snapshot: nothing jumps over the cursor or appears");
        second.Next.Should().BeNull();

        (await ScanAsync(guest, url)).Should().Equal([a1, a5, a4, a3, a2], "a new first page has the new activity and the new article");
    }

    [Fact]
    public async Task A_cursor_from_before_the_ranking_finishes_its_scroll_newest_first()
    {
        var (fieldId, slug) = await NewFieldAsync();
        var writer = await api.UserAsync("Legacy Writer");
        var verified = await api.UserAsync("Legacy Verified");
        await VerifyAsync(verified.Id);
        var v1 = await PublishAsync(verified, fieldId);
        var w1 = await PublishAsync(writer, fieldId);
        var w2 = await PublishAsync(writer, fieldId);
        var url = $"/api/v1/feed/for-you?field={slug}&limit=1";

        (await ScanAsync(api.GuestClient(), url)).Should().Equal([v1, w2, w1], "ranked: the badge puts v1 first");

        // The cursor an older API gave after w2, the newest card.
        var publishedAt = await WithDbAsync(db => db.Articles.Where(a => a.Id == w2).Select(a => a.PublishedAt!.Value).SingleAsync(Ct));
        var legacy = new TieredTimeCursor(0, publishedAt, w2).Encode();

        var next = await PageAsync(api.GuestClient(), url, legacy);
        next.Ids.Should().Equal(w1);
        TieredTimeCursor.Decode(next.Next).Should().NotBeNull("an old scroll keeps old-style cursors");
        RankedCursor.Decode(next.Next).Should().BeNull();
        var last = await PageAsync(api.GuestClient(), url, next.Next);
        last.Ids.Should().Equal(v1);
        last.Next.Should().BeNull();
    }

    [Fact]
    public async Task Todays_article_prefers_a_verified_writer_between_equal_scores()
    {
        var fields = new[] { await NewFieldAsync(), await NewFieldAsync(), await NewFieldAsync() };
        var verified = await api.UserAsync("Daily Verified");
        await VerifyAsync(verified.Id);
        var writer = await api.UserAsync("Daily Writer");
        var reader = await api.UserAsync("Daily Reader");
        (await reader.Client.PutAsJsonAsync("/api/v1/me/interests",
            new { fieldIds = fields.Select(f => f.Id).ToArray(), topicIds = Array.Empty<Guid>() }, Ct)).EnsureSuccessStatusCode();
        (await reader.Client.PutAsJsonAsync("/api/v1/me/preferences",
            new { uiLanguage = "en", articleLanguage = "en", theme = "light", timeZone = "Africa/Cairo", reminderTime = "08:00" }, Ct))
            .EnsureSuccessStatusCode();

        // Both just published with no activity: the same quality score. Without the badge the newer one would win.
        var older = await PublishAsync(verified, fields[0].Id);
        var newer = await PublishAsync(writer, fields[0].Id);
        var scores = await WithDbAsync(db => db.Articles.Where(a => a.Id == older || a.Id == newer).Select(a => a.QualityScore).ToListAsync(Ct));
        scores.Distinct().Should().ContainSingle("the tie the badge breaks");

        var today = await reader.Client.GetAsync("/api/v1/feed/today", Ct).OkJsonAsync();
        today["id"]!.GetValue<Guid>().Should().Be(older);
    }

    // ── Helpers ─────────────────────────────────────────────────

    private async Task<Guid> PublishAsync(SignedInUser writer, Guid fieldId)
    {
        var document = ArticleTestKit.Document(fieldId, $"Ranking test {Guid.NewGuid():N}"[..40],
            blocks: [ArticleTestKit.Paragraph("An article for the For you ranking.")]);
        var (id, _) = await writer.Client.WriteAndPublishAsync(document);
        await ClearCachesAsync();
        return id;
    }

    /// <summary>The Verified badge as the SuperAdmin's approval sets it (F19), dated a minute ago.</summary>
    private Task VerifyAsync(Guid userId) => WithDbAsync(async db =>
    {
        var user = await db.Users.SingleAsync(u => u.Id == userId, Ct);
        user.Verify(DateTime.UtcNow.AddMinutes(-1));
        await db.SaveChangesAsync(Ct);
    });

    private static async Task<(List<Guid> Ids, string? Next)> PageAsync(HttpClient client, string url, string? cursor)
    {
        var body = await client.GetAsync(cursor is null ? url : $"{url}&cursor={Uri.EscapeDataString(cursor)}", Ct).OkJsonAsync();
        return ([.. body["items"]!.AsArray().Select(c => c!["id"]!.GetValue<Guid>())], body["nextCursor"]?.GetValue<string>());
    }

    /// <summary>Every page from the first one, without repeats.</summary>
    private static async Task<List<Guid>> ScanAsync(HttpClient client, string url)
    {
        var ids = new List<Guid>();
        string? cursor = null;
        for (var page = 0; page < 50; page++)
        {
            var (items, next) = await PageAsync(client, url, cursor);
            ids.AddRange(items);
            cursor = next;
            if (cursor is null) break;
        }
        ids.Should().OnlyHaveUniqueItems("paging never repeats a card");
        return ids;
    }

    /// <summary>A new enabled field, disabled again when the test ends.</summary>
    private async Task<(Guid Id, string Slug)> NewFieldAsync()
    {
        var word = $"{Guid.NewGuid():N}"[..10];
        var created = await WithDbAsync(async db =>
        {
            var field = new Field($"rk-{word}", $"مجال {word}", $"Field {word}", "cpu", "primary", 900);
            field.Update(field.NameAr, field.NameEn, "cpu", "primary", 900, false, requiresSources: false, isEnabled: true);
            db.Fields.Add(field);
            await db.SaveChangesAsync(Ct);
            return (field.Id, field.Slug);
        });
        _fields.Add(created.Id);
        await ClearCachesAsync();
        return created;
    }

    private async Task WithDbAsync(Func<AppDbContext, Task> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await action(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    private async Task<T> WithDbAsync<T>(Func<AppDbContext, Task<T>> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await action(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    private async Task ClearCachesAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<HybridCache>()
            .RemoveByTagAsync([CacheTags.Feed, CacheTags.Taxonomy, CacheTags.Articles, CacheTags.Tags], Ct);
    }
}
