using System.Text;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Queries.GetDocumentDownload;

internal sealed class GetDocumentDownloadQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
    : IQueryHandler<GetDocumentDownloadQuery, Result<DocumentDownload>>
{
    public async ValueTask<Result<DocumentDownload>> Handle(GetDocumentDownloadQuery query, CancellationToken cancellationToken)
    {
        var asset = await db.MediaAssets.AsNoTracking()
            .Where(a => a.Id == query.AssetId && a.Kind == MediaKind.Document && a.OriginalPath != null)
            .Select(a => new { a.OwnerId, a.OriginalPath, a.Title, a.AllowDownload })
            .FirstOrDefaultAsync(cancellationToken);
        if (asset is null) return MediaErrors.NotFound;

        var privileged = currentUser.UserId == asset.OwnerId || currentUser.Permissions.Contains(Permissions.Moderation.Manage);
        if (!privileged)
        {
            var published = await db.Articles.AsNoTracking().Visible()
                .AnyAsync(a => a.Attachments.Any(x => x.MediaAssetId == query.AssetId), cancellationToken);
            if (!published) return MediaErrors.NotFound;
            if (!asset.AllowDownload) return MediaErrors.DownloadNotAllowed;
        }

        try
        {
            var content = await storage.OpenReadAsync(asset.OriginalPath!, cancellationToken);
            return new DocumentDownload(content, SafeFileName(asset.Title) + ".pdf");
        }
        catch (FileNotFoundException)
        {
            return MediaErrors.NotFound;
        }
    }

    /// <summary>Letters (any script), digits, spaces, '-' and '_' only, at most 100 characters.</summary>
    internal static string SafeFileName(string? title)
    {
        var name = new StringBuilder();
        foreach (var ch in (title ?? string.Empty).Trim())
        {
            if (char.IsLetterOrDigit(ch) || ch is '-' or '_') name.Append(ch);
            else if (char.IsWhiteSpace(ch) && name.Length > 0 && name[^1] != ' ') name.Append(' ');
            if (name.Length >= 100) break;
        }
        var result = name.ToString().Trim();
        return result.Length == 0 ? "document" : result;
    }
}
