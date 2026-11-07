using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Admin;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

/// <summary>When an account was last seen (SPEC F23): one row per account, off the <c>Users</c> row and its row version.</summary>
internal sealed class UserPresenceConfiguration : IEntityTypeConfiguration<UserPresence>
{
    public void Configure(EntityTypeBuilder<UserPresence> builder)
    {
        builder.ToTable("UserPresence");
        builder.HasKey(p => p.UserId);
        builder.Property(p => p.UserId).ValueGeneratedNever();
        builder.HasIndex(p => p.LastSeenAt);
        builder.HasOne<User>().WithOne().HasForeignKey<UserPresence>(p => p.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

/// <summary>Old spellings and merged tags that lead to a tag (SPEC F23, F32).</summary>
internal sealed class TagAliasConfiguration : IEntityTypeConfiguration<TagAlias>
{
    public void Configure(EntityTypeBuilder<TagAlias> builder)
    {
        builder.ToTable("TagAliases");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Name).HasMaxLength(Tag.NameColumnLength).UseCollation(AppDbContext.SearchCollation).IsRequired();
        // Compared exactly, like Tags.NormalizedName.
        builder.Property(a => a.NormalizedName).HasMaxLength(Tag.NameColumnLength).UseCollation(AppDbContext.OrdinalCollation).IsRequired();
        builder.HasIndex(a => a.NormalizedName).IsUnique();
        // Like Tags.Slug: a merged tag's slug keeps opening the tag it went into.
        builder.Property(a => a.Slug).HasMaxLength(Tag.SlugColumnLength);
        builder.HasIndex(a => a.Slug).IsUnique().HasFilter("[Slug] IS NOT NULL");
        builder.HasIndex(a => a.TagId);
        builder.HasOne<Tag>().WithMany().HasForeignKey(a => a.TagId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class SearchMissConfiguration : IEntityTypeConfiguration<SearchMiss>
{
    public void Configure(EntityTypeBuilder<SearchMiss> builder)
    {
        builder.ToTable("SearchMisses");
        builder.HasKey(m => m.Id);
        builder.Property(m => m.Language).HasMaxLength(2).IsUnicode(false).IsRequired();
        // Normalized in C# (SPEC §22), so compared exactly.
        builder.Property(m => m.Query).HasMaxLength(SearchMiss.MaxQueryLength).UseCollation(AppDbContext.OrdinalCollation).IsRequired();
        builder.HasIndex(m => new { m.Date, m.Language, m.Query }).IsUnique();
    }
}

internal sealed class AnnouncementConfiguration : IEntityTypeConfiguration<Announcement>
{
    public void Configure(EntityTypeBuilder<Announcement> builder)
    {
        builder.ToTable("Announcements");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.TitleAr).HasMaxLength(Announcement.MaxTitleLength).IsRequired();
        builder.Property(a => a.TitleEn).HasMaxLength(Announcement.MaxTitleLength).IsRequired();
        builder.Property(a => a.BodyAr).HasMaxLength(Announcement.MaxBodyLength).IsRequired();
        builder.Property(a => a.BodyEn).HasMaxLength(Announcement.MaxBodyLength).IsRequired();
        builder.Property(a => a.LinkType).HasMaxLength(8).IsUnicode(false);
        builder.Property(a => a.AudienceType).HasMaxLength(8).IsUnicode(false).IsRequired();
        builder.Property(a => a.Language).HasMaxLength(5).IsUnicode(false);
        // One a day (SPEC F23): two sends at once can't both pass.
        builder.HasIndex(a => a.LocalDate).IsUnique();
        builder.HasIndex(a => a.CreatedAt);
    }
}

internal sealed class JobRunConfiguration : IEntityTypeConfiguration<JobRun>
{
    public void Configure(EntityTypeBuilder<JobRun> builder)
    {
        builder.ToTable("JobRuns");
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Job).HasMaxLength(64).IsUnicode(false).IsRequired();
        builder.Property(r => r.Error).HasMaxLength(JobRun.MaxErrorLength);
        builder.HasIndex(r => new { r.Job, r.StartedAt });
        builder.HasIndex(r => r.StartedAt);
    }
}

internal sealed class PushDeliveryStatConfiguration : IEntityTypeConfiguration<PushDeliveryStat>
{
    public void Configure(EntityTypeBuilder<PushDeliveryStat> builder)
    {
        builder.ToTable("PushDeliveryStats");
        builder.HasKey(s => s.Hour);
        builder.Property(s => s.Hour).ValueGeneratedNever();
    }
}
