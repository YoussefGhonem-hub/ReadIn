using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Uploads.Commands.UploadImage;

/// <summary>
/// POST /uploads/images — stores an image as responsive WebP variants under <c>/uploads</c> and records it as a ready
/// <see cref="Domain.Media.MediaAsset"/> (SPEC §24, ADR 0010, ADR 0011). <paramref name="Length"/> is the declared size
/// and only allows an early rejection; the handler enforces the limit on the bytes actually read.
/// </summary>
[Authenticated]
public sealed record UploadImageCommand(string Purpose, Stream Content, long Length) : ICommand<Result<MediaAssetDto>>;
