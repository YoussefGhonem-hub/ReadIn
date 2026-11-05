using System.Text.RegularExpressions;
using PDFtoImage;
using PuppeteerSharp;
using ReadIn.Infrastructure.Pdf;
using SkiaSharp;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Outline;
using UglyToad.PdfPig.Tokens;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

[CollectionDefinition(Name, DisableParallelization = true)]
public sealed class ArticlePdfCollection : ICollectionFixture<ArticlePdfFixture>
{
    public const string Name = "Article PDF";
}

/// <summary>
/// Prints the shared stress fixtures (and the page-break document) once with the real headless Chromium and shares the
/// files with every test. Chromium must be installed (docs/setup/deployment.md); set <c>READIN_PDF_OUT</c> to a folder
/// to get the PDFs and their page images for a look.
/// </summary>
public sealed class ArticlePdfFixture : IAsyncLifetime
{
    public const string PageBreaks = "breaks";
    public const string EmojiOnly = "emoji";
    public const string Symbols = "symbols";

    private readonly Dictionary<string, byte[]> _pdfs = [];
    private ChromiumBrowser? _browser;

    public byte[] Pdf(string name) => _pdfs[name];

    /// <summary>The fixture's Chromium, for tests that need a page of their own.</summary>
    internal ChromiumBrowser Browser => _browser!;

    public async ValueTask InitializeAsync()
    {
        var options = ArticlePdfFixtures.Options();
        _browser = ArticlePdfFixtures.Browser(options);
        var renderer = ArticlePdfFixtures.Renderer(_browser, options);
        foreach (var (name, document) in ArticlePdfFixtures.Languages.Select(l => (l, ArticlePdfFixtures.Document(l)))
                     .Append((PageBreaks, ArticlePdfFixtures.PageBreakDocument()))
                     .Append((EmojiOnly, ArticlePdfFixtures.EmojiOnlyDocument()))
                     .Append((Symbols, ArticlePdfFixtures.SymbolsDocument())))
        {
            var result = await renderer.RenderAsync(document, CancellationToken.None);
            if (result.IsFailure) throw new InvalidOperationException($"The {name} fixture failed: {result.Error.Code}");
            _pdfs[name] = result.Value;
        }

        if (Environment.GetEnvironmentVariable("READIN_PDF_OUT") is { Length: > 0 } output)
        {
            Directory.CreateDirectory(output);
            foreach (var (name, pdf) in _pdfs)
            {
                await File.WriteAllBytesAsync(Path.Combine(output, $"{name}.pdf"), pdf);
#pragma warning disable CA1416 // the tests run on Windows and Linux
                for (var i = 0; i < Conversion.GetPageCount(pdf); i++)
                {
                    using var bitmap = Conversion.ToImage(pdf, i, options: new RenderOptions(Dpi: 80, BackgroundColor: SKColors.White));
                    using var png = bitmap.Encode(SKEncodedImageFormat.Png, 100);
                    await File.WriteAllBytesAsync(Path.Combine(output, $"{name}.p{i + 1}.png"), png.ToArray());
                }
#pragma warning restore CA1416
            }
        }
    }

    public async ValueTask DisposeAsync()
    {
        if (_browser is not null) await _browser.DisposeAsync();
    }
}

/// <summary>Article PDFs printed by headless Chromium (SPEC F33): the seven No-bug rules on the shared fixtures (§27).</summary>
[Collection(ArticlePdfCollection.Name)]
public sealed partial class ArticlePdfRendererTests(ArticlePdfFixture fixture)
{
    public static TheoryData<string> Languages => [.. ArticlePdfFixtures.Languages];

    private PdfDocument Open(string name) => PdfDocument.Open(fixture.Pdf(name));

    // ---- §24: the sandboxed print page ----

