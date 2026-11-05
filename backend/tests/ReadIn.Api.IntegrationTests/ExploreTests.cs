using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Application.Features.Explore;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F15 Explore and field pages (contract-v1 "Explore and field pages"): the ranking windows, weights and fallbacks, who
/// counts as a writer, visibility, cursors, 404s, and caches that are shared while the caller's own state is not.
/// Each test works in fields of its own (disabled again afterwards), so the rankings it checks are exact.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ExploreTests(ApiFactory api) : IAsyncLifetime
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private readonly List<Guid> _fields = [];

    private sealed record TestField(Guid Id, string Slug, string NameAr, string NameEn, Guid TopicA, string TopicASlug, Guid TopicB, string TopicBSlug);

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    /// <summary>The test's fields are disabled again, so their articles leave every list the other tests look at.</summary>
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

    // ── Rankings ────────────────────────────────────────────────

    [Fact]
    public async Task Trending_weighs_this_weeks_reads_reactions_comments_and_saves_then_falls_back_to_the_quality_score()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync("Trending Writer");
        var (a, b, c, d, e, f) = (
            await PublishAsync(writer, field, "Trending A"), await PublishAsync(writer, field, "Trending B"),
            await PublishAsync(writer, field, "Trending C"), await PublishAsync(writer, field, "Trending D"),
            await PublishAsync(writer, field, "Trending E"), await PublishAsync(writer, field, "Trending F"));
        var readers = await ReadersAsync(3);
        var now = DateTime.UtcNow;

        await SaveAsync(a, readers[..1], now.AddHours(-1));                    // 6
        await ReactAsync(b, readers[..2], now.AddHours(-2));                   // 2 × 2
        await ReadAsync(b, readers[2..], now.AddHours(-3));                    // + 1 = 5
        await CommentAsync(c, readers[0], now.AddHours(-1));                   // 4
        await CommentAsync(c, readers[1], now.AddHours(-1), hide: true);       // hidden: nothing
        await CommentAsync(c, readers[2], now.AddHours(-1), delete: true);     // deleted: nothing
        await CommentAsync(c, writer.Id, now.AddHours(-1));                    // the author's own: nothing
        await SaveAsync(c, [writer.Id], now.AddHours(-1));
        await ReactAsync(c, [writer.Id], now.AddHours(-1));
        await ReadAsync(c, [writer.Id], now.AddHours(-1));
        await ReactAsync(f, readers[..2], now.AddDays(-6.9));                  // 4, still this week
        await SaveAsync(d, readers, now.AddDays(-8));                          // last week: nothing
        await ReadAsync(d, readers, now.AddDays(-8));
        await QualityAsync((a, 0.1), (b, 0.1), (c, 0.2), (d, 0.9), (e, 0.3), (f, 0.6));

        var ranked = await RankAsync((rankings, candidates) => rankings.RankTrendingAsync(candidates, now, 10, Ct), field);

        ranked.Should().Equal([a, b, f, c, d, e],
            "engagement first (save 6, reaction 2, comment 4, read 1), then the quality score: f and c tie at 4, and d and e had nothing this week");
    }

    [Fact]
    public async Task Most_saved_ranks_the_last_30_days_then_all_time_saves_and_leaves_out_articles_nobody_saved()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync("Most Saved Writer");
        var (a, b, c, d, e, never) = (
            await PublishAsync(writer, field, "Saved A"), await PublishAsync(writer, field, "Saved B"),
            await PublishAsync(writer, field, "Saved C"), await PublishAsync(writer, field, "Saved D"),
            await PublishAsync(writer, field, "Saved E"), await PublishAsync(writer, field, "Never saved"));
        var readers = await ReadersAsync(5);
        var now = DateTime.UtcNow;

        await SaveAsync(a, readers[..2], now.AddDays(-1));      // 2 this month
        await SaveAsync(b, readers[..1], now.AddDays(-29));     // 1 this month …
        await SaveAsync(b, readers[1..4], now.AddDays(-40));    // … 4 in all
        await SaveAsync(c, readers, now.AddDays(-40));          // 0 this month, 5 in all
        await SaveAsync(d, readers[..2], now.AddDays(-31));     // 0 this month, 2 in all
        await SaveAsync(e, [writer.Id], now);                   // only the author's own: 0 this month, 1 in all
        await RecomputeCountersAsync(a, b, c, d, e, never);

        var ranked = await RankAsync((rankings, candidates) => rankings.RankMostSavedAsync(candidates, now, 10, Ct), field);

        ranked.Should().Equal([a, b, c, d, e], "saves in the last 30 days, then all-time saves; never saved is left out");
    }

    [Fact]
    public async Task New_writers_are_people_whose_first_visible_article_is_at_most_30_days_old_latest_first()
    {
        var field = await NewFieldAsync();
        var fresh = await api.UserAsync("Fresh Writer");
        var hiddenFirst = await api.UserAsync("Hidden First Writer");
        var older = await api.UserAsync("Older New Writer");
        var veteran = await api.UserAsync("Veteran Writer");
        var suspended = await api.UserAsync("Suspended Writer");
        var now = DateTime.UtcNow;

        await PublishedAtAsync(await PublishAsync(fresh, field, "Fresh one"), now.AddDays(-1));
        var hiddenOld = await PublishAsync(hiddenFirst, field, "Hidden old one");
        await PublishedAtAsync(hiddenOld, now.AddDays(-40));
        await WithDbAsync(db => db.Articles.Where(x => x.Id == hiddenOld).ExecuteUpdateAsync(s => s.SetProperty(x => x.HiddenAt, now), Ct));
        await PublishedAtAsync(await PublishAsync(hiddenFirst, field, "Visible one"), now.AddDays(-2));
        await PublishedAtAsync(await PublishAsync(older, field, "Older first"), now.AddDays(-3));
        await PublishAsync(older, field, "Older second");
        await PublishedAtAsync(await PublishAsync(veteran, field, "Veteran first"), now.AddDays(-31));
        await PublishAsync(veteran, field, "Veteran second");
        await PublishAsync(suspended, field, "Suspended one");
        await SuspendAsync(suspended.Id);

        var ids = await WithRankingsAsync(rankings => rankings.NewWriterIdsAsync(now, int.MaxValue, Ct));

        ids.Should().ContainInOrder([fresh.Id, hiddenFirst.Id, older.Id], "latest first publish first; a hidden first article doesn't count");
        ids.Should().NotContain([veteran.Id, suspended.Id, SystemUsers.EditorialId], "first published 31 days ago, suspended, a system account");
    }

    [Fact]
    public async Task Top_writers_rank_reads_and_reactions_in_the_field_over_90_days_and_carry_the_callers_follow_state()
    {
        var field = await NewFieldAsync();
        var otherField = await NewFieldAsync();
        var w1 = await api.UserAsync("Top Writer One");
        var w2 = await api.UserAsync("Top Writer Two");
        var w3 = await api.UserAsync("Top Writer Three");
        var w4 = await api.UserAsync("Top Writer Four");
        var w5 = await api.UserAsync("Top Writer Five");
        var suspended = await api.UserAsync("Top Writer Suspended");
        var official = await api.UserAsync("Becomes Official");
        var viewer = await api.UserAsync("Top Writers Viewer");
        var readers = await ReadersAsync(5);
        var now = DateTime.UtcNow;

        var w1Article = await PublishAsync(w1, field, "W1 article");
        await ReadAsync(w1Article, readers[..3], now.AddDays(-80));           // 3
        await ReadAsync(w1Article, [w1.Id], now);                              // their own: nothing
        var w2Article = await PublishAsync(w2, field, "W2 article");
        await ReactAsync(w2Article, readers[..1], now.AddDays(-10));           // 2
        var w2Old = await PublishAsync(w2, field, "W2 old article");
        await ReactAsync(w2Old, readers, now.AddDays(-100));                   // too old: nothing
        await PublishAsync(w3, field, "W3 article");                           // 0, 1 article, 1 follower
        await PublishAsync(w4, field, "W4 article");                           // 0, 2 articles
        await PublishAsync(w4, field, "W4 second article");
        await PublishAsync(w5, field, "W5 article");                           // 0, 1 article, no followers
        await ReadAsync(await PublishAsync(w5, otherField, "W5 elsewhere"), readers, now); // another field: nothing here
        await ReadAsync(await PublishAsync(suspended, field, "Suspended article"), readers, now);
        await SuspendAsync(suspended.Id);
        var officialArticle = await PublishAsync(official, field, "Official article");
        await ReadAsync(officialArticle, readers, now);
        await WithDbAsync(db => db.Articles.Where(x => x.Id == officialArticle)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.AuthorId, (Guid?)SystemUsers.EditorialId), Ct));
        await WithDbAsync(async db =>
        {
            db.UserFollows.Add(UserFollow.Create(readers[0], w3.Id, now).Value);
            await db.SaveChangesAsync(Ct);
        });

        var ranked = await WithRankingsAsync(rankings => rankings.TopWriterIdsAsync(field.Id, now, 10, Ct));
        ranked.Should().Equal([w1.Id, w2.Id, w4.Id, w3.Id, w5.Id],
            "reads 1 and reactions 2 in 90 days; then articles in the field, then followers; no suspended or system account");

        // The endpoint: cached for everyone, with the caller's own follow state.
        (await viewer.Client.PutEmptyAsync($"/api/v1/users/{w2.Id}/follow")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await w1.Client.PutEmptyAsync($"/api/v1/users/{viewer.Id}/follow")).StatusCode.Should().Be(HttpStatusCode.OK);
        await ClearCachesAsync();

        var guest = await api.GuestClient().GetAsync($"/api/v1/fields/{field.Slug}/writers?limit=3", Ct).OkArrayAsync();
        Ids(guest).Should().Equal(w1.Id, w2.Id, w4.Id);
        guest.Should().OnlyContain(u => !u!["isFollowing"]!.GetValue<bool>() && !u["followsYou"]!.GetValue<bool>());

        var mine = await viewer.Client.GetAsync($"/api/v1/fields/{field.Slug}/writers?limit=3", Ct).OkArrayAsync();
        Ids(mine).Should().Equal(w1.Id, w2.Id, w4.Id);
        mine.Select(u => (u!["isFollowing"]!.GetValue<bool>(), u["followsYou"]!.GetValue<bool>()))
            .Should().Equal((false, true), (true, false), (false, false));

        (await viewer.Client.PutEmptyAsync($"/api/v1/users/{w4.Id}/follow")).StatusCode.Should().Be(HttpStatusCode.OK);
        var after = await viewer.Client.GetAsync($"/api/v1/fields/{field.Slug}/writers?limit=3", Ct).OkArrayAsync();
        after[2]!["isFollowing"]!.GetValue<bool>().Should().BeTrue("the follow state is the caller's, added after the cache");

        (await api.GuestClient().GetAsync($"/api/v1/fields/{field.Slug}/writers?limit=50", Ct).OkArrayAsync())
            .Should().HaveCount(5, "limit is at most 10");
        (await api.GuestClient().GetAsync($"/api/v1/fields/{otherField.Slug}/writers", Ct).OkArrayAsync())
            .Select(u => u!["id"]!.GetValue<Guid>()).Should().Equal(w5.Id);
    }

    [Fact]
    public async Task A_writer_suspended_or_deleted_after_the_writer_lists_were_cached_leaves_them_at_once()
    {
        var field = await NewFieldAsync();
        var stays = await api.UserAsync("Writer Who Stays");
        var suspended = await api.UserAsync("Writer Suspended Later");
        var deleted = await api.UserAsync("Writer Deleted Later");
        var viewer = await api.UserAsync("Writer Lists Viewer");
        await PublishAsync(stays, field, "Stays listed");
        await PublishAsync(suspended, field, "Suspended later");
        await PublishAsync(deleted, field, "Deleted later");
        await ClearCachesAsync();
        var writersUrl = $"/api/v1/fields/{field.Slug}/writers";

        // Both lists are cached now: the field's top writers and Explore's new writers (the latest first publishes).
        Ids(await api.GuestClient().GetAsync(writersUrl, Ct).OkArrayAsync()).Should().BeEquivalentTo([stays.Id, suspended.Id, deleted.Id]);
        Ids((await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync())["newWriters"])
            .Should().Contain([stays.Id, suspended.Id, deleted.Id]);

        // Straight in the database: no event, no cache dropped.
        await WithDbAsync(db => db.Users.Where(u => u.Id == suspended.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.IsSuspended, true).SetProperty(u => u.SuspendedUntil, (DateTime?)null), Ct));
        await WithDbAsync(db => db.Users.Where(u => u.Id == deleted.Id).ExecuteUpdateAsync(s => s.SetProperty(u => u.IsDeleted, true), Ct));

        foreach (var client in new[] { api.GuestClient(), viewer.Client })
        {
            Ids(await client.GetAsync(writersUrl, Ct).OkArrayAsync())
                .Should().Equal([stays.Id], "the cached top writers are checked on every request");
            Ids((await client.GetAsync("/api/v1/explore", Ct).OkJsonAsync())["newWriters"])
                .Should().Contain(stays.Id).And.NotContain([suspended.Id, deleted.Id], "so are the cached new writers");
        }
    }

    // ── The field page ──────────────────────────────────────────

    [Fact]
    public async Task The_field_page_counts_visible_articles_and_field_followers_and_adds_the_callers_follows_after_the_cache()
    {
        var field = await NewFieldAsync(sensitive: true);
        var writer = await api.UserAsync("Field Page Writer");
        await PublishAsync(writer, field, "Topic A one", field.TopicA);
        await PublishAsync(writer, field, "Topic A two", field.TopicA);
        await PublishAsync(writer, field, "No topic");
        var hidden = await PublishAsync(writer, field, "Hidden in topic A", field.TopicA);
        await WithDbAsync(db => db.Articles.Where(x => x.Id == hidden).ExecuteUpdateAsync(s => s.SetProperty(x => x.HiddenAt, DateTime.UtcNow), Ct));

        var follower = await api.UserAsync();
        var topicFollower = await api.UserAsync();
        (await follower.Client.PutEmptyAsync($"/api/v1/me/interests/fields/{field.Id}")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await follower.Client.PutEmptyAsync($"/api/v1/me/interests/topics/{field.TopicB}")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await topicFollower.Client.PutEmptyAsync($"/api/v1/me/interests/topics/{field.TopicA}")).StatusCode.Should().Be(HttpStatusCode.OK);
        await ClearCachesAsync();

        var guest = await api.GuestClient("ar").GetAsync($"/api/v1/fields/{field.Slug.ToUpperInvariant()}", Ct).OkJsonAsync();
        guest["id"]!.GetValue<Guid>().Should().Be(field.Id);
        guest["slug"]!.GetValue<string>().Should().Be(field.Slug, "the slug is matched ignoring case");
        (guest["name"]!.GetValue<string>(), guest["nameEn"]!.GetValue<string>()).Should().Be((field.NameAr, field.NameEn));
        (guest["icon"]!.GetValue<string>(), guest["color"]!.GetValue<string>()).Should().Be(("cpu", "primary"));
        guest["isSensitive"]!.GetValue<bool>().Should().BeTrue();
        guest["articleCount"]!.GetValue<int>().Should().Be(3, "the hidden article doesn't count");
        guest["followerCount"]!.GetValue<int>().Should().Be(1, "a followed topic doesn't follow the field");
        guest["isFollowing"]!.GetValue<bool>().Should().BeFalse();
        Topics(guest).Should().Equal((field.TopicASlug, 2, false), (field.TopicBSlug, 0, false));

        var mine = await follower.Client.GetAsync($"/api/v1/fields/{field.Slug}", Ct).OkJsonAsync();
        mine["name"]!.GetValue<string>().Should().Be(field.NameEn);
        mine["isFollowing"]!.GetValue<bool>().Should().BeTrue();
        Topics(mine).Should().Equal((field.TopicASlug, 2, false), (field.TopicBSlug, 0, true));

        var theirs = await topicFollower.Client.GetAsync($"/api/v1/fields/{field.Slug}", Ct).OkJsonAsync();
        theirs["isFollowing"]!.GetValue<bool>().Should().BeFalse("the same cached header, with this caller's follows");
        Topics(theirs).Should().Equal((field.TopicASlug, 2, true), (field.TopicBSlug, 0, false));
    }

    [Fact]
    public async Task Unknown_and_disabled_fields_and_topics_of_other_fields_are_404()
    {
        var field = await NewFieldAsync();
        var other = await NewFieldAsync();
        var disabled = await NewFieldAsync();
        await WithDbAsync(async db =>
        {
            var row = await db.Fields.SingleAsync(f => f.Id == disabled.Id, Ct);
            row.Update(row.NameAr, row.NameEn, row.Icon, row.Color, row.SortOrder, row.IsSensitive, row.RequiresSources, isEnabled: false);
            await db.SaveChangesAsync(Ct);
        });
        await ClearCachesAsync();
        var guest = api.GuestClient();

        foreach (var slug in new[] { $"nope-{Unique()}", disabled.Slug })
        {
            await guest.GetAsync($"/api/v1/fields/{slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
            await guest.GetAsync($"/api/v1/fields/{slug}/articles", Ct).ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
            await guest.GetAsync($"/api/v1/fields/{slug}/writers", Ct).ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
        }

        await guest.GetAsync($"/api/v1/fields/{field.Slug}/articles?topic=nope", Ct).ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");
        await guest.GetAsync($"/api/v1/fields/{field.Slug}/articles?topic={other.TopicASlug}", Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");
        var problem = await api.GuestClient("ar").GetAsync($"/api/v1/fields/{field.Slug}/articles?topic=nope", Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");
        problem["title"]!.GetValue<string>().Should().Be("الموضوع مش موجود.");
    }

    [Fact]
    public async Task The_field_articles_are_newest_first_filter_by_topic_page_by_cursor_and_drop_hidden_and_deleted_ones()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync("Field Articles Writer");
        var a1 = await PublishAsync(writer, field, "A one", field.TopicA);
        var a2 = await PublishAsync(writer, field, "A two", field.TopicA);
        var b1 = await PublishAsync(writer, field, "B one", field.TopicB);
        var n1 = await PublishAsync(writer, field, "No topic one");
        var a3 = await PublishAsync(writer, field, "A three", field.TopicA);
        var deleted = await PublishAsync(writer, field, "Deleted one", field.TopicA);
        (await writer.Client.DeleteAsync($"/api/v1/articles/{deleted}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var guest = api.GuestClient();
        var url = $"/api/v1/fields/{field.Slug}/articles";

        var page1 = await guest.GetAsync($"{url}?limit=2", Ct).OkJsonAsync();
        Ids(page1["items"]).Should().Equal(a3, n1);
        var page2 = await guest.GetAsync($"{url}?limit=2&cursor={Uri.EscapeDataString(page1["nextCursor"]!.GetValue<string>())}", Ct).OkJsonAsync();
        Ids(page2["items"]).Should().Equal(b1, a2);
        var page3 = await guest.GetAsync($"{url}?limit=2&cursor={Uri.EscapeDataString(page2["nextCursor"]!.GetValue<string>())}", Ct).OkJsonAsync();
        Ids(page3["items"]).Should().Equal(a1);
        page3["nextCursor"].Should().BeNull();
        Ids((await guest.GetAsync($"{url}?cursor=not-a-cursor", Ct).OkJsonAsync())["items"]).Should().Equal(a3, n1, b1, a2, a1);

        Ids((await guest.GetAsync($"{url}?topic={field.TopicASlug.ToUpperInvariant()}", Ct).OkJsonAsync())["items"]).Should().Equal(a3, a2, a1);
        Ids((await guest.GetAsync($"{url}?topic={field.TopicBSlug}", Ct).OkJsonAsync())["items"]).Should().Equal(b1);
        Ids((await guest.GetAsync($"{url}?topic=", Ct).OkJsonAsync())["items"]).Should().HaveCount(5, "an empty topic is the whole field");

        // A signed-in reader gets their own state on the cards; guests don't.
        var reader = await api.UserAsync();
        (await reader.Client.ReactAsync(a2, "love")).StatusCode.Should().Be(HttpStatusCode.OK);
        var cards = (await reader.Client.GetAsync(url, Ct).OkJsonAsync())["items"]!.AsArray();
        cards.Single(x => x!["id"]!.GetValue<Guid>() == a2)!["myReaction"]!.GetValue<string>().Should().Be("love");
        (await guest.GetAsync(url, Ct).OkJsonAsync())["items"]!.AsArray()
            .Single(x => x!["id"]!.GetValue<Guid>() == a2)!["myReaction"].Should().BeNull();

        // Hidden by a moderator: gone at once, from the guests' cached page too.
        var moderator = (await api.SuperAdminAsync("Test Moderator")).Client;
        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "hide", targetType = "article", targetId = a3, note = "Test hide." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        Ids((await guest.GetAsync($"{url}?limit=2", Ct).OkJsonAsync())["items"]).Should().Equal(n1, b1);
    }

    // ── Explore ─────────────────────────────────────────────────

    [Fact]
    public async Task Explore_shows_every_section_from_shared_caches_with_each_callers_own_state_and_see_all_pages_the_rankings()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync("Explore Writer");
        var top = await PublishAsync(writer, field, "Explore top");
        var second = await PublishAsync(writer, field, "Explore second");
        var hidden = await PublishAsync(writer, field, "Explore hidden");
        var readers = await ReadersAsync(44);
        var now = DateTime.UtcNow;
        // Far more engagement than anything else in the suite, so these lead both rankings.
        await SaveAsync(top, readers[..40], now.AddHours(-1));
        await SaveAsync(second, readers[..36], now.AddHours(-1));
        await SaveAsync(hidden, readers[..38], now.AddHours(-1));
        await RecomputeCountersAsync(top, second, hidden);

        var saver = await api.UserAsync();
        var other = await api.UserAsync();
        (await saver.Client.PutEmptyAsync($"/api/v1/me/saved/{top}")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await saver.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow")).StatusCode.Should().Be(HttpStatusCode.OK);
        var moderator = (await api.SuperAdminAsync("Test Moderator")).Client;
        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "hide", targetType = "article", targetId = hidden, note = "Test hide." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await ClearCachesAsync();

        var guest = await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        Ids(guest["trending"]).Take(2).Should().Equal(top, second);
        Ids(guest["trending"]).Should().NotContain(hidden).And.HaveCountLessThanOrEqualTo(6);
        Ids(guest["mostSaved"]).Take(2).Should().Equal(top, second);
        Ids(guest["mostSaved"]).Should().NotContain(hidden).And.HaveCountLessThanOrEqualTo(6);
        guest["trending"]![0]!["isSaved"]!.GetValue<bool>().Should().BeFalse();
        guest["trending"]![0]!["excerpt"].Should().NotBeNull("cards are the post card (F34)");
        var tile = guest["fields"]!.AsArray().Single(x => x!["slug"]!.GetValue<string>() == field.Slug)!;
        (tile["id"]!.GetValue<Guid>(), tile["name"]!.GetValue<string>(), tile["articleCount"]!.GetValue<int>())
            .Should().Be((field.Id, field.NameEn, 2));
        guest["fields"]!.AsArray().Select(x => x!["slug"]!.GetValue<string>()).Should().NotContain("medicine", "only enabled fields");
        guest["newWriters"]![0]!["id"]!.GetValue<Guid>().Should().Be(writer.Id, "the latest first publish");
        guest["newWriters"]!.AsArray().Should().HaveCountLessThanOrEqualTo(10)
            .And.OnlyContain(u => !u!["isFollowing"]!.GetValue<bool>());
        Ids(guest["newWriters"]).Should().NotContain(SystemUsers.EditorialId);

        // Two callers with the same languages share the cached sections, each with their own state.
        var mine = await saver.Client.GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        var theirs = await other.Client.GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        Ids(mine["trending"]).Take(2).Should().Equal(top, second);
        mine["trending"]![0]!["isSaved"]!.GetValue<bool>().Should().BeTrue();
        mine["trending"]![0]!["isFollowingAuthor"]!.GetValue<bool>().Should().BeTrue();
        mine["newWriters"]![0]!["isFollowing"]!.GetValue<bool>().Should().BeTrue();
        theirs["trending"]![0]!["isSaved"]!.GetValue<bool>().Should().BeFalse();
        theirs["newWriters"]![0]!["isFollowing"]!.GetValue<bool>().Should().BeFalse();

        // See all: the full rankings, paged by position.
        var first = await api.GuestClient().GetAsync("/api/v1/explore/trending?limit=1", Ct).OkJsonAsync();
        Ids(first["items"]).Should().Equal(top);
        var next = await api.GuestClient()
            .GetAsync($"/api/v1/explore/trending?limit=1&cursor={Uri.EscapeDataString(first["nextCursor"]!.GetValue<string>())}", Ct).OkJsonAsync();
        Ids(next["items"]).Should().Equal(second);
        Ids((await api.GuestClient().GetAsync("/api/v1/explore/trending?limit=1&cursor=garbage", Ct).OkJsonAsync())["items"])
            .Should().Equal([top], "a cursor that doesn't decode is the first page");
        var all = await AllPagesAsync("/api/v1/explore/trending?limit=50");
        all.Should().OnlyHaveUniqueItems().And.HaveCountLessThanOrEqualTo(100).And.NotContain(hidden);
        Ids((await saver.Client.GetAsync("/api/v1/explore/most-saved?limit=2", Ct).OkJsonAsync())["items"]).Should().Equal(top, second);
        (await saver.Client.GetAsync("/api/v1/explore/most-saved?limit=2", Ct).OkJsonAsync())["items"]![0]!["isSaved"]!
            .GetValue<bool>().Should().BeTrue();
        (await AllPagesAsync("/api/v1/explore/most-saved?limit=50")).Should().OnlyHaveUniqueItems().And.HaveCountLessThanOrEqualTo(100);

        var arabic = await api.GuestClient("ar").GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        arabic["fields"]!.AsArray().Single(x => x!["slug"]!.GetValue<string>() == field.Slug)!["name"]!.GetValue<string>().Should().Be(field.NameAr);
        Ids(arabic["trending"]).Take(2).Should().Equal(top, second);

        // The rankings are cached: new activity moves them once the cache expires (or a publish drops it).
        await SaveAsync(second, readers[36..], now);
        Ids((await api.GuestClient().GetAsync("/api/v1/explore/trending?limit=2", Ct).OkJsonAsync())["items"]).Should().Equal(top, second);
        await ClearCachesAsync();
        Ids((await api.GuestClient().GetAsync("/api/v1/explore/trending?limit=2", Ct).OkJsonAsync())["items"])
            .Should().Equal([second, top], "44 saves this week against 41");
    }

    [Fact]
    public async Task Featured_paths_are_the_featured_published_paths_with_visible_articles_in_featured_order()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync("Featured Paths Writer");
        var a = await PublishAsync(writer, field, "Path article A");
        var b = await PublishAsync(writer, field, "Path article B");
        var hidden = await PublishAsync(writer, field, "Path article hidden");
        await WithDbAsync(db => db.Articles.Where(x => x.Id == hidden).ExecuteUpdateAsync(s => s.SetProperty(x => x.HiddenAt, DateTime.UtcNow), Ct));

        var second = await PathAsync(field, [a], featuredOrder: -1);
        var firstPath = await PathAsync(field, [a, b], featuredOrder: -2);
        var notFeatured = await PathAsync(field, [b], featuredOrder: null);
        var unpublished = await PathAsync(field, [a], featuredOrder: -3, publish: false);
        var empty = await PathAsync(field, [hidden], featuredOrder: -4);
        var reader = await api.UserAsync();
        (await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{firstPath}")).StatusCode.Should().Be(HttpStatusCode.OK);
        await ClearCachesAsync();

        var guest = await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        var paths = Ids(guest["featuredPaths"]);
        paths.Take(2).Should().Equal([firstPath, second], "featured order, lowest first");
        paths.Should().NotContain([notFeatured, unpublished, empty]).And.HaveCountLessThanOrEqualTo(6);
        guest["featuredPaths"]![0]!["articleCount"]!.GetValue<int>().Should().Be(2);
        guest["featuredPaths"]![0]!["progress"].Should().BeNull("guests have no progress");

        var mine = await reader.Client.GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        Ids(mine["featuredPaths"]).Take(2).Should().Equal(firstPath, second);
        mine["featuredPaths"]![0]!["enrollment"].Should().NotBeNull("the caller's enrollment");
        mine["featuredPaths"]![0]!["progress"]!["total"]!.GetValue<int>().Should().Be(2);

        // The seeded editorial paths are featured in their sort order (the migration and seeder #7).
        var editorial = await WithDbAsync(db => db.LearningPaths.Where(p => p.IsEditorial)
            .Select(p => new { p.IsFeatured, p.FeaturedOrder, p.SortOrder }).ToListAsync(Ct));
        editorial.Should().NotBeEmpty().And.OnlyContain(p => p.IsFeatured && p.FeaturedOrder == p.SortOrder);
    }

    // ── Helpers ─────────────────────────────────────────────────

    /// <summary>A short unique word (lower-case hex).</summary>
    private static string Unique() => $"{Guid.NewGuid():N}"[..10];

    private static List<Guid> Ids(JsonNode? items) => [.. items!.AsArray().Select(x => x!["id"]!.GetValue<Guid>())];

    private static List<(string Slug, int Articles, bool Following)> Topics(JsonNode page) =>
        [.. page["topics"]!.AsArray().Select(t => (t!["slug"]!.GetValue<string>(), t["articleCount"]!.GetValue<int>(), t["isFollowing"]!.GetValue<bool>()))];

    /// <summary>A new enabled field with two topics, disabled again when the test ends.</summary>
    private async Task<TestField> NewFieldAsync(bool sensitive = false)
    {
        var u = Unique();
        var (slug, nameAr, nameEn, topicA, topicB) = ($"xf-{u}", $"مجال {u}", $"Field {u}", $"ta-{u}", $"tb-{u}");
        TestField? created = null;
        await WithDbAsync(async db =>
        {
            var field = new Field(slug, nameAr, nameEn, "cpu", "primary", 900);
            field.Update(nameAr, nameEn, "cpu", "primary", 900, sensitive, requiresSources: false, isEnabled: true);
            db.Fields.Add(field);
            await db.SaveChangesAsync(Ct);
            var a = field.UpsertTopic(topicA, $"موضوع أ {u}", $"Topic A {u}", 1);
            var b = field.UpsertTopic(topicB, $"موضوع ب {u}", $"Topic B {u}", 2);
            await db.SaveChangesAsync(Ct);
            created = new TestField(field.Id, slug, nameAr, nameEn, a.Id, topicA, b.Id, topicB);
        });
        _fields.Add(created!.Id);
        await ClearCachesAsync();
        return created;
    }

    private static async Task<Guid> PublishAsync(SignedInUser writer, TestField field, string title, Guid? topicId = null)
    {
        var document = ArticleTestKit.Document(field.Id, $"{title} {Unique()}", blocks: [ArticleTestKit.Paragraph("Explore test article.")]);
        document["topicId"] = topicId is { } topic ? JsonValue.Create(topic) : null;
        return (await writer.Client.WriteAndPublishAsync(document)).Id;
    }

    /// <summary>Readers that only exist to engage: completed profiles straight in the database.</summary>
    private async Task<Guid[]> ReadersAsync(int count)
    {
        var users = Enumerable.Range(0, count)
            .Select(_ => User.CreateSeeded(ApiFactory.NewPhoneNumber(), "Explore Reader", $"xr_{Guid.NewGuid():N}"[..20]))
            .ToList();
        await WithDbAsync(async db =>
        {
            db.Users.AddRange(users);
            await db.SaveChangesAsync(Ct);
        });
        return [.. users.Select(u => u.Id)];
    }

    private Task SaveAsync(Guid articleId, IEnumerable<Guid> users, DateTime at) =>
        AddAsync(users.Select(u => (object)SavedArticle.Create(u, articleId, at)));

    private Task ReactAsync(Guid articleId, IEnumerable<Guid> users, DateTime at) =>
        AddAsync(users.Select(u => (object)Reaction.Set(null, u, articleId, ReactionType.Insightful, at)));

    private Task ReadAsync(Guid articleId, IEnumerable<Guid> users, DateTime at) =>
        AddAsync(users.Select(u => (object)ReadingProgress.SeededCompleted(u, articleId, "en", 120, at)));

    private Task CommentAsync(Guid articleId, Guid author, DateTime at, bool hide = false, bool delete = false)
    {
        var comment = Comment.Post(articleId, author, $"Explore comment {Unique()}", [], at);
        if (hide) comment.Hide(Guid.NewGuid(), at);
        if (delete) comment.Delete(author, at);
        return AddAsync([comment]);
    }

    /// <summary>Rows straight in the database (no notifications, no outbox).</summary>
    private Task AddAsync(IEnumerable<object> rows) => WithDbAsync(async db =>
    {
        foreach (var row in rows)
        {
            if (row is AggregateRoot aggregate) aggregate.ClearDomainEvents();
            db.Add(row);
        }
        await db.SaveChangesAsync(Ct);
    });

    private Task QualityAsync(params (Guid Id, double Score)[] scores) => WithDbAsync(async db =>
    {
        foreach (var (id, score) in scores)
            await db.Articles.Where(a => a.Id == id).ExecuteUpdateAsync(s => s.SetProperty(a => a.QualityScore, score), Ct);
    });

    private Task PublishedAtAsync(Guid articleId, DateTime at) =>
        WithDbAsync(db => db.Articles.Where(a => a.Id == articleId).ExecuteUpdateAsync(s => s.SetProperty(a => a.PublishedAt, at), Ct));

    private Task SuspendAsync(Guid userId) => WithDbAsync(async db =>
    {
        (await db.Users.SingleAsync(u => u.Id == userId, Ct)).Suspend(until: null);
        await db.SaveChangesAsync(Ct);
    });

    private async Task RecomputeCountersAsync(params Guid[] articleIds)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<ArticleCounters>().RecomputeAsync(articleIds, Ct);
    }

    /// <summary>A published (or not) path of <paramref name="articleIds"/> in the field; featured at the order given.</summary>
    private async Task<Guid> PathAsync(TestField field, Guid[] articleIds, int? featuredOrder, bool publish = true)
    {
        var slug = $"explore-path-{Guid.NewGuid():N}";
        var path = new LearningPath(slug, field.Id, $"مسار {slug[^6..]}", $"Path {slug[^6..]}", 1000);
        path.SetItemsInOrder(articleIds);
        if (publish) path.Publish().IsSuccess.Should().BeTrue();
        if (featuredOrder is { } order) path.SetFeatured(true, order);
        await WithDbAsync(async db =>
        {
            db.LearningPaths.Add(path);
            await db.SaveChangesAsync(Ct);
        });
        return path.Id;
    }

    /// <summary>Runs a ranking over the visible articles of <paramref name="field"/> only.</summary>
    private Task<List<Guid>> RankAsync(Func<ExploreRankings, IQueryable<Article>, Task<List<Guid>>> rank, TestField field) =>
        WithRankingsAsync(rankings => rank(rankings, rankings.Visible().Where(a => a.FieldId == field.Id)));

    private async Task<T> WithRankingsAsync<T>(Func<ExploreRankings, Task<T>> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await action(scope.ServiceProvider.GetRequiredService<ExploreRankings>());
    }

    private async Task<List<Guid>> AllPagesAsync(string url)
    {
        var ids = new List<Guid>();
        string? cursor = null;
        for (var page = 0; page < 10; page++)
        {
            var body = await api.GuestClient().GetAsync(cursor is null ? url : $"{url}&cursor={Uri.EscapeDataString(cursor)}", Ct).OkJsonAsync();
            ids.AddRange(Ids(body["items"]));
            cursor = body["nextCursor"]?.GetValue<string>();
            if (cursor is null) return ids;
        }
        throw new InvalidOperationException("The ranking has more pages than it may.");
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
            .RemoveByTagAsync([CacheTags.Feed, CacheTags.Taxonomy, CacheTags.Articles], Ct);
    }
}
