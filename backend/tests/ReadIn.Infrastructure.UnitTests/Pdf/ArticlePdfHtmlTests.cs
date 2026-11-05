using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using NSubstitute;
using PuppeteerSharp;
using ReadIn.Application.Features.Articles.Pdf;
using ReadIn.Infrastructure.Pdf;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// The print HTML of an article PDF (SPEC F33, §24): all text HTML-encoded, no script, only <c>data:</c> resources (so
/// Chromium fetches nothing), the article's own direction and labels, and the page-break classes of No-bug rule 4.
/// </summary>
public sealed partial class ArticlePdfHtmlTests
{
    private static string Html(string language) =>
        ArticlePdfHtml.Build(ArticlePdfFixtures.Document(language), ArticlePdfAssets.Instance, "https://readin.app");

    private static string Html(ArticlePdfDocument document) =>
        ArticlePdfHtml.Build(document, ArticlePdfAssets.Instance, "https://readin.app");

    private static JsonElement Blocks(string json)
    {
        using var document = JsonDocument.Parse($$"""{ "version": 1, "language": "en", "blocks": {{json}} }""");
        return document.RootElement.Clone();
    }

    [Fact]
    public void Every_piece_of_text_and_every_attribute_is_html_encoded()
    {
        const string attack = "<script>alert(1)</script><img src=x onerror=alert(2)>\"'&";
        var html = Html(ArticlePdfFixtures.Document("en") with
        {
            Title = attack,
            Subtitle = attack,
            Author = new ArticlePdfAuthor(attack, "x\"><script>", IsVerified: true),
            FieldName = attack,
            Tags = [attack],
            Sources = [new ArticlePdfSource(attack, "javascript:alert(1)")],
            Content = Blocks($$"""
                [
                  { "id": "p", "type": "paragraph", "content": [
                    { "type": "text", "text": {{JsonSerializer.Serialize(attack)}} },
                    { "type": "text", "text": "link", "marks": [{ "type": "link", "href": "javascript:alert(3)" }] },
                    { "type": "mention", "userId": "0195f3a0-0000-7000-8000-000000000001", "text": {{JsonSerializer.Serialize("@" + attack)}} } ] },
                  { "id": "c", "type": "code", "lang": "html", "filename": {{JsonSerializer.Serialize(attack)}}, "code": {{JsonSerializer.Serialize(attack)}} },
                  { "id": "i", "type": "image", "src": "https://evil.example/x.png", "alt": {{JsonSerializer.Serialize(attack)}}, "caption": {{JsonSerializer.Serialize(attack)}} },
                  { "id": "t", "type": "table", "header": [[{ "type": "text", "text": {{JsonSerializer.Serialize(attack)}} }]], "rows": [] }
                ]
                """),
        });

        html.Should().NotContainAny("<script", "<img src=x", "href=\"javascript:", "<x\"");
        html.Should().Contain("&lt;script&gt;alert(1)&lt;/script&gt;&lt;img src=x onerror=alert(2)&gt;");
        html.Should().Contain("href=\"https://readin.app/@x%22%3E%3Cscript%3E\"");
    }

    [Theory]
    [InlineData("ar-EG")]
    [InlineData("en")]
    public void The_page_has_no_script_and_loads_nothing_but_data_urls(string language)
    {
        var html = Html(language);

        html.Should().NotContain("<script", "JavaScript is off and the page has none (SPEC §24)");
        html.Should().Contain("Content-Security-Policy\" content=\"default-src 'none'; img-src data:; font-src data:; style-src 'unsafe-inline'\"");
        ResourceUrls().Matches(html).Select(m => m.Groups["url"].Value)
            .Should().NotBeEmpty().And.OnlyContain(url => url.StartsWith("data:", StringComparison.Ordinal));
    }

