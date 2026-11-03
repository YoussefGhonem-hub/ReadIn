using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Commands.SetArticleAttachments;

/// <param name="Title">The document's title (required for a PDF).</param>
/// <param name="AllowDownload">Whether readers may download the original PDF.</param>
public sealed record AttachmentItemInput(
    Guid MediaAssetId,
    int Order,
    string? Caption,
    string? AltText,
    string? Title,
    bool? AllowDownload);

/// <summary>
/// PUT /articles/{id}/attachments: replaces the article's attachments with 1–10 images or one PDF (ADR 0011).
/// An empty list removes them. Every asset must be the author's own and ready.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record SetArticleAttachmentsCommand(Guid ArticleId, IReadOnlyList<AttachmentItemInput> Items) : ICommand<Result>;
