using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Reactions.Commands.SetReaction;

/// <summary>
/// PUT /articles/{id}/reaction — sets or changes your one reaction to a published article (SPEC F10). <see cref="Type"/>
/// is <c>insightful</c> | <c>love</c> | <c>fire</c> | <c>mindBlown</c>; anything else is the validation code
/// <c>reaction.invalid</c>.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Reactions.Create)]
public sealed record SetReactionCommand(Guid ArticleId, string? Type) : ICommand<Result<ArticleReactionsDto>>;
