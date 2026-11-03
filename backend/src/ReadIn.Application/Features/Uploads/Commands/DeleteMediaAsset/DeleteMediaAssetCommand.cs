using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads.Commands.DeleteMediaAsset;

/// <summary>DELETE /uploads/{id}: the owner removes an upload that is not attached to an article, with all its files.</summary>
[Authenticated]
public sealed record DeleteMediaAssetCommand(Guid Id) : ICommand<Result>;
