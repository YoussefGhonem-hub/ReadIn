using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Devotions;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

/// <summary>
/// Personal du'as (SPEC F38, §16.2): private to the account that wrote them, listed oldest first (the UserId + CreatedAt
/// index), and deleted with the account (UserId cascade, so account deletion needs nothing else, §9.6).
/// </summary>
internal sealed class PersonalDuaConfiguration : IEntityTypeConfiguration<PersonalDua>
{
    public void Configure(EntityTypeBuilder<PersonalDua> builder)
    {
        builder.ToTable("PersonalDuas");
        builder.HasKey(d => d.Id);
        builder.Property(d => d.Title).HasMaxLength(PersonalDua.MaxTitleLength);
        builder.Property(d => d.Text).HasMaxLength(PersonalDua.MaxTextLength).IsRequired();
        builder.HasIndex(d => new { d.UserId, d.CreatedAt });
        builder.HasOne<User>().WithMany().HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}
