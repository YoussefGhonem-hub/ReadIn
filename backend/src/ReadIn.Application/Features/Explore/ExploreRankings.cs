using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.Search;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Explore;

/// <summary>
/// The rankings behind Explore and the field pages (SPEC F15, contract-v1 "Explore and field pages"): trending this week,
/// most saved, new writers and a field's top writers. The ranked ids are the same for everyone, so the two article
/// rankings are cached (<see cref="ExploreLimits.CacheExpiration"/>, dropped with <see cref="CacheTags.Feed"/>); cards and
/// the caller's own state are added per request. Each ranking is one SQL query.
/// </summary>
public sealed class ExploreRankings(IAppDbContext db, TimeProvider clock, HybridCache cache, TypeAdapterConfig mapping, IFileStorage storage)
{
    internal static readonly HybridCacheEntryOptions CacheOptions = new()
    {
        Expiration = ExploreLimits.CacheExpiration,
        LocalCacheExpiration = ExploreLimits.CacheExpiration,
    };

    internal DateTime Now => clock.GetUtcNow().UtcDateTime;

    /// <summary>Articles readers can open (SPEC F22): every article ranking starts here.</summary>
    internal IQueryable<Article> Visible() => db.Articles.AsNoTracking().Visible().Where(a => a.PublishedAt != null);

    /// <summary>"Trending this week", best first (≤ <see cref="ExploreLimits.MaxRankedResults"/>), cached.</summary>
    public async Task<IReadOnlyList<Guid>> TrendingAsync(CancellationToken ct) =>
        await cache.GetOrCreateAsync(
            "explore:trending",
            this,
            static async (self, token) => await self.RankTrendingAsync(self.Visible(), self.Now, ExploreLimits.MaxRankedResults, token),
            CacheOptions,
            [CacheTags.Feed],
            ct);

    /// <summary>"Most saved", best first (≤ <see cref="ExploreLimits.MaxRankedResults"/>), cached.</summary>
    public async Task<IReadOnlyList<Guid>> MostSavedAsync(CancellationToken ct) =>
        await cache.GetOrCreateAsync(
            "explore:most-saved",
            this,
            static async (self, token) => await self.RankMostSavedAsync(self.Visible(), self.Now, ExploreLimits.MaxRankedResults, token),
            CacheOptions,
            [CacheTags.Feed],
            ct);

    /// <summary>
    /// Trending among <paramref name="candidates"/>: engagement in the last 7 days (completed reads 1, reactions 2,
    /// comments 4, saves 6; the author's own activity left out), then the quality score, the newest, the id.
    /// </summary>
    internal async Task<List<Guid>> RankTrendingAsync(IQueryable<Article> candidates, DateTime now, int take, CancellationToken ct)
    {
        var since = now - ExploreRanking.TrendingWindow;
        return await candidates
            .Select(a => new
            {
                a.Id,
                a.QualityScore,
                a.PublishedAt,
                Engagement =
                    ExploreRanking.CompletedReadWeight * db.ReadingProgress.Count(p =>
                        p.ArticleId == a.Id && p.CompletedAt >= since && (a.AuthorId == null || p.UserId != a.AuthorId))
                    + ExploreRanking.ReactionWeight * db.Reactions.Count(r =>
                        r.ArticleId == a.Id && r.ReactedAt >= since && (a.AuthorId == null || r.UserId != a.AuthorId))
                    // Deleted comments are left out by the query filter, hidden ones here.
                    + ExploreRanking.CommentWeight * db.Comments.Count(c =>
                        c.ArticleId == a.Id && c.CreatedAt >= since && c.HiddenAt == null
                        && (a.AuthorId == null || c.AuthorId == null || c.AuthorId != a.AuthorId))
                    + ExploreRanking.SaveWeight * db.SavedArticles.Count(s =>
                        s.ArticleId == a.Id && s.SavedAt >= since && (a.AuthorId == null || s.UserId != a.AuthorId)),
            })
            .OrderByDescending(x => x.Engagement)
            .ThenByDescending(x => x.QualityScore)
            .ThenByDescending(x => x.PublishedAt)
            .ThenByDescending(x => x.Id)
            .Take(take)
            .Select(x => x.Id)
            .ToListAsync(ct);
    }

