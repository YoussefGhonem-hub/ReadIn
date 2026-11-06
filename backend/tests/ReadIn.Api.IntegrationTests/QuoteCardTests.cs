using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Articles.QuoteCards;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Infrastructure.Persistence;
using SkiaSharp;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// <c>POST /articles/{id}/quote-card</c> (SPEC F24, contract "Quote card (F24)"): guests and members get a PNG of an F30
/// range, checked against the shared offsets fixtures like a highlight, with the reader's visibility, safe headers, the
/// card's codes and its hourly limit. The real headless Chromium draws the PNGs; a recording renderer shows what goes
/// on a card.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class QuoteCardTests(ApiFactory api)
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
    private async Task<(Guid Id, string Slug, SignedInUser Author)> PublishFixtureArticleAsync(SignedInUser? author = null)
    {
        author ??= await api.UserAsync("Quote Author");
        var document = JsonSerializerHelper.ToObject(new
        {
            sourceLanguage = "ar-EG",
            translations = new[]
            {
                new { language = "ar-EG", title = "مقال فيه اقتباسات", subtitle = (string?)null, content = Fixtures["documents"]!["ar"]!.DeepClone() },
                new { language = "en", title = "An article worth quoting", subtitle = (string?)null, content = Fixtures["documents"]!["en"]!.DeepClone() },
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

    private static Task<HttpResponseMessage> CardAsync(
        HttpClient client, Guid articleId, string language, string blockId, int start, int end, string? text,
        string? theme = "light", string? format = "square") =>
        client.PostAsJsonAsync($"/api/v1/articles/{articleId}/quote-card",
            new { language, blockId, startOffset = start, endOffset = end, text, theme, format }, Ct);

    /// <summary>A slice of a fixture block (offsets in its plain text).</summary>
    private static Task<HttpResponseMessage> FixtureCardAsync(
        HttpClient client, Guid articleId, string document, string blockId, int start, int end, string theme = "light", string format = "square") =>
        CardAsync(client, articleId, Language(document), blockId, start, end, PlainText(document, blockId)[start..end], theme, format);

    private static async Task<SKBitmap> PngAsync(HttpResponseMessage response)
    {
        var body = await response.Content.ReadAsByteArrayAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.OK, System.Text.Encoding.UTF8.GetString(body));
        response.Content.Headers.ContentType!.MediaType.Should().Be("image/png");
        response.Content.Headers.ContentLength.Should().Be(body.Length);
        return SKBitmap.Decode(body) ?? throw new InvalidOperationException("Not a PNG.");
    }

    private async Task InDbAsync(Func<AppDbContext, Task> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    /// <summary>A host whose cards go to <paramref name="renderer"/>, signed in as <paramref name="user"/> (or a guest).</summary>
    private (WebApplicationFactory<Program> Host, HttpClient Client) WithRenderer(IQuoteCardRenderer renderer, SignedInUser? user = null)
    {
        var host = api.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.Replace(ServiceDescriptor.Singleton(renderer))));
        var client = host.CreateClient();
        client.DefaultRequestHeaders.AcceptLanguage.ParseAdd("en");
        if (user is not null) client.DefaultRequestHeaders.Authorization = user.Client.DefaultRequestHeaders.Authorization;
        return (host, client);
    }

    [Fact]
    public async Task A_guest_gets_a_square_png_of_the_selection_with_safe_headers_and_its_file_name()
    {
        var (id, slug, _) = await PublishFixtureArticleAsync();

        var response = await FixtureCardAsync(api.GuestClient(), id, "ar", "p1", 15, 62);

        using var image = await PngAsync(response);
        (image.Width, image.Height).Should().Be((1080, 1080));
        response.Headers.GetValues("X-Content-Type-Options").Should().Equal("nosniff");
        response.Headers.CacheControl!.Private.Should().BeTrue();
        response.Headers.CacheControl.MaxAge.Should().Be(TimeSpan.FromMinutes(10));
        response.Content.Headers.GetValues("Content-Disposition").Single()
            .Should().Be($"inline; filename=\"readin-quote.png\"; filename*=UTF-8''readin-quote-{slug}.png");
        response.Content.Headers.ContentDisposition!.FileNameStar.Should().Be($"readin-quote-{slug}.png");
    }

    [Fact]
    public async Task A_member_gets_a_dark_landscape_card_of_the_english_version()
    {
        var (id, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync("Quote Reader");

        using var image = await PngAsync(await FixtureCardAsync(reader.Client, id, "en", "e1", 0, 31, "dark", "landscape"));

        (image.Width, image.Height).Should().Be((1200, 630));
        var corner = image.GetPixel(4, 4);
        (corner.Red, corner.Green, corner.Blue).Should().Be(((byte)0x16, (byte)0x30, (byte)0x2A), "a dark card's page is the dark primary.container token");
    }

    [Theory]
    [InlineData("light", "square", 1080, 1080)]
    [InlineData("dark", "square", 1080, 1080)]
    [InlineData("light", "landscape", 1200, 630)]
    public async Task Every_theme_and_format_has_its_size(string theme, string format, int width, int height)
    {
        var (id, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync("Quote Sizes");

        using var image = await PngAsync(await FixtureCardAsync(reader.Client, id, "ar", "q1", 0, 20, theme, format));

        (image.Width, image.Height).Should().Be((width, height));
    }

    [Fact]
    public async Task The_shared_fixture_checks_answer_like_a_highlight_under_the_quote_codes()
    {
        var (id, _, _) = await PublishFixtureArticleAsync();
        var recorder = new RecordingRenderer();
        var (host, client) = WithRenderer(recorder, await api.UserAsync("Quote Fixtures"));
        await using var _ = host;

        foreach (var check in Fixtures["serverChecks"]!["cases"]!.AsArray())
        {
            var caseId = check!["id"]!.GetValue<string>();
            var document = check["document"]!.GetValue<string>();
            var blockId = check["blockId"]!.GetValue<string>();
            var (start, end) = (check["startOffset"]!.GetValue<int>(), check["endOffset"]!.GetValue<int>());
            if (check["text"] is null && PlainText(document, blockId) is var plain && (end > plain.Length || SplitsPair(plain, start) || SplitsPair(plain, end)))
                continue; // half a surrogate pair can't travel as JSON (the unit tests cover these); past the end has no text to send
            var text = check["text"]?.GetValue<string>() ?? PlainText(document, blockId)[start..end];

            var response = await CardAsync(client, id, Language(document), blockId, start, end, text);
            var body = await response.Content.ReadAsStringAsync(Ct);

            if (check["error"]?.GetValue<string>() is { } error)
            {
                response.StatusCode.Should().Be(HttpStatusCode.BadRequest, caseId);
                JsonNode.Parse(body)!["code"]!.GetValue<string>().Should().Be(error.Replace("highlight.", "quote.", StringComparison.Ordinal), caseId);
            }
            else
            {
                response.StatusCode.Should().Be(HttpStatusCode.OK, $"{caseId}: {body}");
                recorder.Last!.Quote.Should().Be(check["stored"]!["text"]!.GetValue<string>(), $"{caseId}: the card shows the trimmed range");
            }
        }

        // A selection past the block's text is a mismatch too.
        await CardAsync(client, id, "ar-EG", "p1", 70, 75, "حتة.x").ProblemAsync(HttpStatusCode.BadRequest, "quote.text_mismatch");

        static bool SplitsPair(string s, int i) => i > 0 && i < s.Length && char.IsHighSurrogate(s[i - 1]) && char.IsLowSurrogate(s[i]);
    }

    [Fact]
    public async Task The_card_shows_the_quote_the_version_title_the_writer_and_the_slug()
    {
        var writer = await api.VerifiedUserAsync("Quoted Writer");
        var (id, slug, _) = await PublishFixtureArticleAsync(writer);
        var recorder = new RecordingRenderer();
        var (host, guest) = WithRenderer(recorder);
        await using var _ = host;

        (await FixtureCardAsync(guest, id, "ar", "p1", 15, 62, "dark", "landscape")).StatusCode.Should().Be(HttpStatusCode.OK);
        var arabic = recorder.Last!;
        arabic.Should().BeEquivalentTo(new QuoteCard
        {
            Quote = "ASP.NET Core، أكيد شفت الـ Dependency Injection",
            Language = "ar-EG",
            // p1 starts with "لو انت": the reader shows the block right to left, so the card too, though the quote starts in English.
            Dir = "rtl",
            Title = "مقال فيه اقتباسات",
            AuthorName = "Quoted Writer",
            AuthorIsVerified = true,
            Slug = slug,
            Theme = QuoteCardTheme.Dark,
            Format = QuoteCardFormat.Landscape,
        });

        (await FixtureCardAsync(guest, id, "en", "e1", 0, 31)).StatusCode.Should().Be(HttpStatusCode.OK);
        recorder.Last!.Title.Should().Be("An article worth quoting");
        recorder.Last.Language.Should().Be("en");
        recorder.Last.Dir.Should().Be("ltr");

        // An English list in the Arabic version: its block is left to right in the reader, so is the card.
        (await FixtureCardAsync(guest, id, "ar", "o1", 0, 10)).StatusCode.Should().Be(HttpStatusCode.OK);
        recorder.Last!.Quote.Should().Be("First step");
        recorder.Last.Dir.Should().Be("ltr");

        // A deleted writer's kept article (SPEC F01): no name, so the card says "Deleted user".
        await InDbAsync(db => db.Articles.Where(a => a.Id == id).ExecuteUpdateAsync(s => s.SetProperty(a => a.AuthorId, (Guid?)null), Ct));
        (await FixtureCardAsync(guest, id, "en", "e1", 0, 31)).StatusCode.Should().Be(HttpStatusCode.OK);
        recorder.Last!.AuthorName.Should().BeNull();
        recorder.Last.AuthorIsVerified.Should().BeFalse();
    }

    [Fact]
    public async Task Code_tables_and_steps_are_not_quotes_and_the_limits_are_3_to_400()
    {
        var (id, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync("Quote Limits");

        await CardAsync(reader.Client, id, "ar-EG", "k1", 0, 7, "builder").ProblemAsync(HttpStatusCode.BadRequest, "quote.block_not_allowed");
        await CardAsync(reader.Client, id, "ar-EG", "t1", 0, 8, "Lifetime").ProblemAsync(HttpStatusCode.BadRequest, "quote.block_not_allowed");
        await FixtureCardAsync(reader.Client, id, "ar", "p1", 0, 2).ProblemAsync(HttpStatusCode.BadRequest, "quote.too_short");
        await FixtureCardAsync(reader.Client, id, "ar", "p1", 0, 3).ProblemAsync(HttpStatusCode.BadRequest, "quote.too_short");
        // An ar-EG block id with language en: that version has no such block.
        await CardAsync(reader.Client, id, "en", "p1", 0, 5, "لو ان").ProblemAsync(HttpStatusCode.BadRequest, "quote.text_mismatch");

        var writer = await api.UserAsync("Long Quote Writer");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var longText = string.Concat(Enumerable.Repeat("Read daily. Grow daily. ", 20)).Trim(); // 479 characters
        var (longId, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "A long paragraph", blocks: [ArticleTestKit.Paragraph(longText)]));
        const string blockId = "p1"; // ArticleTestKit.Paragraph's id
        longText.Length.Should().BeGreaterThan(402);

        // 401 code units ending in a space are 400 once trimmed, so that one is a quote; 402 ending in a letter isn't.
        longText[400].Should().Be(' ');
        (await CardAsync(reader.Client, longId, "en", blockId, 0, 401, longText[..401])).StatusCode.Should().Be(HttpStatusCode.OK);
        await CardAsync(reader.Client, longId, "en", blockId, 0, 402, longText[..402]).ProblemAsync(HttpStatusCode.BadRequest, "quote.too_long");
        var recorder = new RecordingRenderer();
        var (host, client) = WithRenderer(recorder, reader);
        await using var _ = host;
        (await CardAsync(client, longId, "en", blockId, 0, 400, longText[..400])).StatusCode.Should().Be(HttpStatusCode.OK);
        recorder.Last!.Quote.Should().HaveLength(400);
    }

    [Fact]
    public async Task Hidden_unpublished_and_deleted_articles_have_no_card()
    {
        var (id, _, author) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync("Quote Outsider");
        var moderator = await api.SuperAdminAsync("Quote Moderator");
        var field = await author.Client.FieldIdAsync("dotnet");

        await FixtureCardAsync(reader.Client, Guid.NewGuid(), "ar", "p1", 15, 62).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        await InDbAsync(db => db.Articles.Where(a => a.Id == id).ExecuteUpdateAsync(s => s.SetProperty(a => a.HiddenAt, DateTime.UtcNow), Ct));
        await FixtureCardAsync(api.GuestClient(), id, "ar", "p1", 15, 62).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await FixtureCardAsync(reader.Client, id, "ar", "p1", 15, 62).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        var hidden = await FixtureCardAsync(author.Client, id, "ar", "p1", 15, 62).ProblemAsync(HttpStatusCode.Conflict, "quote.hidden");
        hidden["title"]!.GetValue<string>().Should().Be("Moderators hid this article, so its quotes can't be shared.");
        await FixtureCardAsync(moderator.Client, id, "ar", "p1", 15, 62).ProblemAsync(HttpStatusCode.Conflict, "quote.hidden");

        await InDbAsync(db => db.Articles.Where(a => a.Id == id).ExecuteUpdateAsync(s => s.SetProperty(a => a.HiddenAt, (DateTime?)null)
            .SetProperty(a => a.Status, ArticleStatus.Archived), Ct));
        await FixtureCardAsync(author.Client, id, "ar", "p1", 15, 62).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        var draft = await author.Client.CreateDraftAsync(ArticleTestKit.Document(field, "Never published"));
        await CardAsync(author.Client, draft["id"]!.GetValue<Guid>(), "en", "p1", 0, 5, "Never").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        var (live, _, _) = await PublishFixtureArticleAsync(author);
        (await author.Client.DeleteAsync($"/api/v1/articles/{live}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await FixtureCardAsync(author.Client, live, "ar", "p1", 15, 62).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task A_malformed_body_is_a_validation_problem()
    {
        var (id, _, _) = await PublishFixtureArticleAsync();
        var reader = await api.UserAsync("Quote Validation");

        var empty = await reader.Client.PostAsJsonAsync($"/api/v1/articles/{id}/quote-card", new { }, Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        empty["errors"]!.AsObject().Select(e => e.Key.ToLowerInvariant()).Should().BeEquivalentTo(
            ["language", "blockid", "startoffset", "endoffset", "text", "theme", "format"]);

        var invalid = await CardAsync(reader.Client, id, "ar-EG", "p1", 15, 62, "x", "sepia", "story").ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        invalid["errors"]!.AsObject().Select(e => (e.Key.ToLowerInvariant(), e.Value![0]!.GetValue<string>()))
            .Should().BeEquivalentTo([("theme", "validation.invalid"), ("format", "validation.invalid")]);
    }

    [Fact]
    public async Task Thirty_cards_an_hour_per_user_then_429()
    {
        var reader = await api.SignUpAsync("ar");
        var other = await api.UserAsync("Other Quoter");

        for (var i = 0; i < 30; i++)
            await CardAsync(reader.Client, Guid.NewGuid(), "ar-EG", "p1", 0, 5, "abcde").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        var limited = await CardAsync(reader.Client, Guid.NewGuid(), "ar-EG", "p1", 0, 5, "abcde").ProblemAsync(HttpStatusCode.TooManyRequests, "quote.limit");
        limited["title"]!.GetValue<string>().Should().Be("عملت كروت اقتباس كتير الساعة دي. حاول تاني بعد شوية.");
        // Per user: someone else still gets an answer.
        await CardAsync(other.Client, Guid.NewGuid(), "ar-EG", "p1", 0, 5, "abcde").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task Guests_are_limited_per_ip_address()
    {
        await using var host = api.WithWebHostBuilder(builder =>
        {
            builder.UseSetting("RateLimits:QuoteCardPerHour", "2");
            builder.ConfigureTestServices(services => services.AddSingleton<IStartupFilter, RemoteAddressFromHeader>());
        });
        HttpClient Guest(string ip)
        {
            var client = host.CreateClient();
            client.DefaultRequestHeaders.Add(RemoteAddressFromHeader.Header, ip);
            return client;
        }

        var first = Guest("203.0.113.7");
        for (var i = 0; i < 2; i++)
            await CardAsync(first, Guid.NewGuid(), "ar-EG", "p1", 0, 5, "abcde").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await CardAsync(first, Guid.NewGuid(), "ar-EG", "p1", 0, 5, "abcde").ProblemAsync(HttpStatusCode.TooManyRequests, "quote.limit");

        await CardAsync(Guest("198.51.100.20"), Guid.NewGuid(), "ar-EG", "p1", 0, 5, "abcde").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Theory]
    [InlineData("quote.busy", HttpStatusCode.ServiceUnavailable)]
    [InlineData("quote.failed", HttpStatusCode.InternalServerError)]
    public async Task A_busy_or_failed_card_answers_with_its_code(string code, HttpStatusCode status)
    {
        var (id, _, _) = await PublishFixtureArticleAsync();
        var (host, client) = WithRenderer(new FailingRenderer(code == "quote.busy" ? QuoteCardErrors.Busy : QuoteCardErrors.Failed));
        await using var _ = host;

        await FixtureCardAsync(client, id, "ar", "p1", 15, 62).ProblemAsync(status, code);
    }

    [Fact]
    public async Task The_web_can_read_the_file_name_across_origins_and_openapi_documents_the_endpoint()
    {
        var (id, _, _) = await PublishFixtureArticleAsync();
        var (host, client) = WithRenderer(new RecordingRenderer());
        await using var _ = host;
        using var request = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/articles/{id}/quote-card")
        {
            Content = JsonContent.Create(new { language = "ar-EG", blockId = "p1", startOffset = 15, endOffset = 62, text = PlainText("ar", "p1")[15..62], theme = "light", format = "square" }),
        };
        request.Headers.Add("Origin", "https://readin.app");

        using var response = await client.SendAsync(request, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        response.Headers.GetValues("Access-Control-Expose-Headers").Single().Should().Contain("Content-Disposition");

        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();
        document["paths"]!["/api/v1/articles/{id}/quote-card"]!["post"]!.ToJsonString().Should().Contain("image/png");
        document["components"]!["schemas"]!["QuoteCardRequest"]!["properties"]!.AsObject().Select(p => p.Key)
            .Should().BeEquivalentTo("language", "blockId", "startOffset", "endOffset", "text", "theme", "format");
    }

    /// <summary>Records what each card would show and answers a 1 × 1 PNG.</summary>
    private sealed class RecordingRenderer : IQuoteCardRenderer
    {
        private static readonly byte[] Pixel = Convert.FromBase64String(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=");

        public QuoteCard? Last { get; private set; }

        public Task<Result<byte[]>> RenderAsync(QuoteCard card, CancellationToken cancellationToken)
        {
            Last = card;
            return Task.FromResult<Result<byte[]>>(Pixel);
        }
    }

    private sealed class FailingRenderer(Error error) : IQuoteCardRenderer
    {
        public Task<Result<byte[]>> RenderAsync(QuoteCard card, CancellationToken cancellationToken) =>
            Task.FromResult<Result<byte[]>>(error);
    }

    /// <summary>TestServer has no remote address: this one comes from a test header, before the rate limiter reads it.</summary>
    private sealed class RemoteAddressFromHeader : IStartupFilter
    {
        public const string Header = "X-Test-Remote-Address";

        public Action<IApplicationBuilder> Configure(Action<IApplicationBuilder> next) => app =>
        {
            app.Use(async (context, nextMiddleware) =>
            {
                if (context.Request.Headers[Header].FirstOrDefault() is { } address) context.Connection.RemoteIpAddress = IPAddress.Parse(address);
                await nextMiddleware();
            });
            next(app);
        };
    }
}

/// <summary>The F24 problem titles, in both languages (no server needed).</summary>
public sealed class QuoteCardErrorTitlesTests
{
    [Theory]
    [InlineData("quote.text_mismatch", "النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.", "This text has changed in the article. Reload and try again.")]
    [InlineData("quote.block_not_allowed", "مينفعش تشارك الجزء ده كاقتباس.", "This part can't be shared as a quote.")]
    [InlineData("quote.too_short", "اختار 3 حروف على الأقل.", "Select at least 3 characters.")]
    [InlineData("quote.too_long", "الاقتباس لازم يكون 400 حرف أو أقل. اختار جزء أصغر.", "A quote can be at most 400 characters. Select less text.")]
    [InlineData("quote.hidden", "المشرفين خفّوا المقال ده، فمينفعش تشارك منه اقتباس.", "Moderators hid this article, so its quotes can't be shared.")]
    [InlineData("quote.limit", "عملت كروت اقتباس كتير الساعة دي. حاول تاني بعد شوية.", "You've made many quote cards this hour. Try again later.")]
    [InlineData("quote.busy", "فيه كروت كتير بتتجهز دلوقتي. حاول تاني كمان شوية.", "Many cards are being prepared right now. Try again in a moment.")]
    [InlineData("quote.failed", "معرفناش نجهّز كارت الاقتباس. حاول تاني.", "We couldn't prepare the quote card. Try again.")]
    public void Quote_codes_have_the_contract_titles(string code, string arabic, string english)
    {
        ErrorMessages.Title(code, "ar").Should().Be(arabic);
        ErrorMessages.Title(code, "en").Should().Be(english);
    }
}
