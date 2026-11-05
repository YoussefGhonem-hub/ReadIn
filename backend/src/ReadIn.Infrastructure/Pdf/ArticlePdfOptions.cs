namespace ReadIn.Infrastructure.Pdf;

/// <summary>The <c>ArticlePdf</c> settings (SPEC F33, docs/setup/deployment.md).</summary>
public sealed class ArticlePdfOptions
{
    public const string Section = "ArticlePdf";

    /// <summary>
    /// The Chrome or Chromium executable. Empty: <c>PUPPETEER_EXECUTABLE_PATH</c>, then the usual install paths (Chrome
    /// on Windows/macOS, <c>chromium</c>/<c>google-chrome</c> on Linux). It is never downloaded at runtime.
    /// </summary>
    public string? ChromiumPath { get; set; }

    /// <summary>The web app's origin, for the article link at the end, profile links and the footer's host name.</summary>
    public string WebBaseUrl { get; set; } = "https://readin.app";

    /// <summary>Builds at the same time (per API instance).</summary>
    public int MaxConcurrentBuilds { get; set; } = 2;

    /// <summary>How long a request waits for a free build, then <c>503 article.pdf_busy</c>.</summary>
    public TimeSpan QueueTimeout { get; set; } = TimeSpan.FromSeconds(30);

    /// <summary>How long one build may take, then <c>500 article.pdf_failed</c>.</summary>
    public TimeSpan BuildTimeout { get; set; } = TimeSpan.FromSeconds(60);
}
