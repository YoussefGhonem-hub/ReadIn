using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Features.Articles.Pdf;
using ReadIn.Domain.Common;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// The limits of SPEC F33 around one build: at most <see cref="ArticlePdfOptions.MaxConcurrentBuilds"/> at a time, a
/// request waits <see cref="ArticlePdfOptions.QueueTimeout"/> for a slot (then <c>article.pdf_busy</c>) and a build has
/// <see cref="ArticlePdfOptions.BuildTimeout"/> (then <c>article.pdf_failed</c>): its token is cancelled, so it stops its
/// own work. A failed build is reported to <c>onFailure</c>, which restarts the browser only if it crashed; the other
/// build in progress is never cancelled by it.
/// </summary>
internal sealed class PdfBuildGate(IOptions<ArticlePdfOptions> options, TimeProvider clock, ILogger<PdfBuildGate> logger) : IDisposable
{
    private readonly SemaphoreSlim _slots = new(Math.Max(1, options.Value.MaxConcurrentBuilds));

    public async Task<Result<T>> RunAsync<T>(Func<CancellationToken, Task<T>> build, Func<Exception, Task> onFailure, CancellationToken cancellationToken)
    {
        var settings = options.Value;
        if (!await _slots.WaitAsync(settings.QueueTimeout, cancellationToken)) return ArticlePdfErrors.Busy;

        try
        {
            using var timeout = new CancellationTokenSource(settings.BuildTimeout, clock);
            using var linked = CancellationTokenSource.CreateLinkedTokenSource(timeout.Token, cancellationToken);
            Task<T>? work = null;
            try
            {
                work = build(linked.Token);
                // WaitAsync also ends a build that ignores its token (e.g. a hung browser call).
                return await work.WaitAsync(settings.BuildTimeout, clock, cancellationToken);
            }
            catch (Exception e) when (!cancellationToken.IsCancellationRequested)
            {
                var reason = e is TimeoutException || timeout.IsCancellationRequested ? "timed out" : "failed";
                logger.LogError(e, "An article PDF build {Reason}", reason);
                // This build stops its own work now (its page closes), even when WaitAsync gave up first; nothing else does.
                try
                {
                    await linked.CancelAsync();
                }
                catch (AggregateException stop)
                {
                    logger.LogDebug(stop, "Stopping a failed article PDF build threw");
                }
                _ = work?.ContinueWith(static t => _ = t.Exception, TaskScheduler.Default); // observe a late failure
                await onFailure(e);
                return ArticlePdfErrors.Failed;
            }
        }
        finally
        {
            _slots.Release();
        }
    }

    public void Dispose() => _slots.Dispose();
}
