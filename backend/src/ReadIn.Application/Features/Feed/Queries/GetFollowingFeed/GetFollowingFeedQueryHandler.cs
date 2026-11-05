using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetFollowingFeed;

internal sealed class GetFollowingFeedQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards)
    : IQueryHandler<GetFollowingFeedQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetFollowingFeedQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var limit = Math.Clamp(query.Limit, 1, 50);

        var articles = db.Articles.AsNoTracking()
            .Visible()
            .Where(a => a.PublishedAt != null)
            .Where(a => db.UserFollows.Any(f => f.FollowerId == userId && f.FolloweeId == a.AuthorId))
            // A followed writer is never muted (the two end each other), but their muted fields and topics, and what you
            // marked "show less", stay out (F28).
            .WithoutMutedFor(db, userId)
            .WithoutShownLessFor(db, userId);

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            articles = articles.Where(a =>
                a.PublishedAt < cursor.Timestamp ||
                (a.PublishedAt == cursor.Timestamp && a.Id.CompareTo(cursor.Id) < 0));
        }

        var articleLanguage = await db.Users.AsNoTracking().Where(u => u.Id == userId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct);
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

        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync(page, ct), next);
    }
}
