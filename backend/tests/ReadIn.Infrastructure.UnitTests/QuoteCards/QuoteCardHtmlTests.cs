using System.Text.Json;
using System.Text.RegularExpressions;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Features.Articles.QuoteCards;
using ReadIn.Infrastructure.Pdf;
using ReadIn.Infrastructure.QuoteCards;
using ReadIn.Infrastructure.UnitTests.Pdf;

namespace ReadIn.Infrastructure.UnitTests.QuoteCards;

/// <summary>
/// The quote card's page (SPEC F24, §14.2, §24): everything encoded, no script, only <c>data:</c> resources, the card's
/// direction from the quoted block, mixed text isolated, the dark lockup on dark cards and the link from configuration.
/// </summary>
public sealed partial class QuoteCardHtmlTests
{
    private static readonly QuoteCardAssets Assets = QuoteCardAssets.Instance;

    [Fact]
    public void Text_is_encoded_the_page_has_no_script_and_every_resource_is_a_data_url()
    {
        var html = QuoteCardHtml.Build(QuoteCardSamples.English(QuoteCardTheme.Light, QuoteCardFormat.Square) with
        {
            Quote = "<img src=\"https://example.com/x.png\"><script>alert(1)</script> & done",
            Title = "<b>Bold</b> \"title\"",
            AuthorName = "<i>Writer</i>",
        }, Assets, "https://readin.app");

        html.Should().NotContain("<script").And.NotContain("<img src=\"https://").And.NotContain("<b>").And.NotContain("<i>");
        html.Should().Contain("&lt;img src=&quot;https://example.com/x.png&quot;&gt;&lt;script&gt;").And.Contain("&amp; done");
        html.Should().Contain("default-src 'none'", "a CSP without script is the second wall");
        ResourceUrls().Matches(html).Select(m => m.Groups["url"].Value)
            .Should().NotBeEmpty().And.OnlyContain(url => url.StartsWith("data:", StringComparison.Ordinal));
    }

    [Theory]
    [InlineData("الكود النضيف مش رفاهية، ده احترام للي هيقرا بعدك.", "en", "ltr")]
    [InlineData("Read daily. Grow daily.", "ar-EG", "rtl")]
    [InlineData("12345 ...", "ar-EG", "rtl")]
    [InlineData("12345 ...", "en", "ltr")]
    public void The_card_and_its_quote_take_the_direction_of_the_quoted_block_not_of_the_quote(string quote, string language, string dir)
    {
        var card = QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square) with { Quote = quote, Language = language, Dir = dir };

