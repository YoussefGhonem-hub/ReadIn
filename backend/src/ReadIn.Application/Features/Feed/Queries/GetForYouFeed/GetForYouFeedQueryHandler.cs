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
        var articles = db.Articles.AsNoTracking()
            .Visible()
            .Where(a => a.PublishedAt != null);

        var articleLanguage = ArticleLanguages.ForUi(query.UiLanguage);
        if (!string.IsNullOrWhiteSpace(query.FieldSlug))
        {
            articles = articles.Where(a => a.Field.Slug == query.FieldSlug);
        }

        // The feed is a list of tiers, each newest first. Signed in with interests and no field filter: the articles in
        // your interests, then all the others. Everyone else: one tier, the latest articles. Signed in, what you muted or
        // marked "show less" is left out, and the topics (or fields) you marked are lowered: a last tier (F28).
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
            var (loweredTopics, loweredFields) = await db.LoweredAsync(userId, clock.GetUtcNow().UtcDateTime, ct);
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

        // The cursor names the tier of the last card, so a page that crosses into the next tier never repeats or skips one.
        // A tier the cursor names can be gone (an Undo removed the last "show less" mark while you paged in the lowered
        // tier): then the last tier restarts from the top, so nothing is skipped; clients drop the ids they already show.
        var cursor = TieredTimeCursor.Decode(query.Cursor);
        var startTier = cursor?.Tier ?? 0;
        if (startTier >= tiers.Length)
        {
            startTier = tiers.Length - 1;
            cursor = null;
        }

        using var _ = LocalizedProjection.Begin(query.UiLanguage, articleLanguage);

        var page = new List<(int Tier, ArticleCardDto Card)>(limit + 1);
        for (var tier = startTier; tier < tiers.Length && page.Count <= limit; tier++)
        {
            var source = tiers[tier];
            if (tier == startTier && cursor is { } after)
            {
                source = source.Where(a =>
                    a.PublishedAt < after.Timestamp ||
                    (a.PublishedAt == after.Timestamp && a.Id.CompareTo(after.Id) < 0));
            }

            var found = await source
                .OrderByDescending(a => a.PublishedAt)
                .ThenByDescending(a => a.Id)
                .Take(limit + 1 - page.Count)
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct);
            var current = tier;
            page.AddRange(found.Select(card => (current, card)));
        }

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            var (tier, last) = page[^1];
            next = new TieredTimeCursor(tier, last.PublishedAt!.Value, last.Id).Encode();
        }

        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync([.. page.Select(p => p.Card)], ct), next);
    }

    private static Expression<Func<Article, bool>> Not(Expression<Func<Article, bool>> predicate) =>
        Expression.Lambda<Func<Article, bool>>(Expression.Not(predicate.Body), predicate.Parameters);
}
