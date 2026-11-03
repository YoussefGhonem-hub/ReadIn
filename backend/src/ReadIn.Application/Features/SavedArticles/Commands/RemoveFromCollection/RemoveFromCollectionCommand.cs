using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.RemoveFromCollection;

/// <summary>DELETE /me/collections/{id}/articles/{articleId} — takes an article out of your collection; it stays saved.</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record RemoveFromCollectionCommand(Guid CollectionId, Guid ArticleId) : ICommand<Result>;
