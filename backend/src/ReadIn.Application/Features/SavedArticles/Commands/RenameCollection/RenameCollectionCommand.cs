using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.RenameCollection;

/// <summary>PATCH /me/collections/{id} — renames your collection.</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record RenameCollectionCommand(Guid CollectionId, string Name) : ICommand<Result<CollectionDto>>;
