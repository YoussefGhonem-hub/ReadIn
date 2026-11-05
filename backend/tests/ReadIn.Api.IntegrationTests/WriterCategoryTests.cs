using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Taxonomy;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F31 writer categories: managing them (names, slugs, order, the limit), putting articles in them at once, the profile's
/// Categories tab and the category pages (guests too), the reader's link, what is counted, ownership, the moderator's
/// clear, account deletion and the demo seed.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class WriterCategoryTests(ApiFactory api)
{
    private const string Writer1Phone = "+12025550107";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    /// <summary>A short unique word (lower-case hex), so every test has its own names and slugs.</summary>
    private static string Unique() => $"{Guid.NewGuid():N}"[..8];

    // ── Managing ────────────────────────────────────────────────

    [Fact]
    public async Task Writers_create_rename_reorder_and_delete_their_categories()
    {
        var writer = await api.UserAsync("Category Manager");
        var u = Unique();

        var clean = await CreatedAsync(writer.Client, $"  Clean‏   Code\n{u} ");
        clean["name"]!.GetValue<string>().Should().Be($"Clean Code {u}", "cleaned: invisible marks dropped, whitespace collapsed");
        Slug(clean).Should().Be($"clean-code-{u}");
        clean["articleCount"]!.GetValue<int>().Should().Be(0);
        clean["sortOrder"]!.GetValue<int>().Should().Be(1);

        var arabic = await CreatedAsync(writer.Client, $"البرمجة {u}");
        Slug(arabic).Should().Be($"البرمجة-{u}");
        arabic["sortOrder"]!.GetValue<int>().Should().Be(2, "a new category goes last");
        var sharp = await CreatedAsync(writer.Client, "#1 C#");
        sharp["name"]!.GetValue<string>().Should().Be("#1 C#", "a leading # stays in a category name");
        Slug(sharp).Should().Be("sharp1-csharp");
        var longest = await CreatedAsync(writer.Client, u + new string('a', WriterCategory.MaxNameLength - u.Length));

        await CreateAsync(writer.Client, $"clean   CODE {u.ToUpperInvariant()}").ProblemAsync(HttpStatusCode.Conflict, "category.name_taken");
        await CreateAsync(writer.Client, $"البرمجه {u}").ProblemAsync(HttpStatusCode.Conflict, "category.name_taken");
        foreach (var name in new[] { null, "", "   ", "!!!", "ـــ", new string('a', WriterCategory.MaxNameLength + 1) })
        {
            var problem = await CreateAsync(writer.Client, name).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            Codes(problem, "name").Should().Equal("category.name_invalid");
        }

        var renamed = await writer.Client.PatchAsJsonAsync(CategoryUrl(clean), new { name = $"Clean Architecture {u}" }, Ct).OkJsonAsync();
        renamed["name"]!.GetValue<string>().Should().Be($"Clean Architecture {u}");
        Slug(renamed).Should().Be($"clean-code-{u}", "the slug never changes on rename");
        (await writer.Client.PatchAsJsonAsync(CategoryUrl(clean), new { name = $"clean ARCHITECTURE {u}" }, Ct).OkJsonAsync())["name"]!
            .GetValue<string>().Should().Be($"clean ARCHITECTURE {u}", "another spelling of its own name is fine");
        await writer.Client.PatchAsJsonAsync(CategoryUrl(clean), new { name = $"البرمجة {u}" }, Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "category.name_taken");
        await writer.Client.PatchAsJsonAsync(CategoryUrl(clean), new { name = " " }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");

        // Listed ids first, an unknown id and a repeat ignored, the others after them in their order.
        var reordered = await writer.Client.PutAsJsonAsync("/api/v1/me/categories/order",
            new { categoryIds = new[] { Id(sharp), Guid.NewGuid(), Id(arabic), Id(sharp) } }, Ct).OkJsonAsync();
        Ids(reordered).Should().Equal(Id(sharp), Id(arabic), Id(clean), Id(longest));
        reordered["items"]!.AsArray().Select(c => c!["sortOrder"]!.GetValue<int>()).Should().Equal(1, 2, 3, 4);
        Codes(await writer.Client.PutAsJsonAsync("/api/v1/me/categories/order", new { }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"),
            "categoryIds").Should().Equal("validation.required");
        Codes(await writer.Client.PutAsJsonAsync("/api/v1/me/categories/order",
                new { categoryIds = Enumerable.Range(0, WriterCategory.MaxPerWriter + 1).Select(_ => Guid.NewGuid()) }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "categoryIds").Should().Equal("category.limit");

        // Empty categories: the writer sees them, visitors don't.
        Ids(await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync()).Should().Equal(Id(sharp), Id(arabic), Id(clean), Id(longest));
        var tab = await api.GuestClient().GetAsync($"/api/v1/users/{Username(writer)}/categories", Ct).OkJsonAsync();
        tab["items"]!.AsArray().Should().BeEmpty();
        tab["uncategorizedCount"]!.GetValue<int>().Should().Be(0);

        (await writer.Client.DeleteAsync(CategoryUrl(sharp), Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await writer.Client.DeleteAsync(CategoryUrl(sharp), Ct).ProblemAsync(HttpStatusCode.NotFound, "category.not_found");
        var left = await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync();
        Ids(left).Should().Equal(Id(arabic), Id(clean), Id(longest));
        left["items"]!.AsArray().Select(c => c!["sortOrder"]!.GetValue<int>()).Should().Equal([1, 2, 3], "positions, without gaps");
    }

    [Fact]
    public async Task A_writer_has_at_most_50_categories()
    {
        var writer = await api.UserAsync("Category Collector");
        await WithDbAsync(async db =>
        {
            for (var i = 1; i < WriterCategory.MaxPerWriter; i++)
                db.WriterCategories.Add(new WriterCategory(writer.Id, $"Seeded {i}", $"seeded {i}", $"seeded-{i}", i, DateTime.UtcNow));
            await db.SaveChangesAsync(Ct);
        });

        (await CreatedAsync(writer.Client, "Fiftieth"))["sortOrder"]!.GetValue<int>().Should().Be(WriterCategory.MaxPerWriter);
        await CreateAsync(writer.Client, "Fifty-first").ProblemAsync(HttpStatusCode.BadRequest, "category.limit");
        (await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync())["items"]!.AsArray().Should().HaveCount(WriterCategory.MaxPerWriter);
    }

    [Fact]
    public async Task Creates_at_the_same_moment_never_pass_the_limit()
    {
        const int seeded = WriterCategory.MaxPerWriter - 5;
        const int creates = 12;
        var writer = await api.UserAsync("Category Racer");
        await WithDbAsync(async db =>
        {
            for (var i = 1; i <= seeded; i++)
                db.WriterCategories.Add(new WriterCategory(writer.Id, $"Seeded {i}", $"seeded {i}", $"seeded-{i}", i, DateTime.UtcNow));
            await db.SaveChangesAsync(Ct);
        });

        // All the requests start together, each on its own thread.
        using var start = new SemaphoreSlim(0);
        var racing = Enumerable.Range(0, creates).Select(i => Task.Run(async () =>
        {
            await start.WaitAsync(Ct);
            return await CreateAsync(writer.Client, $"Racing {i}");
        }, Ct)).ToList();
        start.Release(creates);
        var responses = await Task.WhenAll(racing);

        responses.Count(r => r.StatusCode == HttpStatusCode.Created).Should().Be(WriterCategory.MaxPerWriter - seeded);
        foreach (var refused in responses.Where(r => r.StatusCode != HttpStatusCode.Created))
            await Task.FromResult(refused).ProblemAsync(HttpStatusCode.BadRequest, "category.limit");
        var list = await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync();
        list["items"]!.AsArray().Should().HaveCount(WriterCategory.MaxPerWriter);
        await WithDbAsync(async db =>
        {
            var sortOrders = await db.WriterCategories.Where(c => c.UserId == writer.Id).Select(c => c.SortOrder).ToListAsync(Ct);
            sortOrders.Should().HaveCount(WriterCategory.MaxPerWriter);
            sortOrders.Should().OnlyHaveUniqueItems("each create saw the ones before it");
        });
    }

    // ── Articles in categories ──────────────────────────────────

    [Fact]
    public async Task Articles_go_in_a_category_at_once_and_show_on_the_profile_the_category_page_and_the_reader()
    {
        var writer = await api.UserAsync("Category Writer");
        var reader = await api.UserAsync("Category Reader");
        var moderator = await ModeratorAsync();
        var guest = api.GuestClient();
        var u = Unique();
        var profile = $"/api/v1/users/{Username(writer)}";
        var field = await writer.Client.FieldIdAsync("dotnet");
        var (first, firstSlug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"First in category {u}"));
        var (second, secondSlug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Second in category {u}"));
        var (third, thirdSlug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Third without category {u}"));
        var backend = await CreatedAsync(writer.Client, $"Backend {u}");
        var empty = await CreatedAsync(writer.Client, $"Empty {u}");

        // Warm the guests' caches first: every change below must show at once.
        (await guest.GetAsync($"{profile}/categories", Ct).OkJsonAsync())["uncategorizedCount"]!.GetValue<int>().Should().Be(3);
        (await guest.GetAsync($"/api/v1/articles/{firstSlug}", Ct).OkJsonAsync())["category"].Should().BeNull();

        var before = await writer.Client.EditAsync(first);
        (await SetCategoryAsync(writer.Client, first, Id(backend))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await SetCategoryAsync(writer.Client, second, Id(backend))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await SetCategoryAsync(writer.Client, second, Id(backend))).StatusCode.Should().Be(HttpStatusCode.NoContent, "idempotent");

        var after = await writer.Client.EditAsync(first);
        after["categoryId"]!.GetValue<Guid>().Should().Be(Id(backend));
        after["version"]!.GetValue<int>().Should().Be(before["version"]!.GetValue<int>(), "the working copy is untouched");
        after["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeFalse("no republish needed");
        (await writer.Client.GetFromJsonAsync<JsonArray>($"/api/v1/articles/{first}/revisions", Ct))!.Should().HaveCount(1, "no revision");

        // The profile's tab (guests too): categories with articles, in order, then the uncategorized count.
        var tab = await guest.GetAsync($"{profile}/categories", Ct).OkJsonAsync();
        Ids(tab).Should().Equal(Id(backend));
        tab["items"]![0]!["articleCount"]!.GetValue<int>().Should().Be(2);
        tab["uncategorizedCount"]!.GetValue<int>().Should().Be(1);
        Ids(await guest.GetAsync($"/api/v1/users/@{Username(writer).ToUpperInvariant()}/categories", Ct).OkJsonAsync())
            .Should().Equal([Id(backend)], "the username is matched ignoring case and a leading @");
        var mine = await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync();
        Ids(mine).Should().Equal(Id(backend), Id(empty));
        mine["uncategorizedCount"]!.GetValue<int>().Should().Be(1);

        // The category page: its header and its articles, newest first, paged.
        var header = await guest.GetAsync($"{profile}/categories/{Uri.EscapeDataString(Slug(backend))}", Ct).OkJsonAsync();
        header["id"]!.GetValue<Guid>().Should().Be(Id(backend));
        header["name"]!.GetValue<string>().Should().Be($"Backend {u}");
        header["articleCount"]!.GetValue<int>().Should().Be(2);
        header["author"]!["username"]!.GetValue<string>().Should().Be(Username(writer));
        (await guest.GetAsync($"{profile}/categories/{Slug(empty).ToUpperInvariant()}", Ct).OkJsonAsync())["articleCount"]!.GetValue<int>()
            .Should().Be(0, "an empty category answers too (slugs are matched ignoring case)");
        var page1 = await guest.GetAsync($"{profile}/categories/{Slug(backend)}/articles?limit=1", Ct).OkJsonAsync();
        Ids(page1).Should().Equal(second);
        var cursor = Uri.EscapeDataString(page1["nextCursor"]!.GetValue<string>());
        var page2 = await guest.GetAsync($"{profile}/categories/{Slug(backend)}/articles?limit=1&cursor={cursor}", Ct).OkJsonAsync();
        Ids(page2).Should().Equal(first);
        page2["nextCursor"].Should().BeNull();
        await reader.Client.ReactAsync(first, "love");
        (await reader.Client.GetAsync($"{profile}/categories/{Slug(backend)}/articles", Ct).OkJsonAsync())["items"]!.AsArray()
            .Single(c => c!["id"]!.GetValue<Guid>() == first)!["myReaction"]!.GetValue<string>().Should().Be("love");

        // "مقالات تانية": the reserved slug _other.
        var other = await guest.GetAsync($"{profile}/categories/_other", Ct).OkJsonAsync();
        other["id"].Should().BeNull();
        other["name"].Should().BeNull();
        other["slug"]!.GetValue<string>().Should().Be("_other");
        other["articleCount"]!.GetValue<int>().Should().Be(1);
        Ids(await guest.GetAsync($"{profile}/categories/_other/articles", Ct).OkJsonAsync()).Should().Equal(third);

        // The reader's "في قسم {name}".
        var details = await guest.GetAsync($"/api/v1/articles/{firstSlug}", Ct).OkJsonAsync();
        details["category"]!["slug"]!.GetValue<string>().Should().Be(Slug(backend));
        details["category"]!["name"]!.GetValue<string>().Should().Be($"Backend {u}");
        (await guest.GetAsync($"/api/v1/articles/{thirdSlug}", Ct).OkJsonAsync())["category"].Should().BeNull();

        // A rename shows at once, under the same link.
        (await writer.Client.PatchAsJsonAsync(CategoryUrl(backend), new { name = $"Server side {u}" }, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await guest.GetAsync($"/api/v1/articles/{firstSlug}", Ct).OkJsonAsync())["category"]!["name"]!.GetValue<string>().Should().Be($"Server side {u}");
        (await guest.GetAsync($"{profile}/categories/{Slug(backend)}", Ct).OkJsonAsync())["name"]!.GetValue<string>().Should().Be($"Server side {u}");

        // Out of the category: at once, the guests' cached pages too.
        (await SetCategoryAsync(writer.Client, first, null)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/articles/{firstSlug}", Ct).OkJsonAsync())["category"].Should().BeNull();
        Ids(await guest.GetAsync($"{profile}/categories/{Slug(backend)}/articles", Ct).OkJsonAsync()).Should().Equal(second);
        (await guest.GetAsync($"{profile}/categories", Ct).OkJsonAsync())["uncategorizedCount"]!.GetValue<int>().Should().Be(2);

        // Hidden by a moderator: not listed or counted.
        await ModerateAsync(moderator, new { action = "hide", targetType = "article", targetId = second, note = "Test hide." });
        (await guest.GetAsync($"{profile}/categories", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty("its only article is hidden");
        (await guest.GetAsync($"{profile}/categories/{Slug(backend)}", Ct).OkJsonAsync())["articleCount"]!.GetValue<int>().Should().Be(0);
        (await guest.GetAsync($"{profile}/categories/{Slug(backend)}/articles", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty();
        await ModerateAsync(moderator, new { action = "unhide", targetType = "article", targetId = second });

        // Deleting the category leaves its articles published, without a category.
        (await writer.Client.DeleteAsync(CategoryUrl(backend), Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/articles/{secondSlug}", Ct).OkJsonAsync())["category"].Should().BeNull();
        (await guest.GetAsync($"{profile}/categories/_other", Ct).OkJsonAsync())["articleCount"]!.GetValue<int>().Should().Be(3);
        await guest.GetAsync($"{profile}/categories/{Slug(backend)}", Ct).ProblemAsync(HttpStatusCode.NotFound, "category.not_found");
        await guest.GetAsync($"{profile}/categories/{Slug(backend)}/articles", Ct).ProblemAsync(HttpStatusCode.NotFound, "category.not_found");
        await guest.GetAsync($"/api/v1/users/nobody_{u}/categories", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await guest.GetAsync($"/api/v1/users/nobody_{u}/categories/_other", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
    }

    [Fact]
    public async Task A_draft_keeps_its_category_through_saves_and_shows_in_it_once_published()
    {
        var writer = await api.UserAsync("Category Drafter");
        var guest = api.GuestClient();
        var u = Unique();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, $"Draft in category {u}"));
        var id = Id(draft);
        draft["categoryId"].Should().BeNull();
        var category = await CreatedAsync(writer.Client, $"Drafts {u}");

        (await SetCategoryAsync(writer.Client, id, Id(category))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var saved = await writer.Client.SaveDraftAsync(id, (await writer.Client.EditAsync(id))["version"]!.GetValue<int>(),
            ArticleTestKit.Document(field, $"Draft in category {u} v2")).OkJsonAsync();
        saved["categoryId"]!.GetValue<Guid>().Should().Be(Id(category), "it isn't part of the working copy");
        (await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync())["items"]![0]!["articleCount"]!.GetValue<int>()
            .Should().Be(0, "drafts are never counted");
        (await guest.GetAsync($"/api/v1/users/{Username(writer)}/categories", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty();

        var published = await writer.Client.PublishDraftAsync(id, saved["version"]!.GetValue<int>());
        published.StatusCode.Should().Be(HttpStatusCode.OK);
        var tab = await guest.GetAsync($"/api/v1/users/{Username(writer)}/categories", Ct).OkJsonAsync();
        Ids(tab).Should().Equal(Id(category));
        Ids(await guest.GetAsync($"/api/v1/users/{Username(writer)}/categories/{Slug(category)}/articles", Ct).OkJsonAsync()).Should().Equal(id);

        // Discarding changes doesn't touch it either.
        var edit = await writer.Client.EditAsync(id);
        (await writer.Client.SaveDraftAsync(id, edit["version"]!.GetValue<int>(), ArticleTestKit.Document(field, $"Draft in category {u} v3")))
            .StatusCode.Should().Be(HttpStatusCode.OK);
        (await writer.Client.DeleteAsync($"/api/v1/articles/{id}/draft", Ct).OkJsonAsync())["categoryId"]!.GetValue<Guid>().Should().Be(Id(category));
    }

    [Fact]
    public async Task Only_the_owner_sees_and_uses_a_category()
    {
        var writer = await api.UserAsync("Category Owner");
        var other = await api.UserAsync("Category Stranger");
        var u = Unique();
        var (article, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(await writer.Client.FieldIdAsync("dotnet"), $"Owned {u}"));
        var mine = await CreatedAsync(writer.Client, $"Mine {u}");
        var theirs = await CreatedAsync(other.Client, $"Theirs {u}");

        await SetCategoryAsync(writer.Client, article, Id(theirs)).ProblemAsync(HttpStatusCode.Forbidden, "category.not_owner");
        await SetCategoryAsync(writer.Client, article, Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "category.not_found");
        await SetCategoryAsync(other.Client, article, Id(theirs)).ProblemAsync(HttpStatusCode.Forbidden, "article.not_owner");
        await SetCategoryAsync(writer.Client, Guid.NewGuid(), Id(mine)).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await other.Client.PatchAsJsonAsync(CategoryUrl(mine), new { name = $"Taken {u}" }, Ct).ProblemAsync(HttpStatusCode.Forbidden, "category.not_owner");
        await other.Client.DeleteAsync(CategoryUrl(mine), Ct).ProblemAsync(HttpStatusCode.Forbidden, "category.not_owner");
        await other.Client.PatchAsJsonAsync($"/api/v1/me/categories/{Guid.NewGuid()}", new { name = "x" }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "category.not_found");
        Ids(await other.Client.PutAsJsonAsync("/api/v1/me/categories/order", new { categoryIds = new[] { Id(mine), Id(theirs) } }, Ct).OkJsonAsync())
            .Should().Equal([Id(theirs)], "another writer's ids are ignored");

        // Names and slugs are per writer.
        var same = await CreatedAsync(other.Client, $"Mine {u}");
        Slug(same).Should().Be(Slug(mine));

        var guest = api.GuestClient();
        (await guest.GetAsync("/api/v1/me/categories", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await guest.PostAsJsonAsync("/api/v1/me/categories", new { name = "x" }, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await SetCategoryAsync(guest, article, null)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ── Moderation ──────────────────────────────────────────────

    [Fact]
    public async Task A_moderator_clears_an_offensive_category_name_from_the_users_case()
    {
        var writer = await api.UserAsync("Offensive Categories");
        var reporter = await api.UserAsync("Category Reporter");
        var moderator = await ModeratorAsync();
        var guest = api.GuestClient();
        var u = Unique();
        var (article, slug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(await writer.Client.FieldIdAsync("dotnet"), $"Cleared {u}"));
        await CreatedAsync(writer.Client, "Category 1");
        var bad = await CreatedAsync(writer.Client, $"Offensive {u}");
        await CreatedAsync(writer.Client, $"Worse {u}");
        (await SetCategoryAsync(writer.Client, article, Id(bad))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["category"]!["name"]!.GetValue<string>().Should().Be($"Offensive {u}");
        (await reporter.Client.PostAsJsonAsync("/api/v1/reports",
            new { targetType = "user", targetId = writer.Id, reason = "harassment", details = "اسم القسم مسيء" }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        // The user's case lists every category, empty ones included.
        var userCase = await moderator.GetAsync($"/api/v1/moderation/reports/user/{writer.Id}", Ct).OkJsonAsync();
        userCase["categories"]!.AsArray().Select(c => c!["name"]!.GetValue<string>()).Should().Equal("Category 1", $"Offensive {u}", $"Worse {u}");
        userCase["categories"]![1]!["articleCount"]!.GetValue<int>().Should().Be(1);

        Codes(await ModerationPostAsync(moderator, new { action = "clear_category", targetType = "user", targetId = writer.Id })
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "categoryId").Should().Equal("validation.required");
        await ModerationPostAsync(moderator, new { action = "clear_category", targetType = "user", targetId = reporter.Id, categoryId = Id(bad) })
            .ProblemAsync(HttpStatusCode.NotFound, "category.not_found");
        await ModerationPostAsync(moderator, new { action = "clear_category", targetType = "article", targetId = article, categoryId = Id(bad) })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.action_invalid");

        await ModerateAsync(moderator, new { action = "clear_category", targetType = "user", targetId = writer.Id, categoryId = Id(bad), note = "Offensive name." });

        var cleared = (await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync())["items"]!.AsArray()
            .Single(c => c!["id"]!.GetValue<Guid>() == Id(bad))!;
        cleared["name"]!.GetValue<string>().Should().Be("Category 2", "the smallest number the writer doesn't use, in the writer's UI language");
        Slug(cleared).Should().Be("category-2");
        cleared["articleCount"]!.GetValue<int>().Should().Be(1, "its articles stay in it");
        await guest.GetAsync($"/api/v1/users/{Username(writer)}/categories/{Slug(bad)}", Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "category.not_found");
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["category"]!["name"]!.GetValue<string>().Should().Be("Category 2");

        // Logged on the user with the old name, audited, and the user's report is resolved.
        var log = await moderator.GetAsync($"/api/v1/moderation/actions?targetUserId={writer.Id}", Ct).OkJsonAsync();
        var entry = log["items"]!.AsArray().Should().ContainSingle().Subject!;
        entry["action"]!.GetValue<string>().Should().Be("user.clear_category");
        entry["targetType"]!.GetValue<string>().Should().Be("user");
        entry["targetLabel"]!.GetValue<string>().Should().Be($"Offensive {u}");
        entry["note"]!.GetValue<string>().Should().Be("Offensive name.");
        entry["reportsClosed"]!.GetValue<int>().Should().Be(1);
        (await moderator.GetAsync($"/api/v1/moderation/reports/user/{writer.Id}", Ct).OkJsonAsync())["item"]!["status"]!.GetValue<string>()
            .Should().Be("resolved");
        await WithDbAsync(async db => (await db.AuditLogs.CountAsync(l => l.Action == AuditActions.CategoryCleared && l.UserId == writer.Id, Ct))
            .Should().Be(1));

        // Clearing a placeholder again changes nothing and logs nothing.
        await ModerateAsync(moderator, new { action = "clear_category", targetType = "user", targetId = writer.Id, categoryId = Id(bad) });
        (await moderator.GetAsync($"/api/v1/moderation/actions?targetUserId={writer.Id}", Ct).OkJsonAsync())["items"]!.AsArray().Should().HaveCount(1);
    }

    [Fact]
    public async Task A_cleared_name_is_in_the_writers_ui_language()
    {
        var writer = await api.SignUpAsync("ar");
        var username = $"c_{Guid.NewGuid():N}"[..20];
        (await writer.Client.PutAsJsonAsync("/api/v1/me/profile/complete", new { displayName = "كاتب", username }, Ct)).EnsureSuccessStatusCode();
        var moderator = await ModeratorAsync();
        var bad = await CreatedAsync(writer.Client, $"مسيء {Unique()}");

        await ModerateAsync(moderator, new { action = "clear_category", targetType = "user", targetId = writer.Id, categoryId = Id(bad) });

        var cleared = (await writer.Client.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync())["items"]![0]!;
        cleared["name"]!.GetValue<string>().Should().Be("قسم 1");
        Slug(cleared).Should().Be("قسم-1");
    }

    // ── Account deletion and the demo seed ──────────────────────

    [Fact]
    public async Task Deleting_the_account_deletes_its_categories_and_the_kept_articles_lose_theirs()
    {
        var writer = await api.UserAsync("Leaving Categories");
        var guest = api.GuestClient();
        var u = Unique();
        var (article, slug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(await writer.Client.FieldIdAsync("dotnet"), $"Kept {u}"));
        var category = await CreatedAsync(writer.Client, $"Leaving {u}");
        (await SetCategoryAsync(writer.Client, article, Id(category))).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["category"].Should().NotBeNull();

        (await writer.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
        {
            Content = JsonContent.Create(new { password = ApiFactory.TestPassword }),
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var details = await guest.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
        details["author"].Should().BeNull();
        details["category"].Should().BeNull();
        await WithDbAsync(async db =>
        {
            (await db.WriterCategories.CountAsync(c => c.UserId == writer.Id, Ct)).Should().Be(0);
            (await db.Articles.IgnoreQueryFilters().Where(a => a.Id == article).Select(a => a.WriterCategoryId).SingleAsync(Ct)).Should().BeNull();
        });
    }

    [Fact]
    public async Task The_demo_seed_gives_demo_writers_no_categories()
    {
        // Demo writers have no articles (SPEC §18.1), so the seed gives them no categories, not even empty ones.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            scope.ServiceProvider.GetServices<ISeeder>().Select(s => s.Name).Should().NotContain("demo-categories");
        }

        var guest = api.GuestClient();
        foreach (var handle in new[] { "writer1", "writer2", "reviewer_ai" })
            (await guest.GetAsync($"/api/v1/users/{handle}/categories", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty();
        var writer1 = await api.SeedUserClientAsync(Writer1Phone);
        (await writer1.GetAsync("/api/v1/me/categories", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty("only the owner would see an empty one");
    }

    [Fact]
    public async Task The_openapi_document_describes_the_category_endpoints()
    {
        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();

        document["paths"]!.AsObject().Select(p => p.Key).Should().Contain([
            "/api/v1/users/{username}/categories", "/api/v1/users/{username}/categories/{slug}",
            "/api/v1/users/{username}/categories/{slug}/articles", "/api/v1/me/categories", "/api/v1/me/categories/{id}",
            "/api/v1/me/categories/order", "/api/v1/articles/{id}/category"]);
        document["components"]!["schemas"]!["WriterCategoryDto"]!["properties"]!.AsObject().Select(p => p.Key)
            .Should().BeEquivalentTo("id", "slug", "name", "articleCount", "sortOrder");
        document["components"]!["schemas"]!["WriterCategoryPageDto"]!["properties"]!.AsObject().Select(p => p.Key)
            .Should().BeEquivalentTo("id", "slug", "name", "articleCount", "author");
    }

    // ── Helpers ─────────────────────────────────────────────────

    private static Task<HttpResponseMessage> CreateAsync(HttpClient client, string? name) =>
        client.PostAsJsonAsync("/api/v1/me/categories", new { name }, Ct);

    private static async Task<JsonObject> CreatedAsync(HttpClient client, string name)
    {
        var response = await CreateAsync(client, name);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    private static Task<HttpResponseMessage> SetCategoryAsync(HttpClient client, Guid articleId, Guid? categoryId) =>
        client.PutAsJsonAsync($"/api/v1/articles/{articleId}/category", new { categoryId }, Ct);

    private static Task<HttpResponseMessage> ModerationPostAsync(HttpClient moderator, object action) =>
        moderator.PostAsJsonAsync("/api/v1/moderation/actions", action, Ct);

    private static async Task ModerateAsync(HttpClient moderator, object action)
    {
        var response = await ModerationPostAsync(moderator, action);
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));
    }

    /// <summary>Each test's own moderator: the <c>writes</c> limit is per user.</summary>
    private async Task<HttpClient> ModeratorAsync()
    {
        var user = await api.UserAsync("Category Moderator");
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        (await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == user.Id, Ct)).GrantRole(RoleIds.SuperAdmin); // moderation.manage
        await db.SaveChangesAsync(Ct);
        await scope.ServiceProvider.GetRequiredService<IUserAccessService>().InvalidateAsync(user.Id, Ct);
        return user.Client;
    }

    private static string CategoryUrl(JsonNode category) => $"/api/v1/me/categories/{Id(category)}";

    private static Guid Id(JsonNode node) => node["id"]!.GetValue<Guid>();

    private static string Slug(JsonNode node) => node["slug"]!.GetValue<string>();

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static IEnumerable<Guid> Ids(JsonObject list) => list["items"]!.AsArray().Select(c => c!["id"]!.GetValue<Guid>());

    private static IEnumerable<string> Codes(JsonObject problem, string key) =>
        problem["errors"]![key]!.AsArray().Select(e => e!.GetValue<string>());

    private async Task WithDbAsync(Func<AppDbContext, Task> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await action(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }
}
