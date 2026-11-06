using Mediator;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetForYouFeed;

/// <summary>
/// GET /feed/for-you — signed-in users see the articles in their interests first, then all the others; guests see one
/// group, in the UI's language. Each group is ranked by freshness, popularity and the Verified badge
/// (<see cref="FeedRanking"/>, ADR 0020), keyset-paginated over (tier, rank DESC, PublishedAt DESC, Id DESC) against the
/// snapshot time the cursor carries.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetForYouFeedQuery(string? FieldSlug, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<ArticleCardDto>>>;
