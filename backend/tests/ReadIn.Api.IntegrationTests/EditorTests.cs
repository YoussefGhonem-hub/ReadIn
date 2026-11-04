using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Articles;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>The article editor (SPEC F05, ADR 0015): drafts, autosave, the working copy of a published article, revisions.</summary>
[Collection(ApiCollection.Name)]
public sealed class EditorTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task An_unfinished_draft_saves_and_lists_what_it_still_needs()
    {
        var writer = (await api.SignUpAsync()).Client;

        var draft = await writer.CreateDraftAsync(ArticleTestKit.Document(null, "", "ar-EG", blocks: [], sources: []));

        draft["status"]!.GetValue<string>().Should().Be("draft");
        draft["slug"].Should().BeNull("a draft has no reader URL yet");
        draft["version"]!.GetValue<int>().Should().Be(1);
        draft.ProblemCodes().Should().Equal("article.field_required", "article.title_length", "article.content_empty");

        var publish = await writer.PublishDraftAsync(draft["id"]!.GetValue<Guid>(), 1);
        publish.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var problem = await TaxonomyAndContentTests.Problem(publish);
        problem["code"]!.GetValue<string>().Should().Be("article.field_required");
        problem["problems"]!.AsArray().Should().HaveCount(3);
    }

    [Fact]
    public async Task Autosave_is_guarded_by_the_version_and_returns_live_checks()
    {
        var writer = (await api.SignUpAsync()).Client;
        var field = await writer.FieldIdAsync("dotnet");
        var draft = await writer.CreateDraftAsync(ArticleTestKit.Document(field, "Spans in C#", blocks: [ArticleTestKit.Paragraph("Start.")]));
        var id = draft["id"]!.GetValue<Guid>();
        var words = string.Join(' ', Enumerable.Repeat("Span<T> avoids copies.", 300));

        var saved = await writer.SaveDraftAsync(id, 1, ArticleTestKit.Document(field, "Span<T> in C#: slicing without copies",
            blocks: [ArticleTestKit.Paragraph(words), new { id = "i1", type = "image", src = "https://example.com/span.png", alt = "" }])).OkJsonAsync();

        saved["version"]!.GetValue<int>().Should().Be(2);
        var problem = saved["checks"]!["problems"]!.AsArray().Should().ContainSingle().Which!;
        problem["code"]!.GetValue<string>().Should().Be("article.image_alt_required");
        problem["language"]!.GetValue<string>().Should().Be("en");
        problem["blockId"]!.GetValue<string>().Should().Be("i1");
        var readingTime = saved["checks"]!["readingTime"]!.AsArray().Single()!;
        readingTime["words"]!.GetValue<int>().Should().BeGreaterThan(600);
        readingTime["minutes"]!.GetValue<int>().Should().BeGreaterThan(1);

        var stale = await writer.SaveDraftAsync(id, 1, ArticleTestKit.Document(field, "From another device"));
        await Task.FromResult(stale).ProblemAsync(HttpStatusCode.Conflict, "article.draft_conflict");
        (await writer.EditAsync(id))["document"]!["translations"]![0]!["title"]!.GetValue<string>()
            .Should().Be("Span<T> in C#: slicing without copies", "the second device never silently overwrites the first");
    }

    [Fact]
    public async Task Editing_a_published_article_stays_private_until_update_and_each_update_is_a_revision()
    {
        var writer = (await api.SignUpAsync()).Client;
        var field = await writer.FieldIdAsync("dotnet");
        var (id, slug) = await writer.WriteAndPublishAsync(ArticleTestKit.Document(field, "Async streams in C#", blocks: [ArticleTestKit.Paragraph("Version one.")]));
        var edit = await writer.EditAsync(id);
        edit["status"]!.GetValue<string>().Should().Be("published");
        edit["slug"]!.GetValue<string>().Should().Be(slug);
        edit["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeFalse();

        var changed = await writer.SaveDraftAsync(id, edit["version"]!.GetValue<int>(),
            ArticleTestKit.Document(field, "Async streams in C#, revisited", blocks: [ArticleTestKit.Paragraph("Version two.")])).OkJsonAsync();
        changed["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeTrue();

        var reader = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!;
        reader["title"]!.GetValue<string>().Should().Be("Async streams in C#", "readers keep the published version while the writer edits");

        var update = await writer.PublishDraftAsync(id, changed["version"]!.GetValue<int>()).OkJsonAsync();
        update["firstPublish"]!.GetValue<bool>().Should().BeFalse();
        update["revision"]!.GetValue<int>().Should().Be(2);
        update["slug"]!.GetValue<string>().Should().Be(slug, "the URL is fixed at the first publish");

        reader = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!;
        reader["title"]!.GetValue<string>().Should().Be("Async streams in C#, revisited");
        reader["publishedAt"]!.GetValue<DateTime>().Should().Be(update["publishedAt"]!.GetValue<DateTime>(), "the first publish date stays");
        (await writer.EditAsync(id))["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeFalse();

        var revisions = (await writer.GetFromJsonAsync<JsonArray>($"/api/v1/articles/{id}/revisions", Ct))!;
        revisions.Select(r => r!["title"]!.GetValue<string>()).Should().Equal("Async streams in C#, revisited", "Async streams in C#");
        revisions[0]!["languages"]!.AsArray().Select(l => l!.GetValue<string>()).Should().Equal("en");

        var first = (await writer.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{id}/revisions/1", Ct))!;
        first["document"]!["translations"]![0]!["content"]!["blocks"]![0]!["content"]![0]!["text"]!.GetValue<string>().Should().Be("Version one.");
        first["media"]!.AsArray().Should().BeEmpty();
    }

    [Fact]
    public async Task Restoring_a_revision_and_discarding_changes_work_on_the_working_copy()
    {
        var writer = (await api.SignUpAsync()).Client;
        var field = await writer.FieldIdAsync("dotnet");
        var (id, slug) = await writer.WriteAndPublishAsync(ArticleTestKit.Document(field, "LINQ deferred execution"));
        var v2 = await writer.SaveDraftAsync(id, (await writer.EditAsync(id))["version"]!.GetValue<int>(),
            ArticleTestKit.Document(field, "LINQ deferred execution, explained")).OkJsonAsync();
        await writer.PublishDraftAsync(id, v2["version"]!.GetValue<int>()).OkJsonAsync();

        var restored = await writer.PostAsJsonAsync($"/api/v1/articles/{id}/revisions/1/restore", new { baseVersion = v2["version"]!.GetValue<int>() }, Ct)
            .OkJsonAsync();
        restored["document"]!["translations"]![0]!["title"]!.GetValue<string>().Should().Be("LINQ deferred execution");
        restored["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeTrue();
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["title"]!.GetValue<string>()
            .Should().Be("LINQ deferred execution, explained", "a restore goes live only with the next publish");

        var discarded = await writer.DeleteAsync($"/api/v1/articles/{id}/draft", Ct).OkJsonAsync();
        discarded["document"]!["translations"]![0]!["title"]!.GetValue<string>().Should().Be("LINQ deferred execution, explained");
        discarded["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeFalse();

        await writer.PostAsJsonAsync($"/api/v1/articles/{id}/revisions/9/restore", new { baseVersion = discarded["version"]!.GetValue<int>() }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "article.revision_not_found");
        var neverPublished = await writer.CreateDraftAsync(ArticleTestKit.Document(field, "Nothing to discard"));
        await writer.DeleteAsync($"/api/v1/articles/{neverPublished["id"]}/draft", Ct).ProblemAsync(HttpStatusCode.Conflict, "article.not_published");
    }

    [Fact]
    public async Task A_second_language_is_published_with_the_first_and_can_be_removed_again()
    {
        var writer = (await api.SignUpAsync()).Client;
        var field = await writer.FieldIdAsync("dotnet");
        var document = ArticleTestKit.Document(field, "الـ Dependency Injection ببساطة", "ar-EG", [ArticleTestKit.Paragraph("شرح بالمصري.")]);
        document["translations"]!.AsArray().Add(JsonNode.Parse("""
            { "language": "en", "title": "Dependency Injection, simply", "subtitle": null,
              "content": { "version": 1, "language": "en", "blocks": [{ "id": "p1", "type": "paragraph", "content": [{ "type": "text", "text": "In English." }] }] } }
            """));
        var (id, slug) = await writer.WriteAndPublishAsync(document);

        slug.Should().StartWith("dependency-injection", "the slug comes from the source title's Latin words");
        var english = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}?lang=en", Ct))!;
        english["title"]!.GetValue<string>().Should().Be("Dependency Injection, simply");
        english["availableLanguages"]!.AsArray().Select(l => l!.GetValue<string>()).Should().BeEquivalentTo(["ar-EG", "en"]);

        var edit = await writer.EditAsync(id);
        var onlyArabic = edit["document"]!.AsObject();
        onlyArabic["translations"]!.AsArray().RemoveAt(1);
        var saved = await writer.SaveDraftAsync(id, edit["version"]!.GetValue<int>(), onlyArabic).OkJsonAsync();
        await writer.PublishDraftAsync(id, saved["version"]!.GetValue<int>()).OkJsonAsync();

        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}?lang=en", Ct))!["availableLanguages"]!
            .AsArray().Select(l => l!.GetValue<string>()).Should().Equal("ar-EG");
    }

    [Fact]
    public async Task My_articles_lists_drafts_and_published_articles_of_the_owner_only()
    {
        var writer = await api.SignUpAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var untitled = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, "", blocks: []));
        var (published, slug) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Value tasks without the pitfalls"));
        var edit = await writer.Client.EditAsync(published);
        await writer.Client.SaveDraftAsync(published, edit["version"]!.GetValue<int>(), ArticleTestKit.Document(field, "Value tasks, edited")).OkJsonAsync();
        var newest = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(null, "Started on the phone", "ar-EG"));

        var drafts = (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=draft", Ct))!["items"]!.AsArray();
        drafts.Select(d => d!["id"]!.GetValue<Guid>()).Should().Equal(newest["id"]!.GetValue<Guid>(), untitled["id"]!.GetValue<Guid>());
        drafts[0]!["title"]!.GetValue<string>().Should().Be("Started on the phone");
        drafts[0]!["language"]!.GetValue<string>().Should().Be("ar-EG");
        drafts[0]!["field"].Should().BeNull("the writer hasn't picked one yet");
        drafts[0]!["slug"].Should().BeNull();
        drafts[1]!["title"]!.GetValue<string>().Should().BeEmpty("the client shows \"Untitled\"");
        drafts[1]!["field"]!["slug"]!.GetValue<string>().Should().Be("dotnet");

        var mine = (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=published", Ct))!["items"]!.AsArray();
        var item = mine.Should().ContainSingle().Which!;
        item["slug"]!.GetValue<string>().Should().Be(slug);
        item["title"]!.GetValue<string>().Should().Be("Value tasks without the pitfalls", "the list shows what readers see");
        item["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeTrue();

        var paged = (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=draft&limit=1", Ct))!;
        paged["items"]!.AsArray().Should().ContainSingle();
        var next = (await writer.Client.GetFromJsonAsync<JsonObject>($"/api/v1/me/articles?status=draft&limit=1&cursor={paged["nextCursor"]}", Ct))!;
        next["items"]![0]!["id"]!.GetValue<Guid>().Should().Be(untitled["id"]!.GetValue<Guid>());

        var other = (await api.SignUpAsync()).Client;
        (await other.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=draft", Ct))!["items"]!.AsArray().Should().BeEmpty();
        await other.GetAsync("/api/v1/me/articles?status=archived", Ct).ProblemAsync(HttpStatusCode.BadRequest, "article.status_invalid");

        (await writer.Client.DeleteAsync($"/api/v1/articles/{untitled["id"]}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=draft", Ct))!["items"]!.AsArray().Should().ContainSingle();
    }

    [Fact]
    public async Task Tag_suggestions_match_names_and_slugs_most_used_first()
    {
        var writer = (await api.SignUpAsync()).Client;
        var field = await writer.FieldIdAsync("dotnet");
        var unique = $"zq{Guid.NewGuid():N}"[..10];
        await writer.WriteAndPublishAsync(ArticleTestKit.Document(field, $"{unique} one", tags: [$"{unique}-popular", $"{unique}-rare"]));
        await writer.WriteAndPublishAsync(ArticleTestKit.Document(field, $"{unique} two", tags: [$"{unique}-popular"]));

        var tags = (await api.GuestClient().GetFromJsonAsync<JsonArray>($"/api/v1/tags?q={unique.ToUpperInvariant()}", Ct))!;

        tags.Select(t => t!["name"]!.GetValue<string>()).Should().Equal($"{unique}-popular", $"{unique}-rare");
        tags[0]!["articleCount"]!.GetValue<int>().Should().Be(2);
    }

    [Fact]
    public async Task Demo_writers_have_drafts_and_an_article_with_history_locally()
    {
        var verified = await api.SeedUserClientAsync("+12025550106");

        var drafts = (await verified.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=draft", Ct))!["items"]!.AsArray();
        drafts.Select(d => d!["title"]!.GetValue<string>()).Should().Contain("Riverpod ولا Bloc؟");
        var published = (await verified.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=published", Ct))!["items"]!.AsArray();
        var folders = published.Single(a => a!["slug"]!.GetValue<string>() == "flutter-feature-first-folders")!;
        folders["hasUnpublishedChanges"]!.GetValue<bool>().Should().BeTrue();
        folders["title"]!.GetValue<string>().Should().Be("Feature-first folders in Flutter apps", "readers see the second revision");

        var id = folders["id"]!.GetValue<Guid>();
        (await verified.GetFromJsonAsync<JsonArray>($"/api/v1/articles/{id}/revisions", Ct))!.Should().HaveCount(2);
        (await verified.EditAsync(id))["document"]!["translations"]![0]!["title"]!.GetValue<string>()
            .Should().Be("Feature-first folders in Flutter apps, with examples");

        var writer1 = await api.SeedUserClientAsync("+12025550107");
        var signals = (await writer1.GetFromJsonAsync<JsonObject>("/api/v1/me/articles?status=draft", Ct))!["items"]!.AsArray()
            .Single(d => d!["title"]!.GetValue<string>().StartsWith("الـ Signals", StringComparison.Ordinal))!;
        (await writer1.EditAsync(signals["id"]!.GetValue<Guid>())).ProblemCodes()
            .Should().BeEquivalentTo(["article.image_alt_required", "article.sources_required"], "the demo shows the live checks");
    }

    [Fact]
    public async Task The_quality_job_scores_published_articles_with_the_documented_formula()
    {
        var writer = (await api.SignUpAsync()).Client;
        var (id, _) = await writer.WriteAndPublishAsync(ArticleTestKit.Document(await writer.FieldIdAsync("dotnet"), "Quality is engagement, completion and freshness"));

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var publishedAt = DateTime.UtcNow.AddDays(-30);
        await db.Articles.Where(a => a.Id == id).ExecuteUpdateAsync(set => set
            .SetProperty(a => a.PublishedAt, publishedAt)
            .SetProperty(a => a.ReactionCount, 6)
            .SetProperty(a => a.CommentCount, 2)
            .SetProperty(a => a.SaveCount, 1)
            .SetProperty(a => a.ReadCount, 0), Ct);

        await scope.ServiceProvider.GetRequiredService<ArticleQualityJob>().RunAsync(Ct);

        var score = await db.Articles.Where(a => a.Id == id).Select(a => a.QualityScore).SingleAsync(Ct);
        score.Should().BeApproximately(ArticleQuality.Score(6, 2, 1, 0, 0, 30 * 24), 0.002);
    }
}
