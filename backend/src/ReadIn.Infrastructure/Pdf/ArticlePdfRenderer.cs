using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PuppeteerSharp;
using PuppeteerSharp.Media;
using ReadIn.Application.Features.Articles.Pdf;
using ReadIn.Domain.Common;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// <see cref="IArticlePdfRenderer"/> with headless Chromium (SPEC F33, §24): the print HTML goes into a fresh page with
/// JavaScript off and every request except <c>data:</c> URLs aborted, and Chromium prints it as a tagged A4 PDF with
/// bookmarks from H2/H3 and the footer on every page. The title, author and language are then written into the PDF's
/// metadata. Nothing is kept: the bytes go to the response and the page is closed. A build that runs out of time (or
/// whose request is cancelled) closes its own page at once, and a failed build restarts Chromium only when it crashed,
/// so the other build in progress on the same browser carries on (SPEC F33 Limits).
/// </summary>
internal sealed class ArticlePdfRenderer(
    ChromiumBrowser browser,
    PdfBuildGate gate,
    IOptions<ArticlePdfOptions> options,
    ILogger<ArticlePdfRenderer> logger)
    : IArticlePdfRenderer
{
    public Task<Result<byte[]>> RenderAsync(ArticlePdfDocument document, CancellationToken cancellationToken) =>
        gate.RunAsync(token => PrintAsync(document, token), _ => browser.RestartIfCrashedAsync(), cancellationToken);

    private async Task<byte[]> PrintAsync(ArticlePdfDocument document, CancellationToken cancellationToken)
    {
        var settings = options.Value;
        var assets = ArticlePdfAssets.Instance;
        var html = ArticlePdfHtml.Build(document, assets, settings.WebBaseUrl);
        var footer = ArticlePdfHtml.Footer(document.Language, assets, FooterHost(settings.WebBaseUrl));
        var timeout = (int)settings.BuildTimeout.TotalMilliseconds;

        var page = await browser.NewPageAsync(cancellationToken);
        // Out of time or given up: this page closes now, which ends its print; nothing else on the browser is touched.
        using var closeWhenStopped = cancellationToken.Register(() => _ = CloseAsync(page));
        try
        {
            await LockDownAsync(page);

            cancellationToken.ThrowIfCancellationRequested();
            await page.SetContentAsync(html, new SetContentOptions { WaitUntil = [WaitUntilNavigation.Load], Timeout = timeout, CancellationToken = cancellationToken });

            cancellationToken.ThrowIfCancellationRequested();
            var pdf = await page.PdfDataAsync(new PdfOptions
            {
                Format = PaperFormat.A4,
                PrintBackground = true,
                PreferCSSPageSize = false,
                DisplayHeaderFooter = true,
                HeaderTemplate = "<span></span>",
                FooterTemplate = footer,
                MarginOptions = new MarginOptions { Top = "16mm", Bottom = "22mm", Left = "18mm", Right = "18mm" },
                Tagged = true,
                Outline = true,
                WaitForFonts = true,
                Timeout = timeout,
            });

            return ArticlePdfMetadata.Apply(pdf, document.Title, document.Author.DisplayName, ArticlePdfHtml.Headings(document.Content));
        }
        finally
        {
            await CloseAsync(page);
        }
    }

    private async Task CloseAsync(IPage page)
    {
        if (page.IsClosed) return;
        try
        {
            await page.CloseAsync().WaitAsync(TimeSpan.FromSeconds(5), CancellationToken.None);
        }
        catch (Exception e)
        {
            logger.LogDebug(e, "An article PDF page didn't close");
        }
    }

    /// <summary>SPEC §24: JavaScript off and every network request blocked, before any content goes in.</summary>
    internal static async Task LockDownAsync(IPage page)
    {
        await page.SetJavaScriptEnabledAsync(false);
        await page.SetRequestInterceptionAsync(true);
        page.Request += (_, e) => Decide(e.Request).ContinueWith(static t => t.Exception, TaskScheduler.Default);
    }

    /// <summary>Every network request is blocked; only the page's own <c>data:</c> URLs load.</summary>
    internal static Task Decide(IRequest request) =>
        request.Url.StartsWith("data:", StringComparison.Ordinal)
            ? request.ContinueAsync()
            : request.AbortAsync(RequestAbortErrorCode.BlockedByClient);

    private static string FooterHost(string webBaseUrl) =>
        Uri.TryCreate(webBaseUrl, UriKind.Absolute, out var uri) ? uri.Host : "readin.app";
}
