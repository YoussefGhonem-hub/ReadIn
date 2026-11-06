namespace ReadIn.Infrastructure.QuoteCards;

/// <summary>
/// The <c>QuoteCard</c> settings (SPEC F24, docs/setup/deployment.md §10). Cards share the article PDFs' Chromium, its
/// build slots (<c>ArticlePdf:MaxConcurrentBuilds</c>) and the web origin (<c>ArticlePdf:WebBaseUrl</c>); a card is a live
/// preview, so it gives up sooner than a PDF.
/// </summary>
public sealed class QuoteCardOptions
{
    public const string Section = "QuoteCard";

    /// <summary>How long a request waits for a free build slot, then <c>503 quote.busy</c>.</summary>
    public TimeSpan QueueTimeout { get; set; } = TimeSpan.FromSeconds(10);

    /// <summary>How long drawing one card may take, then <c>500 quote.failed</c>.</summary>
    public TimeSpan BuildTimeout { get; set; } = TimeSpan.FromSeconds(20);
}
