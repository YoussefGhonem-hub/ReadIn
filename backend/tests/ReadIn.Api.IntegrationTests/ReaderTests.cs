using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Learning;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The end of the reader and resuming it (SPEC F04): related articles and the viewer's progress in the details.
/// Each test publishes into a field no other test uses, so the rankings are exact.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ReaderTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Related_articles_share_the_topic_first_then_the_field_then_tags_and_terms()
    {
        var writer = await api.UserAsync("Related Writer");
        var tag = $"rel-{Guid.NewGuid():N}"[..20];

        var open = await PublishAsync(writer.Client, "claude-ai-tools", "claude-code", [tag], "context-window");
        var sameTopic = await PublishAsync(writer.Client, "claude-ai-tools", "claude-code");
        var fieldAndTag = await PublishAsync(writer.Client, "claude-ai-tools", "mcp", [tag]);
        var fieldAndTerm = await PublishAsync(writer.Client, "claude-ai-tools", "mcp", termId: "context-window");
        var fieldOnly = await PublishAsync(writer.Client, "claude-ai-tools", "mcp");
        var tagOnly = await PublishAsync(writer.Client, "machine-learning", "mlops", [tag]);
        var unrelated = await PublishAsync(writer.Client, "machine-learning", "mlops");

        var related = await api.GuestClient().GetAsync(Related(open.Id, limit: 10), Ct).OkArrayAsync();

        related.Select(Id).Should().Equal(sameTopic.Id, fieldAndTag.Id, fieldAndTerm.Id, fieldOnly.Id, tagOnly.Id);
        related.Select(Id).Should().NotContain([open.Id, unrelated.Id]);
        related[0]!["slug"]!.GetValue<string>().Should().Be(sameTopic.Slug);
        related[0]!["myReaction"].Should().BeNull("cards carry the viewer state like every other card");

        (await api.GuestClient().GetAsync(Related(open.Id), Ct).OkArrayAsync()).Should().HaveCount(4, "the default limit is 4");
        (await api.GuestClient().GetAsync(Related(open.Id, limit: 99), Ct).OkArrayAsync()).Should().HaveCount(5, "the limit is capped at 10");
    }

    [Fact]
    public async Task Viewers_dont_get_their_own_articles_and_get_the_ones_they_read_last()
    {
        var writer = await api.UserAsync("Related Writer");
        var reader = await api.UserAsync("Related Reader");

        var open = await PublishAsync(writer.Client, "deep-learning-llms", "transformers");
        var older = await PublishAsync(writer.Client, "deep-learning-llms", "transformers");
        var newer = await PublishAsync(writer.Client, "deep-learning-llms", "transformers");
        var own = await PublishAsync(reader.Client, "deep-learning-llms", "transformers");
        await CompleteAsync(reader, newer.Id);

        var forReader = await reader.Client.GetAsync(Related(open.Id), Ct).OkArrayAsync();
        forReader.Select(Id).Should().Equal(older.Id, newer.Id);

        var forGuest = await api.GuestClient().GetAsync(Related(open.Id), Ct).OkArrayAsync();
        forGuest.Select(Id).Should().Equal(own.Id, newer.Id, older.Id);
    }

    [Fact]
    public async Task Neighbours_in_a_learning_path_are_left_to_the_next_in_path_block()
    {
        var writer = await api.UserAsync("Path Writer");
        var first = await PublishAsync(writer.Client, "machine-learning", "feature-engineering");
        var second = await PublishAsync(writer.Client, "machine-learning", "feature-engineering");
        var third = await PublishAsync(writer.Client, "machine-learning", "feature-engineering");
        var fourth = await PublishAsync(writer.Client, "machine-learning", "feature-engineering");

        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var field = await db.Fields.Where(f => f.Slug == "machine-learning").Select(f => f.Id).SingleAsync(Ct);
            var path = new LearningPath($"path-{Guid.NewGuid():N}", field, "مسار", "Path", 99);
            db.LearningPaths.Add(path);
            await db.SaveChangesAsync(Ct);
            path.SetItems([(first.Id, 1), (second.Id, 2), (third.Id, 5), (fourth.Id, 6)]);
            await db.SaveChangesAsync(Ct);
        }

        var related = await api.GuestClient().GetAsync(Related(third.Id, limit: 10), Ct).OkArrayAsync();

        related.Select(Id).Should().Contain(first.Id).And.NotContain([second.Id, third.Id, fourth.Id],
            "the article before and after it in the path (orders 2 and 6) are shown by Next in path");
    }

    [Fact]
    public async Task Related_needs_a_published_article()
    {
        await api.GuestClient().GetAsync(Related(Guid.NewGuid()), Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task The_details_give_the_reader_their_progress_back()
    {
        var writer = await api.UserAsync("Resume Writer");
        var reader = await api.UserAsync("Resume Reader");
        var article = await PublishAsync(writer.Client, "dotnet", "csharp");

        var unopened = await reader.Client.GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync();
        unopened["myProgress"].Should().BeNull();

        var report = new { language = "en", percent = 45, lastPosition = "0.4523", activeSecondsDelta = 0 };
        (await reader.Client.PutAsJsonAsync($"/api/v1/articles/{article.Id}/progress", report, Ct)).EnsureSuccessStatusCode();

        var details = await reader.Client.GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync();
        var progress = details["myProgress"]!;
        progress["language"]!.GetValue<string>().Should().Be("en");
        progress["percent"]!.GetValue<int>().Should().Be(45);
        progress["lastPosition"]!.GetValue<string>().Should().Be("0.4523");
        progress["completedAt"].Should().BeNull();

        var guest = await api.GuestClient().GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync();
        guest["myProgress"].Should().BeNull("the cached details never carry anyone's progress");
        var writerView = await writer.Client.GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync();
        writerView["myProgress"].Should().BeNull();
    }

    private static string Related(Guid id, int? limit = null) =>
        $"/api/v1/articles/{id}/related?lang=en" + (limit is null ? "" : $"&limit={limit}");

    private static Guid Id(JsonNode? card) => card!["id"]!.GetValue<Guid>();

    /// <summary>Opens the article, lets 40 seconds pass on the server and reads it to the end.</summary>
    private async Task CompleteAsync(SignedInUser user, Guid articleId)
    {
        object Report(int percent, int seconds) => new { language = "en", percent, lastPosition = "1.0000", activeSecondsDelta = seconds };

        (await user.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/progress", Report(0, 0), Ct)).EnsureSuccessStatusCode();
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            await db.ReadingProgress
                .Where(r => r.UserId == user.Id && r.ArticleId == articleId)
                .ExecuteUpdateAsync(set => set.SetProperty(r => r.UpdatedAt, r => r.UpdatedAt.AddSeconds(-40)), Ct);
        }
        var read = await user.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/progress", Report(100, 40), Ct).OkJsonAsync();
        read["completedNow"]!.GetValue<bool>().Should().BeTrue();
    }

    /// <summary>Writes and publishes an English article as <paramref name="author"/>, optionally using a glossary term.</summary>
    private static async Task<(Guid Id, string Slug)> PublishAsync(
        HttpClient author, string field, string topic, string[]? tags = null, string? termId = null)
    {
        var topics = (await author.GetFromJsonAsync<JsonArray>($"/api/v1/fields/{field}/topics", Ct))!;
        object[] content = termId is null
            ? [new { type = "text", text = "Related reading." }]
            : [new { type = "text", text = "Related reading about " }, new { type = "term", termId, text = termId }];

        var document = ArticleTestKit.Document(
            await author.FieldIdAsync(field),
            $"Reader test {Guid.NewGuid():N}",
            blocks: [new { id = "p1", type = "paragraph", dir = "auto", content }],
            sources: [new { title = "Example", url = "https://example.com" }],
            tags: tags);
        document["topicId"] = topics.Single(t => t!["slug"]!.GetValue<string>() == topic)!["id"]!.GetValue<Guid>();
        return await author.WriteAndPublishAsync(document);
    }
}