    [Fact]
    public async Task The_print_page_runs_no_script_and_fetches_nothing()
    {
        var page = await fixture.Browser.NewPageAsync(TestContext.Current.CancellationToken);
        try
        {
            await ArticlePdfRenderer.LockDownAsync(page);
            var failed = new List<string>();
            page.RequestFailed += (_, e) => { lock (failed) failed.Add(e.Request.Url); };

            // Content can never contain these (everything is HTML-encoded); this proves the second wall anyway.
            await page.SetContentAsync("""
                <html><head><title>untouched</title><link rel="stylesheet" href="https://example.com/style.css"></head>
                <body><script>document.title = 'script ran';</script>
                <img src="https://example.com/tracker.png"><img src="http://169.254.169.254/latest/meta-data"></body></html>
                """, new SetContentOptions { WaitUntil = [WaitUntilNavigation.Load], Timeout = 30_000 });

            (await page.GetTitleAsync()).Should().Be("untouched", "JavaScript is off");
            lock (failed) failed.Should().Contain(["https://example.com/tracker.png", "http://169.254.169.254/latest/meta-data"], "every network request is aborted");
        }
        finally
        {
            await page.CloseAsync();
        }
    }

    // ---- Rule 1: Arabic and mixed text ----

    /// <summary>The shared §14.2 samples as the Arabic fixture's list items (RTL).</summary>
    public static TheoryData<string> ArabicSamples =>
    [
        "أنا بستخدم ASP.NET Core.", "يعني إيه Dependency Injection؟", "الـ lifetime (Scoped) مهم جداً.",
        "قريت 12 مقال في 30 يوم، بمعدل 0.4 مقال/يوم.", "اتعمل upgrade لـ .NET 10 و Angular 21.",
        "شوف https://learn.microsoft.com/dotnet/ للتفاصيل.", "شكراً @youssef_dev على الشرح!",
        "استخدم services.AddScoped<IFoo, Foo>() هنا.", "مقال النهارده جاهز ☕ — Clean Architecture",
        "افتح backend/src/ReadIn.Api/Program.cs الأول.",
    ];

    [Theory]
    [MemberData(nameof(ArabicSamples))]
    public void Arabic_letters_are_connected_and_mixed_text_reads_in_the_right_order(string sample)
    {
        using var pdf = Open("ar-EG");
        var expected = PdfLines.ExpectedRightToLeft(sample);

        var line = PdfLines.Lines(pdf).FirstOrDefault(l => l.RightToLeft.Contains(expected, StringComparison.Ordinal));

        line.Should().NotBeNull($"the line reads, right to left, \"{expected}\"; lines were:\n{string.Join('\n', PdfLines.Lines(pdf).Select(l => l.RightToLeft))}");
        line!.JoinedShare.Should().BeGreaterThan(0.25, "Arabic letters are shaped into their joining forms, not printed one by one");
    }

    /// <summary>The shared samples with an LTR base, in the English fixture.</summary>
    [Theory]
    [InlineData("Use DI (الحقن) everywhere.")]
    [InlineData("React ولا Angular؟ الاتنين كويسين.")]
    [InlineData("@youssef_dev شكراً على الشرح!")]
    [InlineData("Read daily. Grow daily.")]
    public void Arabic_inside_english_reads_in_the_right_order(string sample)
    {
        using var pdf = Open("en");
        var expected = PdfLines.Normalize(sample);

        PdfLines.Lines(pdf).Should().Contain(l => l.LtrReadingOrder.Contains(expected, StringComparison.Ordinal),
            $"the line reads \"{expected}\"");
    }

    [Fact]
    public void The_arabic_title_keeps_its_english_and_punctuation_in_place()
    {
        using var pdf = Open("ar-EG");

        PdfLines.Lines(pdf).Where(l => l.Page == 1).Should().Contain(l =>
            l.RightToLeft.Contains(PdfLines.ExpectedRightToLeft("الـ Dependency Injection في ASP.NET Core:"), StringComparison.Ordinal));
    }

    // ---- Rule 2: no empty squares ----

    [Theory]
    [MemberData(nameof(Languages))]
    public void Every_font_is_embedded_and_one_the_api_ships(string language)
    {
        using var pdf = Open(language);
        var fonts = Fonts(pdf).ToList();

        OnlyShippedFonts(fonts);
        fonts.Should().Contain(f => f.Subtype == "Type3", "the color emoji are drawn from Noto Color Emoji");
    }

