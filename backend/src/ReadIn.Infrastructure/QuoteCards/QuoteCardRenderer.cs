using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PuppeteerSharp;
using ReadIn.Application.Features.Articles.QuoteCards;
using ReadIn.Domain.Common;
using ReadIn.Infrastructure.Pdf;

namespace ReadIn.Infrastructure.QuoteCards;

/// <summary>
/// <see cref="IQuoteCardRenderer"/> with the article PDFs' headless Chromium (SPEC F24, F33, §24; ADR 0019): the card's
/// HTML goes into a fresh page of exactly the card's size with JavaScript off and every request except <c>data:</c> URLs
/// aborted; the quote's font size is fitted through the DevTools DOM domain (no page script), and the page is captured as
/// a PNG. Cards take the same build slots as PDFs, with their own waits and codes. Nothing is kept: the page is closed.
/// </summary>
internal sealed class QuoteCardRenderer(
    ChromiumBrowser browser,
    PdfBuildGate gate,
    IOptions<QuoteCardOptions> options,
    IOptions<ArticlePdfOptions> pdfOptions,
    ILogger<QuoteCardRenderer> logger)
    : IQuoteCardRenderer
{
    public async Task<Result<byte[]>> RenderAsync(QuoteCard card, CancellationToken cancellationToken)
    {
        var drawn = await DrawAsync(card, cancellationToken);
        if (drawn.IsFailure) return drawn.Error;
        return drawn.Value.Png;
    }

    /// <summary>The card and how its quote was fitted (the tests read the fit).</summary>
    internal async Task<Result<QuoteCardDrawing>> DrawAsync(QuoteCard card, CancellationToken cancellationToken)
    {
        var settings = options.Value;
        var limits = new BuildLimits("quote card", settings.QueueTimeout, settings.BuildTimeout, QuoteCardErrors.Busy, QuoteCardErrors.Failed);
        var drawn = await gate.RunAsync(token => DrawPageAsync(card, token), _ => browser.RestartIfCrashedAsync(), limits, cancellationToken);
        if (drawn.IsFailure) return drawn.Error;
        // Null: the quote fits not even the smallest size with its line breaks as spaces (unreachable in practice at 400).
        if (drawn.Value is not { } drawing) return QuoteCardErrors.TooLong;
        return drawing;
    }

    private async Task<QuoteCardDrawing?> DrawPageAsync(QuoteCard card, CancellationToken cancellationToken)
    {
        var (width, height) = QuoteCardFormats.Size(card.Format);
        var html = QuoteCardHtml.Build(card, QuoteCardAssets.Instance, pdfOptions.Value.WebBaseUrl);
        var timeout = (int)options.Value.BuildTimeout.TotalMilliseconds;

        var page = await browser.NewPageAsync(cancellationToken);
        // Out of time or given up: this page closes now; nothing else on the browser is touched.
        using var closeWhenStopped = cancellationToken.Register(() => _ = CloseAsync(page));
        try
        {
            await ArticlePdfRenderer.LockDownAsync(page);
            await page.SetViewportAsync(new ViewPortOptions { Width = width, Height = height, DeviceScaleFactor = 1 });

            cancellationToken.ThrowIfCancellationRequested();
            await page.SetContentAsync(html, new SetContentOptions { WaitUntil = [WaitUntilNavigation.Load], Timeout = timeout, CancellationToken = cancellationToken });

            // The quote is measured in its own fonts: the DevTools protocol waits for them (the page itself runs no script).
            cancellationToken.ThrowIfCancellationRequested();
            await page.EvaluateExpressionAsync("document.fonts.ready.then(() => true)");

            cancellationToken.ThrowIfCancellationRequested();
            if (await FitAsync(page.Client, card.Format, hasBreaks: card.Quote.Contains('\n')) is not { } fit) return null;

            cancellationToken.ThrowIfCancellationRequested();
            var png = await page.ScreenshotDataAsync(new ScreenshotOptions { Type = ScreenshotType.Png, CaptureBeyondViewport = false });
            return new QuoteCardDrawing(png, fit);
        }
        finally
        {
            await CloseAsync(page);
        }
    }

    /// <summary>
    /// Sets the quote to the largest font size (2 px steps, <see cref="QuoteCardHtml.FontRange"/>) at which it fits its box,
    /// with the DOM domain only: change the quote's <c>style</c>, read both boxes. First the readable sizes with the line
    /// breaks, then (a quote with breaks) the same with the breaks as spaces, then the sizes below readable. Null when even
    /// the smallest doesn't fit: the quote is refused, never cut.
    /// </summary>
    internal static async Task<QuoteFit?> FitAsync(ICDPSession session, QuoteCardFormat format, bool hasBreaks)
    {
        var document = await session.SendAsync<JsonElement>("DOM.getDocument", new Dictionary<string, object> { ["depth"] = 0 });
        var root = document.GetProperty("root").GetProperty("nodeId").GetInt32();
        var quote = await QuerySelectorAsync(session, root, "#" + QuoteCardHtml.QuoteId);
        var box = await QuerySelectorAsync(session, root, "#" + QuoteCardHtml.BoxId);
        var (max, min, floor) = QuoteCardHtml.FontRange(format);
        var step = QuoteCardHtml.FontStep;
        (bool BreaksAsSpaces, int From, int To)[] passes = hasBreaks
            ? [(false, min, max), (true, min, max), (true, floor, min - step)]
            : [(false, min, max), (false, floor, min - step)];

        foreach (var (breaksAsSpaces, from, to) in passes)
        {
            if (await FitsAsync(session, quote, box, from, breaksAsSpaces) is not { Fits: true }) continue;

            // The largest step that fits: the quote only gets taller as its font grows.
            int low = 0, high = (to - from) / step;
            while (low < high)
            {
                var mid = (low + high + 1) / 2;
                if (await FitsAsync(session, quote, box, from + mid * step, breaksAsSpaces) is { Fits: true }) low = mid;
                else high = mid - 1;
            }
            // Set again and measured as drawn.
            return await FitsAsync(session, quote, box, from + low * step, breaksAsSpaces);
        }
        return null;
    }

    private static async Task<QuoteFit> FitsAsync(ICDPSession session, int quote, int box, int fontSize, bool breaksAsSpaces)
    {
        await SetSizeAsync(session, quote, fontSize, breaksAsSpaces);
        var quoteHeight = Height(await BoxModelAsync(session, quote), "border");
        var room = Height(await BoxModelAsync(session, box), "content");
        return new QuoteFit(fontSize, breaksAsSpaces, quoteHeight, room);
    }

    private static Task SetSizeAsync(ICDPSession session, int nodeId, int fontSize, bool breaksAsSpaces) =>
        session.SendAsync("DOM.setAttributeValue", new Dictionary<string, object>
        {
            ["nodeId"] = nodeId,
            ["name"] = "style",
            ["value"] = QuoteCardHtml.QuoteStyle(fontSize, breaksAsSpaces),
        });

    private static async Task<int> QuerySelectorAsync(ICDPSession session, int root, string selector)
    {
        var found = await session.SendAsync<JsonElement>("DOM.querySelector", new Dictionary<string, object> { ["nodeId"] = root, ["selector"] = selector });
        var nodeId = found.GetProperty("nodeId").GetInt32();
        return nodeId != 0 ? nodeId : throw new InvalidOperationException($"The quote card has no {selector}.");
    }

    private static async Task<JsonElement> BoxModelAsync(ICDPSession session, int nodeId) =>
        (await session.SendAsync<JsonElement>("DOM.getBoxModel", new Dictionary<string, object> { ["nodeId"] = nodeId })).GetProperty("model");

    /// <summary>A quad is 4 points (x, y) clockwise from the top left: the height is the bottom's y minus the top's.</summary>
    private static double Height(JsonElement model, string quad)
    {
        var points = model.GetProperty(quad);
        return points[5].GetDouble() - points[1].GetDouble();
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
            logger.LogDebug(e, "A quote card page didn't close");
        }
    }
}

/// <summary>The quote's font size and whether its line breaks became spaces; its height and its box's, in CSS px.</summary>
internal sealed record QuoteFit(int FontSize, bool BreaksAsSpaces, double QuoteHeight, double Room)
{
    public bool Fits => QuoteHeight <= Room + 0.5;
}

/// <summary>A drawn card: the PNG and how its quote was fitted.</summary>
internal sealed record QuoteCardDrawing(byte[] Png, QuoteFit Fit);
