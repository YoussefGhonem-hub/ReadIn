using System.Text;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Queries.GetDocumentDownload;

/// <summary>The original PDF and the file name to save it as. The caller disposes <see cref="Content"/>.</summary>
public sealed record DocumentDownload(Stream Content, string FileName);

/// <summary>
/// GET /documents/{assetId}/download (ADR 0011). Readers get the original PDF when its article is published and the
/// author allowed downloads; the owner and moderators always do. Anything else looks like a missing file, except a
/// published document whose author disabled downloads (<c>media.download_not_allowed</c>).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetDocumentDownloadQuery(Guid AssetId) : IQuery<Result<DocumentDownload>>;
