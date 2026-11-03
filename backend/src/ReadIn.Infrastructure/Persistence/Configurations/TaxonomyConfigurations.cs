using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Taxonomy;

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
        builder.Property(t => t.Slug).HasMaxLength(64).IsRequired();
        builder.HasIndex(t => t.Slug).IsUnique();
        builder.Property(t => t.Name).HasMaxLength(64).UseCollation(AppDbContext.SearchCollation).IsRequired();
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
