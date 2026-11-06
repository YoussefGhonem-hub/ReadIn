using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Persistence.Outbox;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Infrastructure.Persistence.Configurations;

internal sealed class ReadingProgressConfiguration : IEntityTypeConfiguration<ReadingProgress>
{
    public void Configure(EntityTypeBuilder<ReadingProgress> builder)
    {
        builder.ToTable("ReadingProgress");
        builder.HasKey(r => r.Id);
        builder.HasIndex(r => new { r.UserId, r.ArticleId }).IsUnique();
        // The For you ranking counts an article's completed reads in a time window (FeedRanking); also serves the FK.
        builder.HasIndex(r => new { r.ArticleId, r.CompletedAt });
        builder.Property(r => r.Language).HasMaxLength(5).IsRequired();
        builder.Property(r => r.LastPosition).HasMaxLength(100);
        builder.Ignore(r => r.IsCompleted);
        builder.HasOne<User>().WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Article>().WithMany().HasForeignKey(r => r.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class DailyPickConfiguration : IEntityTypeConfiguration<DailyPick>
{
    public void Configure(EntityTypeBuilder<DailyPick> builder)
    {
        builder.ToTable("DailyPicks");
        builder.HasKey(p => p.Id);
        builder.HasIndex(p => new { p.UserId, p.Date }).IsUnique();
        builder.HasOne<User>().WithMany().HasForeignKey(p => p.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Article>().WithMany().HasForeignKey(p => p.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class OutboxMessageConfiguration : IEntityTypeConfiguration<OutboxMessage>
{
    public void Configure(EntityTypeBuilder<OutboxMessage> builder)
    {
        builder.ToTable("OutboxMessages");
        builder.HasKey(m => m.Id);
        builder.Property(m => m.Type).HasMaxLength(300).IsRequired();
        builder.Property(m => m.Content).HasColumnType("nvarchar(max)").IsRequired();
        builder.Property(m => m.Error).HasMaxLength(2000);
        builder.HasIndex(m => m.OccurredAt).HasFilter("[ProcessedAt] IS NULL");
    }
}

internal sealed class SeedHistoryConfiguration : IEntityTypeConfiguration<SeedHistory>
{
    public void Configure(EntityTypeBuilder<SeedHistory> builder)
    {
        builder.ToTable("SeedHistory");
        builder.HasKey(s => s.Name);
        builder.Property(s => s.Name).HasMaxLength(100);
        builder.Property(s => s.Checksum).HasMaxLength(64).IsRequired();
    }
}
