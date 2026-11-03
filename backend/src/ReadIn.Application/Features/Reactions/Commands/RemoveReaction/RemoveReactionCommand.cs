using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Reactions.Commands.RemoveReaction;

/// <summary>DELETE /articles/{id}/reaction — removes your reaction; idempotent (SPEC §17.1).</summary>
[Authenticated]
[RequirePermission(Permissions.Reactions.Create)]
public sealed record RemoveReactionCommand(Guid ArticleId) : ICommand<Result<ArticleReactionsDto>>;