    /// <summary>
    /// Bug F33-1: emoji outside the BMP (most of them, every flag) reached the check already HTML-encoded, so a text with
    /// only those left the emoji font out and the server's emoji font (or empty squares) printed instead.
    /// </summary>
    [Fact]
    public void Emoji_outside_the_bmp_and_flags_print_from_the_shipped_emoji_font()
    {
        using var pdf = Open(ArticlePdfFixture.EmojiOnly);
        var fonts = Fonts(pdf).ToList();

        OnlyShippedFonts(fonts);
        fonts.Should().Contain(f => f.Subtype == "Type3", "🚀 😀 👩‍💻 🇪🇬 🎉 🍕 are drawn from Noto Color Emoji");
        var emoji = pdf.GetPages().SelectMany(p => p.Letters)
            .Where(l => new[] { "🚀", "😀", "🎉", "🍕" }.Any(e => l.Value.Contains(e, StringComparison.Ordinal))).ToList();
        emoji.Should().NotBeEmpty();
        emoji.Should().OnlyContain(l => l.FontName == "Type3", "an emoji comes from the emoji font, never from the server's");
    }

    [Fact]
    public void Symbols_the_text_and_emoji_fonts_lack_print_from_the_shipped_symbol_fonts()
    {
        using var pdf = Open(ArticlePdfFixture.Symbols);
        var letters = pdf.GetPages().SelectMany(p => p.Letters).ToList();

        OnlyShippedFonts([.. Fonts(pdf)]);
        letters.Where(l => l.Value == "★").Should().NotBeEmpty()
            .And.OnlyContain(l => (l.FontName ?? string.Empty).Contains("NotoSansSymbols2", StringComparison.Ordinal), "★ comes from Noto Sans Symbols 2");
        letters.Where(l => l.Value == "⇒").Should().NotBeEmpty()
            .And.OnlyContain(l => (l.FontName ?? string.Empty).Contains("NotoSansMath", StringComparison.Ordinal), "⇒ comes from Noto Sans Math");
    }

    [Theory]
    [MemberData(nameof(Languages))]
    public void Emoji_print_as_emoji_glyphs(string language)
    {
        using var pdf = Open(language);

        var emoji = pdf.GetPages().SelectMany(p => p.Letters).Where(l => l.Value.Contains('☕') || l.Value.Contains("🚀", StringComparison.Ordinal)).ToList();

        emoji.Should().NotBeEmpty();
        emoji.Should().OnlyContain(l => l.FontName == "Type3",
            "an emoji comes from the emoji font, never as a missing glyph of the text font");
    }

    // ---- Rule 3: nothing cut off ----

    [Theory]
    [MemberData(nameof(Languages))]
    public void Text_images_and_links_stay_inside_the_margins(string language)
    {
        using var pdf = Open(language);
        // A glyph's ink may overhang its advance a little (e.g. the first Arabic letter of a line): about 1 mm.
        const double tolerance = 3;
        var left = PdfLines.SideMargin - tolerance;
        var right = PdfLines.PageWidth - PdfLines.SideMargin + tolerance;
        var top = PdfLines.PageHeight - PdfLines.TopMargin + tolerance;

        foreach (var page in pdf.GetPages())
        {
            page.Letters.Where(l => !string.IsNullOrWhiteSpace(l.Value)).Should().OnlyContain(
                l => l.BoundingBox.Left >= left && l.BoundingBox.Right <= right && l.BoundingBox.Top <= top,
                $"page {page.Number} has a glyph outside the margins");
            page.GetImages().Should().OnlyContain(i => i.BoundingBox.Left >= left && i.BoundingBox.Right <= right && i.BoundingBox.Top <= top && i.BoundingBox.Bottom >= 0,
                $"page {page.Number} has an image outside the page or its margins");
        }
    }

