using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetTodayArticle;

/// <summary>
/// GET /feed/today — "مقال النهارده" (SPEC F07). Returns the stored pick for the user's local date, or picks
/// one now. A Hangfire job will precompute picks before the reminder time; this is the on-demand fallback.
/// Value is null when no eligible article exists yet (→ 204).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetTodayArticleQuery(string UiLanguage) : IQuery<Result<ArticleCardDto?>>;
