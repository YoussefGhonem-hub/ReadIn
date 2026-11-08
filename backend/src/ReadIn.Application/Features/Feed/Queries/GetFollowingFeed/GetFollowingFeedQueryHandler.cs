using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Reposts;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetFollowingFeed;

internal sealed class GetFollowingFeedQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    IFileStorage storage)
    : IQueryHandler<GetFollowingFeedQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetFollowingFeedQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var limit = Math.Clamp(query.Limit, 1, 50);
        var followees = db.UserFollows.Where(f => f.FollowerId == userId).Select(f => f.FolloweeId);

        var articles = db.Articles.AsNoTracking()
            .Visible()
            // Your own articles never come back to you through someone's repost (the notification tells you).
            .Where(a => a.PublishedAt != null && a.AuthorId != userId)
            // A followed writer is never muted (the two end each other), but reposted articles by writers you muted, their
            // muted fields and topics, and what you marked "show less" stay out (F28, F29).
            .WithoutMutedFor(db, userId)
            .WithoutShownLessFor(db, userId);

        // The candidates come from the two sources only, never from the whole catalogue: the articles of the writers you
        // follow, at their publish, and the reposts by writers you follow, one row per article at its newest
        // (IX_Reposts_UserId_CreatedAt covers it).
        var byAuthor = articles
            .Where(a => a.AuthorId != null && followees.Contains(a.AuthorId.Value))
            .Select(a => new { a.Id, At = a.PublishedAt!.Value, ByRepost = false });
        var byRepost = db.Reposts
            .Where(r => followees.Contains(r.UserId) && articles.Any(a => a.Id == r.ArticleId))
            .GroupBy(r => r.ArticleId)
            .Select(g => new { Id = g.Key, At = g.Max(r => r.CreatedAt), ByRepost = true });

        // Each article once (F29): at the later of its publish (when you follow its author) and the newest repost by a
        // writer you follow; a repost that placed it (later than the publish, or with the author not followed) gives it
        // the label.
        var placed = byAuthor.Concat(byRepost)
            .GroupBy(c => c.Id)
            .Select(g => new
            {
                Id = g.Key,
                FeedAt = g.Max(c => c.At),
                PublishedAt = g.Max(c => c.ByRepost ? (DateTime?)null : c.At),
                RepostedAt = g.Max(c => c.ByRepost ? c.At : (DateTime?)null),
            })
            .Select(x => new
            {
                x.Id,
                ByRepost = x.RepostedAt != null && (x.PublishedAt == null || x.RepostedAt > x.PublishedAt),
                x.FeedAt,
            });

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            placed = placed.Where(x => x.FeedAt < cursor.Timestamp || (x.FeedAt == cursor.Timestamp && x.Id.CompareTo(cursor.Id) < 0));
        }

        var page = await placed
            .OrderByDescending(x => x.FeedAt)
            .ThenByDescending(x => x.Id)
            .Take(limit + 1)
            .ToListAsync(ct);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].FeedAt, page[^1].Id).Encode();
        }
        if (page.Count == 0) return new CursorPage<ArticleCardDto>([], next);

        var articleLanguage = await db.Users.AsNoTracking().Where(u => u.Id == userId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct);
        using var _ = LocalizedProjection.Begin(query.UiLanguage, articleLanguage);

        var ids = page.Select(p => p.Id).ToList();
        var byId = (await db.Articles.AsNoTracking()
                .Where(a => ids.Contains(a.Id))
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct))
            .ToDictionary(c => c.Id);
        var ordered = page.Where(p => byId.ContainsKey(p.Id)).ToList();
        var completed = await cards.CompleteAsync([.. ordered.Select(p => byId[p.Id])], ct);

        var labels = await LabelsAsync([.. ordered.Where(p => p.ByRepost).Select(p => p.Id)], followees, userId, ct);
        return new CursorPage<ArticleCardDto>(
            [.. completed.Select(card => labels.TryGetValue(card.Id, out var label) ? card with { RepostedBy = label } : card)],
            next);
    }

    /// <summary>
    /// "أعاد نشره {name}" / "{name} و N غيره": the newest reposter you follow, with their caption, and how many others you
    /// follow reposted it (their captions aren't shown).
    /// </summary>
    private async Task<Dictionary<Guid, RepostLabelDto>> LabelsAsync(
        IReadOnlyList<Guid> articleIds, IQueryable<Guid> followees, Guid viewerId, CancellationToken ct)
    {
        if (articleIds.Count == 0) return [];

        var reposts = await db.Reposts.AsNoTracking()
            .Where(r => articleIds.Contains(r.ArticleId) && followees.Contains(r.UserId))
            .Select(r => new
            {
                r.Id,
                r.ArticleId,
                r.CreatedAt,
                r.Caption,
                User = new AuthorDto(r.User.Id, r.User.DisplayName, r.User.Username, r.User.AvatarUrl, r.User.IsVerified, r.User.Headline),
            })
            .ToListAsync(ct);

        // F22: the reposts the viewer reported (clients collapse their captions for them).
        var reported = await RepostLabels.ReportedByAsync(db, viewerId, [.. reposts.Select(r => r.Id)], ct);
        return reposts
            .GroupBy(r => r.ArticleId)
            .ToDictionary(g => g.Key, g =>
            {
                var newest = g.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.User.Id).First();
                var user = newest.User with { AvatarUrl = storage.ToPublicUrl(newest.User.AvatarUrl) };
                return new RepostLabelDto(user, g.Count() - 1, newest.CreatedAt, newest.Caption)
                {
                    RepostId = newest.Id,
                    ReportedByMe = reported.Contains(newest.Id),
                };
            });
    }
}
