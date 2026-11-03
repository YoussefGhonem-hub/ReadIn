using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

internal sealed class ArticleConfiguration : IEntityTypeConfiguration<Article>
{
    public void Configure(EntityTypeBuilder<Article> builder)
    {
        builder.ToTable("Articles");
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Slug).HasMaxLength(100).IsRequired();
        builder.HasIndex(a => a.Slug).IsUnique();

        builder.Property(a => a.Status).HasConversion<string>().HasMaxLength(20);
        builder.Property(a => a.ReviewStatus).HasConversion<string>().HasMaxLength(20);
        builder.Property(a => a.SourceLanguage).HasMaxLength(5).IsRequired();
        builder.Property(a => a.CoverUrl).HasMaxLength(2048);
        builder.Property(a => a.VersionBadge).HasMaxLength(30);

        builder.Ignore(a => a.IsReviewed);
        builder.Ignore(a => a.IsPublished);

        builder.HasOne(a => a.Author).WithMany().HasForeignKey(a => a.AuthorId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(a => a.ReviewedBy).WithMany().HasForeignKey(a => a.ReviewedById).OnDelete(DeleteBehavior.NoAction);
        builder.HasOne(a => a.Field).WithMany().HasForeignKey(a => a.FieldId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(a => a.Topic).WithMany().HasForeignKey(a => a.TopicId).OnDelete(DeleteBehavior.NoAction);

        builder.HasMany(a => a.Translations).WithOne().HasForeignKey(t => t.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(a => a.Tags).WithOne().HasForeignKey(t => t.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(a => a.Sources).WithOne().HasForeignKey(s => s.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(a => a.Revisions).WithOne().HasForeignKey(r => r.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(a => a.Attachments).WithOne().HasForeignKey(x => x.ArticleId).OnDelete(DeleteBehavior.Cascade);

        // SPEC §16.3 key indexes
        builder.HasIndex(a => new { a.Status, a.PublishedAt }).IsDescending(false, true).HasFilter("[IsDeleted] = 0");
        builder.HasIndex(a => new { a.FieldId, a.Status, a.QualityScore }).IsDescending(false, false, true);
        builder.HasIndex(a => a.AuthorId);
    }
}

internal sealed class ArticleTranslationConfiguration : IEntityTypeConfiguration<ArticleTranslation>
{
    public void Configure(EntityTypeBuilder<ArticleTranslation> builder)
    {
        builder.ToTable("ArticleTranslations", t =>
            t.HasCheckConstraint("CK_ArticleTranslations_ContentJson_IsJson", "ISJSON([ContentJson]) = 1"));
        builder.HasKey(t => t.Id);
        builder.HasIndex(t => new { t.ArticleId, t.Language }).IsUnique();

        builder.Property(t => t.Language).HasMaxLength(5).IsRequired();
        builder.Property(t => t.Title).HasMaxLength(150).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(t => t.Subtitle).HasMaxLength(250);
        builder.Property(t => t.Summary).HasMaxLength(2000);
        builder.Property(t => t.ContentJson).HasColumnType("nvarchar(max)").IsRequired();
        builder.Property(t => t.PlainText).HasColumnType("nvarchar(max)").IsRequired();
        builder.Property(t => t.SearchText).HasColumnType("nvarchar(max)")
            .UseCollation(AppDbContext.SearchCollation).IsRequired();
    }
}

internal sealed class ArticleTagConfiguration : IEntityTypeConfiguration<ArticleTag>
{
    public void Configure(EntityTypeBuilder<ArticleTag> builder)
    {
        builder.ToTable("ArticleTags");
        builder.HasKey(t => new { t.ArticleId, t.TagId });
        builder.HasOne(t => t.Tag).WithMany().HasForeignKey(t => t.TagId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class ArticleSourceConfiguration : IEntityTypeConfiguration<ArticleSource>
{
    public void Configure(EntityTypeBuilder<ArticleSource> builder)
    {
        builder.ToTable("ArticleSources");
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Title).HasMaxLength(200).IsRequired();
        builder.Property(s => s.Url).HasMaxLength(2048).IsRequired();
        builder.HasIndex(s => new { s.ArticleId, s.SortOrder });
    }
}

internal sealed class ArticleRevisionConfiguration : IEntityTypeConfiguration<ArticleRevision>
{
    public void Configure(EntityTypeBuilder<ArticleRevision> builder)
    {
        builder.ToTable("ArticleRevisions", t =>
            t.HasCheckConstraint("CK_ArticleRevisions_ContentJson_IsJson", "ISJSON([ContentJson]) = 1"));
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Language).HasMaxLength(5).IsRequired();
        builder.Property(r => r.Title).HasMaxLength(150).IsRequired();
        builder.Property(r => r.Subtitle).HasMaxLength(250);
        builder.Property(r => r.ContentJson).HasColumnType("nvarchar(max)").IsRequired();
        builder.HasIndex(r => new { r.ArticleId, r.RevisionNumber }).IsUnique();
        builder.HasOne<User>().WithMany().HasForeignKey(r => r.CreatedBy).OnDelete(DeleteBehavior.NoAction);
    }
}
