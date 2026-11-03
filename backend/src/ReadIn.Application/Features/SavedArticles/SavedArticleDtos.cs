using FluentValidation;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.SavedArticles;

/// <summary>Your save and the article's save count right after the change, counted from the rows.</summary>
public sealed record SaveStateDto(bool IsSaved, int SaveCount);

/// <summary>One row of the saved list (SPEC F13): when you saved it and which of your collections hold it.</summary>
public sealed record SavedArticleDto(DateTime SavedAt, IReadOnlyList<Guid> CollectionIds, ArticleCardDto Article);

/// <summary><see cref="ArticleCount"/> counts the articles readers can still open.</summary>
public sealed record CollectionDto(Guid Id, string Name, int ArticleCount, DateTime CreatedAt);

internal static class SavedArticleQueries
{
    public static async Task<SaveStateDto> StateAsync(this IAppDbContext db, Guid userId, Guid articleId, CancellationToken ct) => new(
        await db.SavedArticles.AnyAsync(s => s.UserId == userId && s.ArticleId == articleId, ct),
        await db.SavedArticles.CountAsync(s => s.ArticleId == articleId, ct));

    public static IQueryable<CollectionDto> ToDtos(this IQueryable<Collection> collections, IAppDbContext db) =>
        collections.Select(c => new CollectionDto(
            c.Id,
            c.Name,
            c.Items.Count(i => db.Articles.Any(a => a.Id == i.ArticleId && a.Status == ArticleStatus.Published && a.Field.IsEnabled)),
            c.CreatedAt));

    /// <summary>Your collection, tracked with its entry for <paramref name="articleId"/> if any; null when it isn't yours.</summary>
    public static Task<Collection?> FindOwnCollectionAsync(this IAppDbContext db, Guid collectionId, Guid userId, Guid articleId, CancellationToken ct) =>
        db.Collections
            .Include(c => c.Items.Where(i => i.ArticleId == articleId))
            .FirstOrDefaultAsync(c => c.Id == collectionId && c.UserId == userId, ct);

    /// <summary>Names are unique per user, ignoring case: the column's collation compares them in SQL.</summary>
    public static Task<bool> IsCollectionNameTakenAsync(this IAppDbContext db, Guid userId, string name, Guid? exceptId, CancellationToken ct) =>
        db.Collections.AnyAsync(c => c.UserId == userId && c.Name == name && c.Id != exceptId, ct);
}

internal static class CollectionNameRules
{
    /// <summary>1–60 characters once trimmed (<see cref="Collection.MaxNameLength"/>).</summary>
    public static IRuleBuilderOptions<T, string> CollectionName<T>(this IRuleBuilder<T, string> rule) => rule
        .Must(name => !string.IsNullOrWhiteSpace(name)).WithErrorCode("validation.required")
        .Must(name => name is null || name.Trim().Length <= Collection.MaxNameLength).WithErrorCode("validation.max_length");
}