    /// <summary>
    /// Most saved among <paramref name="candidates"/>: saves in the last 30 days (not the author's own), then all-time
    /// saves (<c>SaveCount</c>), the newest, the id. Articles nobody saved are left out.
    /// </summary>
    internal async Task<List<Guid>> RankMostSavedAsync(IQueryable<Article> candidates, DateTime now, int take, CancellationToken ct)
    {
        var since = now - ExploreRanking.MostSavedWindow;
        return await candidates
            .Where(a => a.SaveCount > 0)
            .Select(a => new
            {
                a.Id,
                a.SaveCount,
                a.PublishedAt,
                Recent = db.SavedArticles.Count(s =>
                    s.ArticleId == a.Id && s.SavedAt >= since && (a.AuthorId == null || s.UserId != a.AuthorId)),
            })
            .OrderByDescending(x => x.Recent)
            .ThenByDescending(x => x.SaveCount)
            .ThenByDescending(x => x.PublishedAt)
            .ThenByDescending(x => x.Id)
            .Take(take)
            .Select(x => x.Id)
            .ToListAsync(ct);
    }

    /// <summary>
    /// People whose first article readers can see was published in the last 30 days, latest first publish first. Only
    /// <see cref="ExploreWriters.Listed"/> people.
    /// </summary>
    internal async Task<List<Guid>> NewWriterIdsAsync(DateTime now, int take, CancellationToken ct)
    {
        var since = now - ExploreRanking.NewWriterWindow;
        var firsts = Visible()
            .Where(a => a.AuthorId != null)
            .GroupBy(a => a.AuthorId!.Value)
            .Select(g => new { AuthorId = g.Key, First = g.Min(a => a.PublishedAt!.Value) })
            .Where(x => x.First >= since);

        return await firsts
            .Join(db.Users.AsNoTracking().Listed(now), x => x.AuthorId, u => u.Id, (x, u) => new { u.Id, x.First })
            .OrderByDescending(x => x.First)
            .ThenByDescending(x => x.Id)
            .Take(take)
            .Select(x => x.Id)
            .ToListAsync(ct);
    }

