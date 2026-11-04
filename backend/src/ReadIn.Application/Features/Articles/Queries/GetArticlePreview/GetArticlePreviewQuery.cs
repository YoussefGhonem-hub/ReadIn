using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticlePreview;

/// <summary>
/// GET /articles/{id}/preview?lang= — what a feed card's "Read more" shows (SPEC F34): the first whole blocks of the
/// requested version (else the source language), about 300 words. Visible exactly like <c>GET /articles/{slug}</c>:
/// <c>article.not_found</c> unless published, and an article hidden by a moderator only for its author and moderators
/// (SPEC F22). Cached like the details: one copy for every reader, invalidated with them, the visibility decided per caller.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetArticlePreviewQuery(Guid ArticleId, string? Language) : IQuery<Result<ArticlePreviewDto>>
{
    public static readonly TimeSpan Expiration = TimeSpan.FromMinutes(10);
}
