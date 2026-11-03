using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Authorization;
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

    DbSet<Field> Fields { get; }
    DbSet<Topic> Topics { get; }
    DbSet<Tag> Tags { get; }

    DbSet<Article> Articles { get; }
    DbSet<ArticleTranslation> ArticleTranslations { get; }
    DbSet<ArticleAttachment> ArticleAttachments { get; }

    DbSet<MediaAsset> MediaAssets { get; }

    DbSet<ReadingProgress> ReadingProgress { get; }
    DbSet<DailyPick> DailyPicks { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
