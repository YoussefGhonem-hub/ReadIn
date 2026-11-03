using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #5 (all environments): the official "ReadIn" account's avatar is the platform logo
/// (<c>content/assets/readin-avatar.png</c>), processed by the normal image pipeline into the square avatar variants
/// (64/128/256/512 WebP + BlurHash, ADR 0011). Re-runs when the logo file changes; the old avatar files are released.
/// </summary>
internal sealed partial class OfficialAccountAvatarSeeder(
    AppDbContext db,
    ContentRepository content,
    IImageProcessor images,
    IFileStorage storage,
    UploadCleanup uploads,
    TimeProvider clock,
    ILogger<OfficialAccountAvatarSeeder> logger) : ISeeder
{
    /// <summary>The variant stored as the avatar URL; clients derive the other widths from it.</summary>
    private const int StoredWidth = 256;

    public string Name => "official-account-avatar";
    public int Order => 5;
    public int Version => 1;

    private string LogoPath => Path.Combine(content.Root, "assets", "readin-avatar.png");

    public bool AppliesTo(IHostEnvironment environment) => true;

    public async Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        File.Exists(LogoPath) ? Convert.ToHexString(SHA256.HashData(await File.ReadAllBytesAsync(LogoPath, cancellationToken))) : "missing";

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(LogoPath))
        {
            LogLogoMissing(logger, LogoPath);
            return false;
        }

        var account = await db.Users.IgnoreQueryFilters().FirstOrDefaultAsync(u => u.Id == SystemUsers.EditorialId, cancellationToken);
        if (account is null) return false; // the system-accounts seeder hasn't run yet

        var bytes = await File.ReadAllBytesAsync(LogoPath, cancellationToken);
        if (SeedImages.IsStored(account.AvatarUrl, bytes)) return true;

        var imported = await SeedImages.ImportAsync(
            images, storage, db, account.Id, UploadPurpose.Avatar, bytes, clock.GetUtcNow().UtcDateTime, cancellationToken);
        if (imported.IsFailure)
        {
            LogLogoRejected(logger, imported.Error.Code);
            return false;
        }

        var previous = account.AvatarUrl;
        var avatar = SeedImages.Pick(imported.Value, StoredWidth);
        var updated = account.UpdateProfile(account.DisplayName, account.Username, account.Bio, avatar, account.Links);
        if (updated.IsFailure) return false;

        await db.SaveChangesAsync(cancellationToken);
        if (previous != avatar) await uploads.ReleaseAsync(previous, cancellationToken);
        return true;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "The official account's logo {Path} is missing; its avatar is not seeded")]
    private static partial void LogLogoMissing(ILogger logger, string path);

    [LoggerMessage(Level = LogLevel.Error, Message = "The official account's logo was rejected by the image pipeline ({Code})")]
    private static partial void LogLogoRejected(ILogger logger, string code);
}
