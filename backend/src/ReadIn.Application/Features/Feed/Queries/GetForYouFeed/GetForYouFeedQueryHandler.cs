using System.Linq.Expressions;
using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetForYouFeed;

internal sealed class GetForYouFeedQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards)
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
        // your interests, then all the others. Everyone else: one tier, the latest articles.
        IQueryable<Article>[] tiers = [articles];
        if (currentUser.UserId is { } userId)
        {
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
            if (user is not null && string.IsNullOrWhiteSpace(query.FieldSlug) && user.FieldIds.Count + user.TopicIds.Count > 0)
            {
                Expression<Func<Article, bool>> interesting = a =>
                    user.FieldIds.Contains(a.FieldId) || (a.TopicId != null && user.TopicIds.Contains(a.TopicId.Value));
                var others = Expression.Lambda<Func<Article, bool>>(Expression.Not(interesting.Body), interesting.Parameters);
                tiers = [articles.Where(interesting), articles.Where(others)];
            }
        }

        // The cursor names the tier of the last card, so a page that crosses into the next tier never repeats or skips one.
        var cursor = TieredTimeCursor.Decode(query.Cursor);
        var startTier = Math.Min(cursor?.Tier ?? 0, tiers.Length - 1);

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
}