        QuoteCardHtml.Dir(card).Should().Be(dir);
        QuoteCardHtml.Build(card, Assets, "https://readin.app").Should().Contain($"<html lang=\"{language}\" dir=\"{dir}\">")
            .And.Contain($"class=\"light square {dir}\"")
            .And.Contain($"id=\"{QuoteCardHtml.QuoteId}\" dir=\"{dir}\"");
    }

    [Fact]
    public void An_arabic_quote_that_starts_with_an_english_term_reads_right_to_left()
    {
        // The shared fixture's popular range p1[15..62]: block p1 starts with "لو انت", so the reader shows it right to left.
        var html = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square) with
        {
            Quote = "ASP.NET Core، أكيد شفت الـ Dependency Injection",
            Dir = "rtl",
        }, Assets, "https://readin.app");

        html.Should().Contain("<html lang=\"ar-EG\" dir=\"rtl\">").And.Contain("class=\"light square rtl\"");
        html.Should().Contain($"id=\"{QuoteCardHtml.QuoteId}\" dir=\"rtl\"");
        html.Should().Contain("<bdi>ASP.NET Core</bdi>، أكيد شفت الـ <bdi>Dependency Injection</bdi></blockquote>",
            "the English terms are isolated inside the Arabic sentence, and the Arabic comma stays with the Arabic text");
        html.Should().NotContain("<bdi>،").And.NotContain("<bdi>أكيد");
    }

    [Fact]
    public void Only_rtl_or_ltr_reach_the_page()
    {
        var card = QuoteCardSamples.English(QuoteCardTheme.Light, QuoteCardFormat.Square) with { Dir = "\" onload=\"x" };

        QuoteCardHtml.Dir(card).Should().Be("rtl");
        QuoteCardHtml.Build(card, Assets, "https://readin.app").Should().NotContain("onload");
    }

    public static TheoryData<string> Blocks()
    {
        var data = new TheoryData<string>
        {
            """{ "id": "p", "type": "paragraph", "dir": "ltr", "content": [{ "type": "text", "text": "عربي" }] }""",
            """{ "id": "p", "type": "paragraph", "dir": "rtl", "content": [{ "type": "text", "text": "English" }] }""",
            """{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "12 — 30 ☕" }] }""",
            """{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "AddScoped", "marks": [{ "type": "code" }] }, { "type": "text", "text": " بيعمل service لكل request." }] }""",
            """{ "id": "p", "type": "paragraph", "content": [{ "type": "hardBreak" }, { "type": "term", "termId": "di", "text": "DI" }, { "type": "text", "text": " يعني إيه؟" }] }""",
            """{ "id": "c", "type": "callout", "variant": "tip", "title": "نصيحة", "content": [{ "type": "text", "text": "Use AddScoped." }] }""",
            """{ "id": "q", "type": "quote", "content": [{ "type": "text", "text": "Clean code" }], "cite": "عمّ" }""",
            """{ "id": "l", "type": "orderedList", "dir": "auto", "items": [[{ "type": "text", "text": "First step" }], [{ "type": "text", "text": "تاني خطوة" }]] }""",
            """{ "id": "l", "type": "bulletList", "items": [[{ "type": "text", "text": "Program.cs", "marks": [{ "type": "code" }] }], [{ "type": "text", "text": "سجّل الـ services" }]] }""",
        };
        foreach (var (_, text, _) in ArticlePdfFixtures.BidiSamples())
            data.Add(JsonSerializer.Serialize(new { id = "p", type = "paragraph", content = new[] { new { type = "text", text } } }));
        return data;
    }

    /// <summary>The handler takes the card's direction from the stored block (RDocBlockText); the PDF's helper agrees.</summary>
    [Theory]
    [MemberData(nameof(Blocks))]
    public void The_quoted_block_gets_the_direction_the_pdf_and_the_reader_give_it(string blockJson)
    {
        using var document = JsonDocument.Parse($$"""{ "blocks": [{{blockJson}}] }""");
        var element = document.RootElement.GetProperty("blocks")[0];

        var block = RDocBlockText.Blocks(document.RootElement).Single();

        (block.Dir ?? "rtl").Should().Be(BidiText.ResolveBlockDir(element, "rtl"), blockJson);
        (block.Dir ?? "ltr").Should().Be(BidiText.ResolveBlockDir(element, "ltr"), blockJson);
    }

    [Fact]
    public void English_inside_arabic_is_isolated_and_line_breaks_stay()
    {
        var html = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square) with
        {
            Quote = "لو انت شغال بـ ASP.NET Core، أكيد شفت الـ Dependency Injection\nفي كل حتة.",
        }, Assets, "https://readin.app");

        html.Should().Contain("<bdi>ASP.NET Core</bdi>").And.Contain("<bdi>Dependency Injection</bdi>");
        html.Should().Contain("&#xA;", "a hard break stays a line break (white-space: pre-line)");
    }

    [Fact]
    public void Dark_cards_use_the_dark_lockup_and_light_cards_the_light_one()
    {
        var light = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square), Assets, "https://readin.app");
        var dark = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Dark, QuoteCardFormat.Landscape), Assets, "https://readin.app");

        Assets.DarkLogoDataUri.Should().NotBe(Assets.LightLogoDataUri);
        light.Should().Contain(Assets.LightLogoDataUri).And.NotContain(Assets.DarkLogoDataUri);
        dark.Should().Contain(Assets.DarkLogoDataUri).And.NotContain(Assets.LightLogoDataUri);
        dark.Should().Contain("class=\"dark landscape rtl\"");
    }

    [Fact]
    public void The_approved_lockups_are_embedded_unchanged()
    {
        var logos = Path.Combine(RepoRoot(), "docs", "design", "app-store", "logo");

        Assets.LightLogoDataUri.Should().Be("data:image/png;base64," + Convert.ToBase64String(File.ReadAllBytes(Path.Combine(logos, "lockup.png"))));
        Assets.DarkLogoDataUri.Should().Be("data:image/png;base64," + Convert.ToBase64String(File.ReadAllBytes(Path.Combine(logos, "lockup-dark.png"))));
    }

    [Fact]
    public void The_writer_has_the_verified_badge_and_a_deleted_writer_is_named_in_the_article_language()
    {
        var verified = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square), Assets, "https://readin.app");
        var arabicDeleted = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square) with { AuthorName = null, AuthorIsVerified = true }, Assets, "https://readin.app");
        var englishDeleted = QuoteCardHtml.Build(QuoteCardSamples.English(QuoteCardTheme.Dark, QuoteCardFormat.Landscape), Assets, "https://readin.app");

        verified.Should().Contain("يوسف غنيم").And.Contain("class=\"verified\"");
        arabicDeleted.Should().Contain("مستخدم محذوف").And.NotContain("class=\"verified\"");
        englishDeleted.Should().Contain("Deleted user").And.NotContain("class=\"verified\"");
    }

    [Theory]
    [InlineData("https://readin.app", "en", "clean-code", "readin.app/en/a/clean-code")]
    [InlineData("https://readin.app/", "ar-EG", "article-1a2b3c4d", "readin.app/ar/a/article-1a2b3c4d")]
    [InlineData("http://localhost:4200", "en", "x", "localhost:4200/en/a/x")]
    [InlineData("not a url", "en", "x", "readin.app/en/a/x")]
    public void The_link_is_the_share_url_without_the_scheme(string web, string language, string slug, string link) =>
        QuoteCardHtml.Link(web, language, slug).Should().Be(link);

    [Fact]
    public void The_emoji_font_is_declared_only_when_the_text_has_an_emoji()
    {
        var plain = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square), Assets, "https://readin.app");
        var emoji = QuoteCardHtml.Build(QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square) with { Quote = "شكراً 👍🏽 على الشرح" }, Assets, "https://readin.app");

        plain.Should().NotContain(Assets.Fonts.EmojiFontFace);
        emoji.Should().Contain(Assets.Fonts.EmojiFontFace);
    }

    private static string RepoRoot()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
            if (Directory.Exists(Path.Combine(dir.FullName, "docs", "design", "app-store", "logo"))) return dir.FullName;
        throw new DirectoryNotFoundException("The repository root was not found.");
    }

    /// <summary>Real resource URLs: <c>src="…"</c> attributes and CSS <c>url(…)</c>, not the encoded text (<c>src=&amp;quot;</c>).</summary>
    [GeneratedRegex("""(?:src="|url\()(?<url>[^"\s)]+)""")]
    private static partial Regex ResourceUrls();
}
