using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Identity;

/// <summary>
/// Hard-deletes an account in one transaction, following the data map in SPEC §9.6. Published articles stay without an
/// author ("Deleted user"), with the images and PDFs they show, and so do its comments; drafts and every other article, the
/// avatar and the other uploads go. What isn't deleted outright is unlinked: other people's articles keep their review
/// and revisions without the deleted reviewer or editor, comments it hid and reports it resolved lose the moderator,
/// audit stamps lose the account id, and audit entries of actions the account took on other accounts stay without its
/// IP address. The deletion itself is recorded as <see cref="AuditActions.AccountDeleted"/>
/// with the account id and time only. Right after the commit: uploaded files, the Realtime Database node, the cached
/// details of the articles that stay, and the counters of the articles the account reacted to or saved. A file that fails
/// to delete is picked up by <see cref="Jobs.OrphanedUploadsCleanupJob"/>.
/// </summary>
internal sealed partial class AccountEraser(
    AppDbContext db,
    IFileStorage files,
    IRealtimeAccountData realtime,
    ArticleCounters counters,
    HybridCache cache,
    TimeProvider clock,
    ILogger<AccountEraser> logger) : IAccountEraser
{
    public async Task<bool> EraseAsync(Guid userId, CancellationToken cancellationToken)
    {
        List<string> paths = [];
        List<string> keptSlugs = [];
        List<Guid> engaged = [];
        var deletedArticles = 0;
        var erased = false;

        var strategy = db.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async ct =>
        {
            db.ChangeTracker.Clear(); // a retried attempt starts from a clean slate
            await using var transaction = await db.Database.BeginTransactionAsync(ct);

            // Articles whose reaction and save counters change once this account's rows are gone.
            engaged = await db.Reactions.Where(r => r.UserId == userId).Select(r => r.ArticleId)
                .Union(db.SavedArticles.Where(s => s.UserId == userId).Select(s => s.ArticleId))
                .ToListAsync(ct);
            // Comments whose like count changes once this account's likes are gone.
            var liked = await db.CommentLikes.Where(l => l.UserId == userId).Select(l => l.CommentId).ToListAsync(ct);

            var articles = db.Articles.IgnoreQueryFilters().Where(a => a.AuthorId == userId);
            var kept = articles.Where(a => a.Status == ArticleStatus.Published && !a.IsDeleted);
            var gone = articles.Where(a => a.Status != ArticleStatus.Published || a.IsDeleted);
            keptSlugs = await kept.Select(a => a.Slug).ToListAsync(ct);

            // Media that stay with the published articles: their attachments, and images their cover, translations or
            // revisions show. Everything else the account uploaded goes, avatar included.
            var attached = await db.ArticleAttachments.Where(x => kept.Any(a => a.Id == x.ArticleId)).Select(x => x.MediaAssetId).ToListAsync(ct);
            var shown = new HashSet<string>(StringComparer.Ordinal);
            await CollectAsync(kept.Where(a => a.CoverUrl != null).Select(a => a.CoverUrl!));
            await CollectAsync(db.ArticleTranslations.Where(t => kept.Any(a => a.Id == t.ArticleId)).Select(t => t.ContentJson));
            await CollectAsync(kept.SelectMany(a => a.Revisions).Select(r => r.ContentJson));

            var assets = await db.MediaAssets.AsNoTracking().Include(a => a.Pages)
                .Where(a => a.OwnerId == userId)
                .ToListAsync(ct);
            var keptAssets = assets
                .Where(a => attached.Contains(a.Id) || (UploadPath.TryParse(a.OriginalPath, out var image) && shown.Contains(image.Id)))
                .Select(a => a.Id)
                .ToList();
            paths = [.. assets.Where(a => !keptAssets.Contains(a.Id)).SelectMany(a => a.StoredPaths())];

            await db.Articles.IgnoreQueryFilters()
                .Where(a => a.ReviewedById == userId)
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.ReviewedById, (Guid?)null), ct);
            await db.Set<ArticleRevision>()
                .Where(r => r.CreatedBy == userId)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.CreatedBy, (Guid?)null), ct);
            await db.Comments.IgnoreQueryFilters()
                .Where(c => c.HiddenById == userId)
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.HiddenById, (Guid?)null), ct);
            await db.Reports
                .Where(r => r.ResolvedById == userId)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.ResolvedById, (Guid?)null), ct);
            await ClearAuditStampsAsync(userId, ct);

            // The account's deleted comments (by it or a moderator) stay only as the placeholder that keeps their replies
            // in place: their text goes. Its other comments stay as "Deleted user" (AuthorId SET NULL with the row).
            await db.Comments.IgnoreQueryFilters()
                .Where(c => c.AuthorId == userId && c.IsDeleted)
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.Body, string.Empty), ct);

            // Reports whose target goes: the account itself, and the articles below with the comments on them (the
            // reports this account filed go with the row).
            await db.Reports
                .Where(r => (r.TargetType == ReportTargetType.User && r.TargetId == userId)
                    || (r.TargetType == ReportTargetType.Article && gone.Any(a => a.Id == r.TargetId))
                    || (r.TargetType == ReportTargetType.Comment
                        && db.Comments.IgnoreQueryFilters().Any(c => c.Id == r.TargetId && gone.Any(a => a.Id == c.ArticleId))))
                .ExecuteDeleteAsync(ct);

            // Drafts and every article that isn't live, with their translations, revisions, tags, sources, attachments,
            // reactions, saves, comments, reading progress, daily picks and learning path items (cascades). The published
            // ones stay without an author. Media go after, once no attachment of a deleted article points at them.
            deletedArticles = await gone.ExecuteDeleteAsync(ct);
            await articles.ExecuteUpdateAsync(s => s.SetProperty(a => a.AuthorId, (Guid?)null), ct);
            await db.MediaAssets.Where(a => keptAssets.Contains(a.Id))
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.OwnerId, (Guid?)null), ct);
            await db.MediaAssets.Where(a => a.OwnerId == userId).ExecuteDeleteAsync(ct);

            // Followers of this account (FolloweeId has no cascade: one path from UserFollows to Users only).
            await db.UserFollows.Where(f => f.FolloweeId == userId).ExecuteDeleteAsync(ct);
            await db.RecoveryAttempts.Where(a => a.UserId == userId).ExecuteDeleteAsync(ct);

            await db.AuditLogs
                .Where(l => l.UserId == userId && (l.ActorId == null || l.ActorId == userId))
                .ExecuteDeleteAsync(ct);
            await db.AuditLogs
                .Where(l => l.ActorId == userId)
                .ExecuteUpdateAsync(s => s.SetProperty(l => l.Ip, (string?)null), ct);

            // Roles, interests, devices (push tokens), Google/Apple links (with the stored Apple token), sessions, reset
            // tokens, reading progress and days, streak stats, reactions, saves, collections, follows of other accounts,
            // daily picks, comment likes, mentions of the account and the reports it filed go with the row (cascades).
            erased = await db.Users.IgnoreQueryFilters().Where(u => u.Id == userId).ExecuteDeleteAsync(ct) > 0;
            if (liked.Count > 0)
            {
                await db.Comments.IgnoreQueryFilters()
                    .Where(c => liked.Contains(c.Id))
                    .ExecuteUpdateAsync(s => s.SetProperty(c => c.LikeCount, c => db.CommentLikes.Count(l => l.CommentId == c.Id)), ct);
            }
            if (erased)
            {
                db.AuditLogs.Add(AuditLog.Record(AuditActions.AccountDeleted, actorId: null, userId, ip: null, clock.GetUtcNow().UtcDateTime));
                await db.SaveChangesAsync(ct);
            }

            await transaction.CommitAsync(ct);

            async Task CollectAsync(IQueryable<string> values)
            {
                await foreach (var value in values.AsNoTracking().AsAsyncEnumerable().WithCancellation(ct))
                    shown.UnionWith(UploadPath.FindIds(value));
            }
        }, cancellationToken);

        foreach (var path in paths)
        {
            try
            {
                await files.DeleteAsync(path, cancellationToken);
            }
            catch (IOException ex)
            {
                LogFileNotDeleted(logger, ex, path);
            }
        }
        await realtime.DeleteLiveDataAsync(userId, cancellationToken);

        // The account is gone by now; what's left only refreshes derived data, so a failure is logged, never reported.
        try
        {
            if (keptSlugs.Count > 0)
                await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Articles, .. keptSlugs.Select(CacheTags.Article)], cancellationToken);
            if (engaged.Count > 0) await counters.RecomputeAsync(engaged, cancellationToken);
        }
        catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
        {
            LogRefreshFailed(logger, ex, userId);
        }

        if (erased) LogErased(logger, userId, deletedArticles, keptSlugs.Count, paths.Count);
        return erased;
    }

    /// <summary>Audit stamps (SPEC §16) that rows which stay keep of this account: articles, comments, media, paths, fields, users.</summary>
    private async Task ClearAuditStampsAsync(Guid userId, CancellationToken ct)
    {
        await db.Comments.IgnoreQueryFilters().Where(c => c.CreatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(c => c.CreatedBy, (Guid?)null), ct);
        await db.Comments.IgnoreQueryFilters().Where(c => c.UpdatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(c => c.UpdatedBy, (Guid?)null), ct);
        await db.Articles.IgnoreQueryFilters().Where(a => a.CreatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(a => a.CreatedBy, (Guid?)null), ct);
        await db.Articles.IgnoreQueryFilters().Where(a => a.UpdatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(a => a.UpdatedBy, (Guid?)null), ct);
        await db.MediaAssets.Where(a => a.CreatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(a => a.CreatedBy, (Guid?)null), ct);
        await db.MediaAssets.Where(a => a.UpdatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(a => a.UpdatedBy, (Guid?)null), ct);
        await db.LearningPaths.IgnoreQueryFilters().Where(p => p.CreatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(p => p.CreatedBy, (Guid?)null), ct);
        await db.LearningPaths.IgnoreQueryFilters().Where(p => p.UpdatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(p => p.UpdatedBy, (Guid?)null), ct);
        await db.Fields.IgnoreQueryFilters().Where(f => f.CreatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(f => f.CreatedBy, (Guid?)null), ct);
        await db.Fields.IgnoreQueryFilters().Where(f => f.UpdatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(f => f.UpdatedBy, (Guid?)null), ct);
        await db.Users.IgnoreQueryFilters().Where(u => u.Id != userId && u.CreatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(u => u.CreatedBy, (Guid?)null), ct);
        await db.Users.IgnoreQueryFilters().Where(u => u.Id != userId && u.UpdatedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(u => u.UpdatedBy, (Guid?)null), ct);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Deleted account {UserId}: {Deleted} articles deleted, {Kept} published articles kept without an author, {Files} files")]
    private static partial void LogErased(ILogger logger, Guid userId, int deleted, int kept, int files);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete {Path} of a deleted account; the orphaned uploads job will")]
    private static partial void LogFileNotDeleted(ILogger logger, Exception exception, string path);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Account {UserId} was deleted, but refreshing cached articles or counters failed; the admin rebuild fixes counters")]
    private static partial void LogRefreshFailed(ILogger logger, Exception exception, Guid userId);
}