    [Fact]
    public void An_image_that_isnt_one_of_our_uploads_is_never_fetched_but_printed_as_a_card_with_its_link()
    {
        var html = Html("en");

        html.Should().NotContain($"src=\"{ArticlePdfFixtures.ExternalImageSrc}\"");
        html.Should().Contain($"href=\"{ArticlePdfFixtures.ExternalImageSrc}\"");
        html.Should().Contain("ExternalImageCaption");
    }

    [Fact]
    public void Dark_images_are_ignored_and_alt_text_is_kept()
    {
        var html = Html("ar-EG");

        html.Should().NotContain("33333333333333333333333333333333", "the file is always light");
        html.Should().Contain("alt=\"رسم توضيحي للـ DI container\"");
    }

    [Theory]
    [InlineData("ar-EG", "rtl", "المصادر", "المرفقات", "منشور على ReadIn", "الخلاصة", "5 نوفمبر 2026", "7 دقايق قراءة")]
    [InlineData("en", "ltr", "Sources", "Attachments", "Published on ReadIn", "TL;DR", "November 5, 2026", "7 min read")]
    public void Direction_and_labels_follow_the_article_language_with_western_digits(
        string language, string dir, string sources, string attachments, string published, string summary, string date, string readingTime)
    {
        var html = Html(language);

        html.Should().Contain($"<html lang=\"{language}\" dir=\"{dir}\">");
        html.Should().ContainAll(sources, attachments, published, summary, date, readingTime);
        html.Should().NotMatchRegex("[٠-٩۰-۹]", "digits are Western everywhere (§14.2)");
    }

    [Fact]
    public void The_first_page_has_the_logo_title_writer_meta_ai_label_tags_disclaimer_and_cover_in_that_order()
    {
        var html = Html("en");

        var order = new[]
        {
            "class=\"logo\"", "class=\"title\"", "class=\"byline\"", "class=\"verified\"", "November 5, 2026", "7 min read",
            "<span class=\"ai-label\">AI-assisted</span>", "Medicine</bdi> · <bdi>Public health",
            "class=\"tags\"", "class=\"disclaimer\"", "class=\"cover\"", "<main",
        }.Select(part => html.IndexOf(part, StringComparison.Ordinal)).ToList();

        order.Should().NotContain(-1).And.BeInAscendingOrder();
        html.Should().Contain("href=\"https://readin.app/@youssef_dev\"");
    }

    /// <summary>Bug F33-4: SPEC §20, the AI-assisted label is never hidden, in the PDF either; in the article's language.</summary>
    [Fact]
    public void The_ai_assisted_label_is_printed_in_the_article_language_and_only_on_ai_assisted_articles()
    {
        Html("ar-EG").Should().Contain("<p class=\"meta\">5 نوفمبر 2026 · 7 دقايق قراءة · <span class=\"ai-label\">بمساعدة <bdi>AI</bdi></span></p>");
        Html("en").Should().Contain("<p class=\"meta\">November 5, 2026 · 7 min read · <span class=\"ai-label\">AI-assisted</span></p>");

        Html(ArticlePdfFixtures.Document("en") with { IsAiAssisted = false }).Should().NotContain("ai-label").And.NotContain("AI-assisted");
    }

    [Fact]
    public void The_summary_comes_first_and_the_end_has_attachments_sources_and_the_article_link()
    {
        var html = Html("ar-EG");
        var main = html[html.IndexOf("<main", StringComparison.Ordinal)..];

        main.IndexOf("class=\"summary\"", StringComparison.Ordinal).Should().BeLessThan(main.IndexOf("<p ", StringComparison.Ordinal));
        var end = html[html.IndexOf("<footer class=\"end\"", StringComparison.Ordinal)..];
        new[] { "المرفقات", "المصادر", "منشور على ReadIn" }.Select(label => end.IndexOf(label, StringComparison.Ordinal))
            .Should().NotContain(-1).And.BeInAscendingOrder();
        end.Should().Contain("href=\"https://readin.app/ar/a/" + Uri.EscapeDataString("الـ-pdf-بتاع-readin") + "\"");
        end.Should().Contain(">https://readin.app/ar/a/الـ-pdf-بتاع-readin<", "readers see the slug as written");
    }

