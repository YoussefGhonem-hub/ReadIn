using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

internal sealed class ReadingDayConfiguration : IEntityTypeConfiguration<ReadingDay>
{
    public void Configure(EntityTypeBuilder<ReadingDay> builder)
    {
        builder.ToTable("ReadingDays");
        builder.HasKey(d => d.Id);
        builder.HasIndex(d => new { d.UserId, d.Date }).IsUnique();
        builder.Ignore(d => d.CountsForStreak);
        builder.HasOne<User>().WithMany().HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class UserStatsConfiguration : IEntityTypeConfiguration<UserStats>
{
    public void Configure(EntityTypeBuilder<UserStats> builder)
    {
        builder.ToTable("UserStats");
        builder.HasKey(s => s.UserId);
        builder.Property(s => s.UserId).ValueGeneratedNever();
        builder.Ignore(s => s.History);
        builder.HasOne<User>().WithOne().HasForeignKey<UserStats>(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}
