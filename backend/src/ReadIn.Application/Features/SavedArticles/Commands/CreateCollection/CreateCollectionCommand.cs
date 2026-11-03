using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Commands.CreateCollection;

/// <summary>POST /me/collections — a named list of saved articles; names are unique per user, ignoring case (SPEC F13).</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record CreateCollectionCommand(string Name) : ICommand<Result<CollectionDto>>;