    [Fact]
    public void Nothing_left_out_by_the_spec_is_printed()
    {
        var html = Html("en");

        // No comments, reactions, counters, related articles, highlights or app buttons; no phone number either.
        html.Should().NotContainAny("<button", "reaction", "comment-", "related", "+1202");
    }

    [Fact]
    public void Code_is_always_ltr_short_code_never_splits_and_highlighted_lines_are_tinted()
    {
        var html = Html("ar-EG");

        Regex.Matches(html, "<div class=\"code[^\"]*\" dir=\"([a-z]+)\"").Select(m => m.Groups[1].Value).Should().OnlyContain(d => d == "ltr");
        html.Should().Contain("<div class=\"code code-short\" dir=\"ltr\"><div class=\"code-head mono\">Program.cs</div>");
        html.Should().Contain("<div class=\"code\" dir=\"ltr\"><div class=\"code-head mono\">OrderService.cs</div>", "48 lines may continue on the next page");
        // An indented line also carries its indentation (style="--indent:…").
        Regex.Matches(html[html.IndexOf("Program.cs</div>", StringComparison.Ordinal)..html.IndexOf("end of short code", StringComparison.Ordinal)], "<span class=\"line( hl)?\"[^>]*>")
            .Select(m => m.Groups[1].Success).Should().Equal(false, true, false, false, true, false, false, false, false, false, false, false);
        html.Should().Contain("<div class=\"tabs\">").And.Contain("C# · IClock.cs").And.Contain(">TypeScript<").And.Contain(">Dart<");
    }

    /// <summary>Bug F33-8: a long code line wraps under its own indentation (a hanging indent), never at the left edge.</summary>
    [Fact]
    public void Each_code_line_carries_its_indentation_so_a_wrapped_line_continues_under_it()
    {
        var html = Html("en");

        html.Should().Contain("<span class=\"line\" style=\"--indent:8ch\">        var order = new Order(command.Id, command.CustomerId, clock.UtcNow);</span>");
        html.Should().Contain("<span class=\"line\" style=\"--indent:4ch\">    public async Task&lt;Order&gt; CreateAsync(CreateOrder command)</span>");
        html.Should().Contain("<span class=\"line\">namespace Shop.Orders;</span>", "a line without indentation needs no style");
        ArticlePdfAssets.Instance.Stylesheet.Should().Contain("padding-left: var(--wrap); text-indent: calc(-1 * var(--wrap));",
            "the continuation lines of a wrapped line start under its text, not at the left edge");

        // A tab goes to the next stop of 4.
        var tabs = Html(ArticlePdfFixtures.Document("en") with
        {
            Content = Blocks("""[{ "id": "c", "type": "code", "lang": "go", "code": "func main() {\n\tif ok {\n\t\treturn\n\t}\n}" }]"""),
        });
        tabs.Should().MatchRegex("<span class=\"line\" style=\"--indent:4ch\">[^<]*if ok \\{</span>")
            .And.MatchRegex("<span class=\"line\" style=\"--indent:8ch\">[^<]*return</span>");
    }

    [Fact]
    public void Callouts_carry_their_bundled_icon_and_label_not_an_emoji()
    {
        var html = Html("en");

        foreach (var variant in new[] { "tip", "info", "warning", "danger" })
            html.Should().Contain($"<div class=\"callout callout-{variant}\" role=\"note\"");
        html.Should().Contain("<span class=\"callout-title\">Important tip</span>").And.Contain("<span class=\"callout-title\">Danger</span>");
        Regex.Matches(html, "<span class=\"callout-icon\" aria-hidden=\"true\"><svg").Should().HaveCount(4);
    }

