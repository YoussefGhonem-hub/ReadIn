using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Authorization;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Glossary;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Media;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;
using ReadIn.Domain.Verification;
using ReadIn.Infrastructure.Persistence.Outbox;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Infrastructure.Persistence;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options), IAppDbContext
{
    /// <summary>Case- and accent-insensitive Arabic collation for searchable text (SPEC §16.1).</summary>
    public const string SearchCollation = "Arabic_100_CI_AI";

    /// <summary>Exact code-point comparison, for keys normalized in C# (e.g. <c>Tags.NormalizedName</c>, SPEC F32).</summary>
    public const string OrdinalCollation = "Latin1_General_100_BIN2";

    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Permission> Permissions => Set<Permission>();

    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
    public DbSet<RecoveryAttempt> RecoveryAttempts => Set<RecoveryAttempt>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    public DbSet<Field> Fields => Set<Field>();
    public DbSet<Topic> Topics => Set<Topic>();
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<WriterCategory> WriterCategories => Set<WriterCategory>();
    public DbSet<GlossaryTerm> GlossaryTerms => Set<GlossaryTerm>();
    public DbSet<ArticleTerm> ArticleTerms => Set<ArticleTerm>();

    public DbSet<Article> Articles => Set<Article>();
    public DbSet<ArticleTranslation> ArticleTranslations => Set<ArticleTranslation>();
    public DbSet<ArticleAttachment> ArticleAttachments => Set<ArticleAttachment>();
    public DbSet<ArticleDraft> ArticleDrafts => Set<ArticleDraft>();
    public DbSet<ArticleRevision> ArticleRevisions => Set<ArticleRevision>();

    public DbSet<MediaAsset> MediaAssets => Set<MediaAsset>();

    public DbSet<ReadingProgress> ReadingProgress => Set<ReadingProgress>();
    public DbSet<DailyPick> DailyPicks => Set<DailyPick>();
    public DbSet<ReadingDay> ReadingDays => Set<ReadingDay>();
    public DbSet<UserStats> UserStats => Set<UserStats>();
    public DbSet<LearningPath> LearningPaths => Set<LearningPath>();
    public DbSet<LearningPathItem> LearningPathItems => Set<LearningPathItem>();
    public DbSet<PathEnrollment> PathEnrollments => Set<PathEnrollment>();

    public DbSet<Reaction> Reactions => Set<Reaction>();
    public DbSet<Repost> Reposts => Set<Repost>();
    public DbSet<SavedArticle> SavedArticles => Set<SavedArticle>();
    public DbSet<Collection> Collections => Set<Collection>();
    public DbSet<CollectionItem> CollectionItems => Set<CollectionItem>();
    public DbSet<UserFollow> UserFollows => Set<UserFollow>();
    public DbSet<UserMute> UserMutes => Set<UserMute>();
    public DbSet<ContentMute> ContentMutes => Set<ContentMute>();
    public DbSet<ArticleFeedback> ArticleFeedback => Set<ArticleFeedback>();
    public DbSet<ArticleHighlight> ArticleHighlights => Set<ArticleHighlight>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<CommentLike> CommentLikes => Set<CommentLike>();
    public DbSet<Report> Reports => Set<Report>();
    public DbSet<ModerationAction> ModerationActions => Set<ModerationAction>();
    public DbSet<VerificationRequest> VerificationRequests => Set<VerificationRequest>();

    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<NotificationActor> NotificationActors => Set<NotificationActor>();
    public DbSet<UserNotificationSetting> UserNotificationSettings => Set<UserNotificationSetting>();

    public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();
    public DbSet<SeedHistory> SeedHistory => Set<SeedHistory>();

    public void ClearChangeTracker() => ChangeTracker.Clear();

    public Task<T> LockedForUserAsync<T>(Guid userId, Func<CancellationToken, Task<T>> work, CancellationToken cancellationToken)
    {
        var attempt = 0;
        return Database.CreateExecutionStrategy().ExecuteAsync(async ct =>
        {
            if (attempt++ > 0) ChangeTracker.Clear(); // a retried attempt starts from a clean slate
            await using var transaction = await Database.BeginTransactionAsync(ct);
            // UPDLOCK is held until the transaction ends; another run for this user waits here, plain reads don't.
            await Database.ExecuteSqlAsync($"SELECT 1 FROM [Users] WITH (UPDLOCK, ROWLOCK) WHERE [Id] = {userId}", ct);
            var result = await work(ct);
            await transaction.CommitAsync(ct);
            return result;
        }, cancellationToken);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
        SqlFunctions.Map(modelBuilder);

        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            var clr = entityType.ClrType;

            // Single Guid keys come from EF Core's sequential GUID generator, which follows SQL Server's
            // uniqueidentifier sort order (ADR 0006). This is the EF default; it is stated here so nobody turns it off.
            if (entityType.FindPrimaryKey()?.Properties is [{ ClrType: var keyType } keyProperty] && keyType == typeof(Guid) && !keyProperty.IsForeignKey())
                keyProperty.ValueGenerated = Microsoft.EntityFrameworkCore.Metadata.ValueGenerated.OnAdd;

            if (typeof(ISoftDeletable).IsAssignableFrom(clr) && entityType.BaseType is null)
            {
                // e => !e.IsDeleted
                var parameter = Expression.Parameter(clr, "e");
                var filter = Expression.Lambda(
                    Expression.Not(Expression.Property(parameter, nameof(ISoftDeletable.IsDeleted))),
                    parameter);
                modelBuilder.Entity(clr).HasQueryFilter(filter);
            }

            if (typeof(IHasRowVersion).IsAssignableFrom(clr))
                modelBuilder.Entity(clr).Property(nameof(IHasRowVersion.RowVersion)).IsRowVersion();

            if (typeof(AggregateRoot).IsAssignableFrom(clr))
                modelBuilder.Entity(clr).Ignore(nameof(AggregateRoot.DomainEvents));
        }
    }

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        configurationBuilder.Properties<decimal>().HavePrecision(18, 4);
        // All timestamps are UTC (SPEC §16.1); reading them back with Kind=Utc makes the API emit "...Z".
        configurationBuilder.Properties<DateTime>().HaveConversion<UtcDateTimeConverter>();
    }
}

internal sealed class UtcDateTimeConverter() : Microsoft.EntityFrameworkCore.Storage.ValueConversion.ValueConverter<DateTime, DateTime>(
    value => value.Kind == DateTimeKind.Local ? value.ToUniversalTime() : value,
    value => DateTime.SpecifyKind(value, DateTimeKind.Utc));
