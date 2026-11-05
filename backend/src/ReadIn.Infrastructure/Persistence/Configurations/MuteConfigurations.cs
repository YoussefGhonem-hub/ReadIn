using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

// Mute and "show less" (SPEC F28, §16.2). Deleting a user removes what they muted and marked through the UserId/MuterId
// cascades; the mutes *of* the user (MutedUserId) have no cascade (a second path from Users is refused by SQL Server),
// so account deletion removes them explicitly (SPEC §9.6). Deleting an article removes its marks (ArticleId cascade).

internal sealed class UserMuteConfiguration : IEntityTypeConfiguration<UserMute>
{
    public void Configure(EntityTypeBuilder<UserMute> builder)
    {
        builder.ToTable("UserMutes");
        builder.HasKey(m => m.Id);

        // One per pair; also the "is X muted by the viewer" lookup of every list and notification.
        builder.HasIndex(m => new { m.MuterId, m.MutedUserId }).IsUnique();

        builder.HasOne<User>().WithMany().HasForeignKey(m => m.MuterId).OnDelete(DeleteBehavior.Cascade);
        // Also indexes MutedUserId (by convention), which account deletion uses.
        builder.HasOne(m => m.MutedUser).WithMany().HasForeignKey(m => m.MutedUserId).OnDelete(DeleteBehavior.NoAction);
    }
}

internal sealed class ContentMuteConfiguration : IEntityTypeConfiguration<ContentMute>
{
    public void Configure(EntityTypeBuilder<ContentMute> builder)
    {
        builder.ToTable("ContentMutes");
        builder.HasKey(m => m.Id);
        builder.Property(m => m.TargetType).HasConversion<string>().HasMaxLength(16);

        builder.HasIndex(m => new { m.UserId, m.TargetType, m.TargetId }).IsUnique();

        // TargetId names a field or a topic: no foreign key.
        builder.HasOne<User>().WithMany().HasForeignKey(m => m.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class ArticleFeedbackConfiguration : IEntityTypeConfiguration<ArticleFeedback>
{
    public void Configure(EntityTypeBuilder<ArticleFeedback> builder)
    {
        builder.ToTable("ArticleFeedback");
        builder.HasKey(f => f.Id);
        builder.Property(f => f.Type).HasConversion<string>().HasMaxLength(16);

        builder.HasIndex(f => new { f.UserId, f.ArticleId }).IsUnique();

        // Articles.AuthorId → Users is Restrict, so these two cascades are not two paths from Users.
        builder.HasOne<User>().WithMany().HasForeignKey(f => f.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Article>().WithMany().HasForeignKey(f => f.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}
