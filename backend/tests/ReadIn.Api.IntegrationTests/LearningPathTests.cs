using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Reading;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F09 learning paths, the Home "continue reading" and path cards (F03), the reader's "Next in path" block and F07's
/// preference for the active path. Paths are created in SQL (the admin API has its own tests) so each test owns its
/// paths and articles and every count is exact.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class LearningPathTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    // ── Listing and details ─────────────────────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Guests_see_published_paths_in_their_ui_language_without_progress()
    {
        var (path, articles) = await PathWithArticlesAsync(2);

        var en = await FindAsync(api.GuestClient("en").GetAsync("/api/v1/paths", Ct).OkArrayAsync(), path.Slug);
        var ar = await FindAsync(api.GuestClient("ar").GetAsync("/api/v1/paths?field=dotnet", Ct).OkArrayAsync(), path.Slug);

        en["title"]!.GetValue<string>().Should().Be(path.TitleEn);
        en["description"]!.GetValue<string>().Should().Be("English description");
        en["articleCount"]!.GetValue<int>().Should().Be(2);
        en["readingTimeMinutes"]!.GetValue<int>().Should().BeGreaterThan(0);
        en["field"]!["slug"]!.GetValue<string>().Should().Be("dotnet");
        en["progress"].Should().BeNull();
        en["enrollment"].Should().BeNull();
        ar["title"]!.GetValue<string>().Should().Be(path.TitleAr);
        articles.Should().HaveCount(2);
    }

    [Fact]
    public async Task The_field_filter_and_unpublished_paths_leave_paths_out()
    {
        var (published, _) = await PathWithArticlesAsync(1);
        var (hidden, _) = await PathWithArticlesAsync(1, publish: false);

        var all = await api.GuestClient().GetAsync("/api/v1/paths", Ct).OkArrayAsync();
        var other = await api.GuestClient().GetAsync("/api/v1/paths?field=security", Ct).OkArrayAsync();

        Slugs(all).Should().Contain(published.Slug).And.NotContain(hidden.Slug);
        Slugs(other).Should().NotContain(published.Slug);
        await api.GuestClient().GetAsync($"/api/v1/paths/{hidden.Slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "path.not_found");
        await api.GuestClient().GetAsync("/api/v1/paths/no-such-path", Ct).ProblemAsync(HttpStatusCode.NotFound, "path.not_found");
    }

    [Fact]
    public async Task Details_list_the_articles_in_order_with_your_reads_and_the_next_one()
    {
        var reader = await api.SignUpAsync();
        var (path, articles) = await PathWithArticlesAsync(3);
        await SeedReadAsync(reader.Id, articles[0]);

        var details = await reader.Client.GetAsync($"/api/v1/paths/{path.Slug}", Ct).OkJsonAsync();

        var items = details["items"]!.AsArray();
        items.Select(i => i!["position"]!.GetValue<int>()).Should().Equal(1, 2, 3);
        items.Select(i => i!["article"]!["id"]!.GetValue<Guid>()).Should().Equal(articles);
        items.Select(i => i!["isRead"]!.GetValue<bool>()).Should().Equal(true, false, false);
        items[0]!["article"]!["title"]!.GetValue<string>().Should().NotBeNullOrWhiteSpace();

        var progress = details["progress"]!;
        progress["readCount"]!.GetValue<int>().Should().Be(1);
        progress["total"]!.GetValue<int>().Should().Be(3);
        progress["percent"]!.GetValue<int>().Should().Be(33);
        progress["next"]!["id"]!.GetValue<Guid>().Should().Be(articles[1]);
        progress["next"]!["position"]!.GetValue<int>().Should().Be(2);
        details["enrollment"].Should().BeNull("reading an article doesn't enroll you");
    }

    [Fact]
    public async Task A_path_only_counts_articles_a_reader_can_open()
    {
        var (path, articles) = await PathWithArticlesAsync(3);
        await UnpublishArticleAsync(articles[1]);

        var details = await api.GuestClient().GetAsync($"/api/v1/paths/{path.Slug}", Ct).OkJsonAsync();

        details["articleCount"]!.GetValue<int>().Should().Be(2);
        details["items"]!.AsArray().Select(i => i!["position"]!.GetValue<int>()).Should().Equal(1, 2);
        details["items"]!.AsArray().Select(i => i!["article"]!["id"]!.GetValue<Guid>()).Should().Equal(articles[0], articles[2]);
    }

    // ── Enrollment ─────────────────────────────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Enrolling_is_idempotent_and_leaving_keeps_the_reading_history()
    {
        var reader = await api.SignUpAsync();
        var (path, articles) = await PathWithArticlesAsync(2);
        await SeedReadAsync(reader.Id, articles[0]);

        var first = await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{path.Id}").OkJsonAsync();
        var second = await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{path.Id}").OkJsonAsync();

        first["enrollment"]!["enrolledAt"]!.GetValue<DateTime>().Should().Be(second["enrollment"]!["enrolledAt"]!.GetValue<DateTime>());
        first["enrollment"]!["completedAt"].Should().BeNull();
        first["progress"]!["readCount"]!.GetValue<int>().Should().Be(1);
        Slugs(await reader.Client.GetAsync("/api/v1/me/paths", Ct).OkArrayAsync()).Should().Equal(path.Slug);

        (await reader.Client.DeleteAsync($"/api/v1/me/paths/{path.Id}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await reader.Client.DeleteAsync($"/api/v1/me/paths/{path.Id}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await reader.Client.GetAsync("/api/v1/me/paths", Ct).OkArrayAsync()).Should().BeEmpty();

        var again = await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{path.Id}").OkJsonAsync();
        again["progress"]!["readCount"]!.GetValue<int>().Should().Be(1);
    }

    [Fact]
    public async Task Enrolling_needs_a_visible_path_and_a_session()
    {
        var reader = await api.SignUpAsync();
        var (hidden, _) = await PathWithArticlesAsync(1, publish: false);

        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{hidden.Id}").ProblemAsync(HttpStatusCode.NotFound, "path.not_found");
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{Guid.NewGuid()}").ProblemAsync(HttpStatusCode.NotFound, "path.not_found");
        (await api.GuestClient().PutEmptyAsync($"/api/v1/me/paths/{hidden.Id}")).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await api.GuestClient().GetAsync("/api/v1/me/paths", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Enrolling_after_reading_everything_earns_the_badge_at_once()
    {
        var reader = await api.SignUpAsync();
        var (path, articles) = await PathWithArticlesAsync(2);
        foreach (var id in articles) await SeedReadAsync(reader.Id, id);

        var card = await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{path.Id}").OkJsonAsync();

        card["enrollment"]!["completedAt"].Should().NotBeNull();
        card["progress"]!["next"].Should().BeNull();
        card["progress"]!["percent"]!.GetValue<int>().Should().Be(100);
        (await reader.Client.GetAsync("/api/v1/me/paths/active", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task The_active_path_is_the_one_in_progress_with_the_latest_activity()
    {
        var reader = await api.SignUpAsync();
        (await reader.Client.GetAsync("/api/v1/me/paths/active", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var (older, _) = await PathWithArticlesAsync(2);
        var (newer, newerArticles) = await PathWithArticlesAsync(2);
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{older.Id}").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{newer.Id}").OkJsonAsync();
        await SetActivityAsync(reader.Id, older.Id, DateTime.UtcNow.AddHours(-2));

        var active = await reader.Client.GetAsync("/api/v1/me/paths/active", Ct).OkJsonAsync();

        active["slug"]!.GetValue<string>().Should().Be(newer.Slug);
        active["progress"]!["next"]!["id"]!.GetValue<Guid>().Should().Be(newerArticles[0]);
        Slugs(await reader.Client.GetAsync("/api/v1/me/paths", Ct).OkArrayAsync()).Should().Equal(newer.Slug, older.Slug);
    }

    [Fact]
    public async Task Reading_the_last_article_completes_the_path_and_moves_its_activity()
    {
        var reader = await api.SignUpAsync();
        var (finished, articles) = await PathWithArticlesAsync(2);
        var (other, _) = await PathWithArticlesAsync(2);
        await SeedReadAsync(reader.Id, articles[0]);
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{finished.Id}").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{other.Id}").OkJsonAsync();
        await SetActivityAsync(reader.Id, finished.Id, DateTime.UtcNow.AddHours(-2));

        await CompleteThroughTheApiAsync(reader, articles[1]);

        await WaitForAsync(async () => await CompletedAtAsync(reader.Id, finished.Id) is not null, "the outbox completes the enrollment");
        var mine = await reader.Client.GetAsync("/api/v1/me/paths", Ct).OkArrayAsync();
        Slugs(mine).Should().Equal(other.Slug, finished.Slug); // in progress first, then completed
        mine[1]!["enrollment"]!["completedAt"].Should().NotBeNull();
        mine[1]!["progress"]!["readCount"]!.GetValue<int>().Should().Be(2);
        (await reader.Client.GetAsync("/api/v1/me/paths/active", Ct).OkJsonAsync())["slug"]!.GetValue<string>().Should().Be(other.Slug);
    }

    // ── The reader's "Next in path" block ──────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task The_article_path_block_shows_the_position_and_the_neighbours()
    {
        var (path, articles) = await PathWithArticlesAsync(3);
        var guest = api.GuestClient();

        var middle = await guest.GetAsync($"/api/v1/articles/{articles[1]}/path", Ct).OkJsonAsync();
        var last = await guest.GetAsync($"/api/v1/articles/{articles[2]}/path", Ct).OkJsonAsync();

        middle["path"]!["slug"]!.GetValue<string>().Should().Be(path.Slug);
        middle["position"]!.GetValue<int>().Should().Be(2);
        middle["total"]!.GetValue<int>().Should().Be(3);
        middle["previous"]!["id"]!.GetValue<Guid>().Should().Be(articles[0]);
        middle["next"]!["id"]!.GetValue<Guid>().Should().Be(articles[2]);
        middle["next"]!["author"].Should().NotBeNull("next is a full article card");
        last["next"].Should().BeNull();
        last["position"]!.GetValue<int>().Should().Be(3);
    }

    [Fact]
    public async Task An_article_outside_paths_has_no_block_and_an_unknown_one_is_not_found()
    {
        var writer = await api.UserAsync("Path Writer");
        var (loose, _) = await writer.Client.PublishAsync();

        (await api.GuestClient().GetAsync($"/api/v1/articles/{loose}/path", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await api.GuestClient().GetAsync($"/api/v1/articles/{Guid.NewGuid()}/path", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task An_article_in_two_paths_shows_the_one_you_follow()
    {
        var reader = await api.SignUpAsync();
        var (first, articles) = await PathWithArticlesAsync(2, sortOrder: 1);
        var (second, _) = await PathWithArticlesAsync(1, sortOrder: 2, extra: [articles[1]]);

        var guestView = await api.GuestClient().GetAsync($"/api/v1/articles/{articles[1]}/path", Ct).OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{second.Id}").OkJsonAsync();
        var readerView = await reader.Client.GetAsync($"/api/v1/articles/{articles[1]}/path", Ct).OkJsonAsync();

        guestView["path"]!["slug"]!.GetValue<string>().Should().Be(first.Slug, "the first in editorial order");
        readerView["path"]!["slug"]!.GetValue<string>().Should().Be(second.Slug);
        readerView["path"]!["enrollment"].Should().NotBeNull();
        readerView["position"]!.GetValue<int>().Should().Be(2);
    }

    // ── Continue reading (F03) ─────────────────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Continue_reading_lists_recent_unfinished_articles_newest_first()
    {
        var reader = await api.SignUpAsync();
        var writer = await api.UserAsync("Continue Writer");
        var (older, _) = await writer.Client.PublishAsync();
        var (newer, _) = await writer.Client.PublishAsync();
        var (barelyOpened, _) = await writer.Client.PublishAsync();
        var (finished, _) = await writer.Client.PublishAsync();
        var (stale, _) = await writer.Client.PublishAsync();
        var now = DateTime.UtcNow;
        await SeedProgressAsync(
            ReadingProgress.SeededInProgress(reader.Id, older, "en", percent: 40, activeSeconds: 60, now.AddHours(-3)),
            ReadingProgress.SeededInProgress(reader.Id, newer, "en", percent: 20, activeSeconds: 20, now.AddMinutes(-5)),
            ReadingProgress.SeededInProgress(reader.Id, barelyOpened, "en", percent: 4, activeSeconds: 5, now.AddMinutes(-1)),
            ReadingProgress.SeededCompleted(reader.Id, finished, "en", activeSeconds: 120, now.AddMinutes(-2)),
            ReadingProgress.SeededInProgress(reader.Id, stale, "en", percent: 50, activeSeconds: 60, now.AddDays(-31)));

        var items = await reader.Client.GetAsync("/api/v1/me/continue-reading", Ct).OkArrayAsync();
        var one = await reader.Client.GetAsync("/api/v1/me/continue-reading?limit=1", Ct).OkArrayAsync();

        items.Select(i => i!["article"]!["id"]!.GetValue<Guid>()).Should().Equal(newer, older);
        items[0]!["percent"]!.GetValue<int>().Should().Be(20);
        items[0]!["language"]!.GetValue<string>().Should().Be("en");
        items[0]!["updatedAt"].Should().NotBeNull();
        one.Should().ContainSingle();
        (await api.GuestClient().GetAsync("/api/v1/me/continue-reading", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Continue_reading_drops_articles_that_can_no_longer_be_opened()
    {
        var reader = await api.SignUpAsync();
        var writer = await api.UserAsync("Continue Writer");
        var (gone, _) = await writer.Client.PublishAsync();
        await SeedProgressAsync(ReadingProgress.SeededInProgress(reader.Id, gone, "en", 30, 30, DateTime.UtcNow.AddMinutes(-1)));
        await UnpublishArticleAsync(gone);

        (await reader.Client.GetAsync("/api/v1/me/continue-reading", Ct).OkArrayAsync()).Should().BeEmpty();
    }

    // ── Profile tab ────────────────────────────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Profile_paths_follow_the_reading_stats_privacy_and_show_the_owners_progress()
    {
        var owner = await api.UserAsync("Path Owner");
        var visitor = await api.UserAsync("Path Visitor");
        var (path, articles) = await PathWithArticlesAsync(2);
        await SeedReadAsync(owner.Id, articles[0]);
        await owner.Client.PutEmptyAsync($"/api/v1/me/paths/{path.Id}").OkJsonAsync();
        var url = $"/api/v1/users/{owner.Me["username"]}/paths";

        await visitor.Client.GetAsync(url, Ct).ProblemAsync(HttpStatusCode.Forbidden, "profile.stats_private");
        Slugs(await owner.Client.GetAsync(url, Ct).OkArrayAsync()).Should().Equal(path.Slug);

        (await owner.Client.PutAsJsonAsync("/api/v1/me/privacy", new { publicReadingStats = true }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var shown = await visitor.Client.GetAsync(url, Ct).OkArrayAsync();

        shown.Should().ContainSingle();
        shown[0]!["progress"]!["readCount"]!.GetValue<int>().Should().Be(1, "the owner's progress, not the visitor's");
        await api.GuestClient().GetAsync("/api/v1/users/nobody_here_404/paths", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
    }

    // ── F07: the active path's next article is today's pick ────────────────────────────────────────────────────

    [Fact]
    public async Task Todays_article_is_the_next_one_in_your_active_path()
    {
        var reader = await api.SignUpAsync();
        var (path, articles) = await PathWithArticlesAsync(3);
        await SeedReadAsync(reader.Id, articles[0]);
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{path.Id}").OkJsonAsync();

        var today = await reader.Client.GetAsync("/api/v1/feed/today", Ct).OkJsonAsync();

        today["id"]!.GetValue<Guid>().Should().Be(articles[1]);
    }

    [Fact]
    public async Task The_path_gives_way_on_a_third_day_in_the_same_field()
    {
        var reader = await api.SignUpAsync();
        var (path, articles) = await PathWithArticlesAsync(4);
        await reader.Client.PutEmptyAsync($"/api/v1/me/paths/{path.Id}").OkJsonAsync();
        var today = ReadingClock.LocalDate(DateTime.UtcNow, "Africa/Cairo");
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.DailyPicks.AddRange(new DailyPick(reader.Id, today.AddDays(-1), articles[2]), new DailyPick(reader.Id, today.AddDays(-2), articles[3]));
            await db.SaveChangesAsync(Ct);
        }

        var pick = await reader.Client.GetAsync("/api/v1/feed/today", Ct).OkJsonAsync();

        pick["id"]!.GetValue<Guid>().Should().NotBe(articles[0], "two dotnet days in a row already");
        pick["field"]!["slug"]!.GetValue<string>().Should().NotBe("dotnet");
    }

    // ── Demo data (local only, SPEC §18.2) ─────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Demo_reader6_finished_a_learning_path()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var reader6 = await db.Users.AsNoTracking().Where(u => u.Email == "reader6@readin.test").Select(u => u.Id).SingleAsync(Ct);

        var enrollment = await db.PathEnrollments.AsNoTracking()
            .Where(e => e.UserId == reader6)
            .Join(db.LearningPaths, e => e.PathId, p => p.Id, (e, p) => new { p.Slug, e.CompletedAt, p.Items })
            .SingleAsync(Ct);
        var itemIds = enrollment.Items.Select(i => i.ArticleId).ToList();
        var read = await db.ReadingProgress.CountAsync(r => r.UserId == reader6 && r.CompletedAt != null && itemIds.Contains(r.ArticleId), Ct);

        enrollment.Slug.Should().Be("secure-by-default");
        enrollment.CompletedAt.Should().NotBeNull();
        read.Should().Be(itemIds.Count);
    }

    // ── Admin API ──────────────────────────────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Admins_create_fill_and_publish_a_path()
    {
        var admin = await api.SeedUserClientAsync(ApiFactory.AdminPhone);
        var writer = await api.UserAsync("Admin Path Writer");
        var (a, _) = await writer.Client.PublishAsync();
        var (b, _) = await writer.Client.PublishAsync();
        var fieldId = await admin.FieldIdAsync("dotnet");
        var slug = $"admin-path-{Guid.NewGuid():N}"[..30];
        var body = new { slug, fieldId, titleAr = "مسار الأدمن", titleEn = "Admin path", descriptionAr = (string?)null, descriptionEn = "Made by an admin", sortOrder = 500, isPublished = true };

        await admin.PostAsJsonAsync("/api/v1/admin/paths", body, Ct).ProblemAsync(HttpStatusCode.BadRequest, "path.items_invalid");
        var created = await admin.PostAsJsonAsync("/api/v1/admin/paths", body with { isPublished = false }, Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created);
        var id = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
        await admin.PostAsJsonAsync("/api/v1/admin/paths", body with { isPublished = false }, Ct).ProblemAsync(HttpStatusCode.Conflict, "path.slug_taken");

        (await admin.PutAsJsonAsync($"/api/v1/admin/paths/{id}/items", new { articleIds = new[] { b, a } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await admin.PutAsJsonAsync($"/api/v1/admin/paths/{id}", body, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var details = await api.GuestClient().GetAsync($"/api/v1/paths/{slug}", Ct).OkJsonAsync();
        details["items"]!.AsArray().Select(i => i!["article"]!["id"]!.GetValue<Guid>()).Should().Equal(b, a);
        var listed = (await admin.GetAsync("/api/v1/admin/paths", Ct).OkArrayAsync()).Single(p => p!["id"]!.GetValue<Guid>() == id)!;
        listed["isEditorial"]!.GetValue<bool>().Should().BeFalse();
        listed["articleIds"]!.AsArray().Select(x => x!.GetValue<Guid>()).Should().Equal(b, a);

        (await admin.DeleteAsync($"/api/v1/admin/paths/{id}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await api.GuestClient().GetAsync($"/api/v1/paths/{slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "path.not_found");
    }

    [Fact]
    public async Task Admin_items_must_be_different_published_articles()
    {
        var admin = await api.SeedUserClientAsync(ApiFactory.AdminPhone);
        var (path, articles) = await PathWithArticlesAsync(1, publish: false);
        var url = $"/api/v1/admin/paths/{path.Id}/items";

        await admin.PutAsJsonAsync(url, new { articleIds = Array.Empty<Guid>() }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "path.items_invalid");
        await admin.PutAsJsonAsync(url, new { articleIds = new[] { articles[0], articles[0] } }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "path.items_invalid");
        await admin.PutAsJsonAsync(url, new { articleIds = new[] { Guid.NewGuid() } }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "path.items_invalid");
    }

    [Fact]
    public async Task Editorial_paths_are_read_only_and_members_cant_manage_paths()
    {
        var admin = await api.SeedUserClientAsync(ApiFactory.AdminPhone);
        var member = await api.SignUpAsync();
        var editorial = (await admin.GetAsync("/api/v1/admin/paths", Ct).OkArrayAsync()).First(p => p!["isEditorial"]!.GetValue<bool>())!;
        var id = editorial["id"]!.GetValue<Guid>();
        var fieldId = editorial["fieldId"]!.GetValue<Guid>();
        var body = new { slug = editorial["slug"]!.GetValue<string>(), fieldId, titleAr = "x", titleEn = "x", sortOrder = 1, isPublished = true };

        await admin.PutAsJsonAsync($"/api/v1/admin/paths/{id}", body, Ct).ProblemAsync(HttpStatusCode.Conflict, "path.editorial");
        await admin.DeleteAsync($"/api/v1/admin/paths/{id}", Ct).ProblemAsync(HttpStatusCode.Conflict, "path.editorial");
        (await member.Client.GetAsync("/api/v1/admin/paths", Ct)).StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── Helpers ────────────────────────────────────────────────────────────────────────────────────────────────

    private sealed record TestPath(Guid Id, string Slug, string TitleAr, string TitleEn);

    /// <summary>A fresh writer's <paramref name="count"/> published dotnet articles in a new path, plus <paramref name="extra"/> at the end.</summary>
    private async Task<(TestPath Path, List<Guid> Articles)> PathWithArticlesAsync(
        int count, bool publish = true, int sortOrder = 1000, Guid[]? extra = null)
    {
        var writer = await api.UserAsync("Path Writer");
        var articles = new List<Guid>();
        for (var i = 0; i < count; i++) articles.Add((await writer.Client.PublishAsync()).Id);
        var items = articles.Concat(extra ?? []).ToList();

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var fieldId = await db.Fields.Where(f => f.Slug == "dotnet").Select(f => f.Id).SingleAsync(Ct);
        var slug = $"test-path-{Guid.NewGuid():N}";
        var path = new LearningPath(slug, fieldId, $"مسار {slug[^6..]}", $"Path {slug[^6..]}", sortOrder);
        path.Update(fieldId, path.TitleAr, path.TitleEn, "وصف", "English description", sortOrder);
        path.SetItemsInOrder(items);
        if (publish) path.Publish().IsSuccess.Should().BeTrue();
        db.LearningPaths.Add(path);
        await db.SaveChangesAsync(Ct);
        return (new TestPath(path.Id, slug, path.TitleAr, path.TitleEn), articles);
    }

    private Task SeedReadAsync(Guid userId, Guid articleId) =>
        SeedProgressAsync(ReadingProgress.SeededCompleted(userId, articleId, "en", 120, DateTime.UtcNow.AddMinutes(-30)));

    private async Task SeedProgressAsync(params ReadingProgress[] rows)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.ReadingProgress.AddRange(rows);
        await db.SaveChangesAsync(Ct);
    }

    private async Task UnpublishArticleAsync(Guid articleId)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Articles.Where(a => a.Id == articleId)
            .ExecuteUpdateAsync(set => set.SetProperty(a => a.Status, ReadIn.Domain.Articles.ArticleStatus.Archived), Ct);
    }

    private async Task SetActivityAsync(Guid userId, Guid pathId, DateTime at)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        (await db.PathEnrollments.Where(e => e.UserId == userId && e.PathId == pathId)
            .ExecuteUpdateAsync(set => set.SetProperty(e => e.LastActivityAt, at), Ct)).Should().Be(1);
    }

    private async Task<DateTime?> CompletedAtAsync(Guid userId, Guid pathId)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        return await db.PathEnrollments.AsNoTracking()
            .Where(e => e.UserId == userId && e.PathId == pathId)
            .Select(e => e.CompletedAt)
            .SingleAsync(Ct);
    }

    /// <summary>Opens the article, lets 40 seconds pass on the server and reports reading it to the end (F04).</summary>
    private async Task CompleteThroughTheApiAsync(SignedInUser reader, Guid articleId)
    {
        var url = $"/api/v1/articles/{articleId}/progress";
        (await reader.Client.PutAsJsonAsync(url, new { language = "en", percent = 0, lastPosition = (string?)null, activeSecondsDelta = 0 }, Ct)).EnsureSuccessStatusCode();
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            await db.ReadingProgress.Where(r => r.UserId == reader.Id && r.ArticleId == articleId)
                .ExecuteUpdateAsync(set => set.SetProperty(r => r.UpdatedAt, r => r.UpdatedAt.AddSeconds(-40)), Ct);
        }
        var read = await reader.Client.PutAsJsonAsync(url, new { language = "en", percent = 100, lastPosition = "end", activeSecondsDelta = 40 }, Ct).OkJsonAsync();
        read["completedNow"]!.GetValue<bool>().Should().BeTrue();
    }

    private static async Task<JsonObject> FindAsync(Task<JsonArray> list, string slug) =>
        (await list).Single(p => p!["slug"]!.GetValue<string>() == slug)!.AsObject();

    private static List<string> Slugs(JsonArray paths) => [.. paths.Select(p => p!["slug"]!.GetValue<string>())];

    private static async Task WaitForAsync(Func<Task<bool>> condition, string because)
    {
        for (var i = 0; i < 50; i++)
        {
            if (await condition()) return;
            await Task.Delay(100, Ct);
        }
        (await condition()).Should().BeTrue(because);
    }
}
