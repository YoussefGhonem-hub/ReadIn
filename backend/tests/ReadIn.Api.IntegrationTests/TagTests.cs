using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Taxonomy;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F32 tags: shared names (case and Arabic letter forms ignored, first spelling kept), the editor's rules and limits,
/// suggestions, the tag page and its article list, hidden tags, the daily cleanup and the upgrade of older tags.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class TagTests(ApiFactory api)
{
    private const string ModeratorPhone = "+12025550103";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    /// <summary>A short unique word (lower-case hex), so every test has its own tags.</summary>
    private static string Unique() => $"zt{Guid.NewGuid():N}"[..10];

    private static IEnumerable<(string Name, string Slug)> TagRefs(JsonNode card) =>
        card["tags"]!.AsArray().Select(t => (t!["name"]!.GetValue<string>(), t["slug"]!.GetValue<string>()));

    // ── Names ───────────────────────────────────────────────────

    [Fact]
    public async Task Tags_are_shared_compared_without_case_or_arabic_letter_forms_and_keep_their_first_spelling()
    {
        var first = await api.UserAsync("Tag Writer One");
        var second = await api.UserAsync("Tag Writer Two");
        var field = await first.Client.FieldIdAsync("dotnet");
        var u = Unique();

        await first.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"First {u}", tags: [$"#Clean Code {u}", $"البرمجة {u}"]));
        var (_, slug) = await second.Client.WriteAndPublishAsync(ArticleTestKit.Document(
            field, $"Second {u}", tags: [$"البرمجه {u}", $"clean   code {u}", $"C# {u}"]));

        var details = await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
        TagRefs(details).Should().Equal(
            [($"البرمجة {u}", $"البرمجة-{u}"), ($"Clean Code {u}", $"clean-code-{u}"), ($"C# {u}", $"csharp-{u}")],
            "the writer's order, each tag with its first spelling and a URL-safe slug");
        details["tagCount"]!.GetValue<int>().Should().Be(3);

        var page = await api.GuestClient().GetAsync($"/api/v1/tags/clean-code-{u}", Ct).OkJsonAsync();
        page["name"]!.GetValue<string>().Should().Be($"Clean Code {u}");
        page["articleCount"]!.GetValue<int>().Should().Be(2, "both writers used it");
        (await api.GuestClient().GetAsync($"/api/v1/tags/CLEAN-CODE-{u}", Ct).OkJsonAsync())["slug"]!.GetValue<string>()
            .Should().Be($"clean-code-{u}", "slugs are matched ignoring case");
        var arabic = await api.GuestClient().GetAsync($"/api/v1/tags/{Uri.EscapeDataString($"البرمجة-{u}")}", Ct).OkJsonAsync();
        arabic["articleCount"]!.GetValue<int>().Should().Be(2, "البرمجه and البرمجة are one tag");
    }

    [Fact]
    public async Task Saving_cleans_tag_names_and_rejects_invalid_new_ones_but_not_existing_tags()
    {
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var u = Unique();

        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(
            field, $"Rules {u}", tags: [$"  #AI {u} ", $"ai {u}", $"Machine   Learning {u}", $"تَعَلُّم {u}"]));
        draft["document"]!["tags"]!.AsArray().Select(t => t!.GetValue<string>())
            .Should().Equal([$"AI {u}", $"Machine Learning {u}", $"تَعَلُّم {u}"], "cleaned, and a repeat of the same tag dropped");
        var id = draft["id"]!.GetValue<Guid>();
        var version = draft["version"]!.GetValue<int>();

        var invalid = await writer.Client.SaveDraftAsync(id, version, ArticleTestKit.Document(field, $"Rules {u}", tags: [$"ok {u}", $"CI/CD {u}", "x"]))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        invalid["errors"]!["document.tags[1]"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("tag.invalid");
        invalid["errors"]!["document.tags[2]"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("tag.invalid");
        invalid["errors"]!.AsObject().ContainsKey("document.tags[0]").Should().BeFalse();

        string[] six = [.. Enumerable.Range(1, 6).Select(i => $"t{i} {u}")];
        var tooMany = await writer.Client.SaveDraftAsync(id, version, ArticleTestKit.Document(field, $"Rules {u}", tags: six))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        tooMany["errors"]!["document.tags"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("article.too_many_tags");
        var flood = await writer.Client.SaveDraftAsync(id, version, ArticleTestKit.Document(
                field, $"Rules {u}", tags: [.. Enumerable.Repeat("!!", TagNames.MaxRawCount + 1)]))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        flood["errors"]!.AsObject().Select(e => e.Key).Should().Equal(["document.tags"], "past the cap the names aren't looked at one by one");
        (await writer.Client.SaveDraftAsync(id, version, ArticleTestKit.Document(field, $"Rules {u}", tags: [$"T1 {u}", .. six[..5]])))
            .StatusCode.Should().Be(HttpStatusCode.OK, "six names but five tags");

        // A tag from before the rules (here a system tag, like the seed content's "CI/CD") can still be picked.
        await WithDbAsync(async db =>
        {
            db.Tags.Add(new Tag($"CI/CD {u}", TagNames.Normalize($"CI/CD {u}"), $"ci-cd-{u}", createdById: null, DateTime.UtcNow));
            await db.SaveChangesAsync(Ct);
        });
        var edit = await writer.Client.EditAsync(id);
        var saved = await writer.Client.SaveDraftAsync(id, edit["version"]!.GetValue<int>(), ArticleTestKit.Document(field, $"Rules {u}", tags: [$"ci/cd {u}"]))
            .OkJsonAsync();
        saved.ProblemCodes().Should().BeEmpty();
        var slug = await (await writer.Client.PublishDraftAsync(id, saved["version"]!.GetValue<int>())).PublishedSlugAsync();
        TagRefs(await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())
            .Should().Equal([($"CI/CD {u}", $"ci-cd-{u}")], "the existing tag keeps its spelling");
    }

    // ── Suggestions ─────────────────────────────────────────────

    [Fact]
    public async Task Suggestions_match_words_and_slugs_with_the_exact_match_first_then_the_most_used()
    {
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var u = Unique();
        await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"One {u}", tags: [$"{u} Extra", $"Deep {u}"]));
        await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Two {u}", tags: [$"{u} Extra", $"C# {u}"]));
        await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Three {u}", tags: [u]));

        var found = await api.GuestClient().GetAsync($"/api/v1/tags?q={Uri.EscapeDataString("#" + u.ToUpperInvariant())}", Ct).OkArrayAsync();
        found.Select(t => t!["name"]!.GetValue<string>()).Should().Equal(
            [u, $"{u} Extra", $"C# {u}", $"Deep {u}"], "the exact match, then the most used, then by name; a later word matches too");
        found[1]!["articleCount"]!.GetValue<int>().Should().Be(2);
        found[1]!["slug"]!.GetValue<string>().Should().Be($"{u}-extra");

        var bySlug = await api.GuestClient().GetAsync($"/api/v1/tags?q=csharp-{u}", Ct).OkArrayAsync();
        bySlug.Select(t => t!["name"]!.GetValue<string>()).Should().Equal($"C# {u}");
        (await api.GuestClient().GetAsync($"/api/v1/tags?q={u}&limit=2", Ct).OkArrayAsync()).Should().HaveCount(2);
    }

    // ── The tag page ────────────────────────────────────────────

    [Fact]
    public async Task The_tag_page_lists_published_articles_from_all_writers_newest_first()
    {
        var a = await api.UserAsync("Tag Page A");
        var b = await api.UserAsync("Tag Page B");
        var field = await a.Client.FieldIdAsync("dotnet");
        var u = Unique();
        var tag = $"Paging {u}";
        var slug = $"paging-{u}";

        var (first, _) = await a.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"First {u}", tags: [tag, $"Lonely {u}"]));
        var (second, _) = await b.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Second {u}", tags: [$"Other {u}", tag]));
        var (third, _) = await a.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Third {u}", tags: [tag]));
        await a.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Untagged {u}"));

        var guest = api.GuestClient();
        var header = await guest.GetAsync($"/api/v1/tags/{slug}", Ct).OkJsonAsync();
        header["name"]!.GetValue<string>().Should().Be(tag);
        header["slug"]!.GetValue<string>().Should().Be(slug);
        header["articleCount"]!.GetValue<int>().Should().Be(3);

        var page1 = await guest.GetAsync($"/api/v1/tags/{slug}/articles?limit=2", Ct).OkJsonAsync();
        page1["items"]!.AsArray().Select(c => c!["id"]!.GetValue<Guid>()).Should().Equal(third, second);
        TagRefs(page1["items"]![1]!).Should().Equal([($"Other {u}", $"other-{u}"), (tag, slug)], "cards carry tag refs");
        var cursor = page1["nextCursor"]!.GetValue<string>();
        var page2 = await guest.GetAsync($"/api/v1/tags/{slug}/articles?limit=2&cursor={Uri.EscapeDataString(cursor)}", Ct).OkJsonAsync();
        page2["items"]!.AsArray().Select(c => c!["id"]!.GetValue<Guid>()).Should().Equal(first);
        page2["nextCursor"].Should().BeNull();

        // A signed-in reader gets their own state on the cards.
        await b.Client.ReactAsync(first, "insightful");
        var mine = await b.Client.GetAsync($"/api/v1/tags/{slug}/articles", Ct).OkJsonAsync();
        mine["items"]!.AsArray().Single(c => c!["id"]!.GetValue<Guid>() == first)!["myReaction"]!.GetValue<string>().Should().Be("insightful");

        // Hidden by a moderator or deleted: left out at once (the guests' cached page too).
        var moderator = await api.SeedUserClientAsync(ModeratorPhone);
        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "hide", targetType = "article", targetId = second, note = "Test hide." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await a.Client.DeleteAsync($"/api/v1/articles/{third}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await guest.GetAsync($"/api/v1/tags/{slug}/articles", Ct).OkJsonAsync())["items"]!.AsArray()
            .Select(c => c!["id"]!.GetValue<Guid>()).Should().Equal(first);
        (await guest.GetAsync($"/api/v1/tags/{slug}", Ct).OkJsonAsync())["articleCount"]!.GetValue<int>().Should().Be(1);

        // A tag whose articles are all gone is empty, not missing.
        var empty = await guest.GetAsync($"/api/v1/tags/other-{u}", Ct).OkJsonAsync();
        empty["articleCount"]!.GetValue<int>().Should().Be(0);
        (await guest.GetAsync($"/api/v1/tags/other-{u}/articles", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty();

        await guest.GetAsync($"/api/v1/tags/nope-{u}", Ct).ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
        await guest.GetAsync($"/api/v1/tags/nope-{u}/articles", Ct).ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
    }

    // ── Hidden tags ─────────────────────────────────────────────

    [Fact]
    public async Task A_hidden_tag_is_not_shown_suggested_or_pickable_and_comes_back_when_shown_again()
    {
        var a = await api.UserAsync("Hidden Tag A");
        var b = await api.UserAsync("Hidden Tag B");
        var field = await a.Client.FieldIdAsync("dotnet");
        var u = Unique();
        var hidden = $"Hidden {u}";
        var visible = $"Visible {u}";
        var (id, slug) = await a.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Hidden tags {u}", tags: [hidden, visible]));

        await SetHiddenAsync($"hidden-{u}", true);

        var details = await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
        TagRefs(details).Should().Equal([(visible, $"visible-{u}")]);
        details["tagCount"]!.GetValue<int>().Should().Be(1, "\"+N\" counts visible tags only");
        await api.GuestClient().GetAsync($"/api/v1/tags/hidden-{u}", Ct).ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
        await api.GuestClient().GetAsync($"/api/v1/tags/hidden-{u}/articles", Ct).ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
        (await api.GuestClient().GetAsync($"/api/v1/tags?q={Uri.EscapeDataString(hidden)}", Ct).OkArrayAsync()).Should().BeEmpty();

        // Someone else can't pick it…
        var draft = await b.Client.CreateDraftAsync(ArticleTestKit.Document(field, $"Picks hidden {u}", tags: [$"hidden {u}", $"Fine {u}"]));
        draft["checks"]!["problems"]!.AsArray().Select(p => (p!["code"]!.GetValue<string>(), p["tag"]?.GetValue<string>()))
            .Should().Equal(("tag.hidden", $"hidden {u}"));
        var refused = await b.Client.PublishDraftAsync(draft["id"]!.GetValue<Guid>(), draft["version"]!.GetValue<int>())
            .ProblemAsync(HttpStatusCode.BadRequest, "tag.hidden");
        refused["problems"]!.AsArray().Should().ContainSingle();

        // …but the article that has it keeps it through an Update, and showing the tag brings it back.
        var edit = await a.Client.EditAsync(id);
        var document = edit["document"]!.AsObject();
        document["tags"]!.AsArray().Select(t => t!.GetValue<string>()).Should().Equal(hidden, visible);
        document["translations"]![0]!["title"] = $"Hidden tags updated {u}";
        var saved = await a.Client.SaveDraftAsync(id, edit["version"]!.GetValue<int>(), document).OkJsonAsync();
        saved.ProblemCodes().Should().BeEmpty();
        await (await a.Client.PublishCurrentAsync(id)).PublishedSlugAsync();

        await SetHiddenAsync($"hidden-{u}", false);
        TagRefs(await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())
            .Should().Equal([(hidden, $"hidden-{u}"), (visible, $"visible-{u}")]);
    }

    // ── Limits ──────────────────────────────────────────────────

    [Fact]
    public async Task A_writer_creates_at_most_twenty_new_tags_a_day()
    {
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var u = Unique();
        for (var i = 0; i < 4; i++)
        {
            await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(
                field, $"Batch {i} {u}", tags: [.. Enumerable.Range(0, 5).Select(j => $"L{i}{j} {u}")]));
        }

        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, $"Over {u}", tags: [$"L00 {u}", $"New1 {u}", $"New2 {u}"]));
        draft["checks"]!["problems"]!.AsArray().Select(p => (p!["code"]!.GetValue<string>(), p["tag"]?.GetValue<string>()))
            .Should().Equal([("tag.limit", $"New1 {u}"), ("tag.limit", $"New2 {u}")], "an existing tag is fine; new ones are over the limit");
        var id = draft["id"]!.GetValue<Guid>();
        await writer.Client.PublishDraftAsync(id, draft["version"]!.GetValue<int>()).ProblemAsync(HttpStatusCode.BadRequest, "tag.limit");

        // A day later the allowance is back.
        await WithDbAsync(db => db.Tags.Where(t => t.CreatedById == writer.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.CreatedAt, t => t.CreatedAt.AddHours(-25)), Ct));
        (await writer.Client.EditAsync(id)).ProblemCodes().Should().BeEmpty();
        await (await writer.Client.PublishCurrentAsync(id)).PublishedSlugAsync();
        await WithDbAsync(async db => (await db.Tags.CountAsync(t => t.CreatedById == writer.Id && t.CreatedAt > DateTime.UtcNow.AddHours(-1), Ct))
            .Should().Be(2, "the two new tags are the writer's"));
    }

    [Fact]
    public async Task A_publish_that_loses_the_race_for_a_new_tag_uses_the_tag_the_other_one_saved()
    {
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var u = Unique();
        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, $"Race {u}", tags: [$"Race {u}", $"C# {u}"]));

        // Hold the publish after it looked for its tags and picked their slugs (it reads the article's revisions last,
        // then saves). Meanwhile another writer's tags land: one with the same name, one with the slug "C#" picked.
        string connectionString = null!;
        await WithDbAsync(db =>
        {
            connectionString = db.Database.GetConnectionString()!;
            return Task.CompletedTask;
        });
        await using var gate = new SqlConnection(connectionString);
        await gate.OpenAsync(Ct);
        await using var hold = (SqlTransaction)await gate.BeginTransactionAsync(Ct);
        await using (var lockRevisions = new SqlCommand("SELECT COUNT(*) FROM [ArticleRevisions] WITH (TABLOCKX, HOLDLOCK)", gate, hold))
            await lockRevisions.ExecuteScalarAsync(Ct);

        var publishing = writer.Client.PublishDraftAsync(draft["id"]!.GetValue<Guid>(), draft["version"]!.GetValue<int>());
        await WaitUntilBlockedAsync(gate, hold, "RevisionNumber");
        await WithDbAsync(async db =>
        {
            db.Tags.Add(new Tag($"race {u}", TagNames.Normalize($"race {u}"), $"race-{u}", createdById: null, DateTime.UtcNow));
            db.Tags.Add(new Tag($"csharp {u}", TagNames.Normalize($"csharp {u}"), $"csharp-{u}", createdById: null, DateTime.UtcNow));
            await db.SaveChangesAsync(Ct);
        });
        await hold.CommitAsync(Ct);

        var slug = await (await publishing).PublishedSlugAsync();
        TagRefs(await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync()).Should().Equal(
            [($"race {u}", $"race-{u}"), ($"C# {u}", $"csharp-{u}-2")], "the saved tag is used, and the new one gets a free slug");
        await WithDbAsync(async db => (await db.Tags.Where(t => t.Slug.Contains(u)).Select(t => t.Slug).ToListAsync(Ct))
            .Should().BeEquivalentTo([$"race-{u}", $"csharp-{u}", $"csharp-{u}-2"], "no second copy of the tag"));
    }

    // ── Upkeep ──────────────────────────────────────────────────

    [Fact]
    public async Task The_daily_job_deletes_user_tags_without_articles_for_30_days_and_keeps_system_tags()
    {
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var u = Unique();
        var (gone, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Gone {u}", tags: [$"Gone {u}", $"Kept {u}"]));
        await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Stays {u}", tags: [$"Kept {u}"]));
        (await writer.Client.DeleteAsync($"/api/v1/articles/{gone}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await WithDbAsync(async db =>
        {
            db.Tags.Add(new Tag($"System {u}", TagNames.Normalize($"System {u}"), $"system-{u}", createdById: null, DateTime.UtcNow.AddDays(-90)));
            await db.SaveChangesAsync(Ct);
        });

        await RunCleanupAsync();
        var marked = await TagsAsync(u);
        marked[$"gone-{u}"].EmptySince.Should().NotBeNull("it lost its last published article");
        marked[$"kept-{u}"].EmptySince.Should().BeNull();
        marked[$"system-{u}"].EmptySince.Should().BeNull("system tags are never marked");

        await WithDbAsync(async db =>
        {
            var longAgo = DateTime.UtcNow.AddDays(-31);
            await db.Tags.Where(t => t.Slug == $"gone-{u}" || t.Slug == $"kept-{u}")
                .ExecuteUpdateAsync(s => s.SetProperty(t => t.EmptySince, longAgo), Ct);
        });
        await RunCleanupAsync();

        var left = await TagsAsync(u);
        left.Keys.Should().BeEquivalentTo([$"kept-{u}", $"system-{u}"], "only the empty user tag goes");
        left[$"kept-{u}"].EmptySince.Should().BeNull("a tag that has an article again starts over");
    }

    [Fact]
    public async Task A_deleted_account_leaves_its_tags_without_a_creator()
    {
        var leaving = await api.UserAsync();
        var field = await leaving.Client.FieldIdAsync("dotnet");
        var u = Unique();
        await leaving.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Leaving {u}", tags: [$"Leaver {u}"]));
        (await TagsAsync(u))[$"leaver-{u}"].CreatedById.Should().Be(leaving.Id);

        (await leaving.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
        {
            Content = JsonContent.Create(new { password = ApiFactory.TestPassword }),
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var tag = (await TagsAsync(u))[$"leaver-{u}"];
        tag.CreatedById.Should().BeNull("nothing links a kept row to a deleted account (SPEC §9.6)");
        tag.IsSystem.Should().BeFalse("it is still a user tag the cleanup job may delete");
    }

    [Fact]
    public async Task Tags_from_before_F32_are_upgraded_and_merged_at_startup()
    {
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var u = Unique();
        var (articleId, slug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Legacy {u}"));
        Guid older = Guid.NewGuid(), newer = Guid.NewGuid(), messy = Guid.NewGuid(), seed = Guid.NewGuid();

        await WithDbAsync(async db =>
        {
            var editorial = Article.CreateDraft(SystemUsers.EditorialId, field, topicId: null, $"legacy-seed-{u}", sourceLanguage: "en");
            db.Articles.Add(editorial);
            await db.SaveChangesAsync(Ct);

            var now = DateTime.UtcNow;
            await InsertLegacyTagAsync(db, older, $"Lazy loading {u}", now.AddDays(-2));
            await InsertLegacyTagAsync(db, newer, $"Lazy Loading {u}", now.AddDays(-1));
            await InsertLegacyTagAsync(db, messy, $"#Old   Tag {u}", now.AddDays(-1));
            await InsertLegacyTagAsync(db, seed, $"C# {u}", now.AddDays(-3));
            await db.Database.ExecuteSqlAsync($"""
                INSERT INTO [ArticleTags] ([ArticleId], [TagId], [Position]) VALUES
                    ({articleId}, {newer}, 0), ({articleId}, {older}, 1), ({articleId}, {messy}, 2), ({editorial.Id}, {seed}, 0)
                """, Ct);

            (await LegacyTagsUpgrade.RunAsync(db, Ct)).Should().Be(4);
            (await LegacyTagsUpgrade.RunAsync(db, Ct)).Should().Be(0, "it runs once");
        });

        var tags = await TagsAsync(u);
        tags.Keys.Should().BeEquivalentTo([$"lazy-loading-{u}", $"old-tag-{u}", $"csharp-{u}"], "the two lazy-loading tags are one now");
        tags[$"lazy-loading-{u}"].Should().Match<Tag>(t => t.Id == older && t.Name == $"Lazy loading {u}"
            && t.NormalizedName == $"lazy loading {u}" && !t.IsSystem && t.CreatedById == writer.Id, "the oldest spelling stays");
        tags[$"old-tag-{u}"].Name.Should().Be($"Old Tag {u}");
        tags[$"csharp-{u}"].Should().Match<Tag>(t => t.IsSystem && t.CreatedById == null, "the seed content uses it");

        await ClearCachesAsync();
        TagRefs(await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync()).Select(t => t.Name)
            .Should().Equal([$"Lazy loading {u}", $"Old Tag {u}"], "one link per tag, in the article's order");

        // The editorial draft only stood in for the seed content.
        await WithDbAsync(db => db.Articles.IgnoreQueryFilters().Where(a => a.Slug == $"legacy-seed-{u}").ExecuteDeleteAsync(Ct));
    }

    [Fact]
    public async Task An_api_start_that_does_not_migrate_still_upgrades_tags_from_before_F32()
    {
        var u = Unique();
        await WithDbAsync(db => InsertLegacyTagAsync(db, Guid.NewGuid(), $"#Script   Tag {u}", DateTime.UtcNow));

        // Production may apply the migrations as a SQL script or a bundle: the next start finishes the job before it
        // serves requests.
        await using var host = api.WithWebHostBuilder(builder => builder
            .UseSetting("Database:MigrateOnStartup", "false")
            .UseSetting("Seed:RunOnStartup", "false"));
        _ = host.Server;

        var tag = (await TagsAsync(u)).Should().ContainKey($"script-tag-{u}").WhoseValue;
        tag.Name.Should().Be($"Script Tag {u}");
        tag.NormalizedName.Should().Be($"script tag {u}");
    }

    // ── Helpers ─────────────────────────────────────────────────

    private async Task WithDbAsync(Func<AppDbContext, Task> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await action(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    /// <summary>The tags whose slug ends with <paramref name="u"/>, by slug.</summary>
    private async Task<Dictionary<string, Tag>> TagsAsync(string u)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        return await db.Tags.AsNoTracking().Where(t => t.Slug.EndsWith("-" + u)).ToDictionaryAsync(t => t.Slug, Ct);
    }

    /// <summary>Hides or shows a tag the way F23 will (it isn't built yet): the flag, then the caches that show it.</summary>
    private async Task SetHiddenAsync(string slug, bool hidden)
    {
        await WithDbAsync(async db =>
        {
            var tag = await db.Tags.SingleAsync(t => t.Slug == slug, Ct);
            if (hidden) tag.Hide();
            else tag.Show();
            await db.SaveChangesAsync(Ct);
        });
        await ClearCachesAsync();
    }

    private async Task ClearCachesAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<HybridCache>()
            .RemoveByTagAsync([CacheTags.Tags, CacheTags.Feed, CacheTags.Articles], Ct);
    }

    /// <summary>Waits until a request whose SQL mentions <paramref name="sqlFragment"/> waits for a lock the gate holds.</summary>
    private static async Task WaitUntilBlockedAsync(SqlConnection gate, SqlTransaction hold, string sqlFragment)
    {
        await using var command = new SqlCommand("""
            SELECT COUNT(*) FROM sys.dm_exec_requests AS r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
            WHERE r.blocking_session_id = @@SPID AND t.text LIKE '%' + @fragment + '%'
            """, gate, hold);
        command.Parameters.AddWithValue("@fragment", sqlFragment);
        for (var waited = TimeSpan.Zero; waited < TimeSpan.FromSeconds(20); waited += TimeSpan.FromMilliseconds(50))
        {
            if ((int)(await command.ExecuteScalarAsync(Ct))! > 0) return;
            await Task.Delay(50, Ct);
        }
        throw new TimeoutException($"No request reached the held lock ({sqlFragment}).");
    }

    private async Task RunCleanupAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<TagCleanupJob>().RunAsync(Ct);
    }

    /// <summary>A tag as the migration leaves one made before F32: placeholder normalized name and slug.</summary>
    private static Task InsertLegacyTagAsync(AppDbContext db, Guid id, string name, DateTime createdAt)
    {
        var placeholder = LegacyTagsUpgrade.Marker + id.ToString();
        return db.Database.ExecuteSqlAsync($"""
            INSERT INTO [Tags] ([Id], [Slug], [Name], [NormalizedName], [CreatedAt], [CreatedById], [IsHidden], [IsSystem], [EmptySince])
            VALUES ({id}, {placeholder}, {name}, {placeholder}, {createdAt}, NULL, 0, 0, NULL)
            """, Ct);
    }
}
