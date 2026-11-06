using System.Linq.Expressions;
using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Mutes;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetForYouFeed;

internal sealed class GetForYouFeedQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    TimeProvider clock)
    : IQueryHandler<GetForYouFeedQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetForYouFeedQuery query, CancellationToken ct)
    {
        var limit = Math.Clamp(query.Limit, 1, 50);
        var now = clock.GetUtcNow().UtcDateTime;
        var articles = db.Articles.AsNoTracking()
            .Visible()
            .Where(a => a.PublishedAt != null);

        var articleLanguage = ArticleLanguages.ForUi(query.UiLanguage);
        if (!string.IsNullOrWhiteSpace(query.FieldSlug))
        {
            articles = articles.Where(a => a.Field.Slug == query.FieldSlug);
        }

        // The feed is a list of tiers, each ranked (FeedRanking). Signed in with interests and no field filter: the articles
        // in your interests, then all the others. Everyone else: one tier. Signed in, what you muted or marked "show less"
        // is left out, and the topics (or fields) you marked are lowered: a last tier (F28).
        IQueryable<Article>[] tiers = [articles];
        if (currentUser.UserId is { } userId)
        {
            articles = articles.WithoutMutedFor(db, userId).WithoutShownLessFor(db, userId);
            tiers = [articles];

            var user = await db.Users.AsNoTracking()
                .Where(u => u.Id == userId)
                .Select(u => new
                {
                    u.ArticleLanguagePref,
                    FieldIds = u.Interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value).ToList(),
                    TopicIds = u.Interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value).ToList(),
                })
                .FirstOrDefaultAsync(ct);

            articleLanguage = user?.ArticleLanguagePref ?? articleLanguage;

            // Lowered last, always the final tier, so a cursor's tier number keeps its meaning when marks come and go.
            var (loweredTopics, loweredFields) = await db.LoweredAsync(userId, now, ct);
            var kept = articles;
            IQueryable<Article>[] lowered = [];
            if (loweredTopics.Count + loweredFields.Count > 0)
            {
                Expression<Func<Article, bool>> isLowered = a =>
                    (a.TopicId != null && loweredTopics.Contains(a.TopicId.Value)) || loweredFields.Contains(a.FieldId);
                kept = articles.Where(Not(isLowered));
                lowered = [articles.Where(isLowered)];
            }

            tiers = [kept, .. lowered];
            if (user is not null && string.IsNullOrWhiteSpace(query.FieldSlug) && user.FieldIds.Count + user.TopicIds.Count > 0)
            {
                Expression<Func<Article, bool>> interesting = a =>
                    user.FieldIds.Contains(a.FieldId) || (a.TopicId != null && user.TopicIds.Contains(a.TopicId.Value));
                tiers = [kept.Where(interesting), kept.Where(Not(interesting)), .. lowered];
            }
        }

        using var _ = LocalizedProjection.Begin(query.UiLanguage, articleLanguage);

        // A cursor from before the ranking (ADR 0020) finishes its scroll in the old order; every other one is ranked.
        var (ids, next) = TieredTimeCursor.Decode(query.Cursor) is { } legacy
            ? await NewestFirstAsync(tiers, legacy, limit, ct)
            : await RankedAsync(tiers, RankedCursor.Decode(query.Cursor), now, limit, ct);
        if (ids.Count == 0) return new CursorPage<ArticleCardDto>([], next);

        var found = await db.Articles.AsNoTracking()
            .Visible()
            .Where(a => ids.Contains(a.Id))
            .ProjectToType<ArticleCardDto>(mapping)
            .ToDictionaryAsync(c => c.Id, ct);
        // An article hidden or deleted between the two queries is simply not shown.
        List<ArticleCardDto> page = [.. ids.Where(found.ContainsKey).Select(id => found[id])];
        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync(page, ct), next);
    }

    /// <summary>
    /// The ranked page (ADR 0020): each tier best first against one snapshot time, the cursor's or now. The cursor names
    /// the tier of the last card, so a page that crosses into the next tier never repeats or skips one. A tier the cursor
    /// names can be gone (an Undo removed the last "show less" mark while you paged in the lowered tier): then the last
    /// tier restarts from the top, so nothing is skipped; clients drop the ids they already show.
    /// </summary>
    private async Task<(List<Guid> Ids, string? Next)> RankedAsync(
        IQueryable<Article>[] tiers, RankedCursor? cursor, DateTime now, int limit, CancellationToken ct)
    {
        var snapshot = cursor?.Snapshot ?? now;
        var startTier = cursor?.Tier ?? 0;
        if (startTier >= tiers.Length)
        {
            startTier = tiers.Length - 1;
            cursor = null;
        }

        var page = new List<(int Tier, RankedArticle Row)>(limit + 1);
        for (var tier = startTier; tier < tiers.Length && page.Count <= limit; tier++)
        {
            var ranked = tiers[tier].RankedAt(db, snapshot);
            if (tier == startTier && cursor is { } after) ranked = ranked.After(after.RankedAt, after.Timestamp, after.Id);

            var rows = await ranked.Best().Take(limit + 1 - page.Count).ToListAsync(ct);
            var current = tier;
            page.AddRange(rows.Select(row => (current, row)));
        }

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            var (tier, last) = page[^1];
            next = new RankedCursor(tier, snapshot, last.RankedAt, last.PublishedAt, last.Id).Encode();
        }
        return ([.. page.Select(p => p.Row.Id)], next);
    }

    /// <summary>
    /// The order before the ranking: each tier newest first, for a scroll that started with an older API. Its cursors stay
    /// old-style until it ends; the next first page is ranked.
    /// </summary>
    private static async Task<(List<Guid> Ids, string? Next)> NewestFirstAsync(
        IQueryable<Article>[] tiers, TieredTimeCursor legacy, int limit, CancellationToken ct)
    {
        TieredTimeCursor? cursor = legacy;
        var startTier = legacy.Tier;
        if (startTier >= tiers.Length)
        {
            startTier = tiers.Length - 1;
            cursor = null;
        }

        var page = new List<(int Tier, Guid Id, DateTime PublishedAt)>(limit + 1);
        for (var tier = startTier; tier < tiers.Length && page.Count <= limit; tier++)
        {
            var source = tiers[tier];
            if (tier == startTier && cursor is { } after)
            {
                source = source.Where(a =>
                    a.PublishedAt < after.Timestamp ||
                    (a.PublishedAt == after.Timestamp && a.Id.CompareTo(after.Id) < 0));
            }

            var rows = await source
                .OrderByDescending(a => a.PublishedAt)
                .ThenByDescending(a => a.Id)
                .Take(limit + 1 - page.Count)
                .Select(a => new { a.Id, PublishedAt = a.PublishedAt!.Value })
                .ToListAsync(ct);
            var current = tier;
            page.AddRange(rows.Select(row => (current, row.Id, row.PublishedAt)));
        }

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            var (tier, id, publishedAt) = page[^1];
            next = new TieredTimeCursor(tier, publishedAt, id).Encode();
        }
        return ([.. page.Select(p => p.Id)], next);
    }

    private static Expression<Func<Article, bool>> Not(Expression<Func<Article, bool>> predicate) =>
        Expression.Lambda<Func<Article, bool>>(Expression.Not(predicate.Body), predicate.Parameters);
}
