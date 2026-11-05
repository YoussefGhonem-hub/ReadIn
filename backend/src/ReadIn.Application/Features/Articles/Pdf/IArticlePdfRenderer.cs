using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Pdf;

/// <summary>
/// Turns an article into a PDF (SPEC F33): RDoc → print HTML → headless Chromium. At most a few builds at a time; a
/// request that waits too long gets <see cref="ArticlePdfErrors.Busy"/>, a build that fails or takes too long
/// <see cref="ArticlePdfErrors.Failed"/>. Nothing is stored.
/// </summary>
public interface IArticlePdfRenderer
{
    Task<Result<byte[]>> RenderAsync(ArticlePdfDocument document, CancellationToken cancellationToken);
}
