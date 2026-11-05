using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Mutes.Commands.UndoShowLess;

/// <summary>DELETE /articles/{id}/show-less — the toast's Undo: the article and its topic (or field) come back; idempotent.</summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record UndoShowLessCommand(Guid ArticleId) : ICommand<Result>;
