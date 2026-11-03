using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.DeleteCollection;

/// <summary>DELETE /me/collections/{id} — deletes your collection; its articles stay saved.</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record DeleteCollectionCommand(Guid CollectionId) : ICommand<Result>;
