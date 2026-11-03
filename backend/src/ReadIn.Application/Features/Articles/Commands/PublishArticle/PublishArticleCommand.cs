using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Commands.PublishArticle;

/// <summary>POST /articles/{id}/publish — author publishes now (SPEC F06).</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record PublishArticleCommand(Guid ArticleId) : ICommand<Result>;
