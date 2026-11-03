using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Uploads.Commands.UploadDocument;

/// <summary>
/// POST /uploads/documents: accepts one PDF (≤ 20 MB, ≤ 100 pages, no password), stores the original and queues the
/// page rendering. Returns the asset in <c>processing</c> state with its page count (ADR 0011).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record UploadDocumentCommand(Stream Content, string? FileName, string? Title, bool AllowDownload)
    : ICommand<Result<MediaAssetDto>>;
