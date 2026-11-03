using System.Globalization;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Media;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

internal sealed class MediaAssetConfiguration : IEntityTypeConfiguration<MediaAsset>
{
    public void Configure(EntityTypeBuilder<MediaAsset> builder)
    {
        builder.ToTable("MediaAssets", t => t.HasCheckConstraint("CK_MediaAssets_Variants_IsJson", "ISJSON([Variants]) = 1"));
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Kind).HasConversion<string>().HasMaxLength(20);
        builder.Property(a => a.Purpose).HasConversion<string>().HasMaxLength(20);
        builder.Property(a => a.Status).HasConversion<string>().HasMaxLength(20);
        builder.Property(a => a.FailureReason).HasMaxLength(100);
        builder.Property(a => a.OriginalPath).HasMaxLength(300);
        builder.Property(a => a.BlurHash).HasMaxLength(100);
        // Up to MediaAsset.MaxTitleLength (5000) characters, more than nvarchar(n) holds (4000): nvarchar(max), checked by the domain.
        builder.Property(a => a.Title).HasColumnType("nvarchar(max)").UseCollation(AppDbContext.SearchCollation);
        builder.Property(a => a.ExtractedText).HasColumnType("nvarchar(max)").UseCollation(AppDbContext.SearchCollation);

        builder.Property(a => a.Variants)
            .HasColumnType("nvarchar(max)")
            .HasConversion(VariantsJson.Converter, VariantsJson.Comparer)
            .IsRequired();

        builder.Ignore(a => a.IsReady);

        // Optional: account deletion unlinks the assets of the articles that stay and deletes the rest (SPEC §9.6).
        builder.HasOne<User>().WithMany().HasForeignKey(a => a.OwnerId).OnDelete(DeleteBehavior.Restrict);
        builder.HasMany(a => a.Pages).WithOne().HasForeignKey(p => p.AssetId).OnDelete(DeleteBehavior.Cascade);

        // Quotas (uploads per day, bytes per user) and the orphan cleanup.
        builder.HasIndex(a => new { a.OwnerId, a.CreatedAt });
        builder.HasIndex(a => a.CreatedAt);
    }
}

internal sealed class MediaAssetPageConfiguration : IEntityTypeConfiguration<MediaAssetPage>
{
    public void Configure(EntityTypeBuilder<MediaAssetPage> builder)
    {
        builder.ToTable("MediaAssetPages");
        builder.HasKey(p => new { p.AssetId, p.PageNo });
        builder.Property(p => p.ThumbPath).HasMaxLength(300).IsRequired();
        builder.Property(p => p.ViewPath).HasMaxLength(300).IsRequired();
        builder.Property(p => p.BlurHash).HasMaxLength(100).IsRequired();
    }
}

internal sealed class ArticleAttachmentConfiguration : IEntityTypeConfiguration<ArticleAttachment>
{
    public void Configure(EntityTypeBuilder<ArticleAttachment> builder)
    {
        builder.ToTable("ArticleAttachments");
        builder.HasKey(a => new { a.ArticleId, a.MediaAssetId });
        // Up to 5000 characters each (Article.MaxCaptionLength / MaxAltTextLength): nvarchar(max), checked by the domain.
        builder.Property(a => a.Caption).HasColumnType("nvarchar(max)");
        builder.Property(a => a.AltText).HasColumnType("nvarchar(max)");

        // An asset belongs to at most one article; it can't be deleted while attached.
        builder.HasOne(a => a.MediaAsset).WithMany().HasForeignKey(a => a.MediaAssetId).OnDelete(DeleteBehavior.Restrict);
        builder.HasIndex(a => a.MediaAssetId).IsUnique();
    }
}

/// <summary><c>Variants</c> column: <c>{"320": {"height": 240, "path": "/uploads/…_320.webp", "bytes": 12345}, …}</c>.</summary>
internal static class VariantsJson
{
    private sealed record Entry(int Height, string Path, long Bytes);

    private static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web);

    public static readonly ValueConverter<IReadOnlyList<MediaVariant>, string> Converter = new(
        variants => Serialize(variants),
        json => Deserialize(json));

    public static readonly ValueComparer<IReadOnlyList<MediaVariant>> Comparer = new(
        (a, b) => a!.SequenceEqual(b!),
        variants => variants.Aggregate(0, (hash, v) => HashCode.Combine(hash, v)),
        variants => variants.ToList());

    private static string Serialize(IReadOnlyList<MediaVariant> variants) => JsonSerializer.Serialize(
        variants.ToDictionary(v => v.Width.ToString(CultureInfo.InvariantCulture), v => new Entry(v.Height, v.Path, v.Bytes)),
        Options);

    private static List<MediaVariant> Deserialize(string json) =>
        [.. (JsonSerializer.Deserialize<Dictionary<string, Entry>>(json, Options) ?? [])
            .Select(e => new MediaVariant(int.Parse(e.Key, CultureInfo.InvariantCulture), e.Value.Height, e.Value.Path, e.Value.Bytes))
            .OrderBy(v => v.Width)];
}
