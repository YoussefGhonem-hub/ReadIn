using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Queries.GetCollections;

/// <summary>GET /me/collections — your collections in name order.</summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record GetCollectionsQuery : IQuery<Result<IReadOnlyList<CollectionDto>>>;
