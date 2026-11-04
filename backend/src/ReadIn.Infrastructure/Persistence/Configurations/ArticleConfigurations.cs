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
        builder.Property(a => a.SourceLanguage).HasMaxLength(5).IsRequired();
        builder.Property(a => a.CoverUrl).HasMaxLength(2048);
        builder.Property(a => a.VersionBadge).HasMaxLength(30);

        builder.Ignore(a => a.IsPublished);
        builder.Ignore(a => a.CurrentDraftVersion);
        builder.Ignore(a => a.IsHidden);

        // Optional: account deletion unlinks published articles itself, in its one transaction (SPEC §9.6).
        builder.HasOne(a => a.Author).WithMany().HasForeignKey(a => a.AuthorId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(a => a.Field).WithMany().HasForeignKey(a => a.FieldId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(a => a.Topic).WithMany().HasForeignKey(a => a.TopicId).OnDelete(DeleteBehavior.NoAction);

        builder.HasMany(a => a.Translations).WithOne().HasForeignKey(t => t.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(a => a.Tags).WithOne().HasForeignKey(t => t.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(a => a.Sources).WithOne().HasForeignKey(s => s.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(a => a.Draft).WithOne().HasForeignKey<ArticleDraft>(d => d.ArticleId).OnDelete(DeleteBehavior.Cascade);
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
        // The feed card's text (SPEC F34); null until the backfill job fills versions published before it.
        builder.Property(t => t.Excerpt).HasMaxLength(ArticleTranslation.ExcerptMaxLength);
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
            t.HasCheckConstraint("CK_ArticleRevisions_DocumentJson_IsJson", "ISJSON([DocumentJson]) = 1"));
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Title).HasMaxLength(150).IsRequired();
        builder.Property(r => r.Languages).HasMaxLength(20).IsRequired();
        builder.Property(r => r.DocumentJson).HasColumnType("nvarchar(max)").IsRequired();
        builder.HasIndex(r => new { r.ArticleId, r.RevisionNumber }).IsUnique();
        builder.HasOne<Article>().WithMany().HasForeignKey(r => r.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(r => r.CreatedBy).OnDelete(DeleteBehavior.NoAction);
    }
}

/// <summary>The editor's working copy (F05): one row per article, the whole editor document as JSON.</summary>
internal sealed class ArticleDraftConfiguration : IEntityTypeConfiguration<ArticleDraft>
{
    public void Configure(EntityTypeBuilder<ArticleDraft> builder)
    {
        builder.ToTable("ArticleDrafts", t =>
            t.HasCheckConstraint("CK_ArticleDrafts_DocumentJson_IsJson", "ISJSON([DocumentJson]) = 1"));
        builder.HasKey(d => d.ArticleId);
        builder.Property(d => d.DocumentJson).HasColumnType("nvarchar(max)").IsRequired();
        builder.Property(d => d.Version).IsConcurrencyToken();
    }
}
