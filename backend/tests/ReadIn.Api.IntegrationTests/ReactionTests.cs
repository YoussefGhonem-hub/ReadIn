using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Domain.Reading;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>F10 Reactions end to end, with the counters outbox handler and the live publisher (F27).</summary>
[Collection(ApiCollection.Name)]
public sealed class ReactionTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Guests_must_sign_in_to_react()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();

        await api.GuestClient().ReactAsync(articleId, "love").ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
        await api.GuestClient().DeleteAsync($"/api/v1/articles/{articleId}/reaction", Ct).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
    }

    [Fact]
    public async Task One_reaction_per_user_that_can_change_and_be_removed()
    {
        var author = await api.UserAsync();
        var reader = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();

        var first = await reader.Client.ReactAsync(articleId, "insightful").OkJsonAsync();
        first["reactions"]!.Counts().Should().Be((1, 0, 0, 0));
        first["total"]!.GetValue<int>().Should().Be(1);
        first["myReaction"]!.GetValue<string>().Should().Be("insightful");

        var changed = await reader.Client.ReactAsync(articleId, "mindBlown").OkJsonAsync();
        changed["reactions"]!.Counts().Should().Be((0, 0, 0, 1), "changing replaces the one reaction");
        changed["myReaction"]!.GetValue<string>().Should().Be("mindBlown");

        var again = await reader.Client.ReactAsync(articleId, "mindBlown").OkJsonAsync();
        again["total"]!.GetValue<int>().Should().Be(1, "setting the same reaction is idempotent");

        var removed = await reader.Client.DeleteAsync($"/api/v1/articles/{articleId}/reaction", Ct).OkJsonAsync();
        removed["total"]!.GetValue<int>().Should().Be(0);
        removed["myReaction"].Should().BeNull();

        var removedAgain = await reader.Client.DeleteAsync($"/api/v1/articles/{articleId}/reaction", Ct).OkJsonAsync();
        removedAgain["total"]!.GetValue<int>().Should().Be(0, "removing is idempotent");
        api.Realtime.CountersFor(articleId).Should().HaveCount(3, "set, change and remove each recompute once; no-ops don't")
            .And.EndWith(new ArticleLiveCounters(0, 0, 0, 0, 0, 0));
    }

    [Theory]
    [InlineData("like")]
    [InlineData("")]
    [InlineData(null)]
    public async Task Unknown_reactions_are_a_validation_error(string? type)
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();

        var problem = await author.Client.ReactAsync(articleId, type).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");

        problem["errors"]!["type"]![0]!.GetValue<string>().Should().Be("reaction.invalid");
    }

    [Fact]
    public async Task Unpublished_and_unknown_articles_are_not_found()
    {
        var author = await api.UserAsync();
        var created = await author.Client.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = await author.Client.FieldIdAsync("frontend"), language = "en", title = "A draft nobody can react to",
            content = new { version = 1, language = "en", blocks = new object[] { new { id = "p1", type = "paragraph", content = new[] { new { type = "text", text = "Draft." } } } } },
            isAiAssisted = false,
        }, Ct);
        var draftId = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();

        await author.Client.ReactAsync(draftId, "love").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await author.Client.ReactAsync(Guid.NewGuid(), "love").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await api.GuestClient().GetAsync($"/api/v1/articles/{draftId}/reactions", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task Who_reacted_is_public_newest_first_filterable_and_paged()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var readers = new List<SignedInUser>();
        foreach (var type in new[] { "love", "fire", "love" })
        {
            var reader = await api.UserAsync($"Reactor {readers.Count + 1}");
            await reader.Client.ReactAsync(articleId, type).OkJsonAsync();
            readers.Add(reader);
        }

        var guest = api.GuestClient();
        var all = await guest.GetAsync($"/api/v1/articles/{articleId}/reactions", Ct).OkJsonAsync();
        var items = all["items"]!.AsArray();
        items.Select(i => i!["user"]!["id"]!.GetValue<Guid>()).Should().Equal(readers[2].Id, readers[1].Id, readers[0].Id);
        items[0]!["type"]!.GetValue<string>().Should().Be("love");
        items[0]!["user"]!["username"]!.GetValue<string>().Should().Be(readers[2].Me["username"]!.GetValue<string>());
        items[0]!["user"]!["isVerified"]!.GetValue<bool>().Should().BeFalse();
        items[0]!["reactedAt"]!.GetValue<string>().Should().EndWith("Z");
        all["nextCursor"].Should().BeNull();

        var loves = await guest.GetAsync($"/api/v1/articles/{articleId}/reactions?type=love", Ct).OkJsonAsync();
        loves["items"]!.AsArray().Select(i => i!["user"]!["id"]!.GetValue<Guid>()).Should().Equal(readers[2].Id, readers[0].Id);

        var first = await guest.GetAsync($"/api/v1/articles/{articleId}/reactions?limit=2", Ct).OkJsonAsync();
        first["items"]!.AsArray().Should().HaveCount(2);
        var cursor = first["nextCursor"]!.GetValue<string>();
        var second = await guest.GetAsync($"/api/v1/articles/{articleId}/reactions?limit=2&cursor={cursor}", Ct).OkJsonAsync();
        second["items"]!.AsArray().Single()!["user"]!["id"]!.GetValue<Guid>().Should().Be(readers[0].Id);
        second["nextCursor"].Should().BeNull();

        var problem = await guest.GetAsync($"/api/v1/articles/{articleId}/reactions?type=wow", Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        problem["errors"]!["type"]![0]!.GetValue<string>().Should().Be("reaction.invalid");
    }

    [Fact]
    public async Task Counters_are_recomputed_after_commit_cached_details_refresh_and_the_live_counters_are_published()
    {
        var author = await api.UserAsync();
        var (articleId, slug) = await author.Client.PublishAsync();
        var guest = api.GuestClient();
        (await guest.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["reactionCount"]!.GetValue<int>()
            .Should().Be(0, "this caches the details");

        var love = await api.UserAsync();
        var fire = await api.UserAsync();
        await love.Client.ReactAsync(articleId, "love").OkJsonAsync();
        await fire.Client.ReactAsync(articleId, "insightful").OkJsonAsync();
        await fire.Client.ReactAsync(articleId, "fire").OkJsonAsync();
        await love.Client.PutEmptyAsync($"/api/v1/me/saved/{articleId}").OkJsonAsync();

        var details = (await guest.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!;
        details["reactions"]!.Counts().Should().Be((0, 1, 1, 0));
        details["reactionCount"]!.GetValue<int>().Should().Be(2, "reactionCount stays the sum");
        details["saveCount"]!.GetValue<int>().Should().Be(1);
        details["commentCount"]!.GetValue<int>().Should().Be(0);

        using (var scope = api.Services.CreateScope())
        {
            var stored = await scope.ServiceProvider.GetRequiredService<AppDbContext>().Articles.AsNoTracking().SingleAsync(a => a.Id == articleId, Ct);
            (stored.InsightfulCount, stored.LoveCount, stored.FireCount, stored.MindBlownCount, stored.ReactionCount, stored.SaveCount)
                .Should().Be((0, 1, 1, 0, 2, 1));
        }

        var published = api.Realtime.CountersFor(articleId);
        published.Should().HaveCount(4, "one recompute per committed change, each published");
        published[^1].Should().Be(new ArticleLiveCounters(Insightful: 0, Love: 1, Fire: 1, MindBlown: 0, CommentCount: 0, SaveCount: 1));
        published[1].Should().Be(new ArticleLiveCounters(1, 1, 0, 0, 0, 0), "counters are replaced from SQL, never added to");
    }

    [Fact]
    public async Task Cards_and_details_carry_the_viewers_reaction_and_save()
    {
        var author = await api.UserAsync();
        var reader = await api.UserAsync();
        var (articleId, slug) = await author.Client.PublishAsync();
        await reader.Client.ReactAsync(articleId, "fire").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/saved/{articleId}").OkJsonAsync();

        var mine = await reader.Client.FindInForYouAsync(articleId);
        mine["myReaction"]!.GetValue<string>().Should().Be("fire");
        mine["isSaved"]!.GetValue<bool>().Should().BeTrue();
        mine["reactions"]!.Counts().Should().Be((0, 0, 1, 0));
        mine["saveCount"]!.GetValue<int>().Should().Be(1);

        var guestCard = await api.GuestClient().FindInForYouAsync(articleId);
        guestCard["myReaction"].Should().BeNull();
        guestCard["isSaved"]!.GetValue<bool>().Should().BeFalse();
        guestCard["reactions"]!.Counts().Should().Be((0, 0, 1, 0), "counts are public");

        var stranger = await api.UserAsync();
        var theirs = await stranger.Client.FindInForYouAsync(articleId);
        theirs["myReaction"].Should().BeNull("viewer state belongs to the viewer only");
        theirs["isSaved"]!.GetValue<bool>().Should().BeFalse();

        var details = (await reader.Client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!;
        details["myReaction"]!.GetValue<string>().Should().Be("fire");
        details["isSaved"]!.GetValue<bool>().Should().BeTrue();
        details["isFollowingAuthor"]!.GetValue<bool>().Should().BeFalse();

        await reader.Client.PutEmptyAsync($"/api/v1/users/{author.Id}/follow").OkJsonAsync();
        (await reader.Client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["isFollowingAuthor"]!.GetValue<bool>()
            .Should().BeTrue("the cached details are personalized on every request");
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["isFollowingAuthor"]!.GetValue<bool>()
            .Should().BeFalse();
        (await author.Client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["myReaction"]
            .Should().BeNull("the author did not react");
    }

    [Fact]
    public async Task Article_cards_serialize_the_contract_shape()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();

        var card = await author.Client.FindInForYouAsync(articleId);

        card.Select(p => p.Key).Should().Equal(
            "id", "slug", "language", "title", "subtitle", "coverUrl", "field", "author", "readingTimeMinutes", "isReviewed",
            "isAiAssisted", "versionBadge", "publishedAt", "reactionCount", "reactions", "commentCount", "saveCount", "myReaction",
            "isSaved", "attachments");
        card["reactions"]!.AsObject().Select(p => p.Key).Should().Equal("insightful", "love", "fire", "mindBlown");
    }

    [Fact]
    public async Task Admins_rebuild_every_counter_from_sql()
    {
        var author = await api.UserAsync();
        var reader = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        await reader.Client.ReactAsync(articleId, "love").OkJsonAsync();

        using (var scope = api.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<AppDbContext>().Articles.Where(a => a.Id == articleId)
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.ReactionCount, 99).SetProperty(a => a.LoveCount, 99), Ct);
        }

        await reader.Client.PostAsync("/api/v1/admin/realtime/rebuild-counters", null, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");

        var superAdmin = await api.SeedUserClientAsync(ApiFactory.SuperAdminPhone);
        var rebuilt = await superAdmin.PostAsync("/api/v1/admin/realtime/rebuild-counters", null, Ct).OkJsonAsync();
        rebuilt["articleCount"]!.GetValue<int>().Should().BeGreaterThan(1);

        using var check = api.Services.CreateScope();
        var stored = await check.ServiceProvider.GetRequiredService<AppDbContext>().Articles.AsNoTracking().SingleAsync(a => a.Id == articleId, Ct);
        (stored.LoveCount, stored.ReactionCount).Should().Be((1, 1));
        api.Realtime.CountersFor(articleId)[^1].Should().Be(new ArticleLiveCounters(0, 1, 0, 0, 0, 0));
    }

    [Fact]
    public async Task The_rebuild_recomputes_read_counts_from_completed_reads()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var readers = new[] { await api.UserAsync(), await api.UserAsync(), await api.UserAsync() };

        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var now = DateTime.UtcNow;
            db.ReadingProgress.AddRange(
                ReadingProgress.SeededCompleted(readers[0].Id, articleId, "en", 120, now.AddHours(-2)),
                ReadingProgress.SeededCompleted(readers[1].Id, articleId, "en", 150, now.AddHours(-1)),
                ReadingProgress.SeededInProgress(readers[2].Id, articleId, "en", 40, 60, now));
            await db.SaveChangesAsync(Ct);
            await db.Articles.Where(a => a.Id == articleId).ExecuteUpdateAsync(s => s.SetProperty(a => a.ReadCount, 99), Ct);
        }

        using (var scope = api.Services.CreateScope())
            await scope.ServiceProvider.GetRequiredService<ArticleCounters>().RebuildAllAsync(Ct);

        using var check = api.Services.CreateScope();
        var stored = await check.ServiceProvider.GetRequiredService<AppDbContext>().Articles.AsNoTracking().SingleAsync(a => a.Id == articleId, Ct);
        stored.ReadCount.Should().Be(2, "only completed reads count; the one in progress doesn't");
    }
}
