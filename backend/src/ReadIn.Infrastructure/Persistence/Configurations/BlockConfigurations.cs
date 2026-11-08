using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

/// <summary>
/// Blocks (SPEC F36, §16.2): one row per blocker and blocked person, checked both ways. BlockerId cascades with the
/// account; BlockedId can't (a second cascade path from Users, which SQL Server refuses), so account deletion deletes
/// those rows itself (§9.6).
/// </summary>
internal sealed class UserBlockConfiguration : IEntityTypeConfiguration<UserBlock>
{
    public void Configure(EntityTypeBuilder<UserBlock> builder)
    {
        builder.ToTable("UserBlocks");
        builder.HasKey(b => b.Id);
        builder.HasIndex(b => new { b.BlockerId, b.BlockedId }).IsUnique();
        // The reverse check: who blocked the viewer.
        builder.HasIndex(b => new { b.BlockedId, b.BlockerId });
        builder.HasOne<User>().WithMany().HasForeignKey(b => b.BlockerId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(b => b.BlockedId).OnDelete(DeleteBehavior.NoAction);
    }
}