    /// <summary>
    /// A field's top writers: completed reads (1) and reactions (2) by others on their articles in the field in the last
    /// 90 days, then their articles readers can see in the field, their followers, their @username. Every listed writer
    /// with an article there is a candidate, so a quiet field still has its writers.
    /// </summary>
    internal async Task<List<Guid>> TopWriterIdsAsync(Guid fieldId, DateTime now, int take, CancellationToken ct)
    {
        var since = now - ExploreRanking.TopWritersWindow;
        var inField = Visible().Where(a => a.FieldId == fieldId);

        return await db.Users.AsNoTracking().Listed(now)
            .Where(u => inField.Any(a => a.AuthorId == u.Id))
            .Select(u => new
            {
                u.Id,
                u.Username,
                Score =
                    ExploreRanking.CompletedReadWeight * (
                        from a in inField
                        where a.AuthorId == u.Id
                        join p in db.ReadingProgress on a.Id equals p.ArticleId
                        where p.CompletedAt >= since && p.UserId != u.Id
                        select p.Id).Count()
                    + ExploreRanking.ReactionWeight * (
                        from a in inField
                        where a.AuthorId == u.Id
                        join r in db.Reactions on a.Id equals r.ArticleId
                        where r.ReactedAt >= since && r.UserId != u.Id
                        select r.Id).Count(),
                Articles = inField.Count(a => a.AuthorId == u.Id),
                Followers = db.UserFollows.Count(f => f.FolloweeId == u.Id && !db.Users.Any(r => r.Id == f.FollowerId && r.IsReviewAccount)),
            })
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.Articles)
            .ThenByDescending(x => x.Followers)
            .ThenBy(x => x.Username)
            .Take(take)
            .Select(x => x.Id)
            .ToListAsync(ct);
    }

    /// <summary>
    /// Cards for <paramref name="ids"/> in that order, as SQL projects them (before URLs, attachments and the caller's
    /// state: <see cref="ArticleCards.CompleteAsync"/>). Articles no longer visible, or muted or marked
    /// "show less" by <paramref name="viewerId"/> (F28), are left out.
    /// </summary>
    internal async Task<List<ArticleCardDto>> CardsAsync(
        IReadOnlyList<Guid> ids, string uiLanguage, string? articleLanguage, Guid? viewerId, CancellationToken ct)
    {
        if (ids.Count == 0) return [];
        var wanted = ids.Distinct().ToList();
        List<ArticleCardDto> projected;
        using (LocalizedProjection.Begin(uiLanguage, articleLanguage))
        {
            projected = await Visible()
                .Where(a => wanted.Contains(a.Id))
                .WithoutMutedFor(db, viewerId)
                .WithoutShownLessFor(db, viewerId)
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct);
        }

        var byId = projected.ToDictionary(c => c.Id);
        return [.. ids.Where(byId.ContainsKey).Select(id => byId[id])];
    }

    /// <summary>User summaries for <paramref name="ids"/> in that order, without the caller's follow state.</summary>
    internal async Task<List<UserSummaryDto>> UsersAsync(IReadOnlyList<Guid> ids, CancellationToken ct)
    {
        if (ids.Count == 0) return [];
        var wanted = ids.Distinct().ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => wanted.Contains(u.Id))
            .Select(UserSummaries.For(db, viewerId: null))
            .ToDictionaryAsync(u => u.Id, ct);
        return [.. ids.Where(users.ContainsKey).Select(id => users[id])];
    }

    /// <summary>
    /// The caller's side of a cached list of people: only those still <see cref="ExploreWriters.Listed"/> (someone
    /// suspended, or who deleted their account, since the list was cached leaves it at once), absolute avatar URLs,
    /// <c>isFollowing</c> / <c>followsYou</c>, and without the writers they muted (F28). Guests get the URLs.
    /// </summary>
    internal async Task<List<UserSummaryDto>> ForViewerAsync(IReadOnlyList<UserSummaryDto> users, Guid? viewerId, CancellationToken ct)
    {
        if (users.Count == 0) return [];

        // One small query by primary key on every request, after the cache.
        var ids = users.Select(u => u.Id).ToList();
        var kept = (await db.Users.AsNoTracking().Where(u => ids.Contains(u.Id)).Listed(Now).WithoutMutedFor(db, viewerId)
            .Select(u => u.Id).ToListAsync(ct)).ToHashSet();
        var withUrls = users.Where(u => kept.Contains(u.Id)).Select(u => u.WithPublicUrls(storage)).ToList();
        if (viewerId is not { } viewer || withUrls.Count == 0) return withUrls;

        var follows = await db.UserFollows.AsNoTracking()
            .Where(f => (f.FollowerId == viewer && ids.Contains(f.FolloweeId)) || (f.FolloweeId == viewer && ids.Contains(f.FollowerId)))
            .Select(f => new { f.FollowerId, f.FolloweeId })
            .ToListAsync(ct);
        var following = follows.Where(f => f.FollowerId == viewer).Select(f => f.FolloweeId).ToHashSet();
        var followers = follows.Where(f => f.FolloweeId == viewer).Select(f => f.FollowerId).ToHashSet();

        return [.. withUrls.Select(u => u with { IsFollowing = following.Contains(u.Id), FollowsYou = followers.Contains(u.Id) })];
    }
}

/// <summary>Who Explore and the field pages list as writers (New writers, Top writers).</summary>
internal static class ExploreWriters
{
    /// <summary>
    /// People, not accounts: no system account (the official ReadIn account), nobody suspended right now, no profile
    /// still on its <c>@reader_…</c> placeholder; deleted accounts are left out by the query filter.
    /// </summary>
    public static IQueryable<User> Listed(this IQueryable<User> users, DateTime now) =>
        users.Findable(now).Where(u => !u.IsSystemAccount);
}
