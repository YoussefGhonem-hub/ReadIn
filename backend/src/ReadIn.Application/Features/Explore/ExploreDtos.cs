using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.LearningPaths;

namespace ReadIn.Application.Features.Explore;

/// <summary>
/// GET /explore (SPEC F15, <c>docs/api/contract-v1.md</c> "Explore and field pages"): every section of the Explore page.
/// A section with nothing in it is empty, and clients hide it.
/// </summary>
/// <param name="Fields">Every enabled field in display order, empty ones included.</param>
/// <param name="Trending">The first <see cref="ExploreLimits.SectionArticles"/> of <c>/explore/trending</c>.</param>
/// <param name="MostSaved">The first <see cref="ExploreLimits.SectionArticles"/> of <c>/explore/most-saved</c>.</param>
/// <param name="NewWriters">People whose first article was published in the last 30 days, latest first publish first.</param>
/// <param name="FeaturedPaths">Published paths flagged featured, in featured order.</param>
/// <param name="FeaturedArticles">
/// Articles featured in the admin console (SPEC F23) that readers can open, the most recently featured first; empty when
/// none, so clients hide the section.
/// </param>
public sealed record ExploreDto(
    IReadOnlyList<FieldSummaryDto> Fields,
    IReadOnlyList<ArticleCardDto> Trending,
    IReadOnlyList<ArticleCardDto> MostSaved,
    IReadOnlyList<UserSummaryDto> NewWriters,
    IReadOnlyList<PathCardDto> FeaturedPaths,
    IReadOnlyList<ArticleCardDto> FeaturedArticles);

/// <summary>
/// A field tile on Explore; it opens the field page (<c>/f/{Slug}</c>). <see cref="Name"/> follows <c>Accept-Language</c>;
/// <see cref="ArticleCount"/> counts the articles readers can see in it, the same for everyone.
/// </summary>
public sealed record FieldSummaryDto(
    Guid Id,
    string Slug,
    string Name,
    string NameAr,
    string NameEn,
    string Icon,
    string Color,
    int ArticleCount);

/// <summary>
/// GET /fields/{slug}: the field page's header and topic chips (SPEC F15). <see cref="FollowerCount"/> counts the
/// people who follow the field itself (a followed topic doesn't count); <see cref="IsFollowing"/> is the caller's, false
/// for guests. Follow and unfollow go through the F12 interests endpoints with <see cref="Id"/>.
/// </summary>
/// <param name="IsSensitive">The page shows the health disclaimer note.</param>
/// <param name="ArticleCount">Articles readers can see in the field; 0 is the empty state (web: <c>noindex</c>).</param>
/// <param name="Topics">Every topic of the field in editorial order, empty ones included.</param>
public sealed record FieldPageDto(
    Guid Id,
    string Slug,
    string Name,
    string NameAr,
    string NameEn,
    string Icon,
    string Color,
    bool IsSensitive,
    int ArticleCount,
    int FollowerCount,
    bool IsFollowing,
    IReadOnlyList<FieldPageTopicDto> Topics);

/// <summary>
/// A topic chip on the field page: it filters the field's articles with <c>?topic={Slug}</c>, and offers follow
/// (<c>PUT /me/interests/topics/{Id}</c>). <see cref="IsFollowing"/> is false for guests.
/// </summary>
public sealed record FieldPageTopicDto(
    Guid Id,
    string Slug,
    string Name,
    string NameAr,
    string NameEn,
    int ArticleCount,
    bool IsFollowing);

/// <summary>The sizes the contract promises.</summary>
public static class ExploreLimits
{
    /// <summary>Cards in Explore's Trending and Most saved sections.</summary>
    public const int SectionArticles = 6;

    /// <summary>People in Explore's New writers section.</summary>
    public const int SectionWriters = 10;

    /// <summary>Paths in Explore's Featured paths section.</summary>
    public const int SectionPaths = 6;

    /// <summary><c>limit</c> of the article lists (the two rankings and the field's articles): 1–50, default 20.</summary>
    public const int DefaultLimit = 20;
    public const int MaxLimit = 50;

    /// <summary>Articles one ranking pages through; then <c>nextCursor</c> is null.</summary>
    public const int MaxRankedResults = 100;

    /// <summary><c>limit</c> of <c>/fields/{slug}/writers</c>: 1–10, default 10.</summary>
    public const int MaxTopWriters = 10;

    /// <summary>How long the shared (caller-independent) parts are cached.</summary>
    public static readonly TimeSpan CacheExpiration = TimeSpan.FromMinutes(5);
}

/// <summary>
/// The rankings' windows and weights (contract-v1 "Explore and field pages"). The weights are the quality score's
/// interaction weights (<c>ArticleQuality</c>: reaction 1, comment 2, save 3) doubled, plus 1 for a completed read.
/// Activity by the article's own author never counts.
/// </summary>
public static class ExploreRanking
{
    /// <summary>Trending this week: engagement in the last 7 days, rolling; then the quality score.</summary>
    public static readonly TimeSpan TrendingWindow = TimeSpan.FromDays(7);

    /// <summary>Most saved: saves in the last 30 days; then all-time saves (<c>SaveCount</c>).</summary>
    public static readonly TimeSpan MostSavedWindow = TimeSpan.FromDays(30);

    /// <summary>New writers: the first article readers can see was published in the last 30 days.</summary>
    public static readonly TimeSpan NewWriterWindow = TimeSpan.FromDays(30);

    /// <summary>Top writers in a field: reads and reactions on their articles there in the last 90 days.</summary>
    public static readonly TimeSpan TopWritersWindow = TimeSpan.FromDays(90);

    public const int CompletedReadWeight = 1;
    public const int ReactionWeight = 2;
    public const int CommentWeight = 4;
    public const int SaveWeight = 6;
}
