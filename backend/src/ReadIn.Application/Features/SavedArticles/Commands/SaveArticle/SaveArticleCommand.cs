using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.SaveArticle;

/// <summary>PUT /me/saved/{articleId} — saves a published article; idempotent (SPEC F13).</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record SaveArticleCommand(Guid ArticleId) : ICommand<Result<SaveStateDto>>;