    [Fact]
    public void Mixed_text_is_isolated_like_the_web_reader()
    {
        var html = Html("ar-EG");

        html.Should().Contain("<li>أنا بستخدم <bdi>ASP.NET Core</bdi>.</li>");
        html.Should().Contain("<li>اتعمل <bdi>upgrade</bdi> لـ <bdi>.NET 10</bdi> و <bdi>Angular 21</bdi>.</li>");
        html.Should().Contain("<code class=\"inline\" dir=\"ltr\">AddScoped</code>");
    }

    [Fact]
    public void Embeds_print_as_cards_with_the_full_link()
    {
        var html = Html("ar-EG");

        html.Should().Contain("فيديو YouTube").And.Contain("href=\"https://www.youtube.com/watch?v=dQw4w9WgXcQ\"");
        html.Should().Contain("Gist على GitHub").And.Contain("href=\"https://gist.github.com/readin/0123456789abcdef0123456789abcdef\"");
        html.Should().NotContain("<iframe");
    }

    [Fact]
    public void The_emoji_font_is_inlined_only_when_the_text_has_an_emoji()
    {
        Html("en").Should().Contain($"font-family:\"{ArticlePdfAssets.Emoji}\";src:url(data:font/ttf;base64,");

        var plain = Html(ArticlePdfFixtures.Document("en") with
        {
            Title = "Plain",
            Content = Blocks("""[{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "No pictures here." }] }]"""),
            Images = new Dictionary<string, ArticlePdfImage>(),
        });
        plain.Should().NotContain($"font-family:\"{ArticlePdfAssets.Emoji}\";src:");
    }

    /// <summary>
    /// Bug F33-1: the encoder writes characters outside the BMP as entities (🚀 → <c>&amp;#x1F680;</c>), so the check on
    /// the encoded page missed most emoji and every flag. The raw text decides now.
    /// </summary>
    [Theory]
    [InlineData(ArticlePdfFixtures.EmojiOnlyText)]
    [InlineData("🚀")]
    [InlineData("🇪🇬")]
    [InlineData("1️⃣")]
    public void Emoji_outside_the_bmp_flags_and_keycaps_bring_the_emoji_font(string text)
    {
        var html = Html(ArticlePdfFixtures.EmojiOnlyDocument() with
        {
            Content = Blocks($$"""[{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": {{JsonSerializer.Serialize(text)}} }] }]"""),
        });

        html.Should().Contain($"font-family:\"{ArticlePdfAssets.Emoji}\";src:url(data:font/ttf;base64,");
        ArticlePdfHtml.FallbacksFor(text).Should().HaveFlag(PdfFallbacks.Emoji);
    }

    [Fact]
    public void An_emoji_anywhere_in_the_printed_text_brings_the_emoji_font()
    {
        var plain = ArticlePdfFixtures.EmojiOnlyDocument() with
        {
            Content = Blocks("""[{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "No pictures here." }] }]"""),
        };
        var emojiFace = $"font-family:\"{ArticlePdfAssets.Emoji}\";src:";

        Html(plain).Should().NotContain(emojiFace);
        Html(plain with { Title = "Shipped 🚀" }).Should().Contain(emojiFace, "the title");
        Html(plain with { Tags = ["🇪🇬"] }).Should().Contain(emojiFace, "a tag");
        Html(plain with { Sources = [new ArticlePdfSource("Docs 📚", "https://example.com/docs")] }).Should().Contain(emojiFace, "a source");
        Html(plain with
        {
            Content = Blocks("""[{ "id": "c", "type": "code", "lang": "ts", "code": "const done = '✅🎉';" }]"""),
        }).Should().Contain(emojiFace, "a code line");
    }

