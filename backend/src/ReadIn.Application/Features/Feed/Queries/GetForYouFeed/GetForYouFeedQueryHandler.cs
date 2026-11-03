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

internal sealed class GetForYouFeedQueryHandler(IAppDbContext db, ICurrentUser currentUser, TypeAdapterConfig mapping)
    : IQueryHandler<GetForYouFeedQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetForYouFeedQuery query, CancellationToken ct)
    {
        var limit = Math.Clamp(query.Limit, 1, 50);
        var articles = db.Articles.AsNoTracking()
            .Where(a => a.Status == ArticleStatus.Published && a.PublishedAt != null && a.Field.IsEnabled);

        string? articleLanguage = null;
        if (!string.IsNullOrWhiteSpace(query.FieldSlug))
        {
            articles = articles.Where(a => a.Field.Slug == query.FieldSlug);
        }

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

            articleLanguage = user?.ArticleLanguagePref;
            if (user is not null && string.IsNullOrWhiteSpace(query.FieldSlug) && user.FieldIds.Count + user.TopicIds.Count > 0)
            {
                var interesting = articles.Where(a =>
                    user.FieldIds.Contains(a.FieldId) || (a.TopicId != null && user.TopicIds.Contains(a.TopicId.Value)));
                // Fall back to everything when nothing matches the interests yet (young catalogue).
                if (await interesting.AnyAsync(ct)) articles = interesting;
            }
        }

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            articles = articles.Where(a =>
                a.PublishedAt < cursor.Timestamp ||
                (a.PublishedAt == cursor.Timestamp && a.Id.CompareTo(cursor.Id) < 0));
        }

        using var _ = LocalizedProjection.Begin(query.UiLanguage, articleLanguage);

        var page = await articles
            .OrderByDescending(a => a.PublishedAt)
            .ThenByDescending(a => a.Id)
            .Take(limit + 1)
            .ProjectToType<ArticleCardDto>(mapping)
            .ToListAsync(ct);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            var last = page[^1];
            next = new TimeCursor(last.PublishedAt!.Value, last.Id).Encode();
        }

        return new CursorPage<ArticleCardDto>(page, next);
    }
}
