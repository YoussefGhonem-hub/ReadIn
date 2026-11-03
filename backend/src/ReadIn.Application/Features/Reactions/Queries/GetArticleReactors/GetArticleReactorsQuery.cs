using Mediator;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Reactions.Queries.GetArticleReactors;

/// <summary>GET /articles/{id}/reactions?type= — "who reacted", newest first; <see cref="Type"/> keeps one reaction type.</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetArticleReactorsQuery(Guid ArticleId, string? Type, string? Cursor, int Limit) : IQuery<Result<CursorPage<ReactorDto>>>;
