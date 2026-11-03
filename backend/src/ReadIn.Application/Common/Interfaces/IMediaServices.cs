using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Common.Interfaces;

/// <summary>What the upload request learns about a PDF before accepting it (ADR 0011).</summary>
public sealed record PdfInfo(int PageCount, string? Title);

/// <summary>Opens a PDF without rendering it: rejects encrypted and corrupted files and counts the pages.</summary>
public interface IPdfInspector
{
    /// <returns><see cref="MediaErrors.PdfEncrypted"/>, <see cref="MediaErrors.PdfCorrupted"/> or the page count.</returns>
    Result<PdfInfo> Inspect(byte[] pdf);
}

/// <summary>Absolute URLs of API endpoints that DTOs link to, e.g. a document's download URL.</summary>
public interface IApiUrls
{
    /// <param name="path">Path below <c>/api/v1</c>, e.g. <c>/documents/{id}/download</c>.</param>
    string Absolute(string path);
}

/// <summary>Queues the background rendering of an uploaded PDF (never done in the request).</summary>
public interface IMediaJobScheduler
{
    Task EnqueueDocumentAsync(Guid assetId, CancellationToken cancellationToken);
}

/// <summary>
/// Pushes processing progress to the uploader in real time (Firebase RTDB <c>/live/users/{uid}/media/{assetId}</c>).
/// Best effort: clients also poll <c>GET /uploads/{id}</c>, so a failed signal is only logged.
/// </summary>
public interface IMediaStatusNotifier
{
    Task NotifyAsync(MediaAsset asset, CancellationToken cancellationToken);
}
