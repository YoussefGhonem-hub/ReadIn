using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The foreign keys an account hard delete relies on: deleting the Users row removes the user's reactions, saves,
/// collections and follows through cascades, once the rows that follow them are deleted first (FolloweeId is NO ACTION:
/// SQL Server refuses a second cascade path into UserFollows; NotificationActors.ActorId likewise, F17). Then the touched
/// articles' counters are recomputed.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class EngagementDeletionTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Deleting_a_user_row_cascades_their_engagement_and_counters_can_be_recomputed()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var leaving = await api.UserAsync();
        await leaving.Client.ReactAsync(articleId, "fire").OkJsonAsync();
        var collection = await leaving.Client.PostAsJsonAsync("/api/v1/me/collections", new { name = "Gone soon" }, Ct);
        collection.EnsureSuccessStatusCode();
        var collectionId = (await collection.Content.ReadFromJsonAsync<System.Text.Json.Nodes.JsonObject>(Ct))!["id"]!.GetValue<Guid>();
        (await leaving.Client.PutEmptyAsync($"/api/v1/me/collections/{collectionId}/articles/{articleId}")).EnsureSuccessStatusCode();
        await leaving.Client.PutEmptyAsync($"/api/v1/users/{author.Id}/follow").OkJsonAsync();
        await author.Client.PutEmptyAsync($"/api/v1/users/{leaving.Id}/follow").OkJsonAsync();

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.RefreshTokens.Where(t => t.UserId == leaving.Id).ExecuteDeleteAsync(Ct);
        await db.UserFollows.Where(f => f.FolloweeId == leaving.Id).ExecuteDeleteAsync(Ct);
        await db.NotificationActors.Where(a => a.ActorId == leaving.Id).ExecuteDeleteAsync(Ct);
        await db.Users.IgnoreQueryFilters().Where(u => u.Id == leaving.Id).ExecuteDeleteAsync(Ct);

        (await db.Reactions.AnyAsync(r => r.UserId == leaving.Id, Ct)).Should().BeFalse();
        (await db.SavedArticles.AnyAsync(s => s.UserId == leaving.Id, Ct)).Should().BeFalse();
        (await db.Collections.AnyAsync(c => c.Id == collectionId, Ct)).Should().BeFalse();
        (await db.CollectionItems.AnyAsync(i => i.CollectionId == collectionId, Ct)).Should().BeFalse();
        (await db.UserFollows.AnyAsync(f => f.FollowerId == leaving.Id || f.FolloweeId == leaving.Id, Ct)).Should().BeFalse();

        await scope.ServiceProvider.GetRequiredService<ArticleCounters>().RecomputeAsync([articleId], Ct);
        var article = await db.Articles.AsNoTracking().SingleAsync(a => a.Id == articleId, Ct);
        (article.FireCount, article.ReactionCount, article.SaveCount).Should().Be((0, 0, 0));
        api.Realtime.CountersFor(articleId)[^1].Should().Be(new Application.Common.Interfaces.ArticleLiveCounters(0, 0, 0, 0, 0, 0));
    }
}