    [Theory]
    [MemberData(nameof(Languages))]
    public void Long_urls_long_words_code_and_tables_print_in_full(string language)
    {
        using var pdf = Open(language);
        // Without sentence periods: in an RTL line the period of "…WordEnd." sits at the left, before the wrapped word's end.
        var text = string.Concat(pdf.GetPages().Select(p => PdfLines.Normalize(string.Concat(p.Letters.Select(l => l.Value))))).Replace(".", string.Empty, StringComparison.Ordinal);

        // Content-stream order keeps each wrapped line's glyphs together, so a long token reads back whole.
        text.Should().Contain("Pneumonoultramicroscopicsilicovolcanoconiosis_and_then_some_more_letters_without_any_space_ReadInLongWordEnd");
        text.Should().Contain("trackChanges:false");
        text.Should().Contain("//LongCodeLastLine");
        text.Should().Contain("WideRowOneEnd").And.Contain("WideRowTwoEnd");
        pdf.GetPages().SelectMany(p => p.GetHyperlinks()).Select(h => h.Uri ?? string.Empty).Should().Contain(
            u => u.StartsWith("https://example.com/a/really/long/path/", StringComparison.Ordinal)
                 && (u.EndsWith("yet-another=1234567890", StringComparison.Ordinal) || u.EndsWith("another=another-value", StringComparison.Ordinal)),
            "the very long URL is one clickable link");
    }

    /// <summary>
    /// Bug F33-3: cells could break anywhere, so the browser squeezed short columns ("600" → "60" over "0", "العمود" →
    /// "العم" over "ود"). A cell now wraps at spaces only, so the first line of a row holds every number and short word whole.
    /// </summary>
    [Theory]
    [InlineData("en", "C1C2C3C4C5C6C7C8C9C10C11WideTableLastHeader")]
    [InlineData("en", "1020304050607080WideRowTwoEnd")]
    [InlineData("ar-EG", "WideRowThreeEnd800700600500400300200100")]
    public void A_wide_table_never_splits_a_number_or_a_word(string language, string row)
    {
        using var pdf = Open(language);
        var lines = PdfLines.Lines(pdf);

        lines.Should().Contain(l => l.LeftToRight.Contains(row, StringComparison.Ordinal), $"one line reads \"{row}\" (left to right)");
        if (language == "ar-EG")
        {
            lines.Should().Contain(l => l.LeftToRight.Contains("WideTableLastHeader", StringComparison.Ordinal)
                                        && l.RightToLeft.Contains(PdfLines.Normalize("العمود"), StringComparison.Ordinal),
                "the Arabic headers keep their words whole and joined");
        }
    }

    [Theory]
    [MemberData(nameof(Languages))]
    public void A_tall_image_fits_on_one_page_with_its_caption(string language)
    {
        using var pdf = Open(language);
        var lines = PdfLines.Lines(pdf);

        var tall = pdf.GetPages().SelectMany(p => p.GetImages().Select(i => (Page: p.Number, Image: i)))
            .Single(x => x.Image.BoundingBox.Height > 2.5 * x.Image.BoundingBox.Width);
        var caption = lines.First(l => l.LeftToRight.Contains("TallImageCaption", StringComparison.Ordinal));

        tall.Image.BoundingBox.Height.Should().BeLessThan(PdfLines.PageHeight - PdfLines.TopMargin - PdfLines.BottomMargin);
        caption.Page.Should().Be(tall.Page, "an image stays with its caption");
        caption.Baseline.Should().BeLessThan(tall.Image.BoundingBox.Bottom, "the caption is under the image");
    }

    // ---- Rule 4: clean page breaks ----

    [Theory]
    [MemberData(nameof(Languages))]
    public void A_heading_is_never_the_last_thing_on_a_page(string language) => HeadingsKeepWithNext(language);

    [Fact]
    public void Headings_keep_with_the_lines_after_them_in_a_long_document() => HeadingsKeepWithNext(ArticlePdfFixture.PageBreaks);

    [Theory]
    [MemberData(nameof(Languages))]
    public void Images_stay_with_their_captions(string language)
    {
        using var pdf = Open(language);
        var lines = PdfLines.Lines(pdf);

        foreach (var caption in new[] { "TallImageCaption", "AttachmentCaption", "objectgraph" })
        {
            var line = lines.First(l => l.LeftToRight.Contains(caption, StringComparison.Ordinal) || l.LtrReadingOrder.Contains(caption, StringComparison.Ordinal));
            pdf.GetPage(line.Page).GetImages().Should().Contain(i => i.BoundingBox.Bottom > line.Baseline && i.BoundingBox.Bottom - line.Baseline < 60,
                $"\"{caption}\" sits right under its image on page {line.Page}");
        }
    }

