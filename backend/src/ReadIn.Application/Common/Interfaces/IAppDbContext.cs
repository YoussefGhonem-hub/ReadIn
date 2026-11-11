using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Admin;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Authorization;
using ReadIn.Domain.Devotions;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Glossary;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Media;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Support;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;
using ReadIn.Domain.Verification;

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
    DbSet<TagAlias> TagAliases { get; }
    DbSet<WriterCategory> WriterCategories { get; }
    DbSet<GlossaryTerm> GlossaryTerms { get; }
    DbSet<ArticleTerm> ArticleTerms { get; }

    DbSet<Article> Articles { get; }
    DbSet<ArticleTranslation> ArticleTranslations { get; }
    DbSet<ArticleAttachment> ArticleAttachments { get; }
    DbSet<ArticleDraft> ArticleDrafts { get; }
    DbSet<ArticleRevision> ArticleRevisions { get; }

    DbSet<MediaAsset> MediaAssets { get; }
    DbSet<MediaUpload> MediaUploads { get; }

    DbSet<ReadingProgress> ReadingProgress { get; }
    DbSet<DailyPick> DailyPicks { get; }
    DbSet<ReadingDay> ReadingDays { get; }
    DbSet<UserStats> UserStats { get; }
    DbSet<LearningPath> LearningPaths { get; }
    DbSet<LearningPathItem> LearningPathItems { get; }
    DbSet<PathEnrollment> PathEnrollments { get; }

    DbSet<Reaction> Reactions { get; }
    DbSet<Repost> Reposts { get; }
    DbSet<SavedArticle> SavedArticles { get; }
    DbSet<Collection> Collections { get; }
    DbSet<CollectionItem> CollectionItems { get; }
    DbSet<UserFollow> UserFollows { get; }
    DbSet<UserMute> UserMutes { get; }
    DbSet<UserBlock> UserBlocks { get; }
    DbSet<ContentMute> ContentMutes { get; }
    DbSet<ArticleFeedback> ArticleFeedback { get; }
    DbSet<ArticleHighlight> ArticleHighlights { get; }
    DbSet<Comment> Comments { get; }
    DbSet<CommentLike> CommentLikes { get; }
    DbSet<Report> Reports { get; }
    DbSet<ModerationAction> ModerationActions { get; }
    DbSet<ContentFilterTerm> ContentFilterTerms { get; }
    DbSet<VerificationRequest> VerificationRequests { get; }

    DbSet<Notification> Notifications { get; }
    DbSet<NotificationActor> NotificationActors { get; }
    DbSet<UserNotificationSetting> UserNotificationSettings { get; }

    // Admin console (SPEC F23)
    DbSet<UserPresence> UserPresence { get; }
    DbSet<SearchMiss> SearchMisses { get; }
    DbSet<Announcement> Announcements { get; }
    DbSet<JobRun> JobRuns { get; }
    DbSet<PushDeliveryStat> PushDeliveryStats { get; }

    // Help & support tickets (SPEC F35)
    DbSet<SupportTicket> SupportTickets { get; }
    DbSet<SupportMessage> SupportMessages { get; }
    DbSet<SupportAttachment> SupportAttachments { get; }

    // Private devotions (SPEC F38)
    DbSet<PersonalDua> PersonalDuas { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    /// <summary>Forgets every tracked entity and unsaved change, e.g. to start a command over after it lost a race.</summary>
    void ClearChangeTracker();

    /// <summary>
    /// Runs <paramref name="work"/> in one transaction that first takes an update lock on user <paramref name="userId"/>'s
    /// row, so two runs for the same user happen one after the other: a per-user limit checked by counting before an
    /// insert then holds under concurrent requests. Plain reads of the row don't wait. A transient failure retries the
    /// whole, from a clean change tracker; the transaction commits when <paramref name="work"/> returns.
    /// </summary>
    Task<T> LockedForUserAsync<T>(Guid userId, Func<CancellationToken, Task<T>> work, CancellationToken cancellationToken);
}
