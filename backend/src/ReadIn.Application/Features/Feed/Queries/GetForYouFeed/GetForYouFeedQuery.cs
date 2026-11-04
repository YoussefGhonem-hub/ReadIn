using Mediator;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetForYouFeed;

/// <summary>
/// GET /feed/for-you — signed-in users see the articles in their interests first, then all the others; guests see the
/// latest articles, in the UI's language. Keyset-paginated over (tier, PublishedAt DESC, Id DESC).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetForYouFeedQuery(string? FieldSlug, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<ArticleCardDto>>>;
