using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Features.Feed;

/// <summary>
/// The For you ranking inside each tier (SPEC F03 "interests + popularity + freshness", §10.1 "the badge also gives
/// priority in feeds", ADR 0020, contract-v1 "For you ranking"). Each article gets an effective time, highest first:
/// <code>
/// rank = publishedAt + 4 days × popularity + 1 day × verified          (whole seconds)
/// popularity = 1 − 1 / (1 + E / 20)
/// E = completed reads × 1 + reactions × 2 + comments × 4 + saves × 6 + reposts × 6
/// </code>
/// <c>E</c> is other people's activity in the <see cref="EngagementWindow"/> before the snapshot, and the badge counts
/// when it was given before the snapshot. Everything is measured against one snapshot time per scroll (carried in the
/// cursor), so a rank never moves while the user pages.
/// </summary>
public static class FeedRanking
{
    /// <summary>The most popularity can add: an article nobody can beat on engagement ranks as if 4 days newer.</summary>
    public const int PopularityBoostSeconds = 4 * 24 * 60 * 60;

    /// <summary>A verified writer's article ranks as if it were a day newer.</summary>
    public const int VerifiedBoostSeconds = 24 * 60 * 60;

    /// <summary>The weighted engagement at which popularity is 0.5.</summary>
    public const double EngagementHalfPoint = 20;

    public const int CompletedReadWeight = 1;
    public const int ReactionWeight = 2;
    public const int CommentWeight = 4;
    public const int SaveWeight = 6;
    public const int RepostWeight = 6;

    /// <summary>Only activity in this window before the snapshot counts.</summary>
    public static readonly TimeSpan EngagementWindow = TimeSpan.FromDays(30);

    /// <summary>0 for no engagement, 0.5 at <see cref="EngagementHalfPoint"/>, approaching 1.</summary>
    public static double Popularity(int engagement) => 1.0 - 1.0 / (1.0 + Math.Max(engagement, 0) / EngagementHalfPoint);

    /// <summary>The seconds an article moves up: the SQL ranking computes exactly this (SQL's ROUND rounds a half away from zero).</summary>
    public static int BoostSeconds(int engagement, bool verified) =>
        (int)Math.Round(PopularityBoostSeconds * Popularity(engagement), MidpointRounding.AwayFromZero) + (verified ? VerifiedBoostSeconds : 0);

    /// <summary>
    /// <paramref name="articles"/> (published at or before <paramref name="snapshot"/>) with their rank against it, for
    /// keyset paging over (<see cref="RankedArticle.RankedAt"/> DESC, <see cref="RankedArticle.PublishedAt"/> DESC, id DESC).
    /// One SQL query; the engagement counts are correlated subqueries over the (ArticleId, time) indexes.
    /// </summary>
    internal static IQueryable<RankedArticle> RankedAt(this IQueryable<Article> articles, IAppDbContext db, DateTime snapshot)
    {
        var since = snapshot - EngagementWindow;
        return articles
            .Where(a => a.PublishedAt != null && a.PublishedAt <= snapshot)
            .Select(a => new
            {
                a.Id,
                PublishedAt = a.PublishedAt!.Value,
                Verified = a.Author != null && a.Author.IsVerified && a.Author.VerifiedAt != null && a.Author.VerifiedAt <= snapshot,
                Engagement =
                    CompletedReadWeight * db.ReadingProgress.Count(p =>
                        p.ArticleId == a.Id && p.CompletedAt >= since && p.CompletedAt <= snapshot
                        && (a.AuthorId == null || p.UserId != a.AuthorId))
                    + ReactionWeight * db.Reactions.Count(r =>
                        r.ArticleId == a.Id && r.ReactedAt >= since && r.ReactedAt <= snapshot
                        && (a.AuthorId == null || r.UserId != a.AuthorId))
                    // Deleted comments are left out by the query filter, hidden ones here.
                    + CommentWeight * db.Comments.Count(c =>
                        c.ArticleId == a.Id && c.CreatedAt >= since && c.CreatedAt <= snapshot && c.HiddenAt == null
                        && (a.AuthorId == null || c.AuthorId == null || c.AuthorId != a.AuthorId))
                    + SaveWeight * db.SavedArticles.Count(s =>
                        s.ArticleId == a.Id && s.SavedAt >= since && s.SavedAt <= snapshot
                        && (a.AuthorId == null || s.UserId != a.AuthorId))
                    + RepostWeight * db.Reposts.Count(r =>
                        r.ArticleId == a.Id && r.CreatedAt >= since && r.CreatedAt <= snapshot
                        && (a.AuthorId == null || r.UserId != a.AuthorId)),
            })
            .Select(x => new RankedArticle
            {
                Id = x.Id,
                PublishedAt = x.PublishedAt,
                // The same arithmetic as BoostSeconds, in SQL: rounded to whole seconds, so equal inputs give equal ranks.
                RankedAt = x.PublishedAt.AddSeconds(
                    Math.Round(PopularityBoostSeconds * (1.0 - 1.0 / (1.0 + x.Engagement / EngagementHalfPoint)))
                    + (x.Verified ? VerifiedBoostSeconds : 0)),
            });
    }

    /// <summary>The rows <see cref="RankedAt"/> pages over.</summary>
    internal static IQueryable<RankedArticle> After(this IQueryable<RankedArticle> ranked, DateTime rankedAt, DateTime publishedAt, Guid id) =>
        ranked.Where(r =>
            r.RankedAt < rankedAt
            || (r.RankedAt == rankedAt && (r.PublishedAt < publishedAt || (r.PublishedAt == publishedAt && r.Id.CompareTo(id) < 0))));

    internal static IOrderedQueryable<RankedArticle> Best(this IQueryable<RankedArticle> ranked) =>
        ranked.OrderByDescending(r => r.RankedAt).ThenByDescending(r => r.PublishedAt).ThenByDescending(r => r.Id);
}

/// <summary>An article's place in the ranked For you feed (<see cref="FeedRanking"/>).</summary>
public sealed class RankedArticle
{
    public Guid Id { get; init; }
    public DateTime PublishedAt { get; init; }
    public DateTime RankedAt { get; init; }
}
