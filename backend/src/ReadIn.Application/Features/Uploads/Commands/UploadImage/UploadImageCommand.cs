using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Uploads.Commands.UploadImage;

/// <summary>
/// POST /uploads — stores an image as WebP under <c>/uploads</c> (SPEC §24, ADR 0010). <paramref name="Length"/> is the
/// declared size and only allows an early rejection; the handler enforces the limit on the bytes actually read.
/// </summary>
[Authenticated]
public sealed record UploadImageCommand(string Purpose, Stream Content, long Length) : ICommand<Result<UploadedImageDto>>;
