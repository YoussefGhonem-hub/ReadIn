using System.Text.Json;
using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Content;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Fills <c>ArticleTranslations.Excerpt</c> for versions published before feed-card excerpts existed (SPEC F34). Triggered
/// at every startup through Hangfire, so startup never waits for it, and a no-op once nothing is left: it reads only rows
/// whose excerpt is still null, <see cref="BatchSize"/> at a time, and never overwrites an excerpt a publish wrote meanwhile.
/// New and seeded versions get theirs from the RDoc processor when they are written.
/// </summary>
public sealed partial class ArticleExcerptsBackfillJob(AppDbContext db, ILogger<ArticleExcerptsBackfillJob> logger)
{
    public const int BatchSize = 100;

    /// <returns>How many versions got an excerpt.</returns>
    [DisableConcurrentExecution(timeoutInSeconds: 600)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var filled = 0;
        while (true)
        {
            var batch = await db.ArticleTranslations.AsNoTracking()
                .Where(t => t.Excerpt == null)
                .OrderBy(t => t.Id)
                .Take(BatchSize)
                .Select(t => new { t.Id, t.ContentJson })
                .ToListAsync(cancellationToken);
            if (batch.Count == 0) break;

            foreach (var row in batch)
            {
                var excerpt = ExcerptOf(row.ContentJson);
                // Only while still null, so every row read leaves the loop's query: a publish meanwhile wrote the excerpt
                // of newer content.
                filled += await db.ArticleTranslations
                    .Where(t => t.Id == row.Id && t.Excerpt == null)
                    .ExecuteUpdateAsync(set => set
                        .SetProperty(t => t.Excerpt, excerpt.Text)
                        .SetProperty(t => t.ExcerptHasMore, excerpt.HasMore), cancellationToken);
            }
        }

        if (filled > 0) LogFilled(logger, filled);
        return filled;
    }

    private static RDocExcerptResult ExcerptOf(string contentJson)
    {
        try
        {
            using var document = JsonDocument.Parse(contentJson);
            return RDocExcerpt.From(document.RootElement);
        }
        catch (JsonException)
        {
            return new RDocExcerptResult("", HasMore: true);
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Backfilled the feed-card excerpt of {Count} article versions")]
    private static partial void LogFilled(ILogger logger, int count);
}
