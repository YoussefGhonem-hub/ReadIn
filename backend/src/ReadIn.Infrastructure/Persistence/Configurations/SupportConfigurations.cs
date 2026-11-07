using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Support;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

// Help & support tickets (SPEC F35, §16.2). A ticket goes with its member's account (UserId cascade), and its messages and
// screenshots with it; the files are deleted after the commit. ClosedById and SupportMessages.AuthorId have no foreign key
// (a second cascade path from Users): account deletion nulls them on other members' tickets.

internal sealed class SupportTicketConfiguration : IEntityTypeConfiguration<SupportTicket>
{
    public void Configure(EntityTypeBuilder<SupportTicket> builder)
    {
        builder.ToTable("SupportTickets");
        builder.HasKey(t => t.Id);
        builder.Property(t => t.Number).UseIdentityColumn().ValueGeneratedOnAdd();
        builder.Property(t => t.Number).Metadata.SetAfterSaveBehavior(Microsoft.EntityFrameworkCore.Metadata.PropertySaveBehavior.Ignore);
        builder.HasIndex(t => t.Number).IsUnique();
        builder.Property(t => t.Category).HasMaxLength(16).IsUnicode(false).IsRequired();
        builder.Property(t => t.Subject).HasMaxLength(SupportTicket.MaxSubjectLength).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(t => t.Status).HasConversion<byte>();
        builder.Property(t => t.ClosedBy).HasConversion<byte?>();
        builder.Property(t => t.Platform).HasMaxLength(8).IsUnicode(false);
        builder.Property(t => t.OsVersion).HasMaxLength(SupportDevice.MaxOsVersionLength);
        builder.Property(t => t.AppVersion).HasMaxLength(SupportDevice.MaxAppVersionLength);
        builder.Property(t => t.Language).HasMaxLength(2).IsUnicode(false);
        builder.Property(t => t.Screen).HasMaxLength(SupportDevice.MaxScreenLength);
        builder.Ignore(t => t.IsClosed);

        // SPEC §16.3: the admin queue (Open, waiting longest first) and My tickets (and the 5-a-day limit).
        builder.HasIndex(t => new { t.Status, t.LastUserMessageAt });
        builder.HasIndex(t => new { t.UserId, t.CreatedAt });
        // The auto-close and retention jobs.
        builder.HasIndex(t => new { t.Status, t.LastAdminReplyAt });
        builder.HasIndex(t => new { t.Status, t.ClosedAt });

        builder.HasOne<User>().WithMany().HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(t => t.Messages).WithOne().HasForeignKey(m => m.TicketId).OnDelete(DeleteBehavior.Cascade);
        builder.Navigation(t => t.Messages).UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

internal sealed class SupportMessageConfiguration : IEntityTypeConfiguration<SupportMessage>
{
    public void Configure(EntityTypeBuilder<SupportMessage> builder)
    {
        builder.ToTable("SupportMessages");
        builder.HasKey(m => m.Id);
        builder.Property(m => m.Body).HasMaxLength(SupportTicket.MaxMessageLength).IsRequired();
        builder.HasIndex(m => new { m.TicketId, m.CreatedAt });
        // An admin's replies and notes on other members' tickets (account deletion nulls them).
        builder.HasIndex(m => m.AuthorId);
        builder.HasMany(m => m.Attachments).WithOne().HasForeignKey(a => a.MessageId).OnDelete(DeleteBehavior.Cascade);
        builder.Navigation(m => m.Attachments).UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

internal sealed class SupportAttachmentConfiguration : IEntityTypeConfiguration<SupportAttachment>
{
    public void Configure(EntityTypeBuilder<SupportAttachment> builder)
    {
        builder.ToTable("SupportAttachments");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.FilePath).HasMaxLength(SupportAttachment.MaxPathLength).IsUnicode(false).IsRequired();
        builder.Property(a => a.ContentType).HasMaxLength(16).IsUnicode(false).IsRequired();
        builder.Property(a => a.Position).HasConversion<byte>();
        builder.HasIndex(a => a.MessageId);
    }
}
