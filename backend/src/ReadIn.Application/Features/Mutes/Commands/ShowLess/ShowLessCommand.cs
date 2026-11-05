using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Mutes.Commands.ShowLess;

/// <summary>
/// PUT /articles/{id}/show-less — "قلّل من النوع ده" (SPEC F28): the article leaves your feeds, and its topic (or its field
/// when it has no topic) goes to the bottom of For you for 90 days. Idempotent: a repeat changes nothing.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record ShowLessCommand(Guid ArticleId) : ICommand<Result>;
