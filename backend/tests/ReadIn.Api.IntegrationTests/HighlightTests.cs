using System.Data.Common;
using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Highlights;
using ReadIn.Domain.Engagement;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F30 Highlights end to end (SPEC F30, contract "Highlights (F30)"): the shared offsets fixtures through the API in both
/// language versions, joining, popular ranges (threshold, mutes, at most 5, nothing about who), the shared cache, edits
/// that move text, the limit, Saved → Highlights, the ShowHighlights preference, account deletion and the writes limit.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class HighlightTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static readonly JsonObject Fixtures = JsonNode.Parse(File.ReadAllText(FixturesPath()))!.AsObject();

    private static string FixturesPath()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            var path = Path.Combine(dir.FullName, "shared", "rdoc", "highlight-fixtures.json");
            if (File.Exists(path)) return path;
        }
        throw new FileNotFoundException("shared/rdoc/highlight-fixtures.json not found.");
    }

    private static string Language(string document) => Fixtures["documents"]![document]!["language"]!.GetValue<string>();

    private static string PlainText(string document, string blockId) =>
        Fixtures["blocks"]![document]!.AsArray().Single(b => b!["blockId"]!.GetValue<string>() == blockId)!["plainText"]!.GetValue<string>();

    /// <summary>An article whose ar-EG (source) and en versions are the fixture documents.</summary>
    private async Task<(Guid Id, string Slug, SignedInUser Author)> PublishFixtureArticleAsync()
    {
        var author = await api.UserAsync("Highlights Author");
        var document = JsonSerializerHelper.ToObject(new
        {
            sourceLanguage = "ar-EG",
            translations = new[]
            {
                // The fixture's term nodes stay (their text is part of the offsets), under a term the glossary doesn't have.
                new { language = "ar-EG", title = "مقال فيه Highlights", subtitle = (string?)null, content = Fixtures["documents"]!["ar"]!.DeepClone().WithUnlistedTerms() },
                new { language = "en", title = "An article with highlights", subtitle = (string?)null, content = Fixtures["documents"]!["en"]!.DeepClone().WithUnlistedTerms() },
            },
            fieldId = await author.Client.FieldIdAsync("dotnet"),
            topicId = (Guid?)null,
            tags = Array.Empty<string>(),
            sources = ArticleTestKit.OneSource,
            coverUrl = (string?)null,
            versionBadge = (string?)null,
            isAiAssisted = false,
            attachments = Array.Empty<object>(),
        });
        var (id, slug) = await author.Client.WriteAndPublishAsync(document);
        return (id, slug, author);
    }

    private static Task<HttpResponseMessage> PostAsync(HttpClient client, Guid articleId, string language, string blockId, int start, int end, string? text) =>
        client.PostAsJsonAsync($"/api/v1/articles/{articleId}/highlights", new { language, blockId, startOffset = start, endOffset = end, text }, Ct);

    /// <summary>Highlights a slice of a fixture block (offsets in its plain text) and returns <c>HighlightCreatedDto</c>.</summary>
    private static async Task<JsonObject> MarkAsync(SignedInUser user, Guid articleId, string document, string blockId, int start, int end, HttpStatusCode status = HttpStatusCode.Created)
    {
        var response = await PostAsync(user.Client, articleId, Language(document), blockId, start, end, PlainText(document, blockId)[start..end]);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(status, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    private static Task<JsonObject> GetAsync(HttpClient client, Guid articleId, string? lang = null) =>
        client.GetAsync($"/api/v1/articles/{articleId}/highlights{(lang is null ? "" : $"?lang={lang}")}", Ct).OkJsonAsync();

    private static (string, int, int, string) Range(JsonNode h) =>
        (h["blockId"]!.GetValue<string>(), h["startOffset"]!.GetValue<int>(), h["endOffset"]!.GetValue<int>(), h["text"]!.GetValue<string>());

    private static (string, int, int, string, int) Popular(JsonNode p) =>
        (p["blockId"]!.GetValue<string>(), p["startOffset"]!.GetValue<int>(), p["endOffset"]!.GetValue<int>(), p["text"]!.GetValue<string>(), p["count"]!.GetValue<int>());

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> work)
    {
        using var scope = api.Services.CreateScope();
        return await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    /// <summary>Fresh users in turn, so no one runs past the writes limit (30 a minute; completing the profile is one).</summary>
    private sealed class UserPool(ApiFactory api, int writesEach)
    {
        private SignedInUser? _current;
        private int _used;

        public async Task<SignedInUser> NextAsync(int writes)
        {
            if (_current is null || _used + writes > writesEach)
            {
                _current = await api.UserAsync("Fixture Highlighter");
                _used = 0;
            }
            _used += writes;
            return _current;
        }
    }

    [Fact]
    public async Task Every_fixture_selection_and_server_check_round_trips_through_the_api_in_both_versions()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var pool = new UserPool(api, 26);

        foreach (var selection in Fixtures["selections"]!.AsArray().Where(s => s!["expected"] is not null))
        {
            var id = selection!["id"]!.GetValue<string>();
            var expected = selection["expected"]!;
            var user = await pool.NextAsync(2);
            var response = await PostAsync(user.Client, articleId, Language(selection["document"]!.GetValue<string>()),
                expected["blockId"]!.GetValue<string>(), expected["startOffset"]!.GetValue<int>(), expected["endOffset"]!.GetValue<int>(),
                expected["text"]!.GetValue<string>());
            var body = await response.Content.ReadAsStringAsync(Ct);
            response.StatusCode.Should().Be(HttpStatusCode.Created, $"{id}: {body}");
            var created = JsonNode.Parse(body)!;
            Range(created["highlight"]!).Should().Be(Range(expected), id);
            created["replacedIds"]!.AsArray().Should().BeEmpty(id);
            (await user.Client.DeleteAsync($"/api/v1/highlights/{created["highlight"]!["id"]!.GetValue<Guid>()}", Ct)).StatusCode
                .Should().Be(HttpStatusCode.NoContent, id);
        }

        foreach (var check in Fixtures["serverChecks"]!["cases"]!.AsArray())
        {
            var id = check!["id"]!.GetValue<string>();
            var document = check["document"]!.GetValue<string>();
            var blockId = check["blockId"]!.GetValue<string>();
            var (start, end) = (check["startOffset"]!.GetValue<int>(), check["endOffset"]!.GetValue<int>());
            var user = await pool.NextAsync(2);

            HttpResponseMessage response;
            if (check["text"] is { } given)
            {
                response = await PostAsync(user.Client, articleId, Language(document), blockId, start, end, given.GetValue<string>());
            }
            else
            {
                var plain = PlainText(document, blockId);
                var slice = plain[Math.Min(start, plain.Length)..Math.Min(end, plain.Length)];
                // Half a surrogate pair can't be written as JSON by a serializer: send it escaped by hand.
                var text = string.Concat(slice.Select(c => char.IsSurrogate(c) ? $"\\u{(int)c:x4}" : JsonValue.Create(c.ToString())!.ToJsonString()[1..^1]));
                var json = $$"""{"language":"{{Language(document)}}","blockId":"{{blockId}}","startOffset":{{start}},"endOffset":{{end}},"text":"{{text}}"}""";
                response = await user.Client.PostAsync($"/api/v1/articles/{articleId}/highlights", new StringContent(json, Encoding.UTF8, "application/json"), Ct);
            }

            var body = await response.Content.ReadAsStringAsync(Ct);
            if (check["error"]?.GetValue<string>() is { } error)
            {
                response.StatusCode.Should().Be(HttpStatusCode.BadRequest, $"{id}: {body}");
                // A lone surrogate never reaches the handler: the body itself is refused.
                JsonNode.Parse(body)!["code"]!.GetValue<string>().Should().BeOneOf([error, "request.invalid"], id);
                if (!id.StartsWith("srv-splits-surrogate", StringComparison.Ordinal))
                    JsonNode.Parse(body)!["code"]!.GetValue<string>().Should().Be(error, id);
            }
            else
            {
                response.StatusCode.Should().Be(HttpStatusCode.Created, $"{id}: {body}");
                Range(JsonNode.Parse(body)!["highlight"]!).Should().Be(Range(check["stored"]!), id);
                (await user.Client.DeleteAsync($"/api/v1/highlights/{JsonNode.Parse(body)!["highlight"]!["id"]!.GetValue<Guid>()}", Ct))
                    .StatusCode.Should().Be(HttpStatusCode.NoContent, id);
            }
        }
    }

    [Fact]
    public async Task Mine_is_private_in_document_order_per_version_and_guests_get_only_popular()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();
        var other = await api.UserAsync();

        var inP2 = (await MarkAsync(reader, articleId, "ar", "p2", 6, 18))["highlight"]!;
        var inSummary = (await MarkAsync(reader, articleId, "ar", "s1", 4, 24))["highlight"]!;
        var inEnglish = (await MarkAsync(reader, articleId, "en", "e1", 0, 3))["highlight"]!;
        inSummary["createdAt"]!.GetValue<DateTime>().Should().BeAfter(DateTime.UtcNow.AddMinutes(-5));
        await MarkAsync(other, articleId, "ar", "p1", 0, 10);

        var ar = await GetAsync(reader.Client, articleId, "ar-EG");
        (ar["articleId"]!.GetValue<Guid>(), ar["language"]!.GetValue<string>()).Should().Be((articleId, "ar-EG"));
        ar["mine"]!.AsArray().Select(h => h!["id"]!.GetValue<Guid>()).Should().Equal(
            [inSummary["id"]!.GetValue<Guid>(), inP2["id"]!.GetValue<Guid>()], "document order: the summary comes before p2; nobody else's");
        ar["mine"]![0]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "blockId", "startOffset", "endOffset", "text", "createdAt");

        var en = await GetAsync(reader.Client, articleId, "en");
        en["mine"]!.AsArray().Select(h => h!["id"]!.GetValue<Guid>()).Should().Equal([inEnglish["id"]!.GetValue<Guid>()], "highlights are per version");
        (await GetAsync(reader.Client, articleId, "fr"))["language"]!.GetValue<string>().Should().Be("ar-EG", "an unknown version is the source");
        (await GetAsync(reader.Client, articleId))["language"]!.GetValue<string>().Should().Be("ar-EG");

        var guest = await GetAsync(api.GuestClient(), articleId, "ar-EG");
        guest["mine"]!.AsArray().Should().BeEmpty();
        guest["popular"]!.AsArray().Should().BeEmpty("one reader per range is not popular");

        await api.GuestClient().GetAsync($"/api/v1/articles/{Guid.NewGuid()}/highlights", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task Your_highlights_join_when_they_overlap_or_touch_and_never_overlap()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();

        var first = (await MarkAsync(reader, articleId, "ar", "p1", 15, 27))["highlight"]!; // "ASP.NET Core"
        var overlapping = await MarkAsync(reader, articleId, "ar", "p1", 20, 40);
        overlapping["replacedIds"]!.AsArray().Select(i => i!.GetValue<Guid>()).Should().Equal([first["id"]!.GetValue<Guid>()]);
        Range(overlapping["highlight"]!).Should().Be(("p1", 15, 40, PlainText("ar", "p1")[15..40]));

        var touching = await MarkAsync(reader, articleId, "ar", "p1", 40, 50);
        touching["replacedIds"]!.AsArray().Should().HaveCount(1);
        Range(touching["highlight"]!).Should().Be(("p1", 15, 50, PlainText("ar", "p1")[15..50]));
        var joinedId = touching["highlight"]!["id"]!.GetValue<Guid>();

        var inside = await MarkAsync(reader, articleId, "ar", "p1", 20, 30, HttpStatusCode.OK);
        (inside["highlight"]!["id"]!.GetValue<Guid>(), inside["replacedIds"]!.AsArray().Count).Should().Be((joinedId, 0), "already inside one of yours");
        var same = await MarkAsync(reader, articleId, "ar", "p1", 15, 50, HttpStatusCode.OK);
        same["highlight"]!["id"]!.GetValue<Guid>().Should().Be(joinedId);

        var apart = await MarkAsync(reader, articleId, "ar", "p1", 60, 73);
        apart["replacedIds"]!.AsArray().Should().BeEmpty();
        // Another list item never joins, even right after: items are separate units.
        var item1 = await MarkAsync(reader, articleId, "ar", "l1", 0, 31);
        var item2 = await MarkAsync(reader, articleId, "ar", "l1", 32, 38);
        item2["replacedIds"]!.AsArray().Should().BeEmpty();

        var mine = (await GetAsync(reader.Client, articleId, "ar-EG"))["mine"]!.AsArray();
        mine.Select(h => (h!["blockId"]!.GetValue<string>(), h["startOffset"]!.GetValue<int>(), h["endOffset"]!.GetValue<int>()))
            .Should().Equal(("p1", 15, 50), ("p1", 60, 73), ("l1", 0, 31), ("l1", 32, 38));
        item1["highlight"]!["text"]!.GetValue<string>().Should().Be("سجّل الـ services في Program.cs");

        // Fewer than 3 characters is refused.
        await PostAsync(reader.Client, articleId, "ar-EG", "p1", 0, 2, "لو").ProblemAsync(HttpStatusCode.BadRequest, "highlight.too_short");
    }

    [Fact]
    public async Task Removing_is_for_your_own_highlights_only_and_answers_not_found_after()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();
        var other = await api.UserAsync();
        var id = (await MarkAsync(reader, articleId, "ar", "p4", 0, 6))["highlight"]!["id"]!.GetValue<Guid>();

        await other.Client.DeleteAsync($"/api/v1/highlights/{id}", Ct).ProblemAsync(HttpStatusCode.NotFound, "highlight.not_found");
        (await api.GuestClient().DeleteAsync($"/api/v1/highlights/{id}", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await reader.Client.DeleteAsync($"/api/v1/highlights/{id}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await reader.Client.DeleteAsync($"/api/v1/highlights/{id}", Ct).ProblemAsync(HttpStatusCode.NotFound, "highlight.not_found");
        (await GetAsync(reader.Client, articleId))["mine"]!.AsArray().Should().BeEmpty();
    }

    [Fact]
    public async Task Bad_requests_guests_and_articles_readers_cant_open_are_refused()
    {
        var (articleId, _, author) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();
        var url = $"/api/v1/articles/{articleId}/highlights";

        var problem = await reader.Client.PostAsJsonAsync(url, new { }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        problem["errors"]!.AsObject().ToDictionary(e => e.Key, e => e.Value!.AsArray().Select(c => c!.GetValue<string>()).ToArray())
            .Should().BeEquivalentTo(new Dictionary<string, string[]>
            {
                ["language"] = ["validation.required"],
                ["blockId"] = ["validation.required"],
                ["startOffset"] = ["validation.required"],
                ["endOffset"] = ["validation.required"],
                ["text"] = ["validation.required"],
            });
        problem = await reader.Client.PostAsJsonAsync(url, new { language = "fr", blockId = "p 1", startOffset = -1, endOffset = 5, text = "x" }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        problem["errors"]!.AsObject().ToDictionary(e => e.Key, e => e.Value!.AsArray().Select(c => c!.GetValue<string>()).ToArray())
            .Should().BeEquivalentTo(new Dictionary<string, string[]>
            {
                ["language"] = ["article.language_invalid"],
                ["blockId"] = ["validation.invalid"],
                ["startOffset"] = ["validation.invalid"],
            });
        (await reader.Client.PostAsJsonAsync(url, new { language = "en", blockId = "e1", startOffset = 5, endOffset = 5, text = "x" }, Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))["errors"]!["endOffset"]![0]!.GetValue<string>()
            .Should().Be("validation.invalid");

        (await api.GuestClient().PostAsJsonAsync(url, new { language = "en", blockId = "e1", startOffset = 0, endOffset = 3, text = "Use" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await PostAsync(reader.Client, Guid.NewGuid(), "en", "e1", 0, 3, "Use").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // An article with only an English version has no ar-EG text.
        var (englishOnly, _) = await author.Client.PublishAsync("English only");
        await PostAsync(reader.Client, englishOnly, "ar-EG", "p1", 0, 3, "Rea").ProblemAsync(HttpStatusCode.BadRequest, "highlight.text_mismatch");

        // Hidden by a moderator: gone for readers, still there for its author.
        await MarkAsync(author, articleId, "en", "e1", 0, 3);
        var admin = (await api.SuperAdminAsync()).Client;
        (await admin.PostAsJsonAsync("/api/v1/moderation/actions", new { action = "hide", targetType = "article", targetId = articleId, note = "Spam" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        await reader.Client.GetAsync($"{url}?lang=en", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await api.GuestClient().GetAsync(url, Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await PostAsync(reader.Client, articleId, "en", "e1", 0, 3, "Use").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        (await GetAsync(author.Client, articleId, "en"))["mine"]!.AsArray().Should().HaveCount(1);
    }

    [Fact]
    public async Task Popular_ranges_need_three_readers_leave_out_muted_writers_and_show_at_most_five()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var a = await api.UserAsync();
        var b = await api.UserAsync();
        var c = await api.UserAsync();
        var d = await api.UserAsync();
        var viewer = await api.UserAsync();

        // Six ranges marked by a, b and c; the last one by d too. p3 [16, 27) is marked by two readers only.
        (string Block, int Start, int End)[] ranges = [("s1", 0, 3), ("h1", 0, 4), ("p1", 0, 6), ("p2", 0, 5), ("q1", 0, 5), ("c1", 0, 6)];
        foreach (var user in new[] { a, b, c })
            foreach (var (block, start, end) in ranges) await MarkAsync(user, articleId, "ar", block, start, end);
        await MarkAsync(d, articleId, "ar", "c1", 0, 6);
        await MarkAsync(a, articleId, "ar", "p3", 16, 27);
        await MarkAsync(b, articleId, "ar", "p3", 16, 27);

        var guest = await GetAsync(api.GuestClient(), articleId, "ar-EG");
        guest["popular"]!.AsArray().Select(p => Popular(p!)).Should().Equal(
            [
                ("c1", 0, 6, PlainText("ar", "c1")[..6], 4),
                ("s1", 0, 3, PlainText("ar", "s1")[..3], 3),
                ("h1", 0, 4, PlainText("ar", "h1")[..4], 3),
                ("p1", 0, 6, PlainText("ar", "p1")[..6], 3),
                ("p2", 0, 5, PlainText("ar", "p2")[..5], 3),
            ],
            "most marked first, then document order, at most 5 (q1 is sixth); p3 has only 2 readers");
        guest["popular"]![0]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo(["blockId", "startOffset", "endOffset", "text", "count"], "nothing says who");
        (await GetAsync(a.Client, articleId, "ar-EG"))["popular"]![0]!["count"]!.GetValue<int>().Should().Be(4, "your own mark counts");
        (await GetAsync(api.GuestClient(), articleId, "en"))["popular"]!.AsArray().Should().BeEmpty("ar-EG highlights only show on ar-EG");

        // The viewer mutes a: every range a marked drops to 2 (or 3 for c1) for the viewer only.
        await viewer.Client.PutEmptyAsync($"/api/v1/users/{a.Id}/mute").OkJsonAsync();
        (await GetAsync(viewer.Client, articleId, "ar-EG"))["popular"]!.AsArray().Select(p => Popular(p!))
            .Should().Equal([("c1", 0, 6, PlainText("ar", "c1")[..6], 3)]);
        (await GetAsync(api.GuestClient(), articleId, "ar-EG"))["popular"]!.AsArray().Should().HaveCount(5, "the shared copy never holds a viewer's mutes");
        (await GetAsync(viewer.Client, articleId, "ar-EG"))["popular"]!.AsArray().Should().HaveCount(1);

        // A third reader on p3 makes it popular (sixth in line, so not shown yet); the cached copy is dropped on every
        // highlight change, so removing one of three readers drops a range at once.
        await MarkAsync(d, articleId, "ar", "p3", 16, 27);
        (await GetAsync(api.GuestClient(), articleId, "ar-EG"))["popular"]!.AsArray().Select(p => p!["blockId"]!.GetValue<string>())
            .Should().Equal("c1", "s1", "h1", "p1", "p2");
        var cMine = (await GetAsync(c.Client, articleId, "ar-EG"))["mine"]!.AsArray();
        foreach (var h in cMine.Where(h => h!["blockId"]!.GetValue<string>() != "c1"))
            (await c.Client.DeleteAsync($"/api/v1/highlights/{h!["id"]!.GetValue<Guid>()}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await GetAsync(api.GuestClient(), articleId, "ar-EG"))["popular"]!.AsArray().Select(p => (p!["blockId"]!.GetValue<string>(), p["count"]!.GetValue<int>()))
            .Should().Equal(("c1", 4), ("p3", 3));
    }

    [Fact]
    public async Task An_update_hides_highlights_whose_text_moved_and_the_next_write_deletes_them()
    {
        var (articleId, _, author) = await PublishFixtureArticleAsync();
        var readers = new[] { await api.UserAsync(), await api.UserAsync(), await api.UserAsync() };
        foreach (var reader in readers)
        {
            await MarkAsync(reader, articleId, "ar", "p1", 15, 27); // "ASP.NET Core"
            await MarkAsync(reader, articleId, "ar", "p4", 0, 6);   // "خلّصنا"
        }
        (await GetAsync(api.GuestClient(), articleId, "ar-EG"))["popular"]!.AsArray().Should().HaveCount(2);

        // The author rewrites p1 (its text moves) and leaves p4 alone.
        var edit = await author.Client.EditAsync(articleId);
        var document = edit["document"]!.AsObject();
        var arBlocks = document["translations"]!.AsArray().Single(t => t!["language"]!.GetValue<string>() == "ar-EG")!["content"]!["blocks"]!.AsArray();
        arBlocks.Single(b => b!["id"]!.GetValue<string>() == "p1")!["content"] = new JsonArray(new JsonObject { ["type"] = "text", ["text"] = "كلام جديد خالص عن ASP.NET Core." });
        (await author.Client.SaveDraftAsync(articleId, edit["version"]!.GetValue<int>(), document)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await author.Client.PublishCurrentAsync(articleId)).StatusCode.Should().Be(HttpStatusCode.OK);

        var first = readers[0];
        (await GetAsync(first.Client, articleId, "ar-EG"))["mine"]!.AsArray().Select(h => h!["blockId"]!.GetValue<string>()).Should().Equal(["p4"]);
        (await GetAsync(api.GuestClient(), articleId, "ar-EG"))["popular"]!.AsArray().Select(p => p!["blockId"]!.GetValue<string>())
            .Should().Equal(["p4"], "the moved range is no longer popular");
        var group = (await first.Client.GetAsync("/api/v1/me/highlights", Ct).OkJsonAsync())["items"]!.AsArray()
            .Single(g => g!["article"]!["id"]!.GetValue<Guid>() == articleId)!;
        group["highlights"]!.AsArray().Select(h => h!["blockId"]!.GetValue<string>()).Should().Equal(["p4"]);

        // The same offsets on the new text are a new range; writing deletes the stale highlight.
        var newText = "كلام جديد خالص عن ASP.NET Core.";
        var marked = await PostAsync(first.Client, articleId, "ar-EG", "p1", 15, 27, newText[15..27]).OkOrCreatedAsync();
        marked["highlight"]!["text"]!.GetValue<string>().Should().Be(newText[15..27]);
        marked["replacedIds"]!.AsArray().Should().BeEmpty("a stale highlight is not joined");
        (await InDbAsync(db => db.ArticleHighlights.Where(h => h.UserId == first.Id && h.ArticleId == articleId).Select(h => h.Text).ToListAsync(Ct)))
            .Should().BeEquivalentTo([newText[15..27], "خلّصنا"]);
    }

    [Fact]
    public async Task The_limit_is_100_per_article_across_both_versions_and_stale_ones_dont_count()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();
        var p1 = PlainText("ar", "p1");
        var e1 = PlainText("en", "e1");
        await InDbAsync(async db =>
        {
            var now = DateTime.UtcNow;
            for (var i = 0; i < 60; i++) db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, articleId, "ar-EG", "p1", i, i + 3, p1[i..(i + 3)], now));
            for (var i = 0; i < 39; i++) db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, articleId, "en", "e1", i, i + 3, e1[i..(i + 3)], now));
            db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, articleId, "ar-EG", "p2", 0, 5, "stale", now)); // an Update moved it
            return await db.SaveChangesAsync(Ct);
        });

        var made = await MarkAsync(reader, articleId, "ar", "p4", 0, 6);
        made["replacedIds"]!.AsArray().Should().BeEmpty();
        (await InDbAsync(db => db.ArticleHighlights.CountAsync(h => h.UserId == reader.Id && h.ArticleId == articleId, Ct)))
            .Should().Be(100, "the stale one went, the new one came");

        await PostAsync(reader.Client, articleId, "ar-EG", "h1", 0, 4, PlainText("ar", "h1")[..4]).ProblemAsync(HttpStatusCode.BadRequest, "highlight.limit");
        await PostAsync(reader.Client, articleId, "en", "e4", 4, 13, "Two words").ProblemAsync(HttpStatusCode.BadRequest, "highlight.limit");
        // Joining doesn't add one: a range overlapping yours is still allowed at the limit.
        (await MarkAsync(reader, articleId, "ar", "p4", 3, 12))["replacedIds"]!.AsArray().Should().HaveCount(1);
    }

    [Fact]
    public async Task The_limit_leaves_out_highlights_an_update_hid_in_the_other_version()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();
        var p1 = PlainText("ar", "p1");
        var e1 = PlainText("en", "e1");
        await InDbAsync(async db =>
        {
            var now = DateTime.UtcNow;
            for (var i = 0; i < 60; i++) db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, articleId, "ar-EG", "p1", i, i + 3, p1[i..(i + 3)], now));
            for (var i = 0; i < 39; i++) db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, articleId, "en", "e1", i, i + 3, e1[i..(i + 3)], now));
            db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, articleId, "en", "e2", 0, 5, "stale", now)); // an Update moved it
            return await db.SaveChangesAsync(Ct);
        });

        // 99 still show: the hidden English one doesn't count, though this write is in the Arabic version.
        var made = await MarkAsync(reader, articleId, "ar", "p4", 0, 6);
        made["replacedIds"]!.AsArray().Should().BeEmpty();
        (await InDbAsync(db => db.ArticleHighlights.CountAsync(h => h.UserId == reader.Id && h.ArticleId == articleId, Ct)))
            .Should().Be(101, "the hidden English one stays until you highlight in that version");

        // Now 100 show: full, in either version.
        await PostAsync(reader.Client, articleId, "ar-EG", "h1", 0, 4, PlainText("ar", "h1")[..4]).ProblemAsync(HttpStatusCode.BadRequest, "highlight.limit");
        await PostAsync(reader.Client, articleId, "en", "e4", 4, 13, "Two words").ProblemAsync(HttpStatusCode.BadRequest, "highlight.limit");
    }

    [Fact]
    public async Task Saved_highlights_group_by_article_version_newest_first_with_a_stable_cursor()
    {
        var (first, firstSlug, author) = await PublishFixtureArticleAsync();
        var (second, _, _) = await PublishFixtureArticleAsync();
        var (third, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();

        await MarkAsync(reader, first, "ar", "p1", 0, 6);
        await MarkAsync(reader, second, "en", "e1", 0, 3);
        await MarkAsync(reader, first, "en", "e2", 0, 9);
        await MarkAsync(reader, third, "ar", "p4", 0, 6);
        await MarkAsync(reader, first, "ar", "p4", 0, 6); // first/ar-EG moves to the top

        var groups = new List<JsonObject>();
        string? cursor = null;
        do
        {
            var page = await reader.Client.GetAsync($"/api/v1/me/highlights?limit=1&cursor={Uri.EscapeDataString(cursor ?? "")}", Ct).OkJsonAsync();
            page["items"]!.AsArray().Should().HaveCount(1);
            groups.Add(page["items"]![0]!.AsObject());
            cursor = page["nextCursor"]?.GetValue<string>();
        } while (cursor is not null);

        groups.Select(g => (g["article"]!["id"]!.GetValue<Guid>(), g["article"]!["language"]!.GetValue<string>()))
            .Should().Equal((first, "ar-EG"), (third, "ar-EG"), (first, "en"), (second, "en"));
        var top = groups[0];
        top["article"]!["slug"]!.GetValue<string>().Should().Be(firstSlug);
        top["article"]!["title"]!.GetValue<string>().Should().Be("مقال فيه Highlights");
        top["article"]!["author"]!["id"]!.GetValue<Guid>().Should().Be(author.Id);
        top["highlights"]!.AsArray().Select(h => h!["blockId"]!.GetValue<string>()).Should().Equal(["p4", "p1"], "newest first");
        top["latestAt"]!.GetValue<DateTime>().Should().Be(top["highlights"]![0]!["createdAt"]!.GetValue<DateTime>());
        groups[2]["article"]!["title"]!.GetValue<string>().Should().Be("An article with highlights", "the version's own title");

        // Articles readers can't open drop out.
        (await author.Client.DeleteAsync($"/api/v1/articles/{first}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var after = await reader.Client.GetAsync("/api/v1/me/highlights", Ct).OkJsonAsync();
        after["items"]!.AsArray().Select(g => g!["article"]!["id"]!.GetValue<Guid>()).Should().Equal(third, second);
        after["nextCursor"].Should().BeNull();
        (await api.GuestClient().GetAsync("/api/v1/me/highlights", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Saved_highlights_come_in_the_order_of_the_latestAt_they_return_also_when_an_update_hid_the_newest()
    {
        var (first, _, _) = await PublishFixtureArticleAsync();
        var (second, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync();
        var p4 = PlainText("ar", "p4");
        await InDbAsync(async db =>
        {
            var now = DateTime.UtcNow;
            db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, first, "ar-EG", "p4", 0, 6, p4[..6], now.AddHours(-3)));
            db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, first, "ar-EG", "p2", 0, 5, "stale", now.AddHours(-1))); // an Update moved it
            db.ArticleHighlights.Add(ArticleHighlight.Create(reader.Id, second, "ar-EG", "p4", 0, 6, p4[..6], now.AddHours(-2)));
            return await db.SaveChangesAsync(Ct);
        });

        var groups = new List<JsonObject>();
        string? cursor = null;
        do
        {
            var page = await reader.Client.GetAsync($"/api/v1/me/highlights?limit=1&cursor={Uri.EscapeDataString(cursor ?? "")}", Ct).OkJsonAsync();
            groups.AddRange(page["items"]!.AsArray().Select(g => g!.AsObject()));
            cursor = page["nextCursor"]?.GetValue<string>();
        } while (cursor is not null);

        groups.Select(g => g["article"]!["id"]!.GetValue<Guid>()).Should().Equal(first, second);
        var latest = groups.Select(g => g["latestAt"]!.GetValue<DateTime>()).ToList();
        latest.Should().BeInDescendingOrder("the groups come in the order of the latestAt they return");
        groups[0]["highlights"]!.AsArray().Select(h => h!["blockId"]!.GetValue<string>()).Should().Equal(["p4"], "the hidden one isn't listed");
        latest[0].Should().BeAfter(groups[0]["highlights"]![0]!["createdAt"]!.GetValue<DateTime>(), "the hidden one still places its group");
    }

    [Fact]
    public async Task Saved_highlights_load_a_page_of_article_versions_in_one_query_then_from_the_cache()
    {
        var articles = new List<Guid>();
        for (var i = 0; i < 3; i++) articles.Add((await PublishFixtureArticleAsync()).Id);
        var versions = articles.SelectMany(id => new (Guid ArticleId, string Language)[] { (id, "ar-EG"), (id, "en") }).ToList();

        using var scope = api.Services.CreateScope();
        var counter = new CommandCounter();
        var connection = scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.GetConnectionString()!;
        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer(connection, sql => sql.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery))
            .AddInterceptors(counter)
            .Options);
        var texts = new HighlightTexts(db, scope.ServiceProvider.GetRequiredService<HybridCache>());

        var loaded = await texts.GetVersionsAsync([.. versions, (Guid.NewGuid(), "en")], Ct);
        counter.Commands.Should().Be(1, "every version of the page in one query, not one per group");
        loaded.Keys.Should().BeEquivalentTo(versions, "an unknown article is left out");
        loaded[(articles[0], "ar-EG")].Find("p1")!.Text.Should().Be(PlainText("ar", "p1"));
        loaded[(articles[2], "en")].Find("e1")!.Text.Should().Be(PlainText("en", "e1"));

        // Cached now, for the list and the reader alike.
        (await texts.GetVersionsAsync(versions, Ct)).Should().HaveCount(6);
        (await texts.GetVersionAsync(articles[1], "en", Ct))!.Language.Should().Be("en");
        counter.Commands.Should().Be(1, "the second read comes from the cache");
    }

    /// <summary>Counts the SQL commands one context runs.</summary>
    private sealed class CommandCounter : DbCommandInterceptor
    {
        private int _commands;

        public int Commands => _commands;

        public override InterceptionResult<DbDataReader> ReaderExecuting(DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result)
        {
            Interlocked.Increment(ref _commands);
            return result;
        }

        public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(
            DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result, CancellationToken cancellationToken = default)
        {
            Interlocked.Increment(ref _commands);
            return ValueTask.FromResult(result);
        }
    }

    [Fact]
    public async Task Show_highlights_is_a_synced_preference_that_defaults_on()
    {
        var user = await api.UserAsync();
        user.Me["showHighlights"]!.GetValue<bool>().Should().BeTrue();
        var preferences = new { uiLanguage = "ar", articleLanguage = "ar-EG", theme = "dark", timeZone = "Africa/Cairo", reminderTime = "07:30" };

        (await user.Client.PutAsJsonAsync("/api/v1/me/preferences", new { preferences.uiLanguage, preferences.articleLanguage, preferences.theme,
            preferences.timeZone, preferences.reminderTime, showHighlights = false }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.GetAsync("/api/v1/me", Ct).OkJsonAsync())["showHighlights"]!.GetValue<bool>().Should().BeFalse();

        (await user.Client.PutAsJsonAsync("/api/v1/me/preferences", preferences, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var me = await user.Client.GetAsync("/api/v1/me", Ct).OkJsonAsync();
        (me["showHighlights"]!.GetValue<bool>(), me["theme"]!.GetValue<string>()).Should().Be((false, "dark"), "left out keeps it");

        (await user.Client.PutAsJsonAsync("/api/v1/me/preferences", new { preferences.uiLanguage, preferences.articleLanguage, preferences.theme,
            preferences.timeZone, preferences.reminderTime, showHighlights = true }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.GetAsync("/api/v1/me", Ct).OkJsonAsync())["showHighlights"]!.GetValue<bool>().Should().BeTrue();
    }

    [Fact]
    public async Task Deleting_an_account_deletes_its_highlights_and_their_share_of_popular_at_once()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var readers = new[] { await api.UserAsync(), await api.UserAsync(), await api.UserAsync() };
        foreach (var reader in readers) await MarkAsync(reader, articleId, "en", "e2", 0, 9);
        (await GetAsync(api.GuestClient(), articleId, "en"))["popular"]![0]!["count"]!.GetValue<int>().Should().Be(3);

        var leaving = readers[0];
        (await leaving.Client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { password = ApiFactory.TestPassword }) }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await InDbAsync(db => db.ArticleHighlights.CountAsync(h => h.UserId == leaving.Id, Ct))).Should().Be(0);
        (await GetAsync(api.GuestClient(), articleId, "en"))["popular"]!.AsArray().Should().BeEmpty("2 readers are left");
        (await InDbAsync(db => db.ArticleHighlights.CountAsync(h => h.ArticleId == articleId, Ct))).Should().Be(2, "other readers' highlights stay");
    }

    [Fact]
    public async Task Highlight_writes_share_the_writes_limit_and_reading_is_unthrottled()
    {
        var (articleId, _, _) = await PublishFixtureArticleAsync();
        var user = await api.SignUpAsync(); // no write yet
        var statuses = new List<HttpStatusCode>();
        for (var i = 0; i < 31; i++)
            statuses.Add((await PostAsync(user.Client, articleId, "ar-EG", "p4", 0, 6, PlainText("ar", "p4")[..6])).StatusCode);

        statuses[0].Should().Be(HttpStatusCode.Created);
        statuses.Skip(1).Take(29).Should().OnlyContain(s => s == HttpStatusCode.OK, "the same range again changes nothing");
        statuses[30].Should().Be(HttpStatusCode.TooManyRequests);
        await user.Client.DeleteAsync($"/api/v1/highlights/{Guid.NewGuid()}", Ct).ProblemAsync(HttpStatusCode.TooManyRequests, "rate_limited");
        (await user.Client.GetAsync($"/api/v1/articles/{articleId}/highlights", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await user.Client.GetAsync("/api/v1/me/highlights", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Members_hold_the_highlight_permission_and_openapi_describes_the_endpoints()
    {
        var member = await api.UserAsync();
        (await member.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["permissions"]!.AsArray()
            .Select(p => p!.GetValue<string>()).Should().Contain("highlights.create");

        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();
        document["paths"]!.AsObject().Select(p => p.Key).Should().Contain(
            ["/api/v1/articles/{id}/highlights", "/api/v1/highlights/{id}", "/api/v1/me/highlights"]);
        var schemas = document["components"]!["schemas"]!;
        schemas["ArticleHighlightsDto"]!["properties"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("articleId", "language", "mine", "popular");
        schemas["PopularHighlightDto"]!["properties"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("blockId", "startOffset", "endOffset", "text", "count");
        schemas["HighlightCreatedDto"]!["properties"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("highlight", "replacedIds");
        schemas["HighlightGroupDto"]!["properties"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("article", "highlights", "latestAt");
    }
}

/// <summary>The F30 problem titles, in both languages (no server needed).</summary>
public sealed class HighlightErrorTitlesTests
{
    [Theory]
    [InlineData("highlight.text_mismatch", "النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.", "This text has changed in the article. Reload and try again.")]
    [InlineData("highlight.block_not_allowed", "مينفعش تعمل Highlight للجزء ده.", "This part can't be highlighted.")]
    [InlineData("highlight.too_short", "اختار 3 حروف على الأقل.", "Select at least 3 characters.")]
    [InlineData("highlight.too_long", "الـ Highlight لازم يكون 1000 حرف أو أقل.", "A highlight can be at most 1,000 characters.")]
    [InlineData("highlight.limit", "وصلت لأقصى عدد Highlights في المقال ده (100).", "You can have at most 100 highlights in one article.")]
    [InlineData("highlight.not_found", "الـ Highlight ده مش موجود.", "Highlight not found.")]
    public void Highlight_codes_have_the_contract_titles(string code, string arabic, string english)
    {
        ErrorMessages.Title(code, "ar").Should().Be(arabic);
        ErrorMessages.Title(code, "en").Should().Be(english);
    }
}

internal static class HighlightTestKit
{
    /// <summary>201 (made) or 200 (already inside one of yours): both carry a <c>HighlightCreatedDto</c>.</summary>
    public static async Task<JsonObject> OkOrCreatedAsync(this Task<HttpResponseMessage> request)
    {
        var response = await request;
        var body = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        response.StatusCode.Should().BeOneOf([HttpStatusCode.Created, HttpStatusCode.OK], body);
        return JsonNode.Parse(body)!.AsObject();
    }
}
