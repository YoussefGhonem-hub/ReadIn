using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Commands.DeleteMediaAsset;

internal sealed class DeleteMediaAssetCommandHandler(IAppDbContext db, ICurrentUser currentUser, MediaFiles files)
    : ICommandHandler<DeleteMediaAssetCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteMediaAssetCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var asset = await db.MediaAssets.Include(a => a.Pages)
            .FirstOrDefaultAsync(a => a.Id == command.Id && a.OwnerId == userId, cancellationToken);
        if (asset is null) return MediaErrors.NotFound;
        if (await db.ArticleAttachments.AnyAsync(a => a.MediaAssetId == asset.Id, cancellationToken)) return MediaErrors.InUse;

        // An attachment the writer added in the editor but hasn't published yet is in use too (F05).
        var id = asset.Id.ToString();
        if (await db.ArticleDrafts.AnyAsync(d => d.DocumentJson.Contains(id), cancellationToken)) return MediaErrors.InUse;

        var paths = asset.StoredPaths().ToList();
        db.MediaAssets.Remove(asset);
        await db.SaveChangesAsync(cancellationToken);

        await files.DeleteAsync(paths, cancellationToken);
        return Result.Success();
    }
}
