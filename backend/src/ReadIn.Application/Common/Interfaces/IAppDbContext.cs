using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Authorization;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Glossary;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Media;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Common.Interfaces;

public interface IAppDbContext
{
    DbSet<User> Users { get; }
    DbSet<Role> Roles { get; }
    DbSet<Permission> Permissions { get; }

    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<PasswordResetToken> PasswordResetTokens { get; }
    DbSet<RecoveryAttempt> RecoveryAttempts { get; }
    DbSet<AuditLog> AuditLogs { get; }

    DbSet<Field> Fields { get; }
    DbSet<Topic> Topics { get; }
    DbSet<Tag> Tags { get; }
    DbSet<GlossaryTerm> GlossaryTerms { get; }
    DbSet<ArticleTerm> ArticleTerms { get; }

    DbSet<Article> Articles { get; }
    DbSet<ArticleTranslation> ArticleTranslations { get; }
    DbSet<ArticleAttachment> ArticleAttachments { get; }
    DbSet<ArticleDraft> ArticleDrafts { get; }
    DbSet<ArticleRevision> ArticleRevisions { get; }

    DbSet<MediaAsset> MediaAssets { get; }

    DbSet<ReadingProgress> ReadingProgress { get; }
    DbSet<DailyPick> DailyPicks { get; }
    DbSet<ReadingDay> ReadingDays { get; }
    DbSet<UserStats> UserStats { get; }
    DbSet<LearningPath> LearningPaths { get; }
    DbSet<LearningPathItem> LearningPathItems { get; }
    DbSet<PathEnrollment> PathEnrollments { get; }

    DbSet<Reaction> Reactions { get; }
    DbSet<SavedArticle> SavedArticles { get; }
    DbSet<Collection> Collections { get; }
    DbSet<CollectionItem> CollectionItems { get; }
    DbSet<UserFollow> UserFollows { get; }
    DbSet<Comment> Comments { get; }
    DbSet<CommentLike> CommentLikes { get; }
    DbSet<Report> Reports { get; }
    DbSet<ModerationAction> ModerationActions { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