    /// <summary>Bug F33-7: ★, ⇒ and friends are in none of the text fonts or the emoji font, so the symbol fonts come in.</summary>
    [Theory]
    [InlineData("Rated ★★★★☆", true)]
    [InlineData("A ⇒ B ⟶ C", true)]
    [InlineData("◆ ■ ▲ ☐ ⌘", true)]
    [InlineData("Plain text, 100% ASCII", false)]
    [InlineData("نص عربي من غير رموز", false)]
    public void The_symbol_fonts_are_inlined_only_when_the_text_has_a_symbol(string text, bool needed)
    {
        var html = Html(ArticlePdfFixtures.SymbolsDocument() with
        {
            Content = Blocks($$"""[{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": {{JsonSerializer.Serialize(text)}} }] }]"""),
        });

        var faces = new[] { $"font-family:\"{ArticlePdfAssets.Symbols}\";src:url(data:font/ttf;base64,", $"font-family:\"{ArticlePdfAssets.MathSymbols}\";src:url(data:font/ttf;base64," };
        if (needed) html.Should().ContainAll(faces);
        else html.Should().NotContainAny(faces);
    }

    [Fact]
    public void The_symbol_fonts_come_last_in_every_font_list_after_the_emoji_font()
    {
        var css = ArticlePdfAssets.Instance.Stylesheet;

        foreach (var list in Regex.Matches(css, "font-family: (\"ReadIn [^;]+);").Select(m => m.Groups[1].Value))
            list.Should().EndWith("\"ReadIn Emoji\", \"ReadIn Symbols\", \"ReadIn Math\"", "an emoji stays in color, and a symbol never comes from the server's fonts");
    }

    /// <summary>
    /// Bug F33-3: cells broke anywhere, so short columns were squeezed and numbers and words split. Now each column gets a
    /// fixed width from its measured words, a table too wide for the page a smaller font, and the cells wrap at spaces only.
    /// </summary>
    [Fact]
    public void Tables_get_fixed_column_widths_and_a_wide_table_a_smaller_font()
    {
        var html = Html("ar-EG");
        var tables = Regex.Matches(html, "<table(?: style=\"font-size:(?<size>[0-9.]+)pt\")?><colgroup>(?<cols>(?:<col style=\"width:[0-9.]+%\">)+)</colgroup>")
            .Select(m => (Size: m.Groups["size"].Success ? double.Parse(m.Groups["size"].Value, CultureInfo.InvariantCulture) : PdfTableLayout.BaseFontSize,
                Widths: Regex.Matches(m.Groups["cols"].Value, "width:([0-9.]+)%").Select(w => double.Parse(w.Groups[1].Value, CultureInfo.InvariantCulture)).ToList()))
            .ToList();

        tables.Should().HaveCount(2, "the wide table and the long table");
        var wide = tables.Single(t => t.Widths.Count == 12);
        wide.Size.Should().BeLessThan(PdfTableLayout.BaseFontSize, "12 columns of whole words don't fit at 10 pt").And.BeGreaterThanOrEqualTo(PdfTableLayout.MinFontSize);
        var tall = tables.Single(t => t.Widths.Count == 3);
        tall.Size.Should().Be(PdfTableLayout.BaseFontSize, "3 columns fit");
        foreach (var (_, widths) in tables)
            widths.Sum().Should().BeLessThanOrEqualTo(100).And.BeGreaterThan(99.8, "the columns fill the width and never exceed it");
        ArticlePdfAssets.Instance.Stylesheet.Should().Contain("table-layout: fixed").And.Contain("overflow-wrap: break-word; word-break: normal;")
            .And.NotMatchRegex("th, td \\{[^}]*overflow-wrap: anywhere", "a cell never breaks a word that fits its column");
    }

