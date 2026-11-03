using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Commands.DeleteArticle;

/// <summary>DELETE /articles/{id}: the author soft-deletes an own article; its attachments are deleted with their files (ADR 0011).</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record DeleteArticleCommand(Guid ArticleId) : ICommand<Result>;
