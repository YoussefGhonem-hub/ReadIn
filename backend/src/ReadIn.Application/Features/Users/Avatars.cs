using System.Globalization;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Users;

/// <summary>
/// Avatar renditions (SPEC F14, ADR 0011): square WebP variants of an upload with purpose <c>avatar</c>.
/// <c>Users.AvatarUrl</c> stores the <see cref="StoredWidth"/> variant, the one every <c>AuthorDto</c> and
/// <c>UserSummaryDto</c> serves; the profile adds every size from the upload's <see cref="MediaAsset"/> row.
/// </summary>
public static class Avatars
{
    public const int StoredWidth = 256;

    /// <summary>
    /// The rendition that fills a <paramref name="width"/> px slot: the smallest variant at least that wide, else the
    /// largest (a small upload is never upscaled, so it may have no 256 or 512 variant).
    /// </summary>
    public static MediaVariant ForSlot(IReadOnlyList<MediaVariant> variants, int width) =>
        variants.Where(v => v.Width >= width).MinBy(v => v.Width) ?? variants.MaxBy(v => v.Width)!;

    /// <summary>
    /// <c>{ "64": url, "128": url, "256": url, "512": url }</c>, every key always present so clients can index it;
    /// null without variants (no avatar, or an external URL such as a Google photo).
    /// </summary>
    public static IReadOnlyDictionary<string, string>? Slots(IReadOnlyList<MediaVariant> variants, IFileStorage storage) =>
        variants.Count == 0
            ? null
            : UploadPurpose.Avatar.Sizes.ToDictionary(
                size => size.ToString(CultureInfo.InvariantCulture),
                size => storage.GetPublicUrl(ForSlot(variants, size).Path));

    /// <summary>True for an image the user uploaded with purpose <c>avatar</c> (what <c>avatarAssetId</c> must name).</summary>
    public static bool IsUsableBy(this MediaAsset asset, Guid userId) =>
        asset.OwnerId == userId && asset.Kind == MediaKind.Image && asset.Purpose == MediaPurpose.Avatar && asset.IsReady &&
        asset.Variants.Count > 0;

    /// <summary>
    /// The variants behind a stored avatar path, from the owner's upload row; empty for external URLs and for old
    /// avatars whose row is gone. Uses the <c>MediaAssets(OwnerId, …)</c> index.
    /// </summary>
    public static async Task<IReadOnlyList<MediaVariant>> LoadVariantsAsync(
        this IAppDbContext db, Guid ownerId, string? storedAvatar, CancellationToken cancellationToken)
    {
        if (!UploadPath.TryParse(storedAvatar, out var path) || path.Purpose != UploadPurpose.Avatar) return [];

        var variants = await db.MediaAssets.AsNoTracking()
            .Where(a => a.OwnerId == ownerId && a.Kind == MediaKind.Image && a.Purpose == MediaPurpose.Avatar &&
                        a.OriginalPath != null && a.OriginalPath.Contains(path.Id))
            .Select(a => a.Variants)
            .FirstOrDefaultAsync(cancellationToken);
        return variants ?? [];
    }
}
