using System.Text;
using ReadIn.Infrastructure.Pdf;

namespace ReadIn.Infrastructure.QuoteCards;

/// <summary>
/// What a quote card inlines (SPEC F24): the article PDFs' fonts and verified badge, the approved lockups (the dark one
/// for dark cards, copied unchanged from <c>docs/design/app-store/logo</c>), the Lucide quote mark (ISC) and the card's
/// stylesheet. All embedded in this assembly and loaded once, so a card never depends on the server's fonts or the
/// network.
/// </summary>
internal sealed class QuoteCardAssets
{
    private static readonly Lazy<QuoteCardAssets> Shared = new(() => new QuoteCardAssets(ArticlePdfAssets.Instance));

    private QuoteCardAssets(ArticlePdfAssets pdf)
    {
        Fonts = pdf;
        LightLogoDataUri = pdf.LogoDataUri;
        DarkLogoDataUri = ArticlePdfAssets.DataUri("image/png", ArticlePdfAssets.Read("lockup-dark.png"));
        QuoteMark = Encoding.UTF8.GetString(ArticlePdfAssets.Read("quote.svg")).Trim();
        Verified = pdf.Icons["verified"];
        Stylesheet = Encoding.UTF8.GetString(ArticlePdfAssets.Read("quote-card.css"));
    }

    public static QuoteCardAssets Instance => Shared.Value;

    /// <summary>The <c>@font-face</c> rules (the emoji and symbol fonts are declared only when the text needs them).</summary>
    public ArticlePdfAssets Fonts { get; }

    /// <summary><c>lockup.png</c>, for light cards.</summary>
    public string LightLogoDataUri { get; }

    /// <summary><c>lockup-dark.png</c>, for dark cards.</summary>
    public string DarkLogoDataUri { get; }

    /// <summary>Inline SVG (fill and stroke = currentColor).</summary>
    public string QuoteMark { get; }

    /// <summary>Inline SVG (stroke = currentColor), the badge the reader shows.</summary>
    public string Verified { get; }

    public string Stylesheet { get; }
}