    [Fact]
    public void A_column_gets_the_room_its_words_need()
    {
        var layout = PdfTableLayout.For(Blocks("""
            [{ "id": "t", "type": "table",
               "header": [[{ "type": "text", "text": "#" }], [{ "type": "text", "text": "Description" }], [{ "type": "text", "text": "Score" }]],
               "rows": [[[{ "type": "text", "text": "1" }], [{ "type": "text", "text": "A long sentence that needs most of the width of the page to sit on a single line" }], [{ "type": "text", "text": "600" }]]] }]
            """).GetProperty("blocks")[0], arabicArticle: false);

        layout.FontSize.Should().Be(PdfTableLayout.BaseFontSize);
        layout.ColumnPercents.Should().HaveCount(3);
        layout.ColumnPercents[1].Should().BeGreaterThan(layout.ColumnPercents[0] + layout.ColumnPercents[2], "the text column wants the most room");
        layout.ColumnPercents.Sum().Should().BeLessThanOrEqualTo(100);
    }

    [Fact]
    public void Even_a_table_too_wide_at_the_smallest_font_stays_inside_the_page()
    {
        var word = string.Concat(Enumerable.Repeat("Wide", 5)); // 20 letters: one word that may not split
        var cells = string.Join(", ", Enumerable.Range(0, 16).Select(i => $$"""[{ "type": "text", "text": "{{word}}{{i}}" }]"""));
        var layout = PdfTableLayout.For(Blocks($$"""[{ "id": "t", "type": "table", "header": [{{cells}}], "rows": [] }]""").GetProperty("blocks")[0], arabicArticle: false);

        layout.FontSize.Should().Be(PdfTableLayout.MinFontSize);
        layout.ColumnPercents.Should().HaveCount(16);
        layout.ColumnPercents.Sum().Should().BeLessThanOrEqualTo(100, "the table is never wider than the page");
    }

    [Fact]
    public void The_footer_has_its_own_font_and_logo_the_host_and_page_numbers_in_western_digits()
    {
        var footer = ArticlePdfHtml.Footer("ar-EG", ArticlePdfAssets.Instance, "readin.app");

        footer.Should().Contain($"font-family:\"{ArticlePdfAssets.FooterFamily}\";src:url(data:font/ttf;base64,");
        footer.Should().Contain("<img class=\"l\" src=\"data:image/png;base64,");
        footer.Should().Contain("readin.app").And.Contain("<span class=\"pageNumber\"></span> / <span class=\"totalPages\"></span>");
        footer.Should().Contain("dir=\"rtl\"").And.Contain(".n{direction:ltr;unicode-bidi:isolate}");
    }

    [Fact]
    public void The_bookmark_texts_are_the_h2_and_h3_texts_in_reading_order() =>
        ArticlePdfHtml.Headings(ArticlePdfFixtures.Content("ar-EG")).Should().Equal(
            "ليه أصلاً نستخدم DI؟", "تبدأ منين؟", "جدول عريض فيه 12 عمود", "كود طويل بيكمّل في الصفحة اللي بعدها",
            "صورة طويلة جداً", "جدول طويل الـ header بتاعه بيتكرر", "فقرات عادية", "آخر حاجة");

    [Theory]
    [InlineData("https://example.com/x.png", false)]
    [InlineData("http://169.254.169.254/latest/meta-data", false)]
    [InlineData("file:///etc/passwd", false)]
    [InlineData("data:image/webp;base64,AAAA", true)]
    public async Task Chromium_aborts_every_request_except_the_pages_own_data_urls(string url, bool allowed)
    {
        var request = Substitute.For<IRequest>();
        request.Url.Returns(url);

        await ArticlePdfRenderer.Decide(request);

        if (allowed) await request.Received(1).ContinueAsync();
        else await request.Received(1).AbortAsync(RequestAbortErrorCode.BlockedByClient);
        if (allowed) await request.DidNotReceiveWithAnyArgs().AbortAsync(default);
        else await request.DidNotReceiveWithAnyArgs().ContinueAsync();
    }

    [GeneratedRegex("""(?:src=|url\()"?(?<url>[^"\s)]+)""")]
    private static partial Regex ResourceUrls();
}
