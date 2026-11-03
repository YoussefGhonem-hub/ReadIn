using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Articles.Counters;

/// <summary>
/// The denormalized counters on <c>Articles</c> (SPEC §16.1, F27): reactions per type and their sum, and saves. They are
/// always recomputed from the rows (never incremented), so running it twice, late or after a crash gives the same
/// numbers. Each recompute updates the columns in one SQL statement, publishes the counters of published articles to
/// <c>/live/articles/{id}</c> and drops their cached details. <c>CommentCount</c> is published as stored (F11 owns it);
/// the admin rebuild also recomputes <c>ReadCount</c> (F08). Called by the reactions and saves outbox handler, the admin rebuild, the demo seeder and account deletion.
/// </summary>
public sealed class ArticleCounters(IAppDbContext db, IRealtimePublisher realtime, HybridCache cache)
{
    private const int BatchSize = 500;

    /// <returns>How many articles were recomputed.</returns>
    public async Task<int> RecomputeAsync(IReadOnlyCollection<Guid> articleIds, CancellationToken cancellationToken)
    {
        var count = 0;
        foreach (var batch in articleIds.Distinct().Chunk(BatchSize))
            count += await RecomputeBatchAsync(batch, cancellationToken);
        return count;
    }

    /// <summary>
    /// Recomputes and republishes every article (admin rebuild, SPEC §21.2), and their <c>ReadCount</c> too: the
    /// read-completed outbox handler keeps it per article (F08), and it isn't a live counter, so only the rebuild redoes it.
    /// </summary>
    public async Task<int> RebuildAllAsync(CancellationToken cancellationToken)
    {
        var ids = await db.Articles.IgnoreQueryFilters().AsNoTracking().OrderBy(a => a.Id).Select(a => a.Id).ToListAsync(cancellationToken);
        foreach (var batch in ids.Chunk(BatchSize))
            await RecomputeReadsAsync(batch, cancellationToken);
        return await RecomputeAsync(ids, cancellationToken);
    }

    /// <summary><c>ReadCount</c> = completed reads (SPEC §16.1); rows that already match are left alone, as below.</summary>
    private Task<int> RecomputeReadsAsync(Guid[] ids, CancellationToken ct) =>
        db.Articles.IgnoreQueryFilters()
            .Where(a => ids.Contains(a.Id))
            .Where(a => a.ReadCount != db.ReadingProgress.Count(r => r.ArticleId == a.Id && r.CompletedAt != null))
            .ExecuteUpdateAsync(
                set => set.SetProperty(a => a.ReadCount, a => db.ReadingProgress.Count(r => r.ArticleId == a.Id && r.CompletedAt != null)),
                ct);

    private async Task<int> RecomputeBatchAsync(Guid[] ids, CancellationToken ct)
    {
        // Rows whose counters already match are left alone: an update bumps the rowversion, and an author saving the
        // article at that moment would get a concurrency conflict for nothing (e.g. during a rebuild).
        await db.Articles.IgnoreQueryFilters()
            .Where(a => ids.Contains(a.Id))
            .Where(a =>
                a.InsightfulCount != db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Insightful) ||
                a.LoveCount != db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Love) ||
                a.FireCount != db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Fire) ||
                a.MindBlownCount != db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.MindBlown) ||
                a.ReactionCount != db.Reactions.Count(r => r.ArticleId == a.Id) ||
                a.SaveCount != db.SavedArticles.Count(s => s.ArticleId == a.Id))
            .ExecuteUpdateAsync(set => set
                .SetProperty(a => a.InsightfulCount, a => db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Insightful))
                .SetProperty(a => a.LoveCount, a => db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Love))
                .SetProperty(a => a.FireCount, a => db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.Fire))
                .SetProperty(a => a.MindBlownCount, a => db.Reactions.Count(r => r.ArticleId == a.Id && r.Type == ReactionType.MindBlown))
                .SetProperty(a => a.ReactionCount, a => db.Reactions.Count(r => r.ArticleId == a.Id))
                .SetProperty(a => a.SaveCount, a => db.SavedArticles.Count(s => s.ArticleId == a.Id)),
                ct);

        var rows = await db.Articles.IgnoreQueryFilters().AsNoTracking()
            .Where(a => ids.Contains(a.Id))
            .Select(a => new
            {
                a.Id,
                a.Slug,
                IsLive = a.Status == ArticleStatus.Published && !a.IsDeleted,
                a.InsightfulCount,
                a.LoveCount,
                a.FireCount,
                a.MindBlownCount,
                a.CommentCount,
                a.SaveCount,
            })
            .ToListAsync(ct);

        // Live signals only for what readers can see; drafts and deleted articles never reach RTDB.
        foreach (var row in rows.Where(r => r.IsLive))
        {
            await realtime.PublishArticleCountersAsync(
                row.Id,
                new ArticleLiveCounters(row.InsightfulCount, row.LoveCount, row.FireCount, row.MindBlownCount, row.CommentCount, row.SaveCount),
                ct);
        }

        if (rows.Count > 0) await cache.RemoveByTagAsync([.. rows.Select(r => CacheTags.Article(r.Slug))], ct);
        return rows.Count;
    }
}
