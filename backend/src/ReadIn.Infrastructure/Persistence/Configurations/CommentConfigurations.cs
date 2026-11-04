using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

// Comments (SPEC F11, §16.2). Deleting an article removes its comments, replies, likes and mentions through the
// ArticleId/CommentId cascades. Deleting a user keeps their comments as "Deleted user" (AuthorId SET NULL, as the
// account-deletion page promises) and removes their likes, mentions and reports. ParentId and HiddenById have no
// foreign key: a second path from Articles or Users to Comments would be refused by SQL Server (multiple cascade paths),
// and replies always share their parent's ArticleId, so they go together.

internal sealed class CommentConfiguration : IEntityTypeConfiguration<Comment>
{
    public void Configure(EntityTypeBuilder<Comment> builder)
    {
        builder.ToTable("Comments");
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Body).HasMaxLength(Comment.MaxBodyLength).IsRequired();
        builder.Ignore(c => c.IsReply);
        builder.Ignore(c => c.IsHidden);
        builder.Ignore(c => c.IsVisible);

        // SPEC §16.3: a thread page, top-level comments (ParentId null) or the replies of one comment.
        builder.HasIndex(c => new { c.ArticleId, c.ParentId, c.CreatedAt });
        // Per-user limits: comments on one article in the last hour, and the same text in the last 10 minutes.
        builder.HasIndex(c => new { c.AuthorId, c.CreatedAt });
        builder.HasIndex(c => c.ParentId);
        // One pinned comment per article (SPEC F11).
        builder.HasIndex(c => c.ArticleId, "IX_Comments_ArticleId_Pinned").IsUnique().HasFilter("[IsPinned] = 1");

        builder.HasOne(c => c.Author).WithMany().HasForeignKey(c => c.AuthorId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne<Article>().WithMany().HasForeignKey(c => c.ArticleId).OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(c => c.Mentions).WithOne().HasForeignKey(m => m.CommentId).OnDelete(DeleteBehavior.Cascade);
        builder.Navigation(c => c.Mentions).UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

internal sealed class CommentMentionConfiguration : IEntityTypeConfiguration<CommentMention>
{
    public void Configure(EntityTypeBuilder<CommentMention> builder)
    {
        builder.ToTable("CommentMentions");
        builder.HasKey(m => m.Id);
        builder.HasIndex(m => new { m.CommentId, m.UserId }).IsUnique();
        builder.HasOne(m => m.User).WithMany().HasForeignKey(m => m.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class CommentLikeConfiguration : IEntityTypeConfiguration<CommentLike>
{
    public void Configure(EntityTypeBuilder<CommentLike> builder)
    {
        builder.ToTable("CommentLikes");
        builder.HasKey(l => l.Id);
        builder.HasIndex(l => new { l.CommentId, l.UserId }).IsUnique();
        builder.HasIndex(l => l.UserId);
        builder.HasOne<User>().WithMany().HasForeignKey(l => l.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Comment>().WithMany().HasForeignKey(l => l.CommentId).OnDelete(DeleteBehavior.Cascade);
    }
}
