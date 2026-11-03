using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Queries.GetMediaAsset;

internal sealed class GetMediaAssetQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage, TypeAdapterConfig mapping)
    : IQueryHandler<GetMediaAssetQuery, Result<MediaAssetDto>>
{
    public async ValueTask<Result<MediaAssetDto>> Handle(GetMediaAssetQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var asset = await db.MediaAssets.AsNoTracking()
            .Include(a => a.Pages)
            .FirstOrDefaultAsync(a => a.Id == query.Id && a.OwnerId == userId, cancellationToken);

        return asset is null ? MediaErrors.NotFound : asset.ToDto(mapping, storage);
    }
}
