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
        article["isReviewed"]!.GetValue<bool>().Should().BeFalse("no human reviewed it");
        article["reviewedBy"].Should().BeNull("a \"Reviewed by\" badge is never faked");
        article["lastReviewedAt"]!.GetValue<DateTime>().Should().Be(new DateTime(2026, 11, 3, 0, 0, 0, DateTimeKind.Utc));
        article["author"]!["username"]!.GetValue<string>().Should().Be("readin");
        article["author"]!["isVerified"]!.GetValue<bool>().Should().BeTrue();
        article["author"]!["avatarUrl"]!.GetValue<string>().Should().Contain("/uploads/avatars/").And.EndWith("_256.webp");
        article["coverUrl"]!.GetValue<string>().Should().Contain("/uploads/covers/").And.EndWith("_1200.webp");
        article["publishedAt"]!.GetValue<DateTime>().Should().BeBefore(DateTime.UtcNow.AddDays(-60),
            "seeded articles get staggered publish dates over the last ~120 days");

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var stored = await db.Articles.SingleAsync(a => a.Slug == Slug, Ct);
        stored.ReviewStatus.Should().Be(ReviewStatus.Pending, "it waits in the reviewer queue");
        stored.AutoCheckedAt.Should().NotBeNull();

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
    public async Task Today_falls_back_to_an_auto_checked_article_when_no_reviewed_article_matches()
    {
        var client = api.ClientFor("it-today-fallback", "today.fallback@readin.test");
        (await client.PostAsJsonAsync("/api/v1/auth/sync", new { uiLanguage = "en", timeZone = "Africa/Cairo" }, Ct)).EnsureSuccessStatusCode();

        // Security has only the pipeline article (published, pending review); the other two fields have no articles.
        var fields = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Where(f => f!["slug"]!.GetValue<string>() is "security" or "mobile" or "devops-cloud")
            .Select(f => f!["id"]!.GetValue<Guid>())
            .ToList();
        (await client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = fields, topicIds = Array.Empty<Guid>() }, Ct)).EnsureSuccessStatusCode();

        var today = await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);

        today!["slug"]!.GetValue<string>().Should().Be(Slug);
        today["isReviewed"]!.GetValue<bool>().Should().BeFalse();
    }
}
