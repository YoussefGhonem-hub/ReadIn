using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Identity;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The admin console's Content, featured articles and featured paths (SPEC F23): the article and comment lists with their
/// filters, featuring (Explore and the reader's details), the featured paths' order, and the audit of path writes.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminContentTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Content_routes_are_for_their_permissions_only()
    {
        var id = Guid.NewGuid();
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/articles");
        await api.AssertAdminOnlyAsync(HttpMethod.Get, $"/api/v1/admin/articles/{id}");
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/comments");
        await api.AssertAdminOnlyAsync(HttpMethod.Put, $"/api/v1/admin/articles/{id}/featured");
        await api.AssertAdminOnlyAsync(HttpMethod.Delete, $"/api/v1/admin/articles/{id}/featured");
        await api.AssertAdminOnlyAsync(HttpMethod.Put, "/api/v1/admin/paths/featured", new { pathIds = Array.Empty<Guid>() });

        // Lists need moderation.manage, featuring articles.feature: one doesn't open the other.
        var moderator = await api.UserWithPermissionsAsync("Content Moderator", Permissions.Moderation.Manage);
        await moderator.Client.GetAsync("/api/v1/admin/articles", Ct).OkJsonAsync();
        await moderator.Client.PutEmptyAsync($"/api/v1/admin/articles/{id}/featured").ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        var curator = await api.UserWithPermissionsAsync("Curator", Permissions.Articles.Feature);
        await curator.Client.GetAsync("/api/v1/admin/comments", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await curator.Client.PutEmptyAsync($"/api/v1/admin/articles/{id}/featured").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task The_articles_list_filters_by_writer_field_state_reports_and_title()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Content Writer");
        var marker = $"zq{Guid.NewGuid():N}"[..12];
        var first = await writer.Client.PublishAsync($"Kubernetes notes {marker}", field: "dotnet");
        var second = await writer.Client.PublishAsync($"Angular signals {marker}", field: "frontend");
        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(
            await writer.Client.FieldIdAsync("dotnet"), "Never published", "en", [ArticleTestKit.Paragraph("Draft only.")]));

        var mine = await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}", Ct).OkJsonAsync();
        var items = mine.PageItems();
        Ids(items).Should().Equal([second.Id, first.Id], "newest first; drafts are never listed");
        (mine["totalCount"]!.GetValue<int>(), mine["page"]!.GetValue<int>(), mine["pageSize"]!.GetValue<int>()).Should().Be((2, 1, 50));
        var row = items[0]!.AsObject();
        row.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "slug", "status", "title", "language", "author", "field", "topic", "publishedAt", "readCount", "reactionCount",
            "commentCount", "hiddenAt", "featuredAt", "openReports", "reportCount");
        (row["status"]!.GetValue<string>(), row["title"]!.GetValue<string>(), row["author"]!["id"]!.GetValue<Guid>())
            .Should().Be(("published", $"Angular signals {marker}", writer.Id));
        row["field"]!["slug"]!.GetValue<string>().Should().Be("frontend");
        (row["hiddenAt"], row["featuredAt"]).Should().Be((null, null));

        var dotnet = await writer.Client.FieldIdAsync("dotnet");
        Ids((await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}&field={dotnet}", Ct).OkJsonAsync()).PageItems())
            .Should().Equal(first.Id);
        Ids((await admin.Client.GetAsync($"/api/v1/admin/articles?q=kubernetes%20{marker}", Ct).OkJsonAsync()).PageItems())
            .Should().Equal(first.Id);

        // Hidden, reported and featured.
        await admin.Client.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "article", targetId = first.Id }, Ct)
            .NoContentAsync();
        var reader = await api.UserAsync();
        (await reader.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "article", targetId = second.Id, reason = "spam" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        await admin.Client.PutEmptyAsync($"/api/v1/admin/articles/{second.Id}/featured").NoContentAsync();

        var hidden = (await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}&hidden=true", Ct).OkJsonAsync()).PageItems();
        Ids(hidden).Should().Equal(first.Id);
        hidden[0]!["hiddenAt"].Should().NotBeNull();
        Ids((await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}&hidden=false", Ct).OkJsonAsync()).PageItems())
            .Should().Equal(second.Id);
        var reported = (await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}&reported=true", Ct).OkJsonAsync()).PageItems();
        Ids(reported).Should().Equal(second.Id);
        (reported[0]!["openReports"]!.GetValue<int>(), reported[0]!["reportCount"]!.GetValue<int>()).Should().Be((1, 1));
        Ids((await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}&featured=true", Ct).OkJsonAsync()).PageItems())
            .Should().Equal(second.Id);
        Ids((await admin.Client.GetAsync("/api/v1/admin/articles?featured=true&sort=featured&pageSize=1", Ct).OkJsonAsync()).PageItems())
            .Should().Equal([second.Id], "the most recently featured first");

        // One row, for "Open in console": a draft or an unknown id isn't one.
        var one = await admin.Client.GetAsync($"/api/v1/admin/articles/{first.Id}", Ct).OkJsonAsync();
        one["id"]!.GetValue<Guid>().Should().Be(first.Id);
        one["hiddenAt"].Should().NotBeNull();
        await admin.Client.GetAsync($"/api/v1/admin/articles/{draft["id"]}", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await admin.Client.GetAsync($"/api/v1/admin/articles/{Guid.NewGuid()}", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // The period filter takes local dates (Admin:TimeZone), both ends included.
        var from = DateTime.UtcNow.AddDays(-1).ToString("yyyy-MM-dd");
        var to = DateTime.UtcNow.AddDays(1).ToString("yyyy-MM-dd");
        (await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}&from={from}&to={to}", Ct)
            .OkJsonAsync())["totalCount"]!.GetValue<int>().Should().Be(2);
        (await admin.Client.GetAsync($"/api/v1/admin/articles?writer={writer.Id}&to={DateTime.UtcNow.AddDays(-3):yyyy-MM-dd}", Ct)
            .OkJsonAsync())["totalCount"]!.GetValue<int>().Should().Be(0);
    }

    [Fact]
    public async Task Bad_filter_values_are_validation_errors_and_pages_are_clamped()
    {
        var admin = await api.SuperAdminAsync();
        foreach (var (query, parameter) in new[]
                 {
                     ("hidden=maybe", "hidden"), ("featured=1x", "featured"), ("reported=no", "reported"), ("status=draft", "status"),
                     ("sort=popular", "sort"), ("from=2026-13-01", "from"), ("to=yesterday", "to"), ("field=nope", "field"),
                     ("writer=123", "writer"), ("topic=x", "topic"), ($"q={new string('a', 101)}", "q"),
                 })
        {
            var problem = await admin.Client.GetAsync($"/api/v1/admin/articles?{query}", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            problem["errors"]![parameter]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal(["validation.invalid"], query);
        }
        (await admin.Client.GetAsync("/api/v1/admin/comments?hidden=x", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))
            ["errors"]!["hidden"].Should().NotBeNull();

        var page = await admin.Client.GetAsync("/api/v1/admin/articles?page=0&pageSize=500", Ct).OkJsonAsync();
        (page["page"]!.GetValue<int>(), page["pageSize"]!.GetValue<int>()).Should().Be((1, 100));
        var past = await admin.Client.GetAsync("/api/v1/admin/articles?page=100000&pageSize=1", Ct).OkJsonAsync();
        past.PageItems().Should().BeEmpty();
        past["totalCount"]!.GetValue<int>().Should().BePositive();
    }

    [Fact]
    public async Task Latest_comments_are_newest_first_with_hidden_ones_and_without_deleted_ones()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Comments Writer");
        var article = await writer.Client.PublishAsync("Comments in the console");
        var reader = await api.UserAsync("Commenter");
        var top = await CommentAsync(reader, $"/api/v1/articles/{article.Id}/comments", "First comment, spam soon");
        var reply = await CommentAsync(writer, $"/api/v1/comments/{top}/replies", "A reply from the writer");
        var deleted = await CommentAsync(reader, $"/api/v1/articles/{article.Id}/comments", "Deleted later");
        (await reader.Client.DeleteAsync($"/api/v1/comments/{deleted}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var page = await admin.Client.GetAsync("/api/v1/admin/comments?pageSize=100", Ct).OkJsonAsync();
        var items = page.PageItems();
        var ids = Ids(items);
        ids.Should().ContainInOrder(reply, top).And.NotContain(deleted);
        var row = items.Single(i => i!["id"]!.GetValue<Guid>() == reply)!.AsObject();
        row.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "body", "author", "article", "parentId", "createdAt", "editedAt", "hiddenAt", "likeCount", "replyCount", "openReports",
            "reportCount");
        (row["parentId"]!.GetValue<Guid>(), row["body"]!.GetValue<string>(), row["author"]!["id"]!.GetValue<Guid>())
            .Should().Be((top, "A reply from the writer", writer.Id));
        row["article"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "slug", "title", "language");
        row["article"]!["id"]!.GetValue<Guid>().Should().Be(article.Id);

        await admin.Client.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "comment", targetId = top }, Ct)
            .NoContentAsync();
        var hidden = Ids((await admin.Client.GetAsync("/api/v1/admin/comments?hidden=true&pageSize=100", Ct).OkJsonAsync()).PageItems());
        hidden.Should().Contain(top).And.NotContain(reply);
        Ids((await admin.Client.GetAsync("/api/v1/admin/comments?hidden=false&pageSize=100", Ct).OkJsonAsync()).PageItems())
            .Should().Contain(reply).And.NotContain(top);
    }

    [Fact]
    public async Task A_featured_article_shows_on_explore_and_in_its_details_until_unfeatured()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Featured Writer");
        var article = await writer.Client.PublishAsync("An article worth featuring");
        (await api.GuestClient().GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync())["isFeatured"]!.GetValue<bool>().Should().BeFalse();

        await admin.Client.PutEmptyAsync($"/api/v1/admin/articles/{article.Id}/featured").NoContentAsync();
        var featuredAt = await api.InDbAsync(db => db.Articles.Where(a => a.Id == article.Id).Select(a => a.FeaturedAt).SingleAsync(Ct));
        featuredAt.Should().NotBeNull();
        (await api.GuestClient().GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync())["isFeatured"]!.GetValue<bool>().Should().BeTrue();
        var explore = await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        var featured = explore["featuredArticles"]!.AsArray();
        featured[0]!["id"]!.GetValue<Guid>().Should().Be(article.Id, "the most recently featured first");
        featured.Should().HaveCountLessThanOrEqualTo(6);
        featured[0]!["title"]!.GetValue<string>().Should().Be("An article worth featuring");

        // Featuring again keeps the first time and writes nothing.
        await admin.Client.PutEmptyAsync($"/api/v1/admin/articles/{article.Id}/featured").NoContentAsync();
        (await api.InDbAsync(db => db.Articles.Where(a => a.Id == article.Id).Select(a => a.FeaturedAt).SingleAsync(Ct))).Should().Be(featuredAt);
        (await AuditCountAsync(AuditActions.ArticleFeatured, article.Id)).Should().Be(1);

        // A writer muted by the reader leaves their Explore section too.
        var reader = await api.UserAsync();
        Ids((await reader.Client.GetAsync("/api/v1/explore", Ct).OkJsonAsync())["featuredArticles"]!.AsArray()).Should().Contain(article.Id);
        (await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/mute")).IsSuccessStatusCode.Should().BeTrue();
        Ids((await reader.Client.GetAsync("/api/v1/explore", Ct).OkJsonAsync())["featuredArticles"]!.AsArray()).Should().NotContain(article.Id);

        await admin.Client.DeleteAsync($"/api/v1/admin/articles/{article.Id}/featured", Ct).NoContentAsync();
        await admin.Client.DeleteAsync($"/api/v1/admin/articles/{article.Id}/featured", Ct).NoContentAsync();
        (await AuditCountAsync(AuditActions.ArticleUnfeatured, article.Id)).Should().Be(1);
        (await api.GuestClient().GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync())["isFeatured"]!.GetValue<bool>().Should().BeFalse();
        Ids((await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync())["featuredArticles"]!.AsArray()).Should().NotContain(article.Id);

        // Only articles readers can open are featured; unfeaturing an unknown article is not found.
        await admin.Client.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "article", targetId = article.Id }, Ct)
            .NoContentAsync();
        await admin.Client.PutEmptyAsync($"/api/v1/admin/articles/{article.Id}/featured").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await admin.Client.DeleteAsync($"/api/v1/admin/articles/{Guid.NewGuid()}/featured", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task Featured_paths_follow_the_whole_list_in_order_and_path_writes_are_audited()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Paths Writer");
        var article = await writer.Client.PublishAsync("A path article");
        var fieldId = await admin.Client.FieldIdAsync("dotnet");
        var original = await api.InDbAsync(db => db.LearningPaths.Select(p => new { p.Id, p.IsFeatured, p.FeaturedOrder }).ToListAsync(Ct));
        try
        {
            var a = await CreatePathAsync(admin.Client, fieldId, article.Id);
            var b = await CreatePathAsync(admin.Client, fieldId, article.Id);
            (await AuditCountAsync(AuditActions.PathCreated, a)).Should().Be(1);
            (await AuditCountAsync(AuditActions.PathItemsSet, a)).Should().Be(1);
            (await AuditCountAsync(AuditActions.PathUpdated, a)).Should().Be(1);

            await admin.Client.PutAsJsonAsync("/api/v1/admin/paths/featured", new { pathIds = new[] { b, a } }, Ct).NoContentAsync();
            var listed = await admin.Client.GetAsync("/api/v1/admin/paths", Ct).OkArrayAsync();
            listed.Where(p => p!["isFeatured"]!.GetValue<bool>()).Select(p => p!["id"]!.GetValue<Guid>()).Should().BeEquivalentTo([b, a]);
            Place(listed, b).Should().Be(1);
            Place(listed, a).Should().Be(2);
            listed.Where(p => !p!["isFeatured"]!.GetValue<bool>()).Should().OnlyContain(p => p!["featuredOrder"] == null);
            var explore = await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync();
            Ids(explore["featuredPaths"]!.AsArray()).Should().Equal(b, a);

            // The same list again writes nothing.
            await admin.Client.PutAsJsonAsync("/api/v1/admin/paths/featured", new { pathIds = new[] { b, a } }, Ct).NoContentAsync();
            (await api.InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.FeaturedPathsSet && l.ActorId == admin.Id, Ct)))
                .Should().Be(1);

            foreach (var bad in new object[]
                     {
                         new { pathIds = new[] { a, a } }, new { pathIds = new[] { a, Guid.NewGuid() } },
                         new { pathIds = Enumerable.Range(0, 21).Select(_ => Guid.NewGuid()).ToArray() },
                     })
            {
                await admin.Client.PutAsJsonAsync("/api/v1/admin/paths/featured", bad, Ct).ProblemAsync(HttpStatusCode.BadRequest, "path.featured_invalid");
            }

            await admin.Client.PutAsJsonAsync("/api/v1/admin/paths/featured", new { pathIds = Array.Empty<Guid>() }, Ct).NoContentAsync();
            (await admin.Client.GetAsync("/api/v1/admin/paths", Ct).OkArrayAsync()).Should().OnlyContain(p => !p!["isFeatured"]!.GetValue<bool>());
            (await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync())["featuredPaths"]!.AsArray().Should().BeEmpty();

            (await admin.Client.DeleteAsync($"/api/v1/admin/paths/{b}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
            (await AuditCountAsync(AuditActions.PathDeleted, b)).Should().Be(1);
        }
        finally
        {
            // Other tests rely on the seeded featured paths: put every path back as it was.
            await api.InDbAsync(async db =>
            {
                var paths = await db.LearningPaths.ToListAsync(Ct);
                foreach (var path in paths)
                {
                    var before = original.SingleOrDefault(p => p.Id == path.Id);
                    path.SetFeatured(before?.IsFeatured ?? false, before?.FeaturedOrder ?? 0);
                }
                await db.SaveChangesAsync(Ct);
            });
            await api.DropCacheAsync(CacheTags.Feed);
        }
    }

    private static async Task<Guid> CreatePathAsync(HttpClient admin, Guid fieldId, Guid articleId)
    {
        var slug = $"admin-path-{Guid.NewGuid():N}"[..30];
        var body = new { slug, fieldId, titleAr = "مسار", titleEn = "A path", descriptionAr = (string?)null, descriptionEn = (string?)null, sortOrder = 900, isPublished = false };
        var created = await admin.PostAsJsonAsync("/api/v1/admin/paths", body, Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created, await created.Content.ReadAsStringAsync(Ct));
        var id = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
        await admin.PutAsJsonAsync($"/api/v1/admin/paths/{id}/items", new { articleIds = new[] { articleId } }, Ct).NoContentAsync();
        await admin.PutAsJsonAsync($"/api/v1/admin/paths/{id}", body with { isPublished = true }, Ct).NoContentAsync();
        return id;
    }

    private static int? Place(JsonArray paths, Guid id) =>
        paths.Single(p => p!["id"]!.GetValue<Guid>() == id)!["featuredOrder"]?.GetValue<int>();

    private Task<int> AuditCountAsync(string action, Guid targetId) =>
        api.InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == action && l.TargetId == targetId, Ct));

    private static async Task<Guid> CommentAsync(SignedInUser user, string url, string body)
    {
        var response = await user.Client.PostAsJsonAsync(url, new { body }, Ct);
        var text = await response.Content.ReadAsStringAsync(Ct);
        response.IsSuccessStatusCode.Should().BeTrue(text);
        return JsonNode.Parse(text)!["id"]!.GetValue<Guid>();
    }

    private static List<Guid> Ids(JsonNode? array) => [.. array!.AsArray().Select(n => n!["id"]!.GetValue<Guid>())];
}
