using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

// Reports and the moderation log (SPEC F22, §16.2). Deleting a user removes the reports they filed (ReporterId cascade).
// ModerationActions has no foreign keys: TargetUserId and ModeratorId would be a second cascade path from Users, which
// SQL Server refuses; account deletion nulls them instead.

internal sealed class ReportConfiguration : IEntityTypeConfiguration<Report>
{
    public void Configure(EntityTypeBuilder<Report> builder)
    {
        builder.ToTable("Reports");
        builder.HasKey(r => r.Id);
        builder.Property(r => r.TargetType).HasConversion<string>().HasMaxLength(20);
        builder.Property(r => r.Reason).HasConversion<string>().HasMaxLength(20);
        builder.Property(r => r.Status).HasConversion<string>().HasMaxLength(20);
        builder.Property(r => r.Details).HasMaxLength(Report.MaxDetailsLength);

        // One report per user and target; reporting again changes nothing.
        builder.HasIndex(r => new { r.ReporterId, r.TargetType, r.TargetId }).IsUnique();
        // The F22 queue: reports of one status, grouped by target.
        builder.HasIndex(r => new { r.Status, r.TargetType, r.TargetId });
        builder.HasOne<User>().WithMany().HasForeignKey(r => r.ReporterId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class ModerationActionConfiguration : IEntityTypeConfiguration<ModerationAction>
{
    public void Configure(EntityTypeBuilder<ModerationAction> builder)
    {
        builder.ToTable("ModerationActions");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Action).HasMaxLength(32).IsUnicode(false).IsRequired();
        builder.Property(a => a.TargetType).HasConversion<string>().HasMaxLength(20).IsUnicode(false);
        builder.Property(a => a.TargetLabel).HasMaxLength(ModerationAction.MaxLabelLength);
        builder.Property(a => a.Note).HasMaxLength(ModerationAction.MaxNoteLength);
        builder.Property(a => a.NoticeKind).HasMaxLength(20).IsUnicode(false);
        builder.Ignore(a => a.IsNotice);

        // A case's history, a user's actions, a moderator's actions (the log filters).
        builder.HasIndex(a => new { a.TargetType, a.TargetId, a.CreatedAt });
        builder.HasIndex(a => new { a.TargetUserId, a.CreatedAt });
        builder.HasIndex(a => new { a.ModeratorId, a.CreatedAt });
        // GET /me/moderation-notices: the user's unacknowledged notices.
        builder.HasIndex(a => new { a.TargetUserId, a.AcknowledgedAt }, "IX_ModerationActions_Notices")
            .HasFilter("[NoticeKind] IS NOT NULL");
    }
}
