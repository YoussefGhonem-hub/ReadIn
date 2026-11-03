using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>The demo-interactions seeder (SPEC §18.2 #8): deterministic, idempotent, and counters that match the rows.</summary>
[Collection(ApiCollection.Name)]
public sealed class DemoInteractionsSeedingTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Demo_users_follow_react_and_save_and_reader1_has_a_collection()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var reader1 = await db.Users.AsNoTracking().SingleAsync(u => u.Email == "reader1@readin.test", Ct);

        (await db.UserFollows.AnyAsync(f => f.FollowerId == reader1.Id && f.FolloweeId == SystemUsers.EditorialId, Ct)).Should().BeTrue();
        (await db.SavedArticles.CountAsync(s => s.UserId == reader1.Id, Ct)).Should().BeGreaterThanOrEqualTo(3);
        var collection = await db.Collections.AsNoTracking().Include(c => c.Items).SingleAsync(c => c.UserId == reader1.Id, Ct);
        collection.Name.Should().Be("Interview prep");
        collection.Items.Should().HaveCount(2);
        (await db.Reactions.CountAsync(Ct)).Should().BeGreaterThan(0);

        var client = await api.SeedUserClientAsync(ApiFactory.Reader1Phone);
        var following = (await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/following", Ct))!["items"]!.AsArray();
        following.Should().NotBeEmpty("reader1 follows the official account, the author of the seeded articles");
    }

    [Fact]
    public async Task Seeded_counters_match_the_rows_and_a_second_run_changes_nothing()
    {
        await ExpectCountersToMatchRowsAsync();
        var before = await SnapshotAsync();

        using (var scope = api.Services.CreateScope())
        {
            var seeder = scope.ServiceProvider.GetServices<ISeeder>().Single(s => s.Name == "demo-interactions");
            (await seeder.SeedAsync(Ct)).Should().BeTrue();
        }

        (await SnapshotAsync()).Should().Equal(before, "the seeder is deterministic and add-only");
        await ExpectCountersToMatchRowsAsync();
    }

    /// <summary>Counters of the seeded (official account) articles, which only the seeder touches.</summary>
    private async Task<List<(string Slug, int Reactions, int Saves, int Follows)>> SnapshotAsync()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var follows = await db.UserFollows.CountAsync(f => f.Follower.Email != null && f.Follower.Email.EndsWith("@readin.test"), Ct);
        return [.. (await db.Articles.AsNoTracking()
                .Where(a => a.AuthorId == SystemUsers.EditorialId && a.Status == ArticleStatus.Published)
                .OrderBy(a => a.Slug)
                .Select(a => new { a.Slug, a.ReactionCount, a.SaveCount })
                .ToListAsync(Ct))
            .Select(a => (a.Slug, a.ReactionCount, a.SaveCount, follows))];
    }

    private async Task ExpectCountersToMatchRowsAsync()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var articles = await db.Articles.AsNoTracking()
            .Where(a => a.AuthorId == SystemUsers.EditorialId && a.Status == ArticleStatus.Published)
            .Select(a => new
            {
                a.ReactionCount,
                a.InsightfulCount,
                a.LoveCount,
                a.FireCount,
                a.MindBlownCount,
                a.SaveCount,
                Insightful = db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Insightful),
                Love = db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Love),
                Fire = db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Fire),
                MindBlown = db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.MindBlown),
                Saves = db.SavedArticles.Count(s => s.ArticleId == a.Id),
            })
            .ToListAsync(Ct);

        articles.Should().NotBeEmpty();
        articles.Sum(a => a.ReactionCount).Should().BeGreaterThan(0, "demo users react to the seeded articles");
        foreach (var a in articles)
        {
            (a.InsightfulCount, a.LoveCount, a.FireCount, a.MindBlownCount).Should().Be((a.Insightful, a.Love, a.Fire, a.MindBlown));
            a.ReactionCount.Should().Be(a.Insightful + a.Love + a.Fire + a.MindBlown);
            a.SaveCount.Should().Be(a.Saves);
        }
    }
}
