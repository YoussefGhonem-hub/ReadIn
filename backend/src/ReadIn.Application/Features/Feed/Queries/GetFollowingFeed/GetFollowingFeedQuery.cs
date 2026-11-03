using Mediator;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetFollowingFeed;

/// <summary>
/// GET /feed/following — the "Following" tab (SPEC F03, F12): published articles by the writers you follow, newest
/// first, keyset-paginated over (PublishedAt DESC, Id DESC).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetFollowingFeedQuery(string? Cursor, int Limit, string UiLanguage) : IQuery<Result<CursorPage<ArticleCardDto>>>;
