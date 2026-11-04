using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

// Notifications (SPEC F17, §21.1). Deleting a user removes their notifications and settings (cascade). The article,
// comment and actor links have no cascade (SQL Server refuses a second path from Users): whatever hard-deletes articles,
// comments or accounts deletes the notifications and actor rows that point at them first (AccountEraser).

internal sealed class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> builder)
    {
        builder.ToTable("Notifications");
        builder.HasKey(n => n.Id);
        builder.Property(n => n.Type).HasMaxLength(Notification.MaxTypeLength).IsUnicode(false).IsRequired();
        builder.Property(n => n.GroupKey).HasMaxLength(Notification.MaxKeyLength).IsUnicode(false);
        builder.Property(n => n.DedupeKey).HasMaxLength(Notification.MaxKeyLength).IsUnicode(false);
        builder.Property(n => n.Data);
        builder.Property(n => n.PushStatus).HasConversion<byte>();
        builder.Ignore(n => n.IsRead);

        builder.HasOne<User>().WithMany().HasForeignKey(n => n.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Article>().WithMany().HasForeignKey(n => n.ArticleId).OnDelete(DeleteBehavior.NoAction);
        builder.HasOne<Comment>().WithMany().HasForeignKey(n => n.CommentId).OnDelete(DeleteBehavior.NoAction);
        builder.HasMany(n => n.Actors).WithOne().HasForeignKey(a => a.NotificationId).OnDelete(DeleteBehavior.Cascade);

        // A retried outbox event never writes the same entry twice.
        builder.HasIndex(n => new { n.UserId, n.DedupeKey }).IsUnique().HasFilter("[DedupeKey] IS NOT NULL");
        // The center, newest activity first (keyset paging), the badge count and aggregation.
        builder.HasIndex(n => new { n.UserId, n.UpdatedAt, n.Id }, "IX_Notifications_List").IsDescending(false, true, true);
        // The push job: pending pushes that are due.
        builder.HasIndex(n => new { n.PushStatus, n.PushAfter }, "IX_Notifications_PushDue")
            .HasFilter($"[PushStatus] = {(byte)NotificationPushStatus.Pending}");
    }
}

internal sealed class NotificationActorConfiguration : IEntityTypeConfiguration<NotificationActor>
{
    public void Configure(EntityTypeBuilder<NotificationActor> builder)
    {
        builder.ToTable("NotificationActors");
        // Distinct actors per notification; a redelivered event finds its row.
        builder.HasKey(a => new { a.NotificationId, a.ActorId });
        builder.HasOne<User>().WithMany().HasForeignKey(a => a.ActorId).OnDelete(DeleteBehavior.NoAction);
    }
}

internal sealed class UserNotificationSettingConfiguration : IEntityTypeConfiguration<UserNotificationSetting>
{
    public void Configure(EntityTypeBuilder<UserNotificationSetting> builder)
    {
        builder.ToTable("UserNotificationSettings");
        builder.HasKey(s => new { s.UserId, s.Type });
        builder.Property(s => s.Type).HasMaxLength(Notification.MaxTypeLength).IsUnicode(false);
        builder.Property(s => s.Mode).HasConversion<byte>();
        builder.HasOne<User>().WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}
