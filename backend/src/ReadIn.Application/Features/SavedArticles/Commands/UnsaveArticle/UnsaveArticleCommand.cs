using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.UnsaveArticle;

/// <summary>DELETE /me/saved/{articleId} — unsaves the article and takes it out of every collection; idempotent.</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record UnsaveArticleCommand(Guid ArticleId) : ICommand<Result<SaveStateDto>>;
