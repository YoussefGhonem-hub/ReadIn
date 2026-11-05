using System.Text.Json;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using ReadIn.Application.Features.Articles.Pdf;
using ReadIn.Infrastructure.Pdf;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// The article PDF test inputs (SPEC F33, §27): the shared stress fixtures in <c>shared/rdoc/examples/pdf</c> (every
/// block type, mixed text, emoji, a very long URL, a wide and a long table, long code and a tall image), with pictures
/// made here, as the uploads folder would give them.
/// </summary>
internal static class ArticlePdfFixtures
{
    public const string WideImageSrc = "rdoc-asset://uploads/images/2026/11/22222222222222222222222222222222_1600.webp";
    public const string TallImageSrc = "rdoc-asset://uploads/images/2026/11/11111111111111111111111111111111_800.webp";
    public const string ExternalImageSrc = "https://picsum.photos/seed/readin-di/1200/630";

    public static readonly string[] Languages = ["ar-EG", "en"];

    private static readonly Lazy<byte[]> WideImage = new(() => Picture(1600, 900, SKColors.SteelBlue, SKColors.Orange));
    private static readonly Lazy<byte[]> TallImage = new(() => Picture(800, 3000, SKColors.SeaGreen, SKColors.Gold));
    private static readonly Lazy<byte[]> CoverImage = new(() => Picture(1200, 630, SKColors.DarkSlateGray, SKColors.Coral));

    public static string FixturePath(string language) =>
        Path.Combine(AppContext.BaseDirectory, "fixtures", "rdoc-pdf", $"pdf-stress.{language}.json");

    public static JsonElement Content(string language)
    {
        using var document = JsonDocument.Parse(File.ReadAllText(FixturePath(language)));
        return document.RootElement.Clone();
    }

