using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Queries.GetMediaAsset;

/// <summary>GET /uploads/{id}: the owner's view of an upload; clients poll it every 2 s while it is processing.</summary>
[Authenticated]
public sealed record GetMediaAssetQuery(Guid Id) : IQuery<Result<MediaAssetDto>>;
