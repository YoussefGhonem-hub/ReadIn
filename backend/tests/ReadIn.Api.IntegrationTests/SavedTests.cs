using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Engagement;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>F13 Saved articles and collections end to end.</summary>
[Collection(ApiCollection.Name)]
public sealed class SavedTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Guests_must_sign_in_to_save()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();

        await api.GuestClient().PutEmptyAsync($"/api/v1/me/saved/{articleId}").ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
        await api.GuestClient().GetAsync("/api/v1/me/saved", Ct).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
        await api.GuestClient().GetAsync("/api/v1/me/collections", Ct).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
    }

    [Fact]
    public async Task Saving_is_idempotent_and_counted()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var first = await api.UserAsync();
        var second = await api.UserAsync();

        var saved = await first.Client.PutEmptyAsync($"/api/v1/me/saved/{articleId}").OkJsonAsync();
        saved["isSaved"]!.GetValue<bool>().Should().BeTrue();
        saved["saveCount"]!.GetValue<int>().Should().Be(1);
        (await first.Client.PutEmptyAsync($"/api/v1/me/saved/{articleId}").OkJsonAsync())["saveCount"]!.GetValue<int>().Should().Be(1);
        (await second.Client.PutEmptyAsync($"/api/v1/me/saved/{articleId}").OkJsonAsync())["saveCount"]!.GetValue<int>().Should().Be(2);

        var list = await first.Client.GetAsync("/api/v1/me/saved", Ct).OkJsonAsync();
        var item = list["items"]!.AsArray().Single()!;
        item["savedAt"]!.GetValue<string>().Should().EndWith("Z");
        item["collectionIds"]!.AsArray().Should().BeEmpty();
        item["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId);
        item["article"]!["isSaved"]!.GetValue<bool>().Should().BeTrue();
        item["article"]!["saveCount"]!.GetValue<int>().Should().Be(2);

        var unsaved = await first.Client.DeleteAsync($"/api/v1/me/saved/{articleId}", Ct).OkJsonAsync();
        unsaved["isSaved"]!.GetValue<bool>().Should().BeFalse();
        unsaved["saveCount"]!.GetValue<int>().Should().Be(1);
        (await first.Client.DeleteAsync($"/api/v1/me/saved/{articleId}", Ct).OkJsonAsync())["isSaved"]!.GetValue<bool>().Should().BeFalse();
        (await first.Client.GetAsync("/api/v1/me/saved", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty();

        await first.Client.PutEmptyAsync($"/api/v1/me/saved/{Guid.NewGuid()}").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        api.Realtime.CountersFor(articleId)[^1].SaveCount.Should().Be(1);
    }

    [Fact]
    public async Task The_saved_list_filters_by_field_title_and_collection_newest_first()
    {
        var author = await api.UserAsync();
        var token = Guid.NewGuid().ToString("N")[..8];
        var (dotnet, _) = await author.Client.PublishAsync($"Caching in ASP.NET Core {token}");
        var (arabic, _) = await author.Client.PublishAsync($"مُقَدِّمة عن الـ Caching {token}", field: "frontend", language: "ar-EG");
        var (other, _) = await author.Client.PublishAsync($"Unrelated {token}", field: "frontend");
        var reader = await api.UserAsync();
        foreach (var id in new[] { dotnet, arabic, other }) await reader.Client.PutEmptyAsync($"/api/v1/me/saved/{id}").OkJsonAsync();

        async Task<List<Guid>> SavedAsync(string query) =>
            [.. (await reader.Client.GetAsync($"/api/v1/me/saved{query}", Ct).OkJsonAsync())["items"]!.AsArray()
                .Select(i => i!["article"]!["id"]!.GetValue<Guid>())];

        (await SavedAsync("")).Should().Equal(other, arabic, dotnet);
        (await SavedAsync("?field=frontend")).Should().Equal(other, arabic);
        (await SavedAsync("?q=caching")).Should().Equal([arabic, dotnet], "case-insensitive");
        (await SavedAsync($"?q={Uri.EscapeDataString("مقدمة")}")).Should().ContainSingle().Which.Should().Be(arabic, "diacritics are ignored (Arabic_100_CI_AI)");

        var page = await reader.Client.GetAsync("/api/v1/me/saved?limit=2", Ct).OkJsonAsync();
        page["items"]!.AsArray().Should().HaveCount(2);
        var rest = await reader.Client.GetAsync($"/api/v1/me/saved?limit=2&cursor={page["nextCursor"]!.GetValue<string>()}", Ct).OkJsonAsync();
        rest["items"]!.AsArray().Single()!["article"]!["id"]!.GetValue<Guid>().Should().Be(dotnet);

        var collection = await CreateCollectionAsync(reader.Client, "Caching");
        (await reader.Client.PutEmptyAsync($"/api/v1/me/collections/{collection}/articles/{dotnet}")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await SavedAsync($"?collection={collection}")).Should().Equal(dotnet);

        var stranger = await api.UserAsync();
        await stranger.Client.GetAsync($"/api/v1/me/saved?collection={collection}", Ct).ProblemAsync(HttpStatusCode.NotFound, "collection.not_found");
    }

    [Fact]
    public async Task Collections_are_named_lists_of_saved_articles()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();
        var client = reader.Client;

        var later = await CreateCollectionAsync(client, "  Read later ");
        var interview = await CreateCollectionAsync(client, "Interview prep");
        await client.PostAsJsonAsync("/api/v1/me/collections", new { name = "INTERVIEW PREP" }, Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "collection.name_taken");
        var invalid = await client.PostAsJsonAsync("/api/v1/me/collections", new { name = " " }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        invalid["errors"]!["name"]![0]!.GetValue<string>().Should().Be("validation.required");

        // Adding to a collection saves the article first.
        (await client.PutEmptyAsync($"/api/v1/me/collections/{interview}/articles/{articleId}")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.PutEmptyAsync($"/api/v1/me/collections/{interview}/articles/{articleId}")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.PutEmptyAsync($"/api/v1/me/collections/{later}/articles/{articleId}")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var saved = (await client.GetAsync("/api/v1/me/saved", Ct).OkJsonAsync())["items"]!.AsArray().Single()!;
        saved["collectionIds"]!.AsArray().Select(c => c!.GetValue<Guid>()).Should().BeEquivalentTo([later, interview]);
        api.Realtime.CountersFor(articleId)[^1].SaveCount.Should().Be(1);

        var collections = await client.GetAsync("/api/v1/me/collections", Ct).OkArrayAsync();
        collections.Select(c => c!["name"]!.GetValue<string>()).Should().Equal("Interview prep", "Read later");
        collections.Select(c => c!["articleCount"]!.GetValue<int>()).Should().Equal(1, 1);
        collections[0]!["createdAt"]!.GetValue<string>().Should().EndWith("Z");

        var renamed = await client.PatchAsJsonAsync($"/api/v1/me/collections/{later}", new { name = "Weekend" }, Ct).OkJsonAsync();
        renamed["name"]!.GetValue<string>().Should().Be("Weekend");
        renamed["articleCount"]!.GetValue<int>().Should().Be(1);
        await client.PatchAsJsonAsync($"/api/v1/me/collections/{later}", new { name = "interview PREP" }, Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "collection.name_taken");
        (await client.PatchAsJsonAsync($"/api/v1/me/collections/{later}", new { name = "WEEKEND" }, Ct).OkJsonAsync())["name"]!
            .GetValue<string>().Should().Be("WEEKEND", "a collection may change the case of its own name");

        // Removing from a collection keeps the save; deleting a collection keeps its articles saved.
        (await client.DeleteAsync($"/api/v1/me/collections/{later}/articles/{articleId}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.DeleteAsync($"/api/v1/me/collections/{interview}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var stillSaved = (await client.GetAsync("/api/v1/me/saved", Ct).OkJsonAsync())["items"]!.AsArray().Single()!;
        stillSaved["collectionIds"]!.AsArray().Should().BeEmpty();
        (await client.GetAsync("/api/v1/me/collections", Ct).OkArrayAsync()).Select(c => c!["id"]!.GetValue<Guid>()).Should().Equal(later);

        // Unsaving removes the article from every collection.
        (await client.PutEmptyAsync($"/api/v1/me/collections/{later}/articles/{articleId}")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await client.DeleteAsync($"/api/v1/me/saved/{articleId}", Ct).OkJsonAsync();
        (await client.GetAsync("/api/v1/me/collections", Ct).OkArrayAsync()).Single()!["articleCount"]!.GetValue<int>().Should().Be(0);

        var stranger = await api.UserAsync();
        await stranger.Client.PatchAsJsonAsync($"/api/v1/me/collections/{later}", new { name = "Mine now" }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "collection.not_found");
        await stranger.Client.PutEmptyAsync($"/api/v1/me/collections/{later}/articles/{articleId}")
            .ProblemAsync(HttpStatusCode.NotFound, "collection.not_found");
        await stranger.Client.DeleteAsync($"/api/v1/me/collections/{later}", Ct).ProblemAsync(HttpStatusCode.NotFound, "collection.not_found");
        await client.PutEmptyAsync($"/api/v1/me/collections/{later}/articles/{Guid.NewGuid()}")
            .ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task A_user_has_at_most_fifty_collections()
    {
        var reader = await api.UserAsync();
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            for (var i = 0; i < Collection.MaxPerUser; i++)
                db.Collections.Add(Collection.Create(reader.Id, $"List {i:D2}", i, DateTime.UtcNow).Value);
            await db.SaveChangesAsync(Ct);
        }

        await reader.Client.PostAsJsonAsync("/api/v1/me/collections", new { name = "One too many" }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "collection.limit");
    }

    private static async Task<Guid> CreateCollectionAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/v1/me/collections", new { name }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        var body = (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
        body["name"]!.GetValue<string>().Should().Be(name.Trim());
        body["articleCount"]!.GetValue<int>().Should().Be(0);
        response.Headers.Location!.ToString().Should().Be($"/api/v1/me/collections/{body["id"]}");
        return body["id"]!.GetValue<Guid>();
    }
}
