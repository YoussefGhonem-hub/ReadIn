using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Articles.Pdf;

/// <summary>
/// Reads an article's pictures for its PDF (SPEC F33, §24) from the uploads folder, by the stored path: the cover from
/// its 1200 variant and content images from their 1600 one (the widest the image has up to that). Only our own uploads
/// (<c>/uploads/…</c>, <c>rdoc-asset://uploads/…</c>) are read; anything else is never fetched.
/// </summary>
public sealed class ArticlePdfImages(IAppDbContext db, IFileStorage storage)
{
    public const int ContentWidth = 1600;
    public const int CoverWidth = 1200;
    private const string MediaType = "image/webp";

    /// <summary>The <c>src</c> of every image block in <paramref name="content"/> that is one of our uploads.</summary>
    public static IReadOnlyList<string> UploadSources(JsonElement content)
    {
        var sources = new List<string>();
        Collect(content, sources);
        return [.. sources.Distinct(StringComparer.Ordinal)];

        static void Collect(JsonElement node, List<string> sources)
        {
            switch (node.ValueKind)
            {
                case JsonValueKind.Object:
                    if (node.TryGetProperty("type", out var type) && type.ValueKind == JsonValueKind.String && type.GetString() == "image"
                        && node.TryGetProperty("src", out var src) && src.ValueKind == JsonValueKind.String
                        && ToUploadPath(src.GetString()) is not null)
                        sources.Add(src.GetString()!);
                    foreach (var property in node.EnumerateObject()) Collect(property.Value, sources);
                    break;
                case JsonValueKind.Array:
                    foreach (var item in node.EnumerateArray()) Collect(item, sources);
                    break;
            }
        }
    }

    /// <summary>
    /// The widest variant up to <paramref name="targetWidth"/> of the upload <paramref name="stored"/> names, or null when
    /// it isn't one of our uploads or its file is gone.
    /// </summary>
    public async Task<ArticlePdfImage?> LoadAsync(Guid ownerId, string? stored, int targetWidth, CancellationToken cancellationToken)
    {
        if (ToUploadPath(stored) is not { } path) return null;

        // Every variant of an upload shares its folder and id; the asset row knows which widths exist.
        var prefix = path.Value[..(path.Value.LastIndexOf('_') + 1)];
        var variants = await db.MediaAssets.AsNoTracking()
            .Where(m => m.OwnerId == ownerId && m.Kind == MediaKind.Image && m.OriginalPath != null && m.OriginalPath.StartsWith(prefix))
            .Select(m => m.Variants)
            .FirstOrDefaultAsync(cancellationToken);
        var chosen = variants?.Where(v => v.Width <= targetWidth).OrderByDescending(v => v.Width).FirstOrDefault()
                     ?? variants?.OrderBy(v => v.Width).FirstOrDefault();

        return await ReadAsync(chosen?.Path ?? path.Value, cancellationToken)
               ?? (chosen is null ? null : await ReadAsync(path.Value, cancellationToken));
    }

    /// <summary>One stored variant by its exact path (attachments know theirs).</summary>
    public async Task<ArticlePdfImage?> ReadAsync(string relativePath, CancellationToken cancellationToken)
    {
        try
        {
            await using var stream = await storage.OpenReadAsync(relativePath, cancellationToken);
            using var buffer = new MemoryStream();
            await stream.CopyToAsync(buffer, cancellationToken);
            return new ArticlePdfImage(buffer.ToArray(), MediaType);
        }
        catch (Exception e) when (e is FileNotFoundException or DirectoryNotFoundException or ArgumentException)
        {
            return null;
        }
    }

    private static UploadPath? ToUploadPath(string? stored)
    {
        if (string.IsNullOrEmpty(stored)) return null;
        var value = stored.StartsWith(UploadUrls.AssetScheme, StringComparison.Ordinal) ? "/" + stored[UploadUrls.AssetScheme.Length..] : stored;
        return UploadPath.TryParse(value, out var path) ? path : null;
    }
}
