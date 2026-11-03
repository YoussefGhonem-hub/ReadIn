using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.AddToCollection;

/// <summary>PUT /me/collections/{id}/articles/{articleId} — adds an article to your collection, saving it first if needed.</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record AddToCollectionCommand(Guid CollectionId, Guid ArticleId) : ICommand<Result>;
