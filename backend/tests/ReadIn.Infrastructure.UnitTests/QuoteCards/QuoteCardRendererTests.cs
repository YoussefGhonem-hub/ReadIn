using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using ReadIn.Application.Features.Articles.QuoteCards;
using ReadIn.Infrastructure.Pdf;
using ReadIn.Infrastructure.QuoteCards;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.QuoteCards;

/// <summary>The two approved cards and the texts the tests draw (SPEC F24).</summary>
internal static class QuoteCardSamples
{
    /// <summary>Arabic with English inside, a verified writer: the approved light square card.</summary>
    public static QuoteCard Arabic(QuoteCardTheme theme, QuoteCardFormat format) => new()
    {
        Quote = "لو انت شغال بـ ASP.NET Core، أكيد شفت الـ Dependency Injection في كل حتة. الكود النضيف مش رفاهية، ده احترام للي هيقرا بعدك.",
        Language = "ar-EG",
        Dir = "rtl",
        Title = "الـ Dependency Injection في ASP.NET Core: دليل عملي 2026",
        AuthorName = "يوسف غنيم",
        AuthorIsVerified = true,
        Slug = "dependency-injection-aspnet-core",
        Theme = theme,
        Format = format,
    };

    /// <summary>English with Arabic inside, an emoji and a deleted writer: the approved dark landscape card.</summary>
    public static QuoteCard English(QuoteCardTheme theme, QuoteCardFormat format) => new()
    {
        Quote = "Use Dependency Injection (الحقن) everywhere: it makes testing easy 😀. A class asks for what it needs, and the app decides what it gets.",
        Language = "en",
        Dir = "ltr",
        Title = "Dependency Injection in ASP.NET Core: a practical guide",
        AuthorName = null,
        AuthorIsVerified = false,
        Slug = "dependency-injection-aspnet-core",
        Theme = theme,
        Format = format,
    };
}

[CollectionDefinition(Name)]
public sealed class QuoteCardCollection : ICollectionFixture<QuoteCardFixture>
{
    public const string Name = "Quote card";
}

/// <summary>One headless Chromium for the card tests (installed as for the article PDFs, docs/setup/deployment.md §10).</summary>
public sealed class QuoteCardFixture : IAsyncLifetime
{
    private ChromiumBrowser? _browser;

    internal QuoteCardRenderer Renderer(QuoteCardOptions? options = null)
    {
        var pdf = new ArticlePdfOptions { WebBaseUrl = "https://readin.app", MaxConcurrentBuilds = 2 };
        var card = options ?? new QuoteCardOptions { QueueTimeout = TimeSpan.FromSeconds(60), BuildTimeout = TimeSpan.FromSeconds(60) };
        var gate = new PdfBuildGate(Options.Create(pdf), TimeProvider.System, NullLogger<PdfBuildGate>.Instance);
        return new QuoteCardRenderer(_browser!, gate, Options.Create(card), Options.Create(pdf), NullLogger<QuoteCardRenderer>.Instance);
    }

    public ValueTask InitializeAsync()
    {
        _browser = new ChromiumBrowser(Options.Create(new ArticlePdfOptions()), NullLogger<ChromiumBrowser>.Instance);
        return ValueTask.CompletedTask;
    }

    public async ValueTask DisposeAsync()
    {
        if (_browser is not null) await _browser.DisposeAsync();
    }
}

