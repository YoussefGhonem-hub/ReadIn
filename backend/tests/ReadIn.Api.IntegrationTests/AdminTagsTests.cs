using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Identity;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F23 Tags (SPEC F23, F32): the console's list, rename (the slug stays, the old spelling becomes an alias), merge (articles
/// move, the merged name and slug become aliases, links keep working) and hide/unhide.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminTagsTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    /// <summary>A short unique word, so every test has its own tags.</summary>
    private static string Unique() => $"za{Guid.NewGuid():N}"[..10];

    private static IEnumerable<string> TagSlugs(JsonNode details) => details["tags"]!.AsArray().Select(t => t!["slug"]!.GetValue<string>());

    private async Task<JsonObject> TagRowAsync(HttpClient admin, string q) =>
        (await admin.GetAsync($"/api/v1/admin/tags?q={Uri.EscapeDataString(q)}", Ct).OkJsonAsync()).PageItems()
            .Single()!.AsObject();

    private async Task<(Guid Id, string Slug)> PublishWithTagsAsync(HttpClient writer, params string[] tags)
    {
        var field = await writer.FieldIdAsync("dotnet");
        return await writer.WriteAndPublishAsync(ArticleTestKit.Document(field, $"Tagged {Guid.NewGuid():N}", tags: tags));
    }

    [Fact]
    public async Task Tag_routes_are_for_taxonomy_managers_only()
    {
        var id = Guid.NewGuid();
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/tags");
        await api.AssertAdminOnlyAsync(HttpMethod.Put, $"/api/v1/admin/tags/{id}", new { name = "x y" });
        await api.AssertAdminOnlyAsync(HttpMethod.Post, $"/api/v1/admin/tags/{id}/merge", new { intoTagId = Guid.NewGuid() });
        await api.AssertAdminOnlyAsync(HttpMethod.Put, $"/api/v1/admin/tags/{id}/hidden");
        await api.AssertAdminOnlyAsync(HttpMethod.Delete, $"/api/v1/admin/tags/{id}/hidden");
    }

    [Fact]
    public async Task The_list_has_counts_the_creator_filters_sorts_and_offset_pages()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Tag List Writer");
        var u = Unique();
        await PublishWithTagsAsync(writer.Client, $"Alpha {u}", $"Beta {u}");
        await PublishWithTagsAsync(writer.Client, $"Alpha {u}");

        var page = await admin.Client.GetAsync($"/api/v1/admin/tags?q={u}", Ct).OkJsonAsync();
        var items = page.PageItems();
        (page["totalCount"]!.GetValue<int>(), page["page"]!.GetValue<int>(), page["pageSize"]!.GetValue<int>()).Should().Be((2, 1, 50));
        items.Select(t => t!["name"]!.GetValue<string>()).Should().Equal([$"Alpha {u}", $"Beta {u}"], "most used first");
        var alpha = items[0]!.AsObject();
        alpha.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "slug", "name", "articleCount", "taggedCount", "isHidden", "isSystem", "createdAt", "createdBy", "emptySince", "aliases");
        (alpha["articleCount"]!.GetValue<int>(), alpha["taggedCount"]!.GetValue<int>()).Should().Be((2, 2));
        (alpha["isHidden"]!.GetValue<bool>(), alpha["isSystem"]!.GetValue<bool>()).Should().Be((false, false));
        alpha["createdBy"]!["username"]!.GetValue<string>().Should().Be(writer.Me["username"]!.GetValue<string>());
        alpha["aliases"]!.AsArray().Should().BeEmpty();

        var byName = (await admin.Client.GetAsync($"/api/v1/admin/tags?q={u}&sort=name&pageSize=1&page=2", Ct).OkJsonAsync());
        (byName["totalPages"]!.GetValue<int>(), byName.PageItems().Single()!["name"]!.GetValue<string>()).Should().Be((2, $"Beta {u}"));
        (await admin.Client.GetAsync($"/api/v1/admin/tags?q={u}&page=9", Ct).OkJsonAsync()).PageItems().Should().BeEmpty();
        (await admin.Client.GetAsync($"/api/v1/admin/tags?q={u}&origin=system", Ct).OkJsonAsync()).PageItems().Should().BeEmpty();
        (await admin.Client.GetAsync($"/api/v1/admin/tags?q={u}&origin=user&status=visible", Ct).OkJsonAsync()).PageItems().Should().HaveCount(2);
        (await admin.Client.GetAsync($"/api/v1/admin/tags?q=%23ALPHA%20{u}", Ct).OkJsonAsync()).PageItems().Should().ContainSingle(
            "q is cleaned and normalized like a tag name");

        foreach (var bad in new[] { "status=gone", "origin=robots", "sort=random" })
        {
            var problem = await admin.Client.GetAsync($"/api/v1/admin/tags?{bad}", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            problem["errors"]![bad.Split('=')[0]]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.invalid");
        }
        (await admin.Client.GetAsync($"/api/v1/admin/tags?q={new string('x', 65)}", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))
            ["errors"]!["q"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.max_length");
    }

    [Fact]
    public async Task Renaming_keeps_the_slug_and_the_old_spelling_still_leads_to_the_tag()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Rename Writer");
        var u = Unique();
        var (_, articleSlug) = await PublishWithTagsAsync(writer.Client, $"Javascript {u}");
        var row = await TagRowAsync(admin.Client, $"javascript {u}");
        var id = row["id"]!.GetValue<Guid>();
        var slug = row["slug"]!.GetValue<string>();

        // The same tag, re-spelled: no alias.
        var respelled = await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{id}", new { name = $"JavaScript {u}" }, Ct).OkJsonAsync();
        (respelled["name"]!.GetValue<string>(), respelled["slug"]!.GetValue<string>()).Should().Be(($"JavaScript {u}", slug));
        respelled["aliases"]!.AsArray().Should().BeEmpty();

        // Another name: the old spelling becomes an alias.
        var renamed = await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{id}", new { name = $"  #JS   {u} " }, Ct).OkJsonAsync();
        (renamed["name"]!.GetValue<string>(), renamed["slug"]!.GetValue<string>()).Should().Be(($"JS {u}", slug), "cleaned, and the slug never changes");
        renamed["aliases"]!.AsArray().Select(a => a!.GetValue<string>()).Should().Equal($"JavaScript {u}");
        (await api.GuestClient().GetAsync($"/api/v1/tags/{slug}", Ct).OkJsonAsync())["name"]!.GetValue<string>().Should().Be($"JS {u}");
        (await api.GuestClient().GetAsync($"/api/v1/articles/{articleSlug}", Ct).OkJsonAsync())["tags"]!.AsArray().Single()!["name"]!
            .GetValue<string>().Should().Be($"JS {u}", "cards and the reader carry the new name at once");
        (await TagRowAsync(admin.Client, $"javascript {u}"))["id"]!.GetValue<Guid>().Should().Be(id, "the console's search finds aliases");

        // A writer who types the old spelling gets this tag, and creates none.
        var tagsBefore = await api.InDbAsync(db => db.Tags.CountAsync(Ct));
        var (_, second) = await PublishWithTagsAsync(writer.Client, $"javascript {u}");
        TagSlugs(await api.GuestClient().GetAsync($"/api/v1/articles/{second}", Ct).OkJsonAsync()).Should().Equal(slug);
        (await api.InDbAsync(db => db.Tags.CountAsync(Ct))).Should().Be(tagsBefore);

        // Back to the old spelling: the alias becomes the name again, and the current spelling an alias.
        var back = await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{id}", new { name = $"JavaScript {u}" }, Ct).OkJsonAsync();
        back["aliases"]!.AsArray().Select(a => a!.GetValue<string>()).Should().Equal($"JS {u}");

        var entries = await api.InDbAsync(db => db.AuditLogs.AsNoTracking()
            .Where(a => a.Action == AuditActions.TagRenamed && a.TargetId == id).OrderBy(a => a.CreatedAt).Select(a => a.Details).ToListAsync(Ct));
        entries.Should().Equal($"Javascript {u} → JavaScript {u}", $"JavaScript {u} → JS {u}", $"JS {u} → JavaScript {u}");

        // Unchanged: nothing written.
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{id}", new { name = $"JavaScript {u}" }, Ct).OkJsonAsync();
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.TagRenamed && a.TargetId == id, Ct))).Should().Be(3);
    }

    [Fact]
    public async Task A_rename_onto_another_tag_offers_a_merge_and_bad_names_are_refused()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Clash Writer");
        var u = Unique();
        await PublishWithTagsAsync(writer.Client, $"React {u}", $"ReactJS {u}");
        var react = await TagRowAsync(admin.Client, $"react {u}");
        var reactJs = await TagRowAsync(admin.Client, $"reactjs {u}");

        var clash = await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{reactJs["id"]}", new { name = $"REACT {u}" }, Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "tag.name_taken");
        (clash["tagId"]!.GetValue<Guid>(), clash["tagSlug"]!.GetValue<string>())
            .Should().Be((react["id"]!.GetValue<Guid>(), react["slug"]!.GetValue<string>()));

        // Another tag's alias is taken too.
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{react["id"]}", new { name = $"React Library {u}" }, Ct).OkJsonAsync();
        (await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{reactJs["id"]}", new { name = $"react {u}" }, Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "tag.name_taken"))["tagId"]!.GetValue<Guid>().Should().Be(react["id"]!.GetValue<Guid>());

        foreach (var bad in new[] { "x", "CI/CD", "ـــ", new string('a', 31) })
        {
            (await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{reactJs["id"]}", new { name = bad }, Ct)
                    .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!["name"]!.AsArray()
                .Select(e => e!.GetValue<string>()).Should().Equal("tag.invalid");
        }
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/tags/{Guid.NewGuid()}", new { name = "Fine name" }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
    }

    [Fact]
    public async Task Merging_moves_the_articles_and_the_merged_name_and_slug_lead_to_the_other_tag()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Merge Writer");
        var u = Unique();
        var (_, first) = await PublishWithTagsAsync(writer.Client, $"Kubernetes {u}", $"Docker {u}");
        var (_, second) = await PublishWithTagsAsync(writer.Client, $"K8s {u}", $"Helm {u}", $"Kubernetes {u}");
        var (_, third) = await PublishWithTagsAsync(writer.Client, $"Kubernetes {u}");
        var from = await TagRowAsync(admin.Client, $"kubernetes {u}");
        var into = await TagRowAsync(admin.Client, $"k8s {u}");
        var fromSlug = from["slug"]!.GetValue<string>();
        var intoSlug = into["slug"]!.GetValue<string>();
        var fromId = from["id"]!.GetValue<Guid>();
        var intoId = into["id"]!.GetValue<Guid>();

        var merged = await admin.Client.PostAsJsonAsync($"/api/v1/admin/tags/{fromId}/merge", new { intoTagId = intoId }, Ct).OkJsonAsync();
        merged["id"]!.GetValue<Guid>().Should().Be(intoId);
        (merged["articleCount"]!.GetValue<int>(), merged["taggedCount"]!.GetValue<int>()).Should().Be((3, 3));
        merged["aliases"]!.AsArray().Select(a => a!.GetValue<string>()).Should().Equal($"Kubernetes {u}");

        // Each article has the tag it went into at the merged one's place, once, and its other tags in order.
        TagSlugs(await api.GuestClient().GetAsync($"/api/v1/articles/{first}", Ct).OkJsonAsync()).Should().Equal(intoSlug, $"docker-{u}");
        TagSlugs(await api.GuestClient().GetAsync($"/api/v1/articles/{second}", Ct).OkJsonAsync()).Should().Equal(intoSlug, $"helm-{u}");
        TagSlugs(await api.GuestClient().GetAsync($"/api/v1/articles/{third}", Ct).OkJsonAsync()).Should().Equal(intoSlug);

        // The old link answers the tag it went into; the old name leads there too.
        var page = await api.GuestClient().GetAsync($"/api/v1/tags/{fromSlug}", Ct).OkJsonAsync();
        (page["slug"]!.GetValue<string>(), page["articleCount"]!.GetValue<int>()).Should().Be((intoSlug, 3));
        (await api.GuestClient().GetAsync($"/api/v1/tags/{fromSlug}/articles", Ct).OkJsonAsync())["items"]!.AsArray().Should().HaveCount(3);
        var (_, fourth) = await PublishWithTagsAsync(writer.Client, $"kubernetes {u}");
        TagSlugs(await api.GuestClient().GetAsync($"/api/v1/articles/{fourth}", Ct).OkJsonAsync()).Should().Equal(intoSlug);
        (await api.InDbAsync(db => db.Tags.AnyAsync(t => t.Id == fromId, Ct))).Should().BeFalse("the merged tag is deleted");

        var entry = await api.InDbAsync(db => db.AuditLogs.AsNoTracking().SingleAsync(a => a.Action == AuditActions.TagMerged && a.TargetId == intoId, Ct));
        (entry.TargetType, entry.Details).Should().Be(("tag", $"Kubernetes {u} → K8s {u} (3 articles)"));

        // A new tag can't take the merged tag's slug: it still opens the other tag.
        var (_, fifth) = await PublishWithTagsAsync(writer.Client, $"Kubernetes-{u}");
        TagSlugs(await api.GuestClient().GetAsync($"/api/v1/articles/{fifth}", Ct).OkJsonAsync()).Should().Equal($"{fromSlug}-2");

        await admin.Client.PostAsJsonAsync($"/api/v1/admin/tags/{intoId}/merge", new { intoTagId = intoId }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "tag.merge_self");
        await admin.Client.PostAsJsonAsync($"/api/v1/admin/tags/{fromId}/merge", new { intoTagId = intoId }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
    }

    [Fact]
    public async Task Hiding_is_idempotent_and_unhiding_brings_the_tag_back()
    {
        var admin = await api.SuperAdminAsync();
        var writer = await api.UserAsync("Hide Writer");
        var u = Unique();
        var (_, article) = await PublishWithTagsAsync(writer.Client, $"Spam {u}");
        var row = await TagRowAsync(admin.Client, $"spam {u}");
        var id = row["id"]!.GetValue<Guid>();
        var slug = row["slug"]!.GetValue<string>();
        await api.GuestClient().GetAsync($"/api/v1/tags/{slug}", Ct).OkJsonAsync();

        (await admin.Client.PutAsync($"/api/v1/admin/tags/{id}/hidden", null, Ct).OkJsonAsync())["isHidden"]!.GetValue<bool>().Should().BeTrue();
        await admin.Client.PutAsync($"/api/v1/admin/tags/{id}/hidden", null, Ct).OkJsonAsync();
        await api.GuestClient().GetAsync($"/api/v1/tags/{slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
        (await api.GuestClient().GetAsync($"/api/v1/articles/{article}", Ct).OkJsonAsync())["tags"]!.AsArray().Should().BeEmpty();
        (await admin.Client.GetAsync($"/api/v1/admin/tags?q={u}&status=hidden", Ct).OkJsonAsync()).PageItems().Should().ContainSingle();
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.TagHidden && a.TargetId == id, Ct))).Should().Be(1);

        (await admin.Client.DeleteAsync($"/api/v1/admin/tags/{id}/hidden", Ct).OkJsonAsync())["isHidden"]!.GetValue<bool>().Should().BeFalse();
        await admin.Client.DeleteAsync($"/api/v1/admin/tags/{id}/hidden", Ct).OkJsonAsync();
        await api.GuestClient().GetAsync($"/api/v1/tags/{slug}", Ct).OkJsonAsync();
        TagSlugs(await api.GuestClient().GetAsync($"/api/v1/articles/{article}", Ct).OkJsonAsync()).Should().Equal(slug);
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.TagUnhidden && a.TargetId == id, Ct))).Should().Be(1);

        await admin.Client.PutAsync($"/api/v1/admin/tags/{Guid.NewGuid()}/hidden", null, Ct).ProblemAsync(HttpStatusCode.NotFound, "tag.not_found");
    }
}
