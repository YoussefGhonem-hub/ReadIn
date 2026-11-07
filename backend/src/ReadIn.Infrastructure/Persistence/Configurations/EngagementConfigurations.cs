using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

// Engagement (SPEC §16.2): reactions, saves, collections and follows. Deleting a user removes their rows through the
// UserId cascades; deleting an article removes its rows through the ArticleId cascades. Articles.AuthorId → Users is
// Restrict (account deletion unlinks the articles that stay), so neither table is reached by two cascade paths.

internal sealed class ReactionConfiguration : IEntityTypeConfiguration<Reaction>
{
    public void Configure(EntityTypeBuilder<Reaction> builder)
    {
        builder.ToTable("Reactions");
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Type).HasConversion<string>().HasMaxLength(20);

        // One reaction per user per article (SPEC F10).
        builder.HasIndex(r => new { r.UserId, r.ArticleId }).IsUnique();
        // SPEC §16.3 Reactions(ArticleId, Type): counts per type, and "who reacted" filtered by type, newest first.
        builder.HasIndex(r => new { r.ArticleId, r.Type, r.ReactedAt }).IsDescending(false, false, true);
        // "Who reacted" across all types, newest first.
        builder.HasIndex(r => new { r.ArticleId, r.ReactedAt }).IsDescending(false, true);
        // F23 dashboard: reactions in a period.
        builder.HasIndex(r => r.ReactedAt);

        builder.HasOne(r => r.User).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Article>().WithMany().HasForeignKey(r => r.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}

/// <summary>Reposts (SPEC F29, §16.2): one per user per article; deleted with the user or the article.</summary>
internal sealed class RepostConfiguration : IEntityTypeConfiguration<Repost>
{
    public void Configure(EntityTypeBuilder<Repost> builder)
    {
        builder.ToTable("Reposts");
        builder.HasKey(r => r.Id);
        // "Repost with your thoughts": plain text, trimmed, null when there is none.
        builder.Property(r => r.Caption).HasMaxLength(Repost.MaxCaptionLength);

        // One repost per user per article.
        builder.HasIndex(r => new { r.UserId, r.ArticleId }).IsUnique();
        // A user's reposts, newest first, with the article: the profile's Reposts tab, and the Following feed's
        // candidates (the reposts of the writers you follow, newest per article) read only this index.
        builder.HasIndex(r => new { r.UserId, r.CreatedAt }).IsDescending(false, true).IncludeProperties(r => r.ArticleId);
        // The repost count, and the per-article reads (the labels of a Following page's cards).
        builder.HasIndex(r => new { r.ArticleId, r.CreatedAt }).IsDescending(false, true);
        // F23 dashboard: reposts in a period.
        builder.HasIndex(r => r.CreatedAt);

        builder.HasOne(r => r.User).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Article>().WithMany().HasForeignKey(r => r.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class SavedArticleConfiguration : IEntityTypeConfiguration<SavedArticle>
{
    public void Configure(EntityTypeBuilder<SavedArticle> builder)
    {
        builder.ToTable("SavedArticles");
        builder.HasKey(s => s.Id);

        builder.HasIndex(s => new { s.UserId, s.ArticleId }).IsUnique();
        // The saved list, newest saved first.
        builder.HasIndex(s => new { s.UserId, s.SavedAt }).IsDescending(false, true);
        // The save count and the For you ranking's saves in a time window (FeedRanking); also serves the FK.
        builder.HasIndex(s => new { s.ArticleId, s.SavedAt });

        builder.HasOne<User>().WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(s => s.Article).WithMany().HasForeignKey(s => s.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class CollectionConfiguration : IEntityTypeConfiguration<Collection>
{
    public void Configure(EntityTypeBuilder<Collection> builder)
    {
        builder.ToTable("Collections");
        builder.HasKey(c => c.Id);

        // Unique per user, ignoring case (and Arabic diacritics), like every searchable name.
        builder.Property(c => c.Name).HasMaxLength(Collection.MaxNameLength).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.HasIndex(c => new { c.UserId, c.Name }).IsUnique();

        builder.HasOne<User>().WithMany().HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(c => c.Items).WithOne().HasForeignKey(i => i.CollectionId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class CollectionItemConfiguration : IEntityTypeConfiguration<CollectionItem>
{
    public void Configure(EntityTypeBuilder<CollectionItem> builder)
    {
        builder.ToTable("CollectionItems");
        builder.HasKey(i => new { i.CollectionId, i.ArticleId });
        builder.HasOne<Article>().WithMany().HasForeignKey(i => i.ArticleId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class UserFollowConfiguration : IEntityTypeConfiguration<UserFollow>
{
    public void Configure(EntityTypeBuilder<UserFollow> builder)
    {
        builder.ToTable("UserFollows");
        builder.HasKey(f => f.Id);

        builder.HasIndex(f => new { f.FollowerId, f.FolloweeId }).IsUnique();
        // SPEC §16.3 UserFollows(FolloweeId): follower counts and the followers list, newest first.
        builder.HasIndex(f => new { f.FolloweeId, f.CreatedAt }).IsDescending(false, true);
        // The following list, newest first.
        builder.HasIndex(f => new { f.FollowerId, f.CreatedAt }).IsDescending(false, true);

        builder.HasOne(f => f.Follower).WithMany().HasForeignKey(f => f.FollowerId).OnDelete(DeleteBehavior.Cascade);
        // NoAction: a second cascade from Users into this table is refused by SQL Server ("multiple cascade paths").
        // Deleting a user removes the rows that follow them explicitly first.
        builder.HasOne(f => f.Followee).WithMany().HasForeignKey(f => f.FolloweeId).OnDelete(DeleteBehavior.NoAction);
    }
}
