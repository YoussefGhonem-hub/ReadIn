using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Features.Search;

namespace ReadIn.Infrastructure.Search;

/// <summary>
/// Counts the searches with no results that <see cref="SearchMissBuffer"/> holds (SPEC §22, F23): every 10 seconds the misses
/// that are due go to <c>SearchMisses</c>, and at shutdown every miss still held.
/// </summary>
internal sealed partial class SearchMissFlusher(
    SearchMissBuffer buffer, IServiceScopeFactory scopes, TimeProvider clock, ILogger<SearchMissFlusher> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromSeconds(10);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval, clock);
        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
                await WriteAsync(buffer.TakeDue(clock.GetUtcNow().UtcDateTime), stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await base.StopAsync(cancellationToken);
        // The misses still held; a few seconds at most, so a stopping host never waits long for them.
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
        try
        {
            await WriteAsync(buffer.TakeAll(), timeout.Token);
        }
        catch (OperationCanceledException)
        {
        }
    }

    private async Task WriteAsync(IReadOnlyList<SearchMissEntry> misses, CancellationToken ct)
    {
        if (misses.Count == 0) return;
        try
        {
            await using var scope = scopes.CreateAsyncScope();
            await scope.ServiceProvider.GetRequiredService<SearchMissWriter>().WriteAsync(misses, ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // Losing a few counts is fine; the next tick goes on.
            LogWriteFailed(logger, misses.Count, ex);
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not count {Count} searches with no results")]
    private static partial void LogWriteFailed(ILogger logger, int count, Exception exception);
}
