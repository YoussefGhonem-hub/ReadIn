using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

/// <summary>
/// Highlights (SPEC F30, §16.2). Deleted with the user (UserId cascade, so account deletion needs nothing else) or the
/// article (ArticleId cascade); Articles.AuthorId → Users is Restrict, so they are not reached by two cascade paths.
/// </summary>
internal sealed class ArticleHighlightConfiguration : IEntityTypeConfiguration<ArticleHighlight>
{
    public void Configure(EntityTypeBuilder<ArticleHighlight> builder)
    {
        builder.ToTable("ArticleHighlights", t => t.HasCheckConstraint(
            "CK_ArticleHighlights_Range",
            $"[StartOffset] >= 0 AND [EndOffset] > [StartOffset] AND [EndOffset] - [StartOffset] <= {ArticleHighlight.MaxLength}"));
        builder.HasKey(h => h.Id);

        builder.Property(h => h.Language).HasMaxLength(5).IsUnicode(false).IsRequired();
        // Exact comparison: the same range means the same block id and the same text, code point for code point.
        builder.Property(h => h.BlockId).HasMaxLength(ArticleHighlight.MaxBlockIdLength).IsUnicode(false)
            .UseCollation(AppDbContext.OrdinalCollation).IsRequired();
        builder.Property(h => h.Text).HasMaxLength(ArticleHighlight.MaxLength)
            .UseCollation(AppDbContext.OrdinalCollation).IsRequired();

        // One row per range per user (a double tap can't make two); also the reader's "mine", the per-article limit and
        // the Saved → Highlights groups (newest per article version).
        builder.HasIndex(h => new { h.UserId, h.ArticleId, h.Language, h.BlockId, h.StartOffset, h.EndOffset })
            .IsUnique()
            .IncludeProperties(h => h.CreatedAt);
        // Popular ranges: everyone's highlights on one version, grouped by range, and the viewer's muted writers' share.
        builder.HasIndex(h => new { h.ArticleId, h.Language, h.BlockId, h.StartOffset, h.EndOffset })
            .IncludeProperties(h => h.UserId);

        builder.HasOne<User>().WithMany().HasForeignKey(h => h.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Article>().WithMany().HasForeignKey(h => h.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}
