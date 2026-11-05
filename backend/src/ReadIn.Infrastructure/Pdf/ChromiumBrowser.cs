using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PuppeteerSharp;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// One headless Chromium per API instance for article PDFs (SPEC F33, §24), started on the first build and started
/// again only when it crashed, disconnected or stopped answering: a build that fails or runs out of time closes only its
/// own page, so the other build on the same browser carries on (SPEC F33 Limits). Its sandbox stays on; pages run with
/// JavaScript off and every network request blocked (see <see cref="ArticlePdfRenderer"/>). As a second wall, every
/// request the browser could still make goes to a proxy that doesn't exist.
/// </summary>
internal sealed class ChromiumBrowser(IOptions<ArticlePdfOptions> options, ILogger<ChromiumBrowser> logger) : IAsyncDisposable
{
    private static readonly string[] Args =
    [
        "--disable-gpu",
        "--disable-dev-shm-usage",
        // The same glyph metrics on Windows and Linux, so a page breaks the same way everywhere.
        "--font-render-hinting=none",
        "--force-color-profile=srgb",
        "--proxy-server=127.0.0.1:9",
        "--proxy-bypass-list=<-loopback>",
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-extensions",
        "--disable-sync",
        "--disable-component-update",
        "--mute-audio",
    ];

    /// <summary>How long a browser has to answer after a failed build before it counts as hung.</summary>
    private static readonly TimeSpan AnswerTimeout = TimeSpan.FromSeconds(5);

    private readonly SemaphoreSlim _lock = new(1, 1);
    private IBrowser? _browser;

    /// <summary>The running browser's process id (null before the first build): tests check it is restarted only after a crash.</summary>
    internal int? ProcessId => _browser?.Process?.Id;

    public async Task<IPage> NewPageAsync(CancellationToken cancellationToken)
    {
        var browser = await GetAsync(cancellationToken);
        return await browser.NewPageAsync();
    }

    /// <summary>
    /// After a failed build: closes the browser only when it crashed, disconnected or doesn't answer within a few seconds
    /// (the next build starts a new one). A healthy browser keeps running, with the other build on it.
    /// </summary>
    public async Task RestartIfCrashedAsync()
    {
        var current = _browser;
        if (current is null || await AnswersAsync(current)) return;

        await _lock.WaitAsync();
        try
        {
            // Another failed build may have replaced it already.
            if (!ReferenceEquals(_browser, current)) return;
            logger.LogWarning("Chromium for article PDFs crashed or stopped answering; restarting it");
            await CloseAsync(current);
            _browser = null;
        }
        finally
        {
            _lock.Release();
        }
    }

    private async Task<bool> AnswersAsync(IBrowser browser)
    {
        if (!browser.IsConnected || browser.IsClosed) return false;
        try
        {
            await browser.GetVersionAsync().WaitAsync(AnswerTimeout);
            return true;
        }
        catch (Exception e)
        {
            logger.LogWarning(e, "Chromium for article PDFs didn't answer");
            return false;
        }
    }

    private async Task<IBrowser> GetAsync(CancellationToken cancellationToken)
    {
        if (_browser is { IsConnected: true, IsClosed: false } running) return running;

        await _lock.WaitAsync(cancellationToken);
        try
        {
            if (_browser is { IsConnected: true, IsClosed: false } current) return current;
            if (_browser is not null) await CloseAsync(_browser);

            var path = ChromiumLocator.Find(options.Value.ChromiumPath)
                       ?? throw new InvalidOperationException(
                           $"Chrome/Chromium for article PDFs was not found. Install it (docs/setup/deployment.md) or set {ArticlePdfOptions.Section}:ChromiumPath.");
            _browser = await Puppeteer.LaunchAsync(new LaunchOptions
            {
                ExecutablePath = path,
                Headless = true,
                Args = Args,
                Timeout = 30_000,
            });
            logger.LogInformation("Started Chromium {Version} for article PDFs", await _browser.GetVersionAsync());
            return _browser;
        }
        finally
        {
            _lock.Release();
        }
    }

    private async Task CloseAsync(IBrowser browser)
    {
        try
        {
            await browser.CloseAsync().WaitAsync(TimeSpan.FromSeconds(10));
        }
        catch (Exception e)
        {
            logger.LogWarning(e, "Chromium didn't close cleanly; killing it");
        }
        finally
        {
            try
            {
                if (browser.Process is { HasExited: false } process) process.Kill(entireProcessTree: true);
            }
            catch (Exception e) when (e is InvalidOperationException or System.ComponentModel.Win32Exception)
            {
                // Already gone.
            }
            await browser.DisposeAsync();
        }
    }

    public async ValueTask DisposeAsync()
    {
        if (_browser is not null) await CloseAsync(_browser);
        _lock.Dispose();
    }
}