    [Theory]
    [InlineData("en", "Important tip", "touches a DbContext")]
    [InlineData("en", "Danger", "inside ConfigureServices")]
    [InlineData("ar-EG", "نصيحة مهمة", "DbContext")]
    [InlineData("en", "var builder = WebApplication.CreateBuilder(args);", "// end of short code")]
    [InlineData("ar-EG", "var builder = WebApplication.CreateBuilder(args);", "// end of short code")]
    [InlineData("ar-EG", "Row 06", "جوه الخلية")]
    [InlineData("en", "Write the interface", "For example IOrderService.")]
    public void Callouts_short_code_steps_and_table_rows_never_split(string language, string first, string last)
    {
        using var pdf = Open(language);
        var lines = PdfLines.Lines(pdf);

        var page = PdfLines.PageOf(lines, first);
        page.Should().BePositive($"\"{first}\" is printed");
        PdfLines.PageOf(lines, last).Should().Be(page, $"\"{first}\" … \"{last}\" is one block that never splits");
    }

    [Theory]
    [MemberData(nameof(Languages))]
    public void A_long_table_repeats_its_header_on_every_page_and_long_code_continues_after_its_heading(string language)
    {
        using var pdf = Open(language);
        var lines = PdfLines.Lines(pdf);

        if (language == "ar-EG")
        {
            var rowPages = Enumerable.Range(1, 40).Select(r => PdfLines.PageOf(lines, $"Row {r:00}")).Distinct().ToList();
            rowPages.Should().HaveCountGreaterThan(1, "the 40-row table continues on the next page");
            rowPages.Should().OnlyContain(p => PdfLines.PagesOf(lines, "LongTableHeader").Contains(p), "the header repeats on each page");
        }

        var heading = language == "ar-EG" ? "كود طويل بيكمّل في الصفحة اللي بعدها" : "Long code continues on the next page";
        PdfLines.PageOf(lines, "namespace Shop.Orders;").Should().Be(PdfLines.PageOf(lines, heading), "the heading stays with the code's first lines");
        PdfLines.PageOf(lines, "// LongCodeLastLine").Should().BeGreaterThanOrEqualTo(PdfLines.PageOf(lines, "namespace Shop.Orders;"));
    }

    [Fact]
    public void Paragraphs_keep_two_lines_on_each_side_of_a_break_and_list_items_and_short_code_never_split()
    {
        using var pdf = Open(ArticlePdfFixture.PageBreaks);
        var lines = PdfLines.Lines(pdf).Where(l => l.Baseline > PdfLines.BottomMargin).ToList();

        var crossings = 0;
        foreach (var paragraph in lines.Select(l => Token().Match(l.LeftToRight)).Where(m => m.Success && m.Groups["kind"].Value == "p")
                     .Select(m => m.Groups["id"].Value).Distinct())
        {
            var pages = lines.Where(l => Token().Matches(l.LeftToRight).Any(m => m.Groups["kind"].Value == "p" && m.Groups["id"].Value == paragraph))
                .GroupBy(l => l.Page).Select(g => g.Count()).ToList();
            if (pages.Count < 2) continue;
            crossings++;
            pages.Should().OnlyContain(count => count >= 2, $"paragraph {paragraph} keeps at least 2 lines on each side of a page break");
        }
        crossings.Should().BePositive("the document is long enough for a paragraph to cross a page break");

        foreach (var item in lines.SelectMany(l => Token().Matches(l.LeftToRight)).Where(m => m.Groups["kind"].Value is "l" or "c")
                     .Select(m => m.Groups["kind"].Value + m.Groups["id"].Value).Distinct())
        {
            lines.Where(l => Token().Matches(l.LeftToRight).Any(m => m.Groups["kind"].Value + m.Groups["id"].Value == item))
                .Select(l => l.Page).Distinct().Should().ContainSingle($"{item} (a list item or code of up to 20 lines) never splits");
        }
    }

