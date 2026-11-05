using System.Text;
using ReadIn.Infrastructure.Media;
using SkiaSharp;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// The fonts, logo, icons and stylesheet of article PDFs (SPEC F33), embedded in this assembly and inlined into every
/// page as <c>data:</c> URLs, so a PDF depends on nothing installed on the server and never on the network. Loaded once.
/// Fonts (OFL): IBM Plex Sans Arabic, IBM Plex Sans, JetBrains Mono, Noto Sans (fallback), Noto Color Emoji, and Noto Sans
/// Symbols 2 and Noto Sans Math for the symbols the others lack; their licenses ship next to the API
/// (<c>licenses/fonts</c>). Icons: Lucide (ISC), the same as the web reader's callouts.
/// </summary>
internal sealed class ArticlePdfAssets
{
    private const string Prefix = "ReadIn.Pdf.";

    /// <summary>The font families of the page; unique names, so a font installed on the server is never picked instead.</summary>
    public const string Arabic = "ReadIn Plex Arabic";
    public const string Latin = "ReadIn Plex";
    public const string Mono = "ReadIn Mono";
    public const string Fallback = "ReadIn Noto";
    public const string Emoji = "ReadIn Emoji";
    public const string Symbols = "ReadIn Symbols";
    public const string MathSymbols = "ReadIn Math";
    public const string FooterFamily = "ReadIn Footer";

    /// <summary>The footer's logo is 18 mm wide: about 300 dpi from this width, without the full image on every page.</summary>
    private const int FooterLogoWidth = 400;

    private static readonly Lazy<ArticlePdfAssets> Shared = new(() => new ArticlePdfAssets());

    private ArticlePdfAssets()
    {
        FontFaces = string.Concat(
            FontFace(Arabic, "IBMPlexSansArabic-Regular.ttf", 400),
            FontFace(Arabic, "IBMPlexSansArabic-SemiBold.ttf", 600),
            FontFace(Arabic, "IBMPlexSansArabic-Bold.ttf", 700),
            FontFace(Latin, "IBMPlexSans-Regular.ttf", 400),
            FontFace(Latin, "IBMPlexSans-SemiBold.ttf", 600),
            FontFace(Latin, "IBMPlexSans-Bold.ttf", 700),
            FontFace(Mono, "JetBrainsMono-Regular.ttf", 400),
            FontFace(Fallback, "NotoSans-Regular.ttf", 400),
            FontFace(Fallback, "NotoSans-Bold.ttf", 700));
        EmojiFontFace = FontFace(Emoji, "Noto-COLRv1.ttf", 400);
        SymbolFontFaces = string.Concat(
            FontFace(Symbols, "NotoSansSymbols2-Regular.ttf", 400),
            FontFace(MathSymbols, "NotoSansMath-Regular.ttf", 400));
        FooterFontFace = FontFace(FooterFamily, "IBMPlexSans-Regular.ttf", 400);

        var logo = Read("lockup.png");
        LogoDataUri = DataUri("image/png", logo);
        FooterLogoDataUri = DataUri("image/png", Downscale(logo, FooterLogoWidth));
        Stylesheet = Encoding.UTF8.GetString(Read("article.css"));
        Icons = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["tip"] = Svg("callout-tip.svg"),
            ["info"] = Svg("callout-info.svg"),
            ["warning"] = Svg("callout-warning.svg"),
            ["danger"] = Svg("callout-danger.svg"),
            ["verified"] = Svg("verified.svg"),
        };
    }

    public static ArticlePdfAssets Instance => Shared.Value;

    /// <summary><c>@font-face</c> rules of every text font.</summary>
    public string FontFaces { get; }

    /// <summary>Noto Color Emoji is large, so a page declares it only when its text has an emoji (before the symbol fonts).</summary>
    public string EmojiFontFace { get; }

    /// <summary>
    /// Noto Sans Symbols 2 (★ ✓ ✗ ◆ ▶ ☐ ⌘ ➜ …) and Noto Sans Math (⇒ ⟶ ↵ ⋯ ⊂ …), last in every font list, so a symbol the
    /// text and emoji fonts lack never falls back to the server's fonts (No-bug rule 2). Declared only when the text has one.
    /// </summary>
    public string SymbolFontFaces { get; }

    /// <summary>The footer template gets its own font: Chromium doesn't pass the page's fonts to it.</summary>
    public string FooterFontFace { get; }

    /// <summary>The approved lockup (SPEC F33), unchanged.</summary>
    public string LogoDataUri { get; }

    /// <summary>The same lockup scaled down for the 18 mm footer.</summary>
    public string FooterLogoDataUri { get; }

    public string Stylesheet { get; }

    /// <summary>Inline SVG markup (stroke = currentColor) by name: the callout variants and "verified".</summary>
    public IReadOnlyDictionary<string, string> Icons { get; }

    public static byte[] Read(string name)
    {
        using var stream = typeof(ArticlePdfAssets).Assembly.GetManifestResourceStream(Prefix + name)
                           ?? throw new InvalidOperationException($"The PDF resource {name} is missing from the build.");
        using var buffer = new MemoryStream();
        stream.CopyTo(buffer);
        return buffer.ToArray();
    }

    public static string DataUri(string mediaType, byte[] bytes) => $"data:{mediaType};base64,{Convert.ToBase64String(bytes)}";

    private static string FontFace(string family, string file, int weight) =>
        $"@font-face{{font-family:\"{family}\";src:url({DataUri("font/ttf", Read(file))}) format(\"truetype\");font-weight:{weight};font-style:normal;}}\n";

    private static string Svg(string file) => Encoding.UTF8.GetString(Read(file)).Trim();

    private static byte[] Downscale(byte[] png, int width)
    {
        using var source = SKBitmap.Decode(png) ?? throw new InvalidOperationException("The logo is not a readable PNG.");
        using var scaled = ImageEncoding.Resize(source, width);
        using var image = SKImage.FromBitmap(scaled);
        using var data = image.Encode(SKEncodedImageFormat.Png, 100) ?? throw new InvalidOperationException("The logo could not be encoded.");
        return data.ToArray();
    }
}
