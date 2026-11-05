using Mediator;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetFollowingFeed;

/// <summary>
/// GET /feed/following — the "Following" tab (SPEC F03, F12, F29): published articles written or reposted by the writers
/// you follow, each once, at the later of its publish (when you follow its author) and the newest followed repost,
/// keyset-paginated over (that time DESC, Id DESC). A card a repost placed carries the label (<c>repostedBy</c>).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetFollowingFeedQuery(string? Cursor, int Limit, string UiLanguage) : IQuery<Result<CursorPage<ArticleCardDto>>>;