    [Theory]
    [InlineData("ar-EG")]
    [InlineData("en")]
    [InlineData(ArticlePdfFixture.PageBreaks)]
    public void There_are_no_blank_pages_not_even_at_the_end(string name)
    {
        using var pdf = Open(name);

        foreach (var page in pdf.GetPages())
        {
            var content = page.Letters.Count(l => !string.IsNullOrWhiteSpace(l.Value) && l.StartBaseLine.Y > PdfLines.BottomMargin)
                          + page.GetImages().Count(i => i.BoundingBox.Bottom > PdfLines.BottomMargin);
            content.Should().BePositive($"page {page.Number} of {pdf.NumberOfPages} has content, not only the footer");
        }
    }

    // ---- Rule 5: real text ----

    [Theory]
    [MemberData(nameof(Languages))]
    public void Every_page_is_selectable_searchable_text_with_clickable_links(string language)
    {
        var bytes = fixture.Pdf(language);
        using var pdf = PdfDocument.Open(bytes);

        PdfiumText.Pages(bytes).Should().HaveCount(pdf.NumberOfPages).And.OnlyContain(text => text.Trim().Length > 20, "pages are text, never images");
        var links = pdf.GetPages().SelectMany(p => p.GetHyperlinks()).Select(h => h.Uri).ToList();
        links.Should().Contain("https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection");
        links.Should().Contain("https://readin.app/@editorial", "a mention links to the profile");
        links.Should().Contain("https://readin.app/@youssef_dev", "the writer links to the profile");
        links.Should().Contain("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "an embed is a card with its link");
        links.Should().Contain(l => l != null && l.StartsWith($"https://readin.app/{(language == "en" ? "en" : "ar")}/a/", StringComparison.Ordinal),
            "the end links to the article on ReadIn");
    }

    // ---- Rule 6: a proper document ----

    [Theory]
    [MemberData(nameof(Languages))]
    public void It_is_tagged_with_title_author_and_language_and_bookmarks_from_h2_and_h3(string language)
    {
        using var pdf = Open(language);
        var document = ArticlePdfFixtures.Document(language);
        var catalog = pdf.Structure.Catalog.CatalogDictionary;

        catalog.TryGet(NameToken.StructTreeRoot, out _).Should().BeTrue("the PDF is tagged");
        catalog.TryGet(NameToken.MarkInfo, out _).Should().BeTrue();
        catalog.TryGet(NameToken.Lang, out var lang).Should().BeTrue();
        ((StringToken)lang).Data.Should().Be(language);
        pdf.Information.Title.Should().Be(document.Title);
        pdf.Information.Author.Should().Be(document.Author.DisplayName);

        pdf.TryGetBookmarks(out var bookmarks).Should().BeTrue();
        var nodes = bookmarks!.GetNodes().ToList();
        nodes.Select(n => n.Title).Should().Equal(ArticlePdfHtml.Headings(document.Content), "one bookmark per H2/H3 in reading order, no contents page");
        var levels = document.Content.GetProperty("blocks").EnumerateArray().Where(b => b.GetProperty("type").GetString() == "heading")
            .Select(b => b.GetProperty("level").GetInt32() - 2);
        nodes.Select(n => n.Level).Should().Equal(levels, "H3 bookmarks sit under their H2");
        nodes.OfType<DocumentBookmarkNode>().Should().OnlyContain(n => n.PageNumber >= 1 && n.PageNumber <= pdf.NumberOfPages);
    }

    [Theory]
    [MemberData(nameof(Languages))]
    public void Digits_are_western_everywhere_and_every_footer_numbers_its_page(string language)
    {
        var bytes = fixture.Pdf(language);
        using var pdf = PdfDocument.Open(bytes);
        var footers = PdfLines.Lines(pdf).Where(l => l.Baseline < PdfLines.BottomMargin).ToList();

        string.Concat(PdfiumText.Pages(bytes)).Should().NotMatchRegex("[٠-٩۰-۹]");
        for (var page = 1; page <= pdf.NumberOfPages; page++)
        {
            string.Concat(footers.Where(l => l.Page == page).Select(l => l.LeftToRight)).Should().Contain($"{page}/{pdf.NumberOfPages}")
                .And.Contain("readin.app", $"page {page} has the footer");
        }
    }

    // ---- Rule 7: small file ----

    [Theory]
    [MemberData(nameof(Languages))]
    public void A_typical_article_stays_under_five_megabytes(string language) =>
        fixture.Pdf(language).Length.Should().BeLessThan(5 * 1024 * 1024);

    private void HeadingsKeepWithNext(string name)
    {
        using var pdf = Open(name);
        pdf.TryGetBookmarks(out var bookmarks).Should().BeTrue();

        foreach (var heading in bookmarks!.GetNodes().OfType<DocumentBookmarkNode>())
        {
            var page = pdf.GetPage(heading.PageNumber);
            var top = heading.Destination.Coordinates.Top ?? PdfLines.PageHeight;
            // The destination is the top of the heading's glyphs; its baseline is ~10-15 pt lower and the next line ~35 pt.
            page.Letters.Should().Contain(l => !string.IsNullOrWhiteSpace(l.Value) && l.StartBaseLine.Y < top - 24 && l.StartBaseLine.Y > PdfLines.BottomMargin,
                $"\"{heading.Title}\" on page {heading.PageNumber} is followed by its first lines");
        }
    }

    private static void OnlyShippedFonts(IReadOnlyList<(string Name, string Subtype, bool Embedded)> fonts)
    {
        fonts.Should().NotBeEmpty();
        fonts.Should().OnlyContain(f => f.Embedded, "nothing depends on fonts installed on the server");
        fonts.Where(f => f.Subtype != "Type3").Select(f => Regex.Replace(f.Name, "^[A-Z]{6}\\+", string.Empty))
            .Should().OnlyContain(name => name.StartsWith("IBMPlexSansArabic", StringComparison.Ordinal) || name.StartsWith("IBMPlexSans", StringComparison.Ordinal)
                                          || name.StartsWith("JetBrainsMono", StringComparison.Ordinal) || name.StartsWith("NotoSans", StringComparison.Ordinal),
                "every font is one the API ships (IBM Plex, JetBrains Mono, Noto Sans and its symbol fonts)");
    }

    private static IEnumerable<(string Name, string Subtype, bool Embedded)> Fonts(PdfDocument pdf)
    {
        var seen = new HashSet<UglyToad.PdfPig.Core.IndirectReference>();
        foreach (var page in pdf.GetPages())
        {
            if (!page.Dictionary.TryGet(NameToken.Resources, out var resourcesToken)) continue;
            if (Resolve(pdf, resourcesToken) is not DictionaryToken resources || !resources.TryGet(NameToken.Font, out var fontsToken)) continue;
            if (Resolve(pdf, fontsToken) is not DictionaryToken fonts) continue;
            foreach (var (_, value) in fonts.Data)
            {
                if (value is IndirectReferenceToken reference && !seen.Add(reference.Data)) continue;
                if (Resolve(pdf, value) is not DictionaryToken font) continue;
                var subtype = font.TryGet(NameToken.Subtype, out var s) ? ((NameToken)s).Data : "?";
                var name = font.TryGet(NameToken.BaseFont, out var b) ? ((NameToken)b).Data : subtype;
                if (subtype == "Type3")
                {
                    yield return (name, subtype, font.TryGet(NameToken.CharProcs, out _));
                    continue;
                }
                var descriptorHolder = font;
                if (subtype == "Type0" && font.TryGet(NameToken.DescendantFonts, out var descendants)
                    && Resolve(pdf, descendants) is ArrayToken { Data.Count: > 0 } array && Resolve(pdf, array.Data[0]) is DictionaryToken descendant)
                    descriptorHolder = descendant;
                var embedded = descriptorHolder.TryGet(NameToken.FontDescriptor, out var d) && Resolve(pdf, d) is DictionaryToken descriptor
                               && (descriptor.TryGet(NameToken.FontFile, out _) || descriptor.TryGet(NameToken.FontFile2, out _) || descriptor.TryGet(NameToken.FontFile3, out _));
                yield return (name, subtype, embedded);
            }
        }
    }

    private static IToken? Resolve(PdfDocument pdf, IToken? token) =>
        token is IndirectReferenceToken reference ? pdf.Structure.GetObject(reference.Data).Data : token;

    [GeneratedRegex(@"(?<kind>[plc])(?<id>\d\d(?:i\d)?)(?:w|n)\d{2,3}")]
    private static partial Regex Token();
}
