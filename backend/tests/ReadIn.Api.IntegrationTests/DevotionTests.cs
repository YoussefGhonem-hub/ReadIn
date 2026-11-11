using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Devotions;
using ReadIn.Infrastructure.Content;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F38 private devotions: the account's own du'as, for holders of <c>devotions.access</c> only (the SuperAdmin), oldest
/// first, edits that replace both fields, ownership (another account's du'a is not found), the text rules, the 200 limit
/// (also under creates at the same moment) and account deletion.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class DevotionTests(ApiFactory api)
{
    private const string Duas = "/api/v1/me/duas";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Only_holders_of_devotions_access_reach_the_duas()
    {
        var owner = await api.SuperAdminAsync("Devotions Owner");
        var dua = await CreatedAsync(owner.Client, null, "The owner's du'a");

        var member = await api.UserAsync("Devotions Member");
        await member.Client.GetAsync(Duas, Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await CreateAsync(member.Client, null, "A du'a").ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await member.Client.PatchAsJsonAsync(DuaUrl(dua), new { text = "Edited" }, Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await member.Client.DeleteAsync(DuaUrl(dua), Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        // The permission is checked before the body: an invalid one tells a member nothing either.
        await CreateAsync(member.Client, null, null).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");

        var guest = api.GuestClient();
        (await guest.GetAsync(Duas, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await guest.PostAsJsonAsync(Duas, new { text = "A du'a" }, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        // The permission opens it, not the role name: a staff role holding only devotions.access works.
        var devotee = await api.UserWithPermissionsAsync("Devotee", Permissions.Devotions.Access);
        (await devotee.Client.GetAsync(Duas, Ct).OkArrayAsync()).Should().BeEmpty();

        (await owner.Client.GetAsync(Duas, Ct).OkArrayAsync()).Select(Id).Should().Equal(Id(dua));
    }

    [Fact]
    public async Task The_superadmin_adds_edits_and_deletes_own_duas()
    {
        var admin = await api.SuperAdminAsync("Devotions Keeper");
        (await admin.Client.GetAsync(Duas, Ct).OkArrayAsync()).Should().BeEmpty();

        var response = await CreateAsync(admin.Client, "  دعاء السفر  ",
            "  اللهم إنا نسألك في سفرنا هذا البر والتقوى\r\nومن العمل ما ترضى\n\n  سبحان الذي سخر لنا هذا  \n ");
        var first = await CreatedBodyAsync(response);
        response.Headers.Location!.ToString().Should().Be($"{Duas}/{Id(first)}");
        first["title"]!.GetValue<string>().Should().Be("دعاء السفر");
        first["text"]!.GetValue<string>().Should().Be(
            "اللهم إنا نسألك في سفرنا هذا البر والتقوى\nومن العمل ما ترضى\n\n  سبحان الذي سخر لنا هذا",
            "trimmed at both ends; inner spaces, line breaks and the empty line are kept");
        At(first, "updatedAt").Should().Be(At(first, "createdAt"), "updatedAt is createdAt until the first edit");

        var second = await CreatedAsync(admin.Client, null, "Second\a du'a\twith\0 control\f characters");
        second["title"].Should().BeNull();
        second["text"]!.GetValue<string>().Should().Be("Second du'awith control characters", "control characters other than line breaks go");
        var third = await CreatedAsync(admin.Client, " \n ", "Third");
        third["title"].Should().BeNull("an empty title is null");

        var listed = await admin.Client.GetAsync(Duas, Ct);
        listed.Headers.CacheControl!.NoStore.Should().BeTrue("du'as are private and never cached");
        (await Task.FromResult(listed).OkArrayAsync()).Select(Id).Should().Equal(Id(first), Id(second), Id(third));

        // PATCH replaces both: a missing title clears it.
        var edited = await admin.Client.PatchAsJsonAsync(DuaUrl(first), new { text = "  Edited\nin two lines  " }, Ct).OkJsonAsync();
        edited["title"].Should().BeNull("a missing title clears it");
        edited["text"]!.GetValue<string>().Should().Be("Edited\nin two lines");
        At(edited, "createdAt").Should().Be(At(first, "createdAt"));
        At(edited, "updatedAt").Should().BeOnOrAfter(At(first, "createdAt"));
        var retitled = await admin.Client.PatchAsJsonAsync(DuaUrl(third), new { title = " Line one\r\nline two ", text = "Third" }, Ct).OkJsonAsync();
        retitled["title"]!.GetValue<string>().Should().Be("Line one line two", "a title is one line: its line breaks become spaces");
        (await admin.Client.PatchAsJsonAsync(DuaUrl(third), new { title = "", text = "Third" }, Ct).OkJsonAsync())["title"]
            .Should().BeNull("an empty title clears it");

        await admin.Client.DeleteAsync(DuaUrl(second), Ct).NoContentAsync();
        await admin.Client.DeleteAsync(DuaUrl(second), Ct).ProblemAsync(HttpStatusCode.NotFound, "dua.not_found");
        await admin.Client.PatchAsJsonAsync(DuaUrl(second), new { text = "Back?" }, Ct).ProblemAsync(HttpStatusCode.NotFound, "dua.not_found");

        var left = await admin.Client.GetAsync(Duas, Ct).OkArrayAsync();
        left.Select(Id).Should().Equal(Id(first), Id(third));
        left[0]!["text"]!.GetValue<string>().Should().Be("Edited\nin two lines");
        left[1]!["title"].Should().BeNull();
    }

    [Fact]
    public async Task Duas_are_listed_oldest_first()
    {
        var admin = await api.SuperAdminAsync("Devotions Reader");
        var now = DateTime.UtcNow;
        await api.InDbAsync(async db =>
        {
            db.PersonalDuas.Add(new PersonalDua(admin.Id, null, "Newest seeded", 1, now.AddMinutes(-1)));
            db.PersonalDuas.Add(new PersonalDua(admin.Id, null, "Oldest", 1, now.AddDays(-2)));
            db.PersonalDuas.Add(new PersonalDua(admin.Id, "With a title", "Middle", 1, now.AddDays(-1)));
            await db.SaveChangesAsync(Ct);
        });
        await CreatedAsync(admin.Client, null, "Added now");

        (await admin.Client.GetAsync(Duas, Ct).OkArrayAsync()).Select(d => d!["text"]!.GetValue<string>())
            .Should().Equal("Oldest", "Middle", "Newest seeded", "Added now");
    }

    [Fact]
    public async Task Another_accounts_dua_is_not_found()
    {
        var owner = await api.SuperAdminAsync("Dua Owner");
        var other = await api.SuperAdminAsync("Other SuperAdmin");
        var dua = await CreatedAsync(owner.Client, "Mine", "Only mine");

        await other.Client.PatchAsJsonAsync(DuaUrl(dua), new { title = "Taken", text = "Taken" }, Ct).ProblemAsync(HttpStatusCode.NotFound, "dua.not_found");
        await other.Client.DeleteAsync(DuaUrl(dua), Ct).ProblemAsync(HttpStatusCode.NotFound, "dua.not_found");
        (await other.Client.GetAsync(Duas, Ct).OkArrayAsync()).Should().BeEmpty("only the account that wrote a du'a sees it");
        await other.Client.PatchAsJsonAsync($"{Duas}/{Guid.NewGuid()}", new { text = "Nothing" }, Ct).ProblemAsync(HttpStatusCode.NotFound, "dua.not_found");
        await other.Client.DeleteAsync($"{Duas}/{Guid.NewGuid()}", Ct).ProblemAsync(HttpStatusCode.NotFound, "dua.not_found");

        var mine = (await owner.Client.GetAsync(Duas, Ct).OkArrayAsync()).Should().ContainSingle().Which!;
        mine["title"]!.GetValue<string>().Should().Be("Mine");
        mine["text"]!.GetValue<string>().Should().Be("Only mine", "the other account changed nothing");
    }

    [Fact]
    public async Task Text_and_title_are_checked_after_cleaning()
    {
        var admin = await api.SuperAdminAsync("Dua Validator");

        // Missing, empty, only whitespace, only control characters.
        foreach (var text in new string?[] { null, "", " \n\t ", "\a\0\f" })
            Codes(await CreateAsync(admin.Client, null, text).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "text")
                .Should().Equal("validation.required");
        Codes(await CreateAsync(admin.Client, null, new string('د', PersonalDua.MaxTextLength + 1))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "text").Should().Equal("validation.length");
        Codes(await CreateAsync(admin.Client, new string('t', PersonalDua.MaxTitleLength + 1), "A du'a")
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "title").Should().Equal("validation.length");
        var both = await CreateAsync(admin.Client, new string('t', PersonalDua.MaxTitleLength + 1), " ")
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        both["errors"]!.AsObject().Select(e => e.Key).Should().BeEquivalentTo("title", "text");

        // The limits count what is left after cleaning.
        var longest = await CreatedAsync(admin.Client, $"  {new string('t', PersonalDua.MaxTitleLength)}\n",
            $"\n  {new string('د', PersonalDua.MaxTextLength)}  \n");
        longest["title"]!.GetValue<string>().Should().HaveLength(PersonalDua.MaxTitleLength);
        longest["text"]!.GetValue<string>().Should().HaveLength(PersonalDua.MaxTextLength);

        Codes(await admin.Client.PatchAsJsonAsync(DuaUrl(longest), new { title = "Kept" }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "text").Should().Equal("validation.required");
        Codes(await admin.Client.PatchAsJsonAsync(DuaUrl(longest), new { title = new string('t', PersonalDua.MaxTitleLength + 1), text = "Fine" }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"), "title").Should().Equal("validation.length");
        (await admin.Client.GetAsync(Duas, Ct).OkArrayAsync()).Should().ContainSingle()
            .Which!["text"]!.GetValue<string>().Should().HaveLength(PersonalDua.MaxTextLength, "a refused edit changes nothing");
    }

    [Fact]
    public async Task An_account_has_at_most_200_duas()
    {
        var admin = await api.SuperAdminAsync("Dua Collector");
        await SeedAsync(admin.Id, PersonalDua.MaxPerUser - 1);

        var last = await CreatedAsync(admin.Client, null, "The 200th");
        await CreateAsync(admin.Client, null, "The 201st").ProblemAsync(HttpStatusCode.Conflict, "dua.limit");
        var list = await admin.Client.GetAsync(Duas, Ct).OkArrayAsync();
        list.Should().HaveCount(PersonalDua.MaxPerUser);
        Id(list[^1]!).Should().Be(Id(last), "a new du'a is added last");

        // Deleting one makes room again.
        await admin.Client.DeleteAsync(DuaUrl(list[0]!), Ct).NoContentAsync();
        await CreatedAsync(admin.Client, null, "In the freed place");
    }

    [Fact]
    public async Task Creates_at_the_same_moment_never_pass_the_limit()
    {
        const int seeded = PersonalDua.MaxPerUser - 5;
        const int creates = 12;
        var admin = await api.SuperAdminAsync("Dua Racer");
        await SeedAsync(admin.Id, seeded);

        // All the requests start together, each on its own thread.
        using var start = new SemaphoreSlim(0);
        var racing = Enumerable.Range(0, creates).Select(i => Task.Run(async () =>
        {
            await start.WaitAsync(Ct);
            return await CreateAsync(admin.Client, null, $"Racing {i}");
        }, Ct)).ToList();
        start.Release(creates);
        var responses = await Task.WhenAll(racing);

        responses.Count(r => r.StatusCode == HttpStatusCode.Created).Should().Be(PersonalDua.MaxPerUser - seeded);
        foreach (var refused in responses.Where(r => r.StatusCode != HttpStatusCode.Created))
            await Task.FromResult(refused).ProblemAsync(HttpStatusCode.Conflict, "dua.limit");
        (await api.InDbAsync(db => db.PersonalDuas.CountAsync(d => d.UserId == admin.Id, Ct))).Should().Be(PersonalDua.MaxPerUser);
    }

    [Fact]
    public async Task Deleting_the_account_deletes_its_duas()
    {
        var admin = await api.SuperAdminAsync("Leaving SuperAdmin");
        await CreatedAsync(admin.Client, "Gone with the account", "Deleted with it (SPEC §9.6)");

        (await admin.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me")
        {
            Content = JsonContent.Create(new { password = ApiFactory.TestPassword }),
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await api.InDbAsync(db => db.PersonalDuas.CountAsync(d => d.UserId == admin.Id, Ct))).Should().Be(0);
    }

    [Fact]
    public async Task The_openapi_document_describes_the_dua_endpoints()
    {
        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();

        document["paths"]!.AsObject().Select(p => p.Key).Should().Contain(["/api/v1/me/duas", "/api/v1/me/duas/{id}"]);
        document["components"]!["schemas"]!["PersonalDuaDto"]!["properties"]!.AsObject().Select(p => p.Key)
            .Should().BeEquivalentTo("id", "title", "text", "repeat", "createdAt", "updatedAt");
    }

    [Fact]
    public async Task A_dua_says_how_many_times_it_is_said_once_by_default()
    {
        var admin = await api.SuperAdminAsync("Devotions Counter");

        (await CreatedAsync(admin.Client, null, "Once"))["repeat"]!.GetValue<int>().Should().Be(1);
        var seven = await CreatedBodyAsync(await admin.Client.PostAsJsonAsync(Duas, new { text = "Seven times", repeat = 7 }, Ct));
        seven["repeat"]!.GetValue<int>().Should().Be(7);

        (await admin.Client.PatchAsJsonAsync(DuaUrl(seven), new { text = "Three times", repeat = 3 }, Ct).OkJsonAsync())["repeat"]!
            .GetValue<int>().Should().Be(3);
        (await admin.Client.PatchAsJsonAsync(DuaUrl(seven), new { text = "Back to once" }, Ct).OkJsonAsync())["repeat"]!
            .GetValue<int>().Should().Be(1, "PATCH replaces every field: a missing repeat is 1");

        foreach (var repeat in new[] { 0, -1, PersonalDua.MaxRepeat + 1 })
        {
            var problem = await admin.Client.PostAsJsonAsync(Duas, new { text = "Bad count", repeat }, Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            Codes(problem, "repeat").Should().Equal("validation.range");
        }
        (await admin.Client.GetAsync(Duas, Ct).OkArrayAsync()).Select(d => d!["repeat"]!.GetValue<int>()).Should().Equal(1, 1);
    }

    [Fact]
    public async Task The_starter_duas_land_once_in_the_files_order_after_the_accounts_own()
    {
        var admin = await api.SuperAdminAsync("Devotions Starter");
        var own = await CreatedAsync(admin.Client, "Mine", "Already mine");
        await api.InScopeAsync(async services =>
        {
            // The suite's content root is tests/fixtures/content: three placeholder du'as.
            var seeder = new StarterDuasSeeder(
                services.GetRequiredService<AppDbContext>(), services.GetRequiredService<ContentRepository>(), TimeProvider.System);
            await seeder.SeedForAsync([admin.Id], Ct);
            await seeder.SeedForAsync([admin.Id], Ct); // a second run adds nothing
        });

        var list = await admin.Client.GetAsync(Duas, Ct).OkArrayAsync();
        list.Select(d => (d!["title"]?.GetValue<string>(), d!["text"]!.GetValue<string>(), d["repeat"]!.GetValue<int>()))
            .Should().Equal(
                ("Mine", "Already mine", 1),
                ("Starter one", "First starter du'a\nin two lines", 1),
                (null, "Second starter du'a", 3),
                ("Starter three", "Third starter du'a", 1));
        list.Select(Id).First().Should().Be(Id(own));

        var member = await api.UserAsync("Devotions Bystander");
        (await api.InDbAsync(db => db.PersonalDuas.CountAsync(d => d.UserId == member.Id, Ct))).Should().Be(0);
    }

    [Fact]
    public void The_real_starter_list_follows_the_dua_rules()
    {
        // content/devotions/starter-duas.json at the repository's root, the file production seeds.
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null && !File.Exists(Path.Combine(directory.FullName, "content", "devotions", "starter-duas.json")))
            directory = directory.Parent;
        directory.Should().NotBeNull("the repository's content folder has the starter list");

        var file = JsonNode.Parse(File.ReadAllText(Path.Combine(directory!.FullName, "content", "devotions", "starter-duas.json")))!;
        var duas = file["duas"]!.AsArray();
        duas.Should().HaveCountGreaterThan(6).And.HaveCountLessThanOrEqualTo(PersonalDua.MaxPerUser);
        foreach (var dua in duas)
        {
            var text = PersonalDuaText.Text(dua!["text"]!.GetValue<string>());
            text.Length.Should().BeInRange(1, PersonalDua.MaxTextLength);
            (PersonalDuaText.Title(dua["title"]?.GetValue<string>())?.Length ?? 0).Should().BeLessThanOrEqualTo(PersonalDua.MaxTitleLength);
            (dua["repeat"]?.GetValue<int>() ?? 1).Should().BeInRange(1, PersonalDua.MaxRepeat);
        }
        duas.Select(d => PersonalDuaText.Text(d!["text"]!.GetValue<string>())).Should().OnlyHaveUniqueItems("a repeat would be skipped");
    }

    // ── Helpers ─────────────────────────────────────────────────

    private static Task<HttpResponseMessage> CreateAsync(HttpClient client, string? title, string? text) =>
        client.PostAsJsonAsync(Duas, new { title, text }, Ct);

    private static async Task<JsonObject> CreatedAsync(HttpClient client, string? title, string text) =>
        await CreatedBodyAsync(await CreateAsync(client, title, text));

    private static async Task<JsonObject> CreatedBodyAsync(HttpResponseMessage response)
    {
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    /// <summary>Du'as written straight to the database, a second apart and older than anything the API adds now.</summary>
    private Task SeedAsync(Guid userId, int count) => api.InDbAsync(async db =>
    {
        var start = DateTime.UtcNow.AddDays(-1);
        db.PersonalDuas.AddRange(Enumerable.Range(1, count).Select(i => new PersonalDua(userId, null, $"Seeded {i}", 1, start.AddSeconds(i))));
        await db.SaveChangesAsync(Ct);
    });

    private static string DuaUrl(JsonNode dua) => $"{Duas}/{Id(dua)}";

    private static Guid Id(JsonNode? dua) => dua!["id"]!.GetValue<Guid>();

    private static DateTime At(JsonNode dua, string property) => dua[property]!.GetValue<DateTime>();

    private static IEnumerable<string> Codes(JsonObject problem, string key) =>
        problem["errors"]![key]!.AsArray().Select(c => c!.GetValue<string>());
}
