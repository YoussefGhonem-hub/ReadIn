using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Search;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Search;
using static ReadIn.Api.IntegrationTests.ArticleTestKit;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F16 search (contract-v1 "Search"): where articles match (title, text, attached PDF), Arabic normalization, filters,
/// visibility, ranking and paging; people, topics and tags; suggestions, errors and the rate limit. The suite runs on
/// SQL Server with Full-Text Search, and the article cases run again on the LIKE fallback.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class SearchTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private SearchEngineState Engine => api.Services.GetRequiredService<SearchEngineState>();

    /// <summary>A unique lower-case word (letters and digits), so every test finds only what it wrote.</summary>
    private static string Unique() => $"srch{Guid.NewGuid():N}"[..14];

    [Fact]
    public void The_full_text_engine_is_used_when_the_server_has_it()
    {
        if (Environment.GetEnvironmentVariable("READIN_TESTS_SQL_IMAGE") is { Length: > 0 }) return; // another image: either engine
        Engine.Kind.Should().Be(SearchEngineKind.FullText, "the test image (docker/sqlserver) has Full-Text Search");
    }

    [Fact]
    public Task Articles_match_in_the_title_the_text_and_the_attached_pdf() => OnBothEnginesAsync(async () =>
    {
        var m = Unique();
        var writer = await api.UserAsync("Search Writer");
        var reader = await api.UserAsync("Search Reader");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var inTitle = await writer.Client.WriteAndPublishAsync(Document(field, $"A guide to {m} for teams", blocks: [Paragraph("Nothing to see.")]));
        var inText = await writer.Client.WriteAndPublishAsync(Document(field, "Other things to know", blocks: [Paragraph($"A deep dive into {m} today.")]));

        // The fixture PDF holds readinmarker1 … readinmarker12 (tests/fixtures/media).
        var (withPdf, pdfAsset) = await PublishWithPdfAsync(writer.Client, field, $"Inspection notes {Unique()}");
        var (draftWithPdf, draftAsset) = await DraftWithPdfAsync(writer.Client, field);
        var unattached = await UploadPdfAsync(writer.Client);
        await IndexedAsync(inTitle.Id, m);
        await IndexedAsync(inText.Id, m);
        await DocumentIndexedAsync(pdfAsset, "readinmarker7");
        await DocumentIndexedAsync(draftAsset, "readinmarker7");
        await DocumentIndexedAsync(unattached, "readinmarker7");

        var page = await SearchAsync(reader.Client, $"q={m}");
        Ids(page).Should().Equal([inTitle.Id, inText.Id], "a title hit (1.0) outranks a text hit (0.6)");
        MatchedIn(page, inTitle.Id).Should().Be("title");
        MatchedIn(page, inText.Id).Should().Be("text");
        var card = Item(page, inTitle.Id)["article"]!;
        card["slug"]!.GetValue<string>().Should().Be(inTitle.Slug);
        card["author"]!["displayName"]!.GetValue<string>().Should().Be("Search Writer");

        var pdf = await SearchAsync(reader.Client, "q=readinmarker7&limit=50");
        Ids(pdf).Should().Contain(withPdf).And.NotContain(draftWithPdf, "a PDF of an unpublished post is never searched");
        MatchedIn(pdf, withPdf).Should().Be("attachment");
        Item(pdf, withPdf)["article"]!["attachments"]!["kind"]!.GetValue<string>().Should().Be("document");
    });

    [Fact]
    public Task Arabic_queries_ignore_hamza_taa_marbuta_diacritics_and_tatweel() => OnBothEnginesAsync(async () =>
    {
        var m = Unique();
        var writer = await api.UserAsync("كاتب البحث");
        var reader = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var article = await writer.Client.WriteAndPublishAsync(Document(
            field, $"مكتبة أحمد للمبتدئين {m}", "ar-EG", [Paragraph($"مقدمة عن الذكاء الاصطناعي في الطب {m}")]));
        await IndexedAsync(article.Id, m);

        foreach (var q in new[] { $"مكتبه احمد {m}", $"مَكْتَبَةُ {m}", $"مكتبــة {m}", $"أحمد {m}" })
        {
            var page = await SearchAsync(reader.Client, $"q={Uri.EscapeDataString(q)}");
            Ids(page).Should().Equal([article.Id], q);
            MatchedIn(page, article.Id).Should().Be("title", q);
        }

        var withoutArticle = await SearchAsync(reader.Client, $"q={Uri.EscapeDataString($"ذكاء {m}")}");
        Ids(withoutArticle).Should().Equal([article.Id], "ذكاء also finds الذكاء");
        MatchedIn(withoutArticle, article.Id).Should().Be("text");
        Item(withoutArticle, article.Id)["article"]!["language"]!.GetValue<string>().Should().Be("ar-EG");
    });

    [Fact]
    public Task A_title_hit_follows_the_engines_word_rule() => OnBothEnginesAsync(async () =>
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var english = await writer.Client.WriteAndPublishAsync(Document(field, $"Internet basics {m}", blocks: [Paragraph("Networks explained.")]));
        var arabic = await writer.Client.WriteAndPublishAsync(Document(field, $"تعلم بالذكاء {m}", "ar-EG", [Paragraph("نص قصير.")]));
        await IndexedAsync(english.Id, m);
        await IndexedAsync(arabic.Id, m);

        // "net" starts "Networks" in the text; in the title it is only inside "Internet", which the LIKE fallback also counts.
        var net = await SearchAsync(reader.Client, $"q=net%20{m}");
        Ids(net).Should().Equal([english.Id]);
        MatchedIn(net, english.Id).Should().Be(Engine.Kind == SearchEngineKind.FullText ? "text" : "title", Engine.Kind.ToString());

        // The Arabic word breaker finds ذكاء behind بال, and so does the title check.
        var ai = await SearchAsync(reader.Client, $"q={Uri.EscapeDataString($"ذكاء {m}")}");
        Ids(ai).Should().Equal([arabic.Id]);
        MatchedIn(ai, arabic.Id).Should().Be("title", Engine.Kind.ToString());
    });

    [Fact]
    public Task Filters_keep_the_field_the_language_and_the_reading_time() => OnBothEnginesAsync(async () =>
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var dotnet = await writer.Client.FieldIdAsync("dotnet");
        var ml = await writer.Client.FieldIdAsync("machine-learning");
        var english = await writer.Client.WriteAndPublishAsync(Document(dotnet, $"Short english {m}"));
        var arabic = await writer.Client.WriteAndPublishAsync(Document(ml, $"مقال قصير {m}", "ar-EG", [Paragraph("نص قصير.")]));
        var longText = Enumerable.Range(0, 13)
            .Select(p => Paragraph(string.Join(' ', Enumerable.Range(0, 200).Select(i => $"word{p}x{i}")), $"p{p}"))
            .ToArray();
        var longOne = await writer.Client.WriteAndPublishAsync(Document(dotnet, $"Long english {m}", blocks: longText));
        foreach (var id in new[] { english.Id, arabic.Id, longOne.Id }) await IndexedAsync(id, m);

        var all = await SearchAsync(reader.Client, $"q={m}");
        Ids(all).Should().BeEquivalentTo([english.Id, arabic.Id, longOne.Id]);
        var longMinutes = Item(all, longOne.Id)["article"]!["readingTimeMinutes"]!.GetValue<int>();
        longMinutes.Should().BeGreaterThan(10);

        Ids(await SearchAsync(reader.Client, $"q={m}&lang=en")).Should().BeEquivalentTo([english.Id, longOne.Id]);
        Ids(await SearchAsync(reader.Client, $"q={m}&lang=ar-EG")).Should().Equal([arabic.Id]);
        Ids(await SearchAsync(reader.Client, $"q={m}&field=machine-learning")).Should().Equal([arabic.Id]);
        Ids(await SearchAsync(reader.Client, $"q={m}&field=no-such-field")).Should().BeEmpty();
        Ids(await SearchAsync(reader.Client, $"q={m}&maxMinutes=5")).Should().BeEquivalentTo([english.Id, arabic.Id]);
        Ids(await SearchAsync(reader.Client, $"q={m}&minMinutes=11")).Should().Equal([longOne.Id]);
        Ids(await SearchAsync(reader.Client, $"q={m}&minMinutes=6&maxMinutes=10")).Should().BeEmpty();
    });

    [Fact]
    public Task A_card_comes_in_the_version_that_matched() => OnBothEnginesAsync(async () =>
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var document = Document(field, $"English version {m}");
        document["translations"]!.AsArray().Add(JsonSerializerHelper.ToNode(new
        {
            language = "ar-EG",
            title = $"النسخة العربية {m}",
            subtitle = (string?)null,
            content = new { version = 1, language = "ar-EG", blocks = new[] { Paragraph("نص عربي.") } },
        }));
        var article = await writer.Client.WriteAndPublishAsync(document);
        await IndexedAsync(article.Id, m);
        await IndexedAsync(article.Id, "العربيه");
        var preferred = (await reader.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["articleLanguage"]!.GetValue<string>();

        Language(await SearchAsync(reader.Client, $"q={Uri.EscapeDataString($"العربية {m}")}"), article.Id).Should().Be("ar-EG");
        Language(await SearchAsync(reader.Client, $"q={Uri.EscapeDataString($"english {m}")}"), article.Id).Should().Be("en");
        Language(await SearchAsync(reader.Client, $"q={m}"), article.Id).Should().Be(preferred, "both matched: the caller's article language");
        Language(await SearchAsync(reader.Client, $"q={m}&lang=en"), article.Id).Should().Be("en");
    });

    [Fact]
    public Task Hidden_deleted_and_unpublished_articles_are_never_found() => OnBothEnginesAsync(async () =>
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var visible = await writer.Client.WriteAndPublishAsync(Document(field, $"Visible {m}"));
        var hidden = await writer.Client.WriteAndPublishAsync(Document(field, $"Hidden {m}"));
        var deleted = await writer.Client.WriteAndPublishAsync(Document(field, $"Deleted {m}"));
        var draft = (await writer.Client.CreateDraftAsync(Document(field, $"Draft {m}")))["id"]!.GetValue<Guid>();
        foreach (var id in new[] { visible.Id, hidden.Id, deleted.Id }) await IndexedAsync(id, m);

        await InDbAsync(db => db.Articles.Where(a => a.Id == hidden.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(a => a.HiddenAt, DateTime.UtcNow), Ct));
        (await writer.Client.DeleteAsync($"/api/v1/articles/{deleted.Id}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        Ids(await SearchAsync(writer.Client, $"q={m}")).Should().Equal([visible.Id], "hidden articles are left out even for their author");
        Ids(await SearchAsync(api.GuestClient(), $"q={m}")).Should().Equal([visible.Id]);
        Ids(await SearchAsync(writer.Client, $"q={m}")).Should().NotContain(draft);
    });

    [Fact]
    public async Task Pages_follow_the_cursor_without_repeats()
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var ids = new List<Guid>();
        for (var i = 0; i < 3; i++) ids.Add((await writer.Client.WriteAndPublishAsync(Document(field, $"Paging {i} {m}"))).Id);
        foreach (var id in ids) await IndexedAsync(id, m);

        var first = await SearchAsync(reader.Client, $"q={m}&limit=2");
        Ids(first).Should().HaveCount(2);
        var cursor = first["nextCursor"]!.GetValue<string>();
        var second = await SearchAsync(reader.Client, $"q={m}&limit=2&cursor={Uri.EscapeDataString(cursor)}");
        Ids(second).Should().HaveCount(1);
        second["nextCursor"].Should().BeNull();
        Ids(first).Concat(Ids(second)).Should().BeEquivalentTo(ids);

        Ids(await SearchAsync(reader.Client, $"q={m}&cursor=not-a-cursor")).Should().HaveCount(3, "a cursor that doesn't decode is the first page");
    }

    [Fact]
    public async Task Guests_get_cached_results_that_a_publish_refreshes()
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var first = await writer.Client.WriteAndPublishAsync(Document(field, $"First {m}"));
        await IndexedAsync(first.Id, m);
        var guest = api.GuestClient("ar");
        Ids(await SearchAsync(guest, $"q={m}")).Should().Equal([first.Id]);

        var second = await writer.Client.WriteAndPublishAsync(Document(field, $"Second {m}"));
        await IndexedAsync(second.Id, m);
        Ids(await SearchAsync(guest, $"q={m}")).Should().BeEquivalentTo([first.Id, second.Id], "publishing clears the guests' cache");
        var card = Item(await SearchAsync(guest, $"q={m}"), first.Id)["article"]!;
        card["myReaction"].Should().BeNull();
        card["isSaved"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task People_are_found_by_name_and_username_exact_matches_first()
    {
        var m = Unique();
        var reader = await api.UserAsync();
        var exact = await api.UserAsync(m);
        var byHandle = await api.SignUpAsync();
        (await byHandle.Client.PutAsJsonAsync("/api/v1/me/profile/complete", new { displayName = "Handle Owner", username = $"{m}_h" }, Ct))
            .EnsureSuccessStatusCode();
        var byWord = await api.UserAsync($"Zed {m}");
        var suspended = await api.UserAsync($"Suspended {m}");
        await InDbAsync(db => db.Users.Where(u => u.Id == suspended.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.IsSuspended, true), Ct));
        var incomplete = await api.SignUpAsync();

        var page = await SearchAsync(reader.Client, $"q={m}&type=users");
        var ids = page["items"]!.AsArray().Select(u => u!["id"]!.GetValue<Guid>()).ToList();
        ids.Should().Equal([exact.Id, byHandle.Id, byWord.Id], "exact name, then a username prefix, then a word; never a suspended account");
        page["items"]![0]!["isFollowing"]!.GetValue<bool>().Should().BeFalse();
        page["items"]![0]!["username"]!.GetValue<string>().Should().Be(exact.Me["username"]!.GetValue<string>());

        var handle = exact.Me["username"]!.GetValue<string>();
        (await SearchAsync(reader.Client, $"q=%40{handle}&type=users"))["items"]![0]!["id"]!.GetValue<Guid>().Should().Be(exact.Id);
        var placeholder = incomplete.Me["username"]!.GetValue<string>();
        (await SearchAsync(reader.Client, $"q={placeholder}&type=users"))["items"]!.AsArray().Should().BeEmpty("an unfinished profile isn't listed");

        (await reader.Client.PutAsync($"/api/v1/users/{byWord.Id}/follow", null, Ct)).EnsureSuccessStatusCode();
        var followed = (await SearchAsync(reader.Client, $"q={Uri.EscapeDataString($"zed {m}")}&type=users"))["items"]![0]!;
        followed["id"]!.GetValue<Guid>().Should().Be(byWord.Id);
        followed["isFollowing"]!.GetValue<bool>().Should().BeTrue();
    }

    [Fact]
    public async Task Topics_and_fields_match_their_arabic_and_english_names_and_slugs()
    {
        var reader = await api.UserAsync();

        var evaluation = (await SearchAsync(reader.Client, $"q={Uri.EscapeDataString("موديلات")}&type=topics"))["items"]!.AsArray();
        var topic = evaluation.Single(t => t!["topicSlug"]?.GetValue<string>() == "model-evaluation")!;
        topic["kind"]!.GetValue<string>().Should().Be("topic");
        topic["fieldSlug"]!.GetValue<string>().Should().Be("machine-learning");
        topic["name"]!.GetValue<string>().Should().Be("Model Evaluation", "Accept-Language: en");
        topic["nameAr"]!.GetValue<string>().Should().Be("تقييم الموديلات");
        topic["fieldName"]!.GetValue<string>().Should().Be("Machine Learning");
        topic["icon"]!.GetValue<string>().Should().NotBeNullOrEmpty();

        var field = (await SearchAsync(reader.Client, "q=machine%20learning&type=topics"))["items"]![0]!;
        field["kind"]!.GetValue<string>().Should().Be("field", "the exact name first, and fields before topics");
        field["fieldSlug"]!.GetValue<string>().Should().Be("machine-learning");
        field["topicSlug"].Should().BeNull();
        field["articleCount"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(0);

        var arabicUi = await api.UserAsync();
        arabicUi.Client.DefaultRequestHeaders.AcceptLanguage.Clear();
        arabicUi.Client.DefaultRequestHeaders.AcceptLanguage.ParseAdd("ar");
        (await SearchAsync(arabicUi.Client, "q=dotnet&type=topics"))["items"]!.AsArray()
            .Should().Contain(t => t!["fieldSlug"]!.GetValue<string>() == "dotnet" && t["kind"]!.GetValue<string>() == "field", "the slug matches too");
    }

    [Fact]
    public async Task Tags_are_found_unless_hidden_or_empty()
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        await writer.Client.WriteAndPublishAsync(Document(field, $"Tagged {m}", tags: [$"{m} Basics", $"{m}-hidden"]));
        var gone = await writer.Client.WriteAndPublishAsync(Document(field, $"Gone {m}", tags: [$"{m} empty"]));
        (await writer.Client.DeleteAsync($"/api/v1/articles/{gone.Id}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await InDbAsync(db => db.Tags.Where(t => t.Name == $"{m}-hidden").ExecuteUpdateAsync(s => s.SetProperty(t => t.IsHidden, true), Ct));

        var tags = (await SearchAsync(writer.Client, $"q={m}&type=tags"))["items"]!.AsArray();
        tags.Select(t => t!["name"]!.GetValue<string>()).Should().Equal($"{m} Basics");
        tags[0]!["articleCount"]!.GetValue<int>().Should().Be(1);
        tags[0]!["slug"]!.GetValue<string>().Should().Be($"{m}-basics");

        (await SearchAsync(writer.Client, $"q=%23{m}%20basics&type=tags"))["items"]![0]!["name"]!.GetValue<string>()
            .Should().Be($"{m} Basics", "a leading # is dropped");
        (await SearchAsync(writer.Client, $"q=basics%20{m}&type=tags"))["items"]!.AsArray().Should().HaveCount(1, "every word, in any order");
    }

    [Fact]
    public async Task Suggestions_give_the_first_three_of_each_type()
    {
        var m = Unique();
        var writer = await api.UserAsync($"Suggest {m}");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var ids = new List<Guid>();
        for (var i = 0; i < 4; i++) ids.Add((await writer.Client.WriteAndPublishAsync(Document(field, $"Suggest {i} {m}", tags: [$"{m}tag"]))).Id);
        foreach (var id in ids) await IndexedAsync(id, m);

        var suggestions = await writer.Client.GetAsync($"/api/v1/search/suggest?q={m}", Ct).OkJsonAsync();
        suggestions["articles"]!.AsArray().Should().HaveCount(3);
        suggestions["articles"]![0]!["matchedIn"]!.GetValue<string>().Should().Be("title");
        suggestions["users"]!.AsArray().Select(u => u!["id"]!.GetValue<Guid>()).Should().Equal(writer.Id);
        suggestions["tags"]!.AsArray().Select(t => t!["name"]!.GetValue<string>()).Should().Equal($"{m}tag");
        suggestions["topics"]!.AsArray().Should().BeEmpty();

        await writer.Client.GetAsync("/api/v1/search/suggest?q=", Ct).ProblemAsync(HttpStatusCode.BadRequest, "search.query_invalid");
    }

    [Theory]
    [InlineData("q=", "search.query_invalid")]
    [InlineData("q=%20%20", "search.query_invalid")]
    [InlineData("q=%21%21%3F", "search.query_invalid")]
    [InlineData("q=%D9%80%D9%80", "search.query_invalid")] // tatweel only
    [InlineData("type=articles", "search.query_invalid")]
    [InlineData("q=docker&type=posts", "search.type_invalid")]
    [InlineData("q=docker&lang=fr", "search.filter_invalid")]
    [InlineData("q=docker&minMinutes=-1", "search.filter_invalid")]
    [InlineData("q=docker&maxMinutes=601", "search.filter_invalid")]
    [InlineData("q=docker&minMinutes=8&maxMinutes=3", "search.filter_invalid")]
    [InlineData("q=docker&minMinutes=abc", "request.invalid")]
    public async Task Bad_requests_have_their_codes(string query, string code)
    {
        var user = await api.UserAsync();
        await user.Client.GetAsync($"/api/v1/search?{query}", Ct).ProblemAsync(HttpStatusCode.BadRequest, code);
    }

    [Fact]
    public async Task A_query_longer_than_100_characters_is_refused()
    {
        var user = await api.UserAsync();
        await user.Client.GetAsync($"/api/v1/search?q={new string('a', 101)}", Ct).ProblemAsync(HttpStatusCode.BadRequest, "search.query_invalid");
        (await user.Client.GetAsync($"/api/v1/search?q={new string('a', 100)}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await user.Client.GetAsync($"/api/v1/search?q=%23%40{new string('a', 100)}", Ct)).StatusCode
            .Should().Be(HttpStatusCode.OK, "the leading # and @ are cleaned away before the length counts");
    }

    [Fact]
    public Task Query_syntax_and_wildcards_are_plain_text() => OnBothEnginesAsync(async () =>
    {
        var m = Unique();
        var writer = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var article = await writer.Client.WriteAndPublishAsync(Document(field, $"Plain {m}", blocks: [Paragraph("Exactly 100 percent sure.")]));
        await IndexedAsync(article.Id, m);

        foreach (var q in new[] { $"{m}\" OR \"a", $"{m} *", $"\"{m}\"", $"{m} AND NOT", $"{m} NEAR(a,b)", $"{m} [a-z]", $"({m}" })
        {
            var response = await writer.Client.GetAsync($"/api/v1/search?q={Uri.EscapeDataString(q)}", Ct);
            response.StatusCode.Should().Be(HttpStatusCode.OK, q);
        }

        Ids(await SearchAsync(writer.Client, $"q={Uri.EscapeDataString($"\"{m}\"")}")).Should().Equal([article.Id], "quotes are dropped, not syntax");
        Ids(await SearchAsync(writer.Client, $"q={Uri.EscapeDataString($"{m} 1_0%")}")).Should().BeEmpty("_ and % are not wildcards");
    });

    [Fact]
    public async Task Search_is_limited_to_60_requests_a_minute_per_user()
    {
        var user = await api.UserAsync();
        var statuses = new List<HttpStatusCode>();
        for (var i = 0; i < 61; i++)
            statuses.Add((await user.Client.GetAsync(i % 2 == 0 ? "/api/v1/search?q=" : "/api/v1/search/suggest?q=", Ct)).StatusCode);

        statuses.Take(60).Should().OnlyContain(s => s == HttpStatusCode.BadRequest, "both endpoints share the budget");
        statuses[60].Should().Be(HttpStatusCode.TooManyRequests);
        await user.Client.GetAsync("/api/v1/search?q=docker", Ct).ProblemAsync(HttpStatusCode.TooManyRequests, "rate_limited");
        (await (await api.UserAsync()).Client.GetAsync("/api/v1/search?q=docker", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "per user");
    }

    // ── helpers ──────────────────────────────────────────────────────────

    /// <summary>Runs <paramref name="body"/> on the engine startup chose, then again on the LIKE fallback.</summary>
    private async Task OnBothEnginesAsync(Func<Task> body)
    {
        await body();
        if (Engine.Kind == SearchEngineKind.Like) return;

        Engine.Kind = SearchEngineKind.Like;
        try
        {
            await body();
        }
        finally
        {
            Engine.Kind = SearchEngineKind.FullText;
        }
    }

    private static async Task<JsonObject> SearchAsync(HttpClient client, string query) =>
        await client.GetAsync($"/api/v1/search?{query}", Ct).OkJsonAsync();

    private static List<Guid> Ids(JsonObject page) =>
        page["items"]!.AsArray().Select(i => i!["article"]!["id"]!.GetValue<Guid>()).ToList();

    private static JsonNode Item(JsonObject page, Guid articleId) =>
        page["items"]!.AsArray().Single(i => i!["article"]!["id"]!.GetValue<Guid>() == articleId)!;

    private static string MatchedIn(JsonObject page, Guid articleId) => Item(page, articleId)["matchedIn"]!.GetValue<string>();

    private static string Language(JsonObject page, Guid articleId) => Item(page, articleId)["article"]!["language"]!.GetValue<string>();

    private static byte[] Pdf() => File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "normal-12-pages.pdf"));

    /// <summary>POST /uploads/documents; Hangfire is off in tests, so the PDF is processed (text extracted) before it answers.</summary>
    private static async Task<Guid> UploadPdfAsync(HttpClient client)
    {
        using var form = new MultipartFormDataContent();
        var file = new ByteArrayContent(Pdf());
        file.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream");
        form.Add(file, "file", "Search Report.pdf");
        var response = await client.PostAsync("/api/v1/uploads/documents", form, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Accepted, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
    }

    private static async Task<(Guid ArticleId, Guid AssetId)> PublishWithPdfAsync(HttpClient client, Guid field, string title)
    {
        var (articleId, assetId) = await DraftWithPdfAsync(client, field, title);
        (await client.PublishCurrentAsync(articleId)).StatusCode.Should().Be(HttpStatusCode.OK);
        return (articleId, assetId);
    }

    private static async Task<(Guid ArticleId, Guid AssetId)> DraftWithPdfAsync(HttpClient client, Guid field, string title = "A draft with a PDF")
    {
        var assetId = await UploadPdfAsync(client);
        var articleId = (await client.CreateDraftAsync(Document(field, title)))["id"]!.GetValue<Guid>();
        var saved = await client.SetDraftAttachmentsAsync(articleId, new { mediaAssetId = assetId, order = 0, title = "Search report" });
        saved.StatusCode.Should().Be(HttpStatusCode.OK, await saved.Content.ReadAsStringAsync(Ct));
        return (articleId, assetId);
    }

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> work)
    {
        using var scope = api.Services.CreateScope();
        return await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    /// <summary>Full-text indexing runs a few seconds after a commit: waits until a version of the article is indexed with <paramref name="word"/>.</summary>
    private Task IndexedAsync(Guid articleId, string word) => EventuallyIndexedAsync("""
        SELECT COUNT(*) AS [Value] FROM CONTAINSTABLE([dbo].[ArticleTranslations], [SearchText], {0}, LANGUAGE 1025) AS ct
        JOIN [dbo].[ArticleTranslations] AS t ON t.[Id] = ct.[KEY] WHERE t.[ArticleId] = {1}
        """, word, articleId);

    /// <summary>Waits until the upload's extracted text is indexed with <paramref name="word"/>.</summary>
    private Task DocumentIndexedAsync(Guid assetId, string word) => EventuallyIndexedAsync("""
        SELECT COUNT(*) AS [Value] FROM CONTAINSTABLE([dbo].[MediaAssets], [ExtractedText], {0}, LANGUAGE 1025) AS ct
        WHERE ct.[KEY] = {1}
        """, word, assetId);

    private async Task EventuallyIndexedAsync(string sql, string word, Guid key)
    {
        if (Engine.Kind != SearchEngineKind.FullText) return;
        var deadline = DateTime.UtcNow.AddSeconds(60);
        while (true)
        {
            var found = await InDbAsync(db => db.Database.SqlQueryRaw<int>(sql, $"\"{word}*\"", key).SingleAsync(Ct));
            if (found > 0) return;
            if (DateTime.UtcNow > deadline) throw new TimeoutException($"Full-text never indexed {key} with \"{word}\".");
            await Task.Delay(200, Ct);
        }
    }
}
