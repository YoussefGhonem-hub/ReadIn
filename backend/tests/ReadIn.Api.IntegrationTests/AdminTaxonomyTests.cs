using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Identity;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F23 Taxonomy (SPEC F23, §18): fields and topics in the admin console. Add, rename, restyle, reorder, disable and enable,
/// nothing deleted, slugs fixed; a changed row is customized and the taxonomy seeder leaves it alone; a disabled topic
/// leaves the lists but stays on its articles.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminTaxonomyTests(ApiFactory api) : IAsyncLifetime
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    /// <summary>When this test started: the fields it adds are created after it.</summary>
    private readonly DateTime _started = DateTime.UtcNow.AddSeconds(-1);

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    /// <summary>
    /// The suite shares one database: the fields a test added are disabled afterwards, so other tests still see exactly the
    /// seeded fields in <c>GET /fields</c> (and Explore, the sitemap, interests).
    /// </summary>
    public async ValueTask DisposeAsync() =>
        await api.InDbAsync(db => db.Fields.IgnoreQueryFilters()
            .Where(f => f.CreatedAt >= _started && f.IsEnabled)
            .ExecuteUpdateAsync(s => s.SetProperty(f => f.IsEnabled, false), CancellationToken.None));

    private static string Slug(string prefix) => $"{prefix}-{Guid.NewGuid():N}"[..(prefix.Length + 9)];

    private static object NewField(string slug, string nameEn = "Robotics", bool isEnabled = true, string icon = "cpu", string color = "accent") =>
        new { slug, nameAr = "الروبوتات", nameEn, icon, color, isSensitive = false, requiresSources = true, isEnabled };

    private static async Task<JsonObject> CreateFieldAsync(HttpClient admin, string slug, bool isEnabled = true)
    {
        var response = await admin.PostAsJsonAsync("/api/v1/admin/fields", NewField(slug, isEnabled: isEnabled), Ct);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    private static async Task<JsonObject> CreateTopicAsync(HttpClient admin, Guid fieldId, string slug, string nameEn = "Drones")
    {
        var response = await admin.PostAsJsonAsync("/api/v1/admin/topics", new { fieldId, slug, nameAr = "طائرات", nameEn, isEnabled = true }, Ct);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    private async Task<JsonObject> FieldRowAsync(HttpClient admin, string slug) =>
        (await admin.GetAsync("/api/v1/admin/fields", Ct).OkJsonAsync())["fields"]!.AsArray()
            .Single(f => f!["slug"]!.GetValue<string>() == slug)!.AsObject();

    private Task<int> AuditCountAsync(string action, Guid targetId) =>
        api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == action && a.TargetId == targetId, Ct));

    [Fact]
    public async Task Taxonomy_routes_are_for_taxonomy_managers_only()
    {
        var id = Guid.NewGuid();
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/fields");
        await api.AssertAdminOnlyAsync(HttpMethod.Post, "/api/v1/admin/fields", NewField(Slug("guard")));
        await api.AssertAdminOnlyAsync(HttpMethod.Put, $"/api/v1/admin/fields/{id}", NewField("x"));
        await api.AssertAdminOnlyAsync(HttpMethod.Put, "/api/v1/admin/fields/order", new { ids = new[] { id } });
        await api.AssertAdminOnlyAsync(HttpMethod.Post, "/api/v1/admin/topics", new { fieldId = id, slug = "x", nameAr = "x", nameEn = "x", isEnabled = true });
        await api.AssertAdminOnlyAsync(HttpMethod.Put, $"/api/v1/admin/topics/{id}", new { nameAr = "x", nameEn = "x", isEnabled = true });
        await api.AssertAdminOnlyAsync(HttpMethod.Put, $"/api/v1/admin/fields/{id}/topics/order", new { ids = new[] { id } });

        // A staff role with taxonomy.manage alone is enough; another admin permission is not.
        var taxonomist = await api.UserWithPermissionsAsync("Taxonomist", "taxonomy.manage");
        await taxonomist.Client.GetAsync("/api/v1/admin/fields", Ct).OkJsonAsync();
        var other = await api.UserWithPermissionsAsync("Path Keeper", "paths.manage", "admin.access");
        await other.Client.GetAsync("/api/v1/admin/fields", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    [Fact]
    public async Task The_list_has_every_field_with_its_topics_the_file_flags_and_the_styles()
    {
        var admin = await api.SuperAdminAsync();
        var taxonomy = await admin.Client.GetAsync("/api/v1/admin/fields", Ct).OkJsonAsync();

        taxonomy.Select(p => p.Key).Should().BeEquivalentTo("fields", "icons", "colors");
        taxonomy["icons"]!.AsArray().Select(i => i!.GetValue<string>()).Should().Contain(["cpu", "shield-check", "stethoscope"]).And.BeInAscendingOrder();
        taxonomy["colors"]!.AsArray().Select(i => i!.GetValue<string>()).Should().Contain(["primary", "callout-danger-accent"]);

        var fields = taxonomy["fields"]!.AsArray();
        var security = fields.Single(f => f!["slug"]!.GetValue<string>() == "security")!.AsObject();
        security.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "slug", "nameAr", "nameEn", "icon", "color", "sortOrder", "isSensitive", "requiresSources", "isEnabled", "inTaxonomyFile",
            "customizedAt", "articleCount", "topics");
        security["inTaxonomyFile"]!.GetValue<bool>().Should().BeTrue();
        var topic = security["topics"]!.AsArray().Single(t => t!["slug"]!.GetValue<string>() == "owasp-top-10")!.AsObject();
        topic.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "fieldId", "slug", "nameAr", "nameEn", "sortOrder", "isEnabled", "inTaxonomyFile", "customizedAt", "articleCount");
        (topic["isEnabled"]!.GetValue<bool>(), topic["inTaxonomyFile"]!.GetValue<bool>()).Should().Be((true, true));

        // Disabled fields are listed too, in display order.
        fields.Select(f => f!["slug"]!.GetValue<string>()).Should().Contain("medicine");
        fields.Select(f => f!["sortOrder"]!.GetValue<int>()).Should().BeInAscendingOrder();
    }

    [Fact]
    public async Task A_new_field_goes_last_is_customized_and_shows_in_the_field_list_while_enabled()
    {
        var admin = await api.SuperAdminAsync();
        var slug = Slug("robo");
        var created = await CreateFieldAsync(admin.Client, slug);

        created["slug"]!.GetValue<string>().Should().Be(slug);
        (created["nameAr"]!.GetValue<string>(), created["nameEn"]!.GetValue<string>()).Should().Be(("الروبوتات", "Robotics"));
        created["customizedAt"].Should().NotBeNull("console fields are never touched by the seeder");
        created["inTaxonomyFile"]!.GetValue<bool>().Should().BeFalse();
        created["articleCount"]!.GetValue<int>().Should().Be(0);
        created["topics"]!.AsArray().Should().BeEmpty();
        var maxOrder = (await admin.Client.GetAsync("/api/v1/admin/fields", Ct).OkJsonAsync())["fields"]!.AsArray()
            .Max(f => f!["sortOrder"]!.GetValue<int>());
        created["sortOrder"]!.GetValue<int>().Should().Be(maxOrder, "a new field goes last");

        var publicFields = await api.GuestClient().GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct);
        publicFields!.Select(f => f!["slug"]!.GetValue<string>()).Should().Contain(slug, "creating drops the cached field list");
        (await AuditCountAsync(AuditActions.FieldCreated, created["id"]!.GetValue<Guid>())).Should().Be(1);

        await admin.Client.PostAsJsonAsync("/api/v1/admin/fields", NewField(slug), Ct).ProblemAsync(HttpStatusCode.Conflict, "field.slug_taken");
        await admin.Client.PostAsJsonAsync("/api/v1/admin/fields", NewField("security"), Ct).ProblemAsync(HttpStatusCode.Conflict, "field.slug_taken");

        var hidden = await CreateFieldAsync(admin.Client, Slug("draft"), isEnabled: false);
        (await api.GuestClient().GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!.Select(f => f!["slug"]!.GetValue<string>())
            .Should().NotContain(hidden["slug"]!.GetValue<string>(), "a field created disabled stays out of every list");
    }

    [Fact]
    public async Task A_new_field_is_validated()
    {
        var admin = await api.SuperAdminAsync();
        var invalid = await admin.Client.PostAsJsonAsync("/api/v1/admin/fields",
                new { slug = "Not A Slug", nameAr = " ", nameEn = new string('x', 101), icon = "rocket", color = "pink", isEnabled = true }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        var errors = invalid["errors"]!.AsObject();
        errors["slug"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.slug");
        errors["nameAr"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Contain("validation.required");
        errors["nameEn"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.max_length");
        errors["icon"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("field.icon_invalid");
        errors["color"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("field.color_invalid");

        var tooShort = await admin.Client.PostAsJsonAsync("/api/v1/admin/fields", NewField("x"), Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        tooShort["errors"]!["slug"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.slug");
    }

    [Fact]
    public async Task Editing_a_field_renames_disables_and_audits_what_changed_and_a_repeat_writes_nothing()
    {
        var admin = await api.SuperAdminAsync();
        var created = await CreateFieldAsync(admin.Client, Slug("edit"));
        var id = created["id"]!.GetValue<Guid>();
        var slug = created["slug"]!.GetValue<string>();

        var edit = new { nameAr = "  الآلات  ", nameEn = "Machines", icon = "cog", color = "success", isSensitive = true, requiresSources = true, isEnabled = false };
        var edited = await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{id}", edit, Ct).OkJsonAsync();
        (edited["nameAr"]!.GetValue<string>(), edited["nameEn"]!.GetValue<string>(), edited["icon"]!.GetValue<string>())
            .Should().Be(("الآلات", "Machines", "cog"), "names are trimmed");
        (edited["isSensitive"]!.GetValue<bool>(), edited["isEnabled"]!.GetValue<bool>()).Should().Be((true, false));
        edited["slug"]!.GetValue<string>().Should().Be(slug, "the slug never changes");

        var entry = await api.InDbAsync(db => db.AuditLogs.AsNoTracking().SingleAsync(a => a.Action == AuditActions.FieldUpdated && a.TargetId == id, Ct));
        (entry.TargetType, entry.Details).Should().Be(("field", "nameAr, nameEn, icon, color, isSensitive=true, isEnabled=false"));
        entry.ActorId.Should().Be(admin.Id);

        (await api.GuestClient().GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!.Select(f => f!["slug"]!.GetValue<string>())
            .Should().NotContain(slug, "a disabled field leaves the lists");
        await api.GuestClient().GetAsync($"/api/v1/fields/{slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "field.not_found");

        // The same values again: nothing is written.
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{id}", edit, Ct).OkJsonAsync();
        (await AuditCountAsync(AuditActions.FieldUpdated, id)).Should().Be(1);

        await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{Guid.NewGuid()}", edit, Ct).ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
        (await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{id}", edit with { nameEn = " " }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!["nameEn"]!.AsArray()
            .Select(e => e!.GetValue<string>()).Should().Contain("validation.required");
    }

    [Fact]
    public async Task A_field_keeps_an_icon_off_the_list_but_a_new_one_must_come_from_it()
    {
        var admin = await api.SuperAdminAsync();
        var created = await CreateFieldAsync(admin.Client, Slug("icon"));
        var id = created["id"]!.GetValue<Guid>();
        // As the taxonomy file may give a field an icon the console doesn't offer.
        await api.InDbAsync(db => db.Fields.Where(f => f.Id == id).ExecuteUpdateAsync(s => s.SetProperty(f => f.Icon, "rocket"), Ct));

        var kept = await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{id}",
            new { nameAr = "الروبوتات", nameEn = "Robots", icon = "rocket", color = "accent", isSensitive = false, requiresSources = true, isEnabled = true }, Ct)
            .OkJsonAsync();
        (kept["icon"]!.GetValue<string>(), kept["nameEn"]!.GetValue<string>()).Should().Be(("rocket", "Robots"));

        var problem = await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{id}",
                new { nameAr = "الروبوتات", nameEn = "Robots", icon = "rocket-2", color = "neon", isSensitive = false, requiresSources = true, isEnabled = true }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        problem["errors"]!["icon"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("field.icon_invalid");
        problem["errors"]!["color"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("field.color_invalid");
    }

    [Fact]
    public async Task Fields_are_reordered_with_the_whole_list_and_a_partial_list_is_refused()
    {
        var admin = await api.SuperAdminAsync();
        var first = await CreateFieldAsync(admin.Client, Slug("ord"));
        var second = await CreateFieldAsync(admin.Client, Slug("ord"));
        var ids = (await admin.Client.GetAsync("/api/v1/admin/fields", Ct).OkJsonAsync())["fields"]!.AsArray()
            .Select(f => f!["id"]!.GetValue<Guid>()).ToList();
        ids[^2..].Should().Equal(first["id"]!.GetValue<Guid>(), second["id"]!.GetValue<Guid>());

        // The same order: nothing moves, nothing is written.
        var before = await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.FieldsReordered, Ct));
        await admin.Client.PutAsJsonAsync("/api/v1/admin/fields/order", new { ids }, Ct).NoContentAsync();
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.FieldsReordered, Ct))).Should().Be(before);

        // Swap the last two (the rest stays as it is).
        List<Guid> swapped = [.. ids[..^2], ids[^1], ids[^2]];
        await admin.Client.PutAsJsonAsync("/api/v1/admin/fields/order", new { ids = swapped }, Ct).NoContentAsync();
        (await admin.Client.GetAsync("/api/v1/admin/fields", Ct).OkJsonAsync())["fields"]!.AsArray()
            .Select(f => f!["id"]!.GetValue<Guid>()).Should().Equal(swapped);
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.FieldsReordered, Ct))).Should().Be(before + 1);

        await admin.Client.PutAsJsonAsync("/api/v1/admin/fields/order", new { ids = swapped.Skip(1) }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "admin.order_invalid");
        await admin.Client.PutAsJsonAsync("/api/v1/admin/fields/order", new { ids = swapped.Append(swapped[0]) }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "admin.order_invalid");
        await admin.Client.PutAsJsonAsync("/api/v1/admin/fields/order", new { ids = swapped.Skip(1).Append(Guid.NewGuid()) }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "admin.order_invalid");
    }

    [Fact]
    public async Task Topics_are_added_renamed_reordered_and_a_disabled_one_leaves_the_lists_but_stays_on_its_articles()
    {
        var admin = await api.SuperAdminAsync();
        var field = await CreateFieldAsync(admin.Client, Slug("topics"));
        var fieldId = field["id"]!.GetValue<Guid>();
        var fieldSlug = field["slug"]!.GetValue<string>();

        var drones = await CreateTopicAsync(admin.Client, fieldId, "drones");
        var arms = await CreateTopicAsync(admin.Client, fieldId, "arms", "Robot Arms");
        drones["customizedAt"].Should().NotBeNull();
        (drones["sortOrder"]!.GetValue<int>(), arms["sortOrder"]!.GetValue<int>()).Should().Be((1, 2), "a new topic goes last");
        (await AuditCountAsync(AuditActions.TopicCreated, drones["id"]!.GetValue<Guid>())).Should().Be(1);

        await admin.Client.PostAsJsonAsync("/api/v1/admin/topics", new { fieldId, slug = "drones", nameAr = "x", nameEn = "x", isEnabled = true }, Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "topic.slug_taken");
        await admin.Client.PostAsJsonAsync("/api/v1/admin/topics", new { fieldId = Guid.NewGuid(), slug = "drones", nameAr = "x", nameEn = "x", isEnabled = true }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
        (await admin.Client.PostAsJsonAsync("/api/v1/admin/topics", new { fieldId, slug = "-bad-", nameAr = "x", nameEn = "", isEnabled = true }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!.AsObject().Select(e => e.Key).Should().BeEquivalentTo("slug", "nameEn");

        // Reorder.
        var droneId = drones["id"]!.GetValue<Guid>();
        var armId = arms["id"]!.GetValue<Guid>();
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{fieldId}/topics/order", new { ids = new[] { armId, droneId } }, Ct).NoContentAsync();
        var topics = await api.GuestClient().GetFromJsonAsync<JsonArray>($"/api/v1/fields/{fieldSlug}/topics", Ct);
        topics!.Select(t => t!["slug"]!.GetValue<string>()).Should().Equal("arms", "drones");
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{fieldId}/topics/order", new { ids = new[] { armId } }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "admin.order_invalid");
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{Guid.NewGuid()}/topics/order", new { ids = new[] { armId } }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "field.not_found");

        // An article with the topic, before it is disabled.
        var writer = await api.UserAsync("Topic Writer");
        var document = ArticleTestKit.Document(fieldId, $"Drones {Guid.NewGuid():N}");
        document["topicId"] = droneId;
        var draft = await writer.Client.CreateDraftAsync(document);

        // Rename and disable.
        var disabled = await admin.Client.PutAsJsonAsync($"/api/v1/admin/topics/{droneId}", new { nameAr = "مسيّرات", nameEn = "UAVs", isEnabled = false }, Ct)
            .OkJsonAsync();
        (disabled["nameEn"]!.GetValue<string>(), disabled["isEnabled"]!.GetValue<bool>()).Should().Be(("UAVs", false));
        (await api.InDbAsync(db => db.AuditLogs.AsNoTracking().SingleAsync(a => a.Action == AuditActions.TopicUpdated && a.TargetId == droneId, Ct)))
            .Details.Should().Be("nameAr, nameEn, isEnabled=false");
        await admin.Client.PutAsJsonAsync($"/api/v1/admin/topics/{Guid.NewGuid()}", new { nameAr = "x", nameEn = "x", isEnabled = true }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");

        (await api.GuestClient().GetFromJsonAsync<JsonArray>($"/api/v1/fields/{fieldSlug}/topics", Ct))!
            .Select(t => t!["slug"]!.GetValue<string>()).Should().Equal("arms");
        var page = await api.GuestClient().GetAsync($"/api/v1/fields/{fieldSlug}", Ct).OkJsonAsync();
        page["topics"]!.AsArray().Select(t => t!["slug"]!.GetValue<string>()).Should().Equal("arms");
        await api.GuestClient().GetAsync($"/api/v1/fields/{fieldSlug}/articles?topic=drones", Ct).ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");
        (await api.GuestClient().GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Single(f => f!["slug"]!.GetValue<string>() == fieldSlug)!["topicCount"]!.GetValue<int>().Should().Be(1);
        await writer.Client.PutEmptyAsync($"/api/v1/me/interests/topics/{droneId}").ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");

        // It can't be picked any more, but the article that has it keeps it.
        await writer.Client.PostAsJsonAsync("/api/v1/articles", document, Ct).ProblemAsync(HttpStatusCode.BadRequest, "topic.not_in_field");
        await writer.Client.SaveDraftAsync(draft["id"]!.GetValue<Guid>(), draft["version"]!.GetValue<int>(), document).OkJsonAsync();
    }

    [Fact]
    public async Task The_seeder_leaves_customized_rows_alone_and_keeps_following_the_file_for_the_others()
    {
        var admin = await api.SuperAdminAsync();
        var consoleField = await CreateFieldAsync(admin.Client, Slug("own"));
        var engineering = await FieldRowAsync(admin.Client, "engineering");
        var engineeringId = engineering["id"]!.GetValue<Guid>();
        var testing = await FieldRowAsync(admin.Client, "testing");
        var e2e = testing["topics"]!.AsArray().Single(t => t!["slug"]!.GetValue<string>() == "e2e-testing")!.AsObject();
        var e2eId = e2e["id"]!.GetValue<Guid>();

        try
        {
            // An admin renames a seeded field and a seeded topic; another seeded field drifts without the console.
            await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{engineeringId}", new
            {
                nameAr = "الهندسة", nameEn = "Engineering (admin)", icon = "cog", color = "callout-warning-accent", isSensitive = false,
                requiresSources = true, isEnabled = false,
            }, Ct).OkJsonAsync();
            await admin.Client.PutAsJsonAsync($"/api/v1/admin/topics/{e2eId}", new { nameAr = "E2E Testing", nameEn = "End-to-end (admin)", isEnabled = true }, Ct)
                .OkJsonAsync();
            await api.InDbAsync(db => db.Fields.Where(f => f.Slug == "public-health")
                .ExecuteUpdateAsync(s => s.SetProperty(f => f.NameEn, "Drifted"), Ct));

            await RunTaxonomySeederAsync();

            var fields = await api.InDbAsync(db => db.Fields.AsNoTracking().Include(f => f.Topics).ToListAsync(Ct));
            fields.Single(f => f.Slug == "engineering").NameEn.Should().Be("Engineering (admin)", "the admin's change wins over the file");
            fields.Single(f => f.Slug == "testing").Topics.Single(t => t.Slug == "e2e-testing").NameEn.Should().Be("End-to-end (admin)");
            fields.Single(f => f.Slug == "public-health").NameEn.Should().Be("Public Health", "rows nobody edited keep following the file");
            var own = fields.Single(f => f.Slug == consoleField["slug"]!.GetValue<string>());
            own.IsEnabled.Should().BeTrue("a console field missing from the file is not disabled");
        }
        finally
        {
            await admin.Client.PutAsJsonAsync($"/api/v1/admin/fields/{engineeringId}", new
            {
                nameAr = "الهندسة", nameEn = "Engineering", icon = "cog", color = "callout-warning-accent", isSensitive = false,
                requiresSources = true, isEnabled = false,
            }, Ct);
            await admin.Client.PutAsJsonAsync($"/api/v1/admin/topics/{e2eId}", new { nameAr = "E2E Testing", nameEn = "E2E Testing", isEnabled = true }, Ct);
        }
    }

    private async Task RunTaxonomySeederAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var seeder = scope.ServiceProvider.GetServices<ISeeder>().Single(s => s.Name == "taxonomy");
        (await seeder.SeedAsync(Ct)).Should().BeTrue();
    }
}
