using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The content seeders against the fixture content root (backend/tests/fixtures/content): official account avatar,
/// pipeline articles with covers, learning paths, and Today's-article fallback to auto-checked articles (F07).
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ContentSeedingTests(ApiFactory api)
{
    private const string Slug = "hashing-is-not-encryption";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Pipeline_articles_are_published_by_the_official_account_and_wait_for_a_human_review()
    {
        var article = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{Slug}?lang=en", Ct))!;

        article["isAiAssisted"]!.GetValue<bool>().Should().BeTrue();
        article.ContainsKey("isReviewed").Should().BeFalse("there is no review (ADR 0015)");
        article.ContainsKey("reviewedBy").Should().BeFalse();
        article.ContainsKey("lastReviewedAt").Should().BeFalse();
        article["author"]!["username"]!.GetValue<string>().Should().Be("readin");
        article["author"]!["isVerified"]!.GetValue<bool>().Should().BeTrue();
        article["author"]!["avatarUrl"]!.GetValue<string>().Should().Contain("/uploads/avatars/").And.EndWith("_256.webp");
        article["coverUrl"]!.GetValue<string>().Should().Contain("/uploads/covers/").And.EndWith("_1200.webp");
        article["publishedAt"]!.GetValue<DateTime>().Should().BeBefore(DateTime.UtcNow.AddDays(-60),
            "seeded articles get staggered publish dates over the last ~120 days");

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var stored = await db.Articles.SingleAsync(a => a.Slug == Slug, Ct);
        stored.AutoCheckedAt.Should().Be(new DateTime(2026, 11, 3, 0, 0, 0, DateTimeKind.Utc), "meta.json lastReviewedAt is the pipeline check date");

        var cover = await db.MediaAssets.SingleAsync(m => m.OwnerId == SystemUsers.EditorialId && m.Purpose == MediaPurpose.Cover, Ct);
        cover.BlurHash.Should().NotBeNullOrEmpty();
        cover.Variants.Select(v => v.Width).Should().Equal(400, 800, 1200);
    }

    [Fact]
    public async Task The_official_avatar_is_the_logo_processed_by_the_image_pipeline()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var account = await db.Users.SingleAsync(u => u.Id == SystemUsers.EditorialId, Ct);
        var avatar = await db.MediaAssets.SingleAsync(m => m.OwnerId == SystemUsers.EditorialId && m.Purpose == MediaPurpose.Avatar, Ct);
        avatar.Variants.Select(v => v.Width).Should().Equal(64, 128, 256, 512);
        avatar.Variants.Should().OnlyContain(v => v.Width == v.Height, "avatars are square");
        account.AvatarUrl.Should().Be(avatar.Variants.Single(v => v.Width == 256).Path);
    }

    [Fact]
    public async Task Learning_paths_come_from_the_taxonomy_with_the_imported_articles_in_order()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var path = await db.LearningPaths.Include(p => p.Items).SingleAsync(p => p.Slug == "secure-by-default", Ct);
        var articleId = await db.Articles.Where(a => a.Slug == Slug).Select(a => a.Id).SingleAsync(Ct);
        path.IsPublished.Should().BeTrue();
        path.TitleAr.Should().Be("الأمان من الأساس");
        path.Items.Should().ContainSingle().Which.Should().Match<ReadIn.Domain.Learning.LearningPathItem>(i => i.ArticleId == articleId && i.Order == 1);
    }

    [Fact]
    public async Task Re_running_the_seeders_changes_nothing()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var before = (Articles: await db.Articles.CountAsync(Ct), Media: await db.MediaAssets.CountAsync(m => m.OwnerId == SystemUsers.EditorialId, Ct));
        var publishedAt = await db.Articles.Where(a => a.Slug == Slug).Select(a => a.PublishedAt).SingleAsync(Ct);

        await scope.ServiceProvider.GetRequiredService<SeedRunner>().RunAsync(force: true, Ct);

        db.ChangeTracker.Clear();
        (await db.Articles.CountAsync(Ct)).Should().Be(before.Articles);
        (await db.MediaAssets.CountAsync(m => m.OwnerId == SystemUsers.EditorialId, Ct)).Should().Be(before.Media,
            "an unchanged cover or logo is recognized from its stored URL and not processed again");
        (await db.Articles.Where(a => a.Slug == Slug).Select(a => a.PublishedAt).SingleAsync(Ct)).Should().Be(publishedAt);
    }

    [Fact]
    public async Task Today_picks_a_published_article_in_the_readers_interests()
    {
        var client = (await api.SignUpAsync()).Client;

        // Security has only the pipeline article; the other two fields have no articles.
        var fields = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Where(f => f!["slug"]!.GetValue<string>() is "security" or "mobile" or "devops-cloud")
            .Select(f => f!["id"]!.GetValue<Guid>())
            .ToList();
        (await client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = fields, topicIds = Array.Empty<Guid>() }, Ct)).EnsureSuccessStatusCode();

        var today = await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);

        today!["slug"]!.GetValue<string>().Should().Be(Slug, "any published article can be Today's article (ADR 0015)");
    }
}