    /// <summary>The shared mixed Arabic/English samples (shared/bidi/fixtures.json, SPEC §14.2 rule 7).</summary>
    public static IReadOnlyList<(string Id, string Text, string ExpectedDir)> BidiSamples()
    {
        using var document = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "fixtures", "bidi", "fixtures.json")));
        return [.. document.RootElement.GetProperty("fixtures").EnumerateArray()
            .Select(f => (f.GetProperty("id").GetString()!, f.GetProperty("text").GetString()!, f.GetProperty("expectedDir").GetString()!))];
    }

    public static ArticlePdfDocument Document(string language)
    {
        var arabic = language == "ar-EG";
        return new ArticlePdfDocument
        {
            ArticleId = Guid.Parse("0195f3a0-0000-7000-8000-00000000f033"),
            Language = language,
            Slug = arabic ? "الـ-pdf-بتاع-readin" : "the-readin-pdf",
            Title = arabic ? "الـ Dependency Injection في ASP.NET Core: دليل عملي 2026" : "Dependency Injection in ASP.NET Core: a practical guide (الحقن)",
            Subtitle = arabic ? "إزاي تبني app سهل يتغيّر ويتختبر" : "How to build an app that is easy to change and to test",
            Author = new ArticlePdfAuthor(arabic ? "يوسف غنيم" : "Youssef Ghonem", "youssef_dev", IsVerified: true),
            PublishedOn = new DateOnly(2026, 11, 5),
            ReadingTimeMinutes = 7,
            FieldName = arabic ? "الطب" : "Medicine",
            TopicName = arabic ? "الصحة العامة" : "Public health",
            Tags = arabic ? ["الذكاء الاصطناعي", ".NET", "C#"] : [".NET", "C#", "الذكاء الاصطناعي"],
            ShowHealthDisclaimer = true,
            IsAiAssisted = true,
            Cover = new ArticlePdfImage(CoverImage.Value, "image/webp"),
            Content = Content(language),
            Images = new Dictionary<string, ArticlePdfImage>
            {
                [WideImageSrc] = new(WideImage.Value, "image/webp"),
                [TallImageSrc] = new(TallImage.Value, "image/webp"),
            },
            Sources =
            [
                new ArticlePdfSource(arabic ? "توثيق Microsoft للـ DI" : "Microsoft docs on DI", "https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection"),
                new ArticlePdfSource("A very long source URL",
                    "https://example.com/sources/a/very/long/path/that/must/wrap/inside/the/margins/0123456789abcdefghijklmnopqrstuvwxyz/0123456789abcdefghijklmnopqrstuvwxyz/end?with=query&and=more"),
            ],
            ImageAttachments = [new ArticlePdfImageAttachment(new ArticlePdfImage(WideImage.Value, "image/webp"), arabic ? "مرفق" : "Attachment", arabic ? "كابشن المرفق AttachmentCaption" : "AttachmentCaption: an image attachment")],
        };
    }

    /// <summary>
    /// Many sections of headings, paragraphs, list items and short code whose words name where they belong
    /// (<c>p03w017</c>: paragraph 3, word 17), so page breaks can be checked line by line (No-bug rule 4).
    /// </summary>
    public static ArticlePdfDocument PageBreakDocument()
    {
        var blocks = new List<object>();
        for (var k = 1; k <= 16; k++)
        {
            blocks.Add(new { id = $"h{k}", type = "heading", level = k % 3 == 0 ? 3 : 2, content = new[] { new { type = "text", text = $"Heading {k:00}" } } });
            var words = 45 + (k * 37 % 70);
            blocks.Add(new { id = $"p{k}", type = "paragraph", content = new[] { new { type = "text", text = Words($"p{k:00}w", words) } } });
            if (k % 4 == 0)
            {
                blocks.Add(new
                {
                    id = $"l{k}", type = "bulletList",
                    items = Enumerable.Range(1, 3).Select(j => new[] { new { type = "text", text = Words($"l{k:00}i{j}w", 34) } }).ToArray(),
                });
            }
            if (k % 5 == 0)
            {
                blocks.Add(new
                {
                    id = $"c{k}", type = "code", lang = "csharp",
                    code = string.Join('\n', Enumerable.Range(1, ArticlePdfHtml.ShortCodeLines).Select(n => $"c{k:00}n{n:00} = Compute({n});")),
                });
            }
        }

        using var content = JsonDocument.Parse(JsonSerializer.Serialize(new { version = 1, language = "en", blocks }));
        return Document("en") with
        {
            Title = "Page breaks",
            Subtitle = null,
            Tags = [],
            ShowHealthDisclaimer = false,
            Cover = null,
            Content = content.RootElement.Clone(),
            Images = new Dictionary<string, ArticlePdfImage>(),
            Sources = [],
            ImageAttachments = [],
        };

        static string Words(string prefix, int count) =>
            string.Join(' ', Enumerable.Range(1, count).Select(i => $"{prefix}{i:000}"));
    }

    /// <summary>
    /// An English article whose only emoji are outside the BMP, a flag and a ZWJ sequence included (no ☕ or ✅ to bring
    /// the emoji font in by themselves): every one prints from Noto Color Emoji, never from the server's fonts (rule 2).
    /// </summary>
    public static ArticlePdfDocument EmojiOnlyDocument() => ShortDocument("Shipped", EmojiOnlyText);

    public const string EmojiOnlyText = "We shipped it 🚀 and everyone smiled 😀. The team 👩‍💻 from 🇪🇬 celebrated 🎉 with 🍕.";

    /// <summary>Symbols none of the text or emoji fonts have (★, ⇒ …): they print from the symbol fonts the API ships (rule 2).</summary>
    public static ArticlePdfDocument SymbolsDocument() => ShortDocument("Symbols", SymbolsText);

    public const string SymbolsText = "Rated ★★★★☆ by readers ⇒ ship it ⟶ done ◆ ■ ▲ ▶ ☐ ⌘ ⌥ ⏎ ∑ ≠ ≤ ∞ ✓ ✗";

    private static ArticlePdfDocument ShortDocument(string title, string text)
    {
        using var content = JsonDocument.Parse(JsonSerializer.Serialize(new
        {
            version = 1,
            language = "en",
            blocks = new[] { new { id = "p1", type = "paragraph", content = new[] { new { type = "text", text } } } },
        }));
        return Document("en") with
        {
            Title = title,
            Subtitle = null,
            Tags = [],
            ShowHealthDisclaimer = false,
            Cover = null,
            Content = content.RootElement.Clone(),
            Images = new Dictionary<string, ArticlePdfImage>(),
            Sources = [],
            ImageAttachments = [],
        };
    }

    public static ArticlePdfOptions Options(string? chromiumPath = null) => new()
    {
        ChromiumPath = chromiumPath,
        WebBaseUrl = "https://readin.app",
        BuildTimeout = TimeSpan.FromSeconds(60),
        QueueTimeout = TimeSpan.FromSeconds(60),
    };

    public static ArticlePdfRenderer Renderer(ChromiumBrowser browser, ArticlePdfOptions options) =>
        new(browser, new PdfBuildGate(Microsoft.Extensions.Options.Options.Create(options), TimeProvider.System, NullLogger<PdfBuildGate>.Instance),
            Microsoft.Extensions.Options.Options.Create(options), NullLogger<ArticlePdfRenderer>.Instance);

    public static ChromiumBrowser Browser(ArticlePdfOptions options) =>
        new(Microsoft.Extensions.Options.Options.Create(options), NullLogger<ChromiumBrowser>.Instance);

    /// <summary>A WebP with two colour bands and a frame, so its edges show in page images.</summary>
    private static byte[] Picture(int width, int height, SKColor background, SKColor band)
    {
        using var bitmap = new SKBitmap(width, height);
        using (var canvas = new SKCanvas(bitmap))
        {
            canvas.Clear(background);
            using var paint = new SKPaint { Color = band };
            canvas.DrawRect(0, height / 3f, width, height / 3f, paint);
            using var frame = new SKPaint { Color = SKColors.Black, Style = SKPaintStyle.Stroke, StrokeWidth = Math.Max(4, width / 100f) };
            canvas.DrawRect(0, 0, width, height, frame);
        }
        using var data = bitmap.Encode(SKEncodedImageFormat.Webp, 80);
        return data.ToArray();
    }
}
