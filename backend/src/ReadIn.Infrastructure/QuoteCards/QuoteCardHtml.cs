using System.Globalization;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Unicode;
using ReadIn.Application.Features.Articles.QuoteCards;
using ReadIn.Infrastructure.Pdf;

namespace ReadIn.Infrastructure.QuoteCards;

/// <summary>
/// The page Chromium draws a quote card from (SPEC F24, ADR 0019). Every piece of text and every attribute is
/// HTML-encoded; the page has no script, a CSP that allows none, and only <c>data:</c> resources (fonts, logo, icons), so
/// drawing it fetches nothing. The card and its quote take the direction the reader gives the quoted block
/// (<see cref="QuoteCard.Dir"/>); the title and the name keep their own, and runs in the other direction are isolated like
/// the reader (§14.2).
/// </summary>
internal static class QuoteCardHtml
{
    /// <summary>The element whose font size the renderer fits, and the box it must fit in.</summary>
    public const string QuoteId = "quote";
    public const string BoxId = "qbox";

    /// <summary>The steps between font sizes the renderer tries, in px.</summary>
    public const int FontStep = 2;

    private static readonly HtmlEncoder Html = HtmlEncoder.Create(UnicodeRanges.All);

    /// <summary>
    /// The quote's font sizes in px: the largest (a short quote), the smallest readable one, and a last resort below it for
    /// text nobody selects to share (400 wide letters without a space), so a quote is refused only if even that fails.
    /// </summary>
    public static (int Max, int Min, int Floor) FontRange(QuoteCardFormat format) =>
        format == QuoteCardFormat.Landscape ? (48, 24, 14) : (64, 28, 16);

    /// <summary>The quote's <c>style</c>: its size, and its line breaks as spaces when it fits no size with them.</summary>
    public static string QuoteStyle(int fontSize, bool breaksAsSpaces) =>
        string.Create(CultureInfo.InvariantCulture, $"font-size:{fontSize}px") + (breaksAsSpaces ? ";white-space:normal" : string.Empty);

    /// <summary>
    /// The card's direction: the quoted block's in the reader (<see cref="QuoteCard.Dir"/>), so an Arabic quote that starts
    /// with an English term still reads right to left. Only <c>rtl</c> or <c>ltr</c> ever reach the page.
    /// </summary>
    public static string Dir(QuoteCard card) => card.Dir == BidiText.Ltr ? BidiText.Ltr : BidiText.Rtl;

    /// <summary>The article's link as people read it, without <c>https://</c>: <c>readin.app/en/a/clean-code</c>.</summary>
    public static string Link(string webBaseUrl, string language, string slug)
    {
        var origin = Uri.TryCreate(webBaseUrl, UriKind.Absolute, out var uri)
            ? uri.Authority + uri.AbsolutePath.TrimEnd('/')
            : "readin.app";
        return $"{origin}/{(language == "en" ? "en" : "ar")}/a/{slug}";
    }

    public static string Build(QuoteCard card, QuoteCardAssets assets, string webBaseUrl)
    {
        var dir = Dir(card);
        var arabic = card.Language != "en";
        var author = card.AuthorName ?? (arabic ? "مستخدم محذوف" : "Deleted user");
        var (maxSize, _, _) = FontRange(card.Format);
        var fallbacks = ArticlePdfHtml.FallbacksFor(card.Quote) | ArticlePdfHtml.FallbacksFor(card.Title) | ArticlePdfHtml.FallbacksFor(author);

        var page = new StringBuilder(4 * 1024 * 1024);
        page.Append("<!DOCTYPE html><html lang=\"").Append(Attr(card.Language)).Append("\" dir=\"").Append(dir).Append("\"><head>")
            .Append("<meta charset=\"utf-8\">")
            // A second wall next to the browser's own blocking: no script, nothing but data: URLs.
            .Append("<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src data:; font-src data:; style-src 'unsafe-inline'\">")
            .Append("<title>ReadIn</title><style>").Append(assets.Fonts.FontFaces);
        if (fallbacks.HasFlag(PdfFallbacks.Emoji)) page.Append(assets.Fonts.EmojiFontFace);
        if (fallbacks.HasFlag(PdfFallbacks.Symbols)) page.Append(assets.Fonts.SymbolFontFaces);
        page.Append(assets.Stylesheet).Append("</style></head>");

        page.Append("<body class=\"")
            .Append(card.Theme == QuoteCardTheme.Dark ? "dark" : "light").Append(' ')
            .Append(card.Format == QuoteCardFormat.Landscape ? "landscape" : "square").Append(' ')
            .Append(dir).Append("\">")
            .Append("<main class=\"frame\">")
            .Append("<div class=\"mark\" aria-hidden=\"true\">").Append(assets.QuoteMark).Append("</div>");

        // The quote keeps its block's direction, as in the reader; runs in the other one are isolated against it.
        page.Append("<div class=\"qbox\" id=\"").Append(BoxId).Append("\">")
            .Append("<blockquote class=\"quote\" id=\"").Append(QuoteId).Append("\" dir=\"").Append(dir)
            .Append("\" style=\"").Append(QuoteStyle(maxSize, breaksAsSpaces: false)).Append("\">");
        Plain(page, card.Quote, dir);
        page.Append("</blockquote></div>");

        var titleDir = BidiText.DetectDir(card.Title) ?? BidiText.LanguageDir(card.Language);
        page.Append("<footer class=\"meta\"><div class=\"about\">")
            .Append("<div class=\"title\" dir=\"").Append(titleDir).Append("\">");
        Plain(page, card.Title, titleDir);
        page.Append("</div>");

        var nameDir = BidiText.DetectDir(author) ?? BidiText.LanguageDir(card.Language);
        page.Append("<div class=\"byline\"><span class=\"name\" dir=\"").Append(nameDir).Append("\">").Append(Text(author)).Append("</span>");
        if (card.AuthorName is not null && card.AuthorIsVerified)
            page.Append("<span class=\"verified\" aria-label=\"").Append(arabic ? "موثّق" : "Verified").Append("\">").Append(assets.Verified).Append("</span>");
        page.Append("</div></div>");

        page.Append("<div class=\"brand\"><img class=\"logo\" src=\"")
            .Append(card.Theme == QuoteCardTheme.Dark ? assets.DarkLogoDataUri : assets.LightLogoDataUri)
            .Append("\" alt=\"ReadIn\"><span class=\"url\">").Append(Text(Link(webBaseUrl, card.Language, card.Slug))).Append("</span></div>")
            .Append("</footer></main></body></html>");
        return page.ToString();
    }

    /// <summary>Text with the runs in the other direction isolated (<c>&lt;bdi&gt;</c>), as the reader and the PDF do.</summary>
    private static void Plain(StringBuilder html, string text, string dir)
    {
        foreach (var segment in BidiText.Segment(text, dir))
        {
            if (segment.Isolate) html.Append("<bdi>").Append(Text(segment.Text)).Append("</bdi>");
            else html.Append(Text(segment.Text));
        }
    }

    private static string Text(string value) => Html.Encode(value);

    private static string Attr(string value) => Html.Encode(value);
}
