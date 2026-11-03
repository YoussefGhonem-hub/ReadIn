using System.Text.Json;
using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Commands.CreateArticle;

public sealed record SourceInput(string Title, string Url);

/// <summary>POST /articles — creates a draft with its first language version (SPEC §6.3, F05).</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record CreateArticleCommand(
    Guid FieldId,
    Guid? TopicId,
    string Language,
    string Title,
    string? Subtitle,
    JsonElement Content,
    IReadOnlyList<string>? Tags,
    IReadOnlyList<SourceInput>? Sources,
    string? CoverUrl,
    string? VersionBadge,
    bool IsAiAssisted) : ICommand<Result<CreatedArticle>>;

/// <summary>The new draft: its id for further edits and its slug for the reader URL.</summary>
public sealed record CreatedArticle(Guid Id, string Slug);
