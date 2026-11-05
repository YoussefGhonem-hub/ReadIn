using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Articles;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Daily (SPEC F32): a user-created tag that no published article has carried for 30 days is deleted. System tags from
/// the seed content stay. <c>Tags.EmptySince</c> remembers when a tag lost its last published article (hidden ones
/// count, so un-hiding an article brings its tags back); a tag used again starts over.
/// </summary>
public sealed partial class TagCleanupJob(AppDbContext db, TimeProvider clock, ILogger<TagCleanupJob> logger)
{
    [DisableConcurrentExecution(timeoutInSeconds: 300)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var published = db.Articles.Where(a => a.Status == ArticleStatus.Published);

        await db.Tags
            .Where(t => t.EmptySince != null && published.Any(a => a.Tags.Any(x => x.TagId == t.Id)))
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.EmptySince, (DateTime?)null), cancellationToken);
        await db.Tags
            .Where(t => !t.IsSystem && t.EmptySince == null && !published.Any(a => a.Tags.Any(x => x.TagId == t.Id)))
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.EmptySince, now), cancellationToken);

        var before = now - TagNames.EmptyRetention;
        var deleted = await db.Tags
            .Where(t => !t.IsSystem && t.EmptySince <= before && !published.Any(a => a.Tags.Any(x => x.TagId == t.Id)))
            .ExecuteDeleteAsync(cancellationToken);

        if (deleted > 0) LogDeleted(logger, deleted);
        return deleted;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Deleted {Count} user-created tags that no published article carried for 30 days")]
    private static partial void LogDeleted(ILogger logger, int count);
}
