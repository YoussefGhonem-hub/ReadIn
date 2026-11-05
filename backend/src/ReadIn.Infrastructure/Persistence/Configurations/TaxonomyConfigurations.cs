using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

internal sealed class FieldConfiguration : IEntityTypeConfiguration<Field>
{
    public void Configure(EntityTypeBuilder<Field> builder)
    {
        builder.ToTable("Fields");
        builder.HasKey(f => f.Id);
        builder.Property(f => f.Slug).HasMaxLength(64).IsRequired();
        builder.HasIndex(f => f.Slug).IsUnique();
        builder.Property(f => f.NameAr).HasMaxLength(100).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(f => f.NameEn).HasMaxLength(100).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(f => f.Icon).HasMaxLength(50);
        builder.Property(f => f.Color).HasMaxLength(50);
        builder.HasMany(f => f.Topics).WithOne().HasForeignKey(t => t.FieldId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class TopicConfiguration : IEntityTypeConfiguration<Topic>
{
    public void Configure(EntityTypeBuilder<Topic> builder)
    {
        builder.ToTable("Topics");
        builder.HasKey(t => t.Id);
        builder.Property(t => t.Slug).HasMaxLength(64).IsRequired();
        builder.HasIndex(t => new { t.FieldId, t.Slug }).IsUnique();
        builder.Property(t => t.NameAr).HasMaxLength(100).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(t => t.NameEn).HasMaxLength(100).UseCollation(AppDbContext.SearchCollation).IsRequired();
    }
}

internal sealed class TagConfiguration : IEntityTypeConfiguration<Tag>
{
    public void Configure(EntityTypeBuilder<Tag> builder)
    {
        builder.ToTable("Tags");
        builder.HasKey(t => t.Id);
        builder.Property(t => t.Slug).HasMaxLength(Tag.SlugColumnLength).IsRequired();
        builder.HasIndex(t => t.Slug).IsUnique();
        builder.Property(t => t.Name).HasMaxLength(Tag.NameColumnLength).UseCollation(AppDbContext.SearchCollation).IsRequired();
        // Compared exactly (ordinal), like TagNames.Normalize in C#: one tag per normalized name (SPEC F32).
        builder.Property(t => t.NormalizedName).HasMaxLength(Tag.NameColumnLength).UseCollation(AppDbContext.OrdinalCollation).IsRequired();
        builder.HasIndex(t => t.NormalizedName).IsUnique();
        // No foreign key: account deletion nulls it (SPEC §9.6). Indexed for the new-tags-per-day limit.
        builder.HasIndex(t => new { t.CreatedById, t.CreatedAt });
    }
}

/// <summary>
/// F31 writer categories: unique slug and normalized name per writer; they go with the account (cascade), and deleting one
/// leaves its articles without a category (<c>Articles.WriterCategoryId</c> SET NULL).
/// </summary>
internal sealed class WriterCategoryConfiguration : IEntityTypeConfiguration<WriterCategory>
{
    public void Configure(EntityTypeBuilder<WriterCategory> builder)
    {
        builder.ToTable("WriterCategories");
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Name).HasMaxLength(WriterCategory.NameColumnLength).UseCollation(AppDbContext.SearchCollation).IsRequired();
        // Compared exactly (ordinal), like TagNames.Normalize in C#: one name per writer ignoring case and letter forms.
        builder.Property(c => c.NormalizedName).HasMaxLength(WriterCategory.NameColumnLength).UseCollation(AppDbContext.OrdinalCollation)
            .IsRequired();
        builder.Property(c => c.Slug).HasMaxLength(WriterCategory.SlugColumnLength).UseCollation(AppDbContext.OrdinalCollation).IsRequired();
        builder.HasIndex(c => new { c.UserId, c.Slug }).IsUnique();
        builder.HasIndex(c => new { c.UserId, c.NormalizedName }).IsUnique();
        builder.HasOne<User>().WithMany().HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class LearningPathConfiguration : IEntityTypeConfiguration<LearningPath>
{
    public void Configure(EntityTypeBuilder<LearningPath> builder)
    {
        builder.ToTable("LearningPaths");
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Slug).HasMaxLength(100).IsRequired();
        builder.HasIndex(p => p.Slug).IsUnique();
        builder.Property(p => p.TitleAr).HasMaxLength(200).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(p => p.TitleEn).HasMaxLength(200).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(p => p.DescriptionAr).HasMaxLength(500);
        builder.Property(p => p.DescriptionEn).HasMaxLength(500);
        builder.HasOne<Field>().WithMany().HasForeignKey(p => p.FieldId).OnDelete(DeleteBehavior.Restrict);
        builder.HasMany(p => p.Items).WithOne().HasForeignKey(i => i.PathId).OnDelete(DeleteBehavior.Cascade);
    }
}

/// <summary>F09 enrollments: one per user and path; they go with the account (hard delete) and with the path.</summary>
internal sealed class PathEnrollmentConfiguration : IEntityTypeConfiguration<PathEnrollment>
{
    public void Configure(EntityTypeBuilder<PathEnrollment> builder)
    {
        builder.ToTable("PathEnrollments");
        builder.HasKey(e => e.Id);
        builder.HasIndex(e => new { e.UserId, e.PathId }).IsUnique();
        builder.HasIndex(e => e.PathId);
        builder.Ignore(e => e.IsCompleted);
        builder.HasOne<User>().WithMany().HasForeignKey(e => e.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<LearningPath>().WithMany().HasForeignKey(e => e.PathId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class LearningPathItemConfiguration : IEntityTypeConfiguration<LearningPathItem>
{
    public void Configure(EntityTypeBuilder<LearningPathItem> builder)
    {
        builder.ToTable("LearningPathItems");
        builder.HasKey(i => i.Id);
        builder.HasIndex(i => new { i.PathId, i.ArticleId }).IsUnique();
        builder.HasIndex(i => i.ArticleId);
        builder.HasOne<Article>().WithMany().HasForeignKey(i => i.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}
