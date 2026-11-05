using System.Diagnostics;
using System.Text;
using PuppeteerSharp;
using PuppeteerSharp.Media;
using ReadIn.Infrastructure.Pdf;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// SPEC F33 Limits: "Chromium restarts if it crashed". Bug F33-2: any failed or timed-out build restarted the shared
/// browser, which killed the other build printing on it. Each test starts its own Chromium, so the shared fixture's one
/// is never touched.
/// </summary>
[Collection(ArticlePdfCollection.Name)]
public sealed class ChromiumBrowserTests
{
    [Fact]
    public async Task A_failed_build_on_a_healthy_browser_keeps_it_running_and_the_other_build_prints()
    {
        var token = TestContext.Current.CancellationToken;
        await using var browser = ArticlePdfFixtures.Browser(ArticlePdfFixtures.Options());
        var failing = await browser.NewPageAsync(token);
        var other = await browser.NewPageAsync(token);
        var process = browser.ProcessId;
        await other.SetContentAsync("<p>Still printing</p>", new SetContentOptions { Timeout = 30_000 });

        // What a failed or timed-out build does: close its own page, then ask whether Chromium crashed.
        await failing.CloseAsync();
        await browser.RestartIfCrashedAsync();

        browser.ProcessId.Should().NotBeNull().And.Be(process, "a healthy browser is never restarted");
        var pdf = await other.PdfDataAsync(new PdfOptions { Format = PaperFormat.A4 });
        Encoding.ASCII.GetString(pdf, 0, 5).Should().Be("%PDF-", "the other build finishes on the same browser");
        await other.CloseAsync();
    }

    [Fact]
    public async Task A_crashed_browser_is_started_again_for_the_next_build()
    {
        var token = TestContext.Current.CancellationToken;
        await using var browser = ArticlePdfFixtures.Browser(ArticlePdfFixtures.Options());
        _ = await browser.NewPageAsync(token);
        var crashed = browser.ProcessId!.Value;

        // A crash: the browser process dies (its renderers follow it).
        using (var process = Process.GetProcessById(crashed))
        {
            process.Kill();
            await process.WaitForExitAsync(token);
        }
        await browser.RestartIfCrashedAsync();

        var page = await browser.NewPageAsync(token);
        browser.ProcessId.Should().NotBeNull().And.NotBe(crashed, "a crashed Chromium is replaced by a new one");
        await page.SetContentAsync("<p>A new browser</p>", new SetContentOptions { Timeout = 30_000 });
        var pdf = await page.PdfDataAsync(new PdfOptions { Format = PaperFormat.A4 });
        Encoding.ASCII.GetString(pdf, 0, 5).Should().Be("%PDF-");
        await page.CloseAsync();
    }

    [Fact]
    public async Task A_build_that_runs_out_of_time_fails_alone_and_chromium_keeps_running()
    {
        var token = TestContext.Current.CancellationToken;
        var options = ArticlePdfFixtures.Options();
        await using var browser = ArticlePdfFixtures.Browser(options);
        var renderer = ArticlePdfFixtures.Renderer(browser, options);
        (await renderer.RenderAsync(ArticlePdfFixtures.PageBreakDocument(), token)).IsSuccess.Should().BeTrue();
        var process = browser.ProcessId;

        // The same browser, with no time at all for a build.
        var hurried = ArticlePdfFixtures.Options();
        hurried.BuildTimeout = TimeSpan.FromMilliseconds(1);
        var timedOut = await ArticlePdfFixtures.Renderer(browser, hurried).RenderAsync(ArticlePdfFixtures.Document("en"), token);

        timedOut.Error!.Code.Should().Be("article.pdf_failed");
        browser.ProcessId.Should().Be(process, "a build that runs out of time closes its own page; Chromium restarts only when it crashed");
        (await renderer.RenderAsync(ArticlePdfFixtures.PageBreakDocument(), token)).IsSuccess.Should().BeTrue("the next build prints on the same browser");
        browser.ProcessId.Should().Be(process);
    }
}
