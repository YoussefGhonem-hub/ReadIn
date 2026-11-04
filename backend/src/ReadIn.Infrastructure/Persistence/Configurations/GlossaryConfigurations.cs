using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Glossary;

namespace ReadIn.Infrastructure.Persistence.Configurations;

internal sealed class GlossaryTermConfiguration : IEntityTypeConfiguration<GlossaryTerm>
{
    public void Configure(EntityTypeBuilder<GlossaryTerm> builder)
    {
        builder.ToTable("GlossaryTerms");
        builder.HasKey(t => t.Id);
        builder.Property(t => t.Slug).HasMaxLength(GlossaryTerm.SlugMaxLength).IsRequired();
        builder.HasIndex(t => t.Slug).IsUnique();
        builder.Property(t => t.TermEn).HasMaxLength(GlossaryTerm.TermMaxLength).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.HasIndex(t => t.TermEn);
        builder.Property(t => t.DefinitionEn).HasMaxLength(GlossaryTerm.DefinitionMaxLength).IsRequired();
        builder.Property(t => t.ExplanationAr).HasMaxLength(GlossaryTerm.DefinitionMaxLength).IsRequired();
    }
}

internal sealed class ArticleTermConfiguration : IEntityTypeConfiguration<ArticleTerm>
{
    public void Configure(EntityTypeBuilder<ArticleTerm> builder)
    {
        builder.ToTable("ArticleTerms");
        builder.HasKey(t => new { t.ArticleId, t.TermId });
        builder.HasIndex(t => t.TermId);
        builder.HasOne<Article>().WithMany().HasForeignKey(t => t.ArticleId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<GlossaryTerm>().WithMany().HasForeignKey(t => t.TermId).OnDelete(DeleteBehavior.Cascade);
    }
}
