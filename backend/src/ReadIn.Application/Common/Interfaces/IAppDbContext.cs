using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Authorization;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Media;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Common.Interfaces;

public interface IAppDbContext
{
    DbSet<User> Users { get; }
    DbSet<Role> Roles { get; }
    DbSet<Permission> Permissions { get; }
    DbSet<ReviewerField> ReviewerFields { get; }

    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<PasswordResetToken> PasswordResetTokens { get; }
    DbSet<RecoveryAttempt> RecoveryAttempts { get; }
    DbSet<AuditLog> AuditLogs { get; }

    DbSet<Field> Fields { get; }
    DbSet<Topic> Topics { get; }
    DbSet<Tag> Tags { get; }

    DbSet<Article> Articles { get; }
    DbSet<ArticleTranslation> ArticleTranslations { get; }
    DbSet<ArticleAttachment> ArticleAttachments { get; }

    DbSet<MediaAsset> MediaAssets { get; }

    DbSet<ReadingProgress> ReadingProgress { get; }
    DbSet<DailyPick> DailyPicks { get; }
    DbSet<LearningPath> LearningPaths { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