/// <summary>
/// Quote cards drawn by the real headless Chromium (SPEC F24, ADR 0019): the exact PNG sizes, the quote's font fitted to
/// its box (largest for a short quote, smaller for a long one, never cut, line breaks kept while they fit), and the two
/// approved images (SPEC §27: Arabic light square, English dark landscape). Set <c>READIN_QUOTE_OUT</c> to a folder to
/// get every card drawn here for a look.
/// </summary>
[Collection(QuoteCardCollection.Name)]
public sealed class QuoteCardRendererTests(QuoteCardFixture fixture)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    public static TheoryData<QuoteCardTheme, QuoteCardFormat> Variants() => new()
    {
        { QuoteCardTheme.Light, QuoteCardFormat.Square },
        { QuoteCardTheme.Dark, QuoteCardFormat.Square },
        { QuoteCardTheme.Light, QuoteCardFormat.Landscape },
        { QuoteCardTheme.Dark, QuoteCardFormat.Landscape },
    };

    private async Task<QuoteCardDrawing> DrawAsync(QuoteCard card, string name)
    {
        var drawn = await fixture.Renderer().DrawAsync(card, Ct);
        drawn.IsSuccess.Should().BeTrue(drawn.Error?.Code);
        if (Environment.GetEnvironmentVariable("READIN_QUOTE_OUT") is { Length: > 0 } output)
        {
            Directory.CreateDirectory(output);
            await File.WriteAllBytesAsync(Path.Combine(output, name + ".png"), drawn.Value.Png, Ct);
        }
        return drawn.Value;
    }

    [Theory]
    [MemberData(nameof(Variants))]
    public async Task Every_theme_and_format_is_a_png_of_its_exact_size(QuoteCardTheme theme, QuoteCardFormat format)
    {
        foreach (var card in new[] { QuoteCardSamples.Arabic(theme, format), QuoteCardSamples.English(theme, format) })
        {
            var drawing = await DrawAsync(card, $"size.{card.Language}.{theme}.{format}".ToLowerInvariant());

            drawing.Png.AsSpan(0, 8).ToArray().Should().Equal([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], "a PNG");
            using var image = SKBitmap.Decode(drawing.Png);
            var (width, height) = QuoteCardFormats.Size(format);
            (image.Width, image.Height).Should().Be((width, height));
            drawing.Fit.Fits.Should().BeTrue();
            drawing.Png.Length.Should().BeLessThan(1024 * 1024, "a card is small enough to share");
        }
    }

    [Theory]
    [InlineData(QuoteCardFormat.Square)]
    [InlineData(QuoteCardFormat.Landscape)]
    public async Task A_short_quote_gets_the_largest_font_and_a_long_one_a_smaller_one_that_still_fits(QuoteCardFormat format)
    {
        var (max, min, _) = QuoteCardHtml.FontRange(format);

        var shortQuote = await DrawAsync(QuoteCardSamples.English(QuoteCardTheme.Light, format) with { Quote = "Read daily. Grow daily." }, $"short.{format}".ToLowerInvariant());
        var longQuote = await DrawAsync(QuoteCardSamples.Arabic(QuoteCardTheme.Light, format) with { Quote = LongArabic(QuoteCardErrors.MaxLength) }, $"long.{format}".ToLowerInvariant());

        shortQuote.Fit.FontSize.Should().Be(max);
        longQuote.Fit.FontSize.Should().BeLessThan(max).And.BeGreaterThanOrEqualTo(min);
        longQuote.Fit.QuoteHeight.Should().BeLessThanOrEqualTo(longQuote.Fit.Room + 0.5, "the quote never leaves its box");
        longQuote.Fit.BreaksAsSpaces.Should().BeFalse();
    }

    public static TheoryData<string, QuoteCardFormat> Hardest() => new()
    {
        { "wide-latin", QuoteCardFormat.Square },
        { "wide-latin", QuoteCardFormat.Landscape },
        { "arabic-no-spaces", QuoteCardFormat.Square },
        { "arabic-no-spaces", QuoteCardFormat.Landscape },
        { "emoji", QuoteCardFormat.Square },
        { "emoji", QuoteCardFormat.Landscape },
        { "many-breaks", QuoteCardFormat.Square },
        { "many-breaks", QuoteCardFormat.Landscape },
    };

    [Theory]
    [MemberData(nameof(Hardest))]
    public async Task The_hardest_quotes_of_400_characters_fit_and_are_never_cut(string kind, QuoteCardFormat format)
    {
        var quote = kind switch
        {
            "wide-latin" => new string('W', QuoteCardErrors.MaxLength),
            "arabic-no-spaces" => string.Concat(Enumerable.Repeat("ممـ", QuoteCardErrors.MaxLength / 3)),
            "emoji" => string.Concat(Enumerable.Repeat("👨‍💻", QuoteCardErrors.MaxLength / 5)),
            _ => string.Join('\n', Enumerable.Range(0, QuoteCardErrors.MaxLength / 4).Select(i => $"{i % 100:00}x")),
        };
        quote.Length.Should().BeLessThanOrEqualTo(QuoteCardErrors.MaxLength);

        // Arabic text comes from a right-to-left block.
        var dir = kind == "arabic-no-spaces" ? "rtl" : "ltr";
        var drawing = await DrawAsync(QuoteCardSamples.English(QuoteCardTheme.Dark, format) with { Quote = quote, Dir = dir }, $"hard.{kind}.{format}".ToLowerInvariant());

        drawing.Fit.Fits.Should().BeTrue();
        drawing.Fit.FontSize.Should().BeGreaterThanOrEqualTo(QuoteCardHtml.FontRange(format).Floor);
        drawing.Fit.BreaksAsSpaces.Should().Be(kind == "many-breaks", "line breaks become spaces only when the quote can't fit with them");
        // Only text nobody selects to share (400 wide letters without a space) goes below the readable size.
        if (kind != "wide-latin") drawing.Fit.FontSize.Should().BeGreaterThanOrEqualTo(QuoteCardHtml.FontRange(format).Min);
    }

    [Fact]
    public async Task Line_breaks_stay_when_the_quote_fits_with_them()
    {
        var drawing = await DrawAsync(QuoteCardSamples.English(QuoteCardTheme.Light, QuoteCardFormat.Square) with { Quote = "One\nTwo words here" }, "breaks");

        drawing.Fit.BreaksAsSpaces.Should().BeFalse();
        drawing.Fit.FontSize.Should().Be(QuoteCardHtml.FontRange(QuoteCardFormat.Square).Max);
    }

    [Fact]
    public async Task A_card_that_gets_no_slot_in_time_is_busy_and_one_that_runs_out_of_time_failed()
    {
        var busy = fixture.Renderer(new QuoteCardOptions { QueueTimeout = TimeSpan.Zero, BuildTimeout = TimeSpan.FromSeconds(60) });
        var hurried = fixture.Renderer(new QuoteCardOptions { QueueTimeout = TimeSpan.FromSeconds(60), BuildTimeout = TimeSpan.FromMilliseconds(1) });

        // Two slots, both taken by long cards: a third request with no wait at all is busy.
        var card = QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square);
        var first = busy.DrawAsync(card, Ct);
        var second = busy.DrawAsync(card, Ct);
        var third = await busy.DrawAsync(card, Ct);
        await Task.WhenAll(first, second);

        third.Error!.Code.Should().Be("quote.busy");
        (await hurried.RenderAsync(card, Ct)).Error!.Code.Should().Be("quote.failed");
        (await fixture.Renderer().RenderAsync(card, Ct)).IsSuccess.Should().BeTrue("the browser keeps drawing after a failed card");
    }

    // ---- The approved images (SPEC §27: one Arabic light, one English dark) ----

    /// <summary>A pixel differs when a colour channel moves by more than this (0–255).</summary>
    private const int PixelTolerance = 48;

    /// <summary>The share of pixels that may differ: room for glyph rasterization, not for a moved block or a wrong colour.</summary>
    private const double AllowedShare = 0.01;

    public static TheoryData<string> Approved() => ["ar-EG.light.square", "en.dark.landscape"];

    /// <summary>
    /// The two cards compared with their approved images, at full size and in colour. Linux has its own approved images
    /// (<c>*.linux.png</c>), as the PDF pages: Chrome places glyphs a fraction of a pixel differently there. To approve a
    /// deliberate change, set <c>READIN_QUOTE_BASELINES_DIR</c> to
    /// <c>backend/tests/ReadIn.Infrastructure.UnitTests/QuoteCards/baselines</c>, run the test on Windows and on Linux
    /// (docs/setup/deployment.md §10), and look at the new images. A card that differs is written to
    /// <c>{temp}/readin-pdf-baselines</c>, next to the PDF pages, which CI uploads.
    /// </summary>
    [Theory]
    [MemberData(nameof(Approved))]
    public async Task The_card_looks_like_its_approved_image(string variant)
    {
        var card = variant == "ar-EG.light.square"
            ? QuoteCardSamples.Arabic(QuoteCardTheme.Light, QuoteCardFormat.Square)
            : QuoteCardSamples.English(QuoteCardTheme.Dark, QuoteCardFormat.Landscape);
        var name = OperatingSystem.IsLinux() ? $"quote-card.{variant}.linux.png" : $"quote-card.{variant}.png";
        var drawing = await DrawAsync(card, "approved." + variant);

        if (Environment.GetEnvironmentVariable("READIN_QUOTE_BASELINES_DIR") is { Length: > 0 } approve)
        {
            Directory.CreateDirectory(approve);
            await File.WriteAllBytesAsync(Path.Combine(approve, name), drawing.Png, Ct);
            return;
        }

        var baselinePath = Path.Combine(AppContext.BaseDirectory, "QuoteCards", "baselines", name);
        File.Exists(baselinePath).Should().BeTrue($"{name} is approved (see the test's summary to create it)");
        using var baseline = SKBitmap.Decode(baselinePath);
        using var actual = SKBitmap.Decode(drawing.Png);

        (actual.Width, actual.Height).Should().Be((baseline.Width, baseline.Height));
        var differing = 0;
        for (var y = 0; y < actual.Height; y++)
        {
            for (var x = 0; x < actual.Width; x++)
            {
                var a = actual.GetPixel(x, y);
                var b = baseline.GetPixel(x, y);
                if (Math.Abs(a.Red - b.Red) > PixelTolerance || Math.Abs(a.Green - b.Green) > PixelTolerance || Math.Abs(a.Blue - b.Blue) > PixelTolerance)
                    differing++;
            }
        }

        var share = differing / (double)(actual.Width * actual.Height);
        if (share > AllowedShare)
        {
            var output = Path.Combine(Path.GetTempPath(), "readin-pdf-baselines");
            Directory.CreateDirectory(output);
            await File.WriteAllBytesAsync(Path.Combine(output, name), drawing.Png, Ct);
        }
        share.Should().BeLessThanOrEqualTo(AllowedShare,
            $"the card matches {name} (the new image is in {Path.Combine(Path.GetTempPath(), "readin-pdf-baselines")} when it doesn't)");
    }

    /// <summary>Arabic words of mixed lengths, exactly <paramref name="length"/> UTF-16 code units.</summary>
    private static string LongArabic(int length)
    {
        string[] words = ["الكود", "النضيف", "مش", "رفاهية،", "ده", "احترام", "للي", "هيقرا", "بعدك", "Dependency", "Injection", "في", "كل", "حتة."];
        var text = new System.Text.StringBuilder();
        for (var i = 0; text.Length < length; i++) text.Append(words[i % words.Length]).Append(' ');
        var quote = text.ToString(0, length);
        return quote.EndsWith(' ') ? quote[..^1] + "ه" : quote;
    }
}
