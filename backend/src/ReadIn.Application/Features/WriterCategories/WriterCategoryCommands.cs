using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.WriterCategories;

/// <summary>POST /me/categories (SPEC F31): a new category, added last. Its slug is made once from the name.</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record CreateWriterCategoryCommand(string? Name) : ICommand<Result<WriterCategoryDto>>;

/// <summary>PATCH /me/categories/{id}: a new name; the slug stays, so links keep working.</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record RenameWriterCategoryCommand(Guid CategoryId, string? Name) : ICommand<Result<WriterCategoryDto>>;

/// <summary>DELETE /me/categories/{id}: its articles stay published and become uncategorized (drafts too).</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record DeleteWriterCategoryCommand(Guid CategoryId) : ICommand<Result>;

/// <summary>
/// PUT /me/categories/order: your categories in the order sent. Ids that aren't your categories are ignored, a repeat
/// counts once, and the categories left out keep their order after the listed ones, so a list from another device never
/// fails.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record ReorderWriterCategoriesCommand(IReadOnlyList<Guid>? CategoryIds) : ICommand<Result<WriterCategoryListDto>>;

/// <summary>
/// PUT /articles/{id}/category: your article (draft or published) goes in that category, or in none. It applies at once:
/// no publish, no revision, and the editor's working copy (and its version) is untouched.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record SetArticleCategoryCommand(Guid ArticleId, Guid? CategoryId) : ICommand<Result>;

internal static class CategoryNameRules
{
    /// <summary>Clean, then 1–40 characters with a letter or a digit: <c>category.name_invalid</c> in <c>errors.name</c>.</summary>
    public static IRuleBuilderOptions<T, string?> CategoryName<T>(this IRuleBuilder<T, string?> rule) => rule
        .Must(name => WriterCategoryNames.IsValid(WriterCategoryNames.Clean(name))).WithErrorCode(WriterCategoryErrors.NameInvalidCode);
}

internal sealed class CreateWriterCategoryCommandValidator : AbstractValidator<CreateWriterCategoryCommand>
{
    public CreateWriterCategoryCommandValidator() => RuleFor(c => c.Name).CategoryName();
}

internal sealed class RenameWriterCategoryCommandValidator : AbstractValidator<RenameWriterCategoryCommand>
{
    public RenameWriterCategoryCommandValidator() => RuleFor(c => c.Name).CategoryName();
}

internal sealed class ReorderWriterCategoriesCommandValidator : AbstractValidator<ReorderWriterCategoriesCommand>
{
    public ReorderWriterCategoriesCommandValidator() => RuleFor(c => c.CategoryIds)
        .NotNull()
        .Must(ids => ids is null || ids.Count <= WriterCategory.MaxPerWriter).WithErrorCode(WriterCategoryErrors.Limit.Code);
}

internal sealed class CreateWriterCategoryCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, WriterCategoryReader reader, ContentFilter.ContentScreening screening, TimeProvider clock)
    : ICommandHandler<CreateWriterCategoryCommand, Result<WriterCategoryDto>>
{
    public async ValueTask<Result<WriterCategoryDto>> Handle(CreateWriterCategoryCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var name = WriterCategoryNames.Clean(command.Name);
        var key = WriterCategoryNames.Normalize(name);
        // F37: a category name is public on the writer's profile; a flag reports the writer.
        var screened = await screening.ScreenAsync([new ContentFilter.ScreenedField("name", name)], cancellationToken);
        if (screened.IsFailure) return screened.Error;

        // Two creates at the same moment (two devices, a double tap) run one after the other, so the count below is
        // never stale and the 50 limit holds.
        var result = await db.LockedForUserAsync<Result<WriterCategoryDto>>(userId, async ct =>
        {
            var existing = await db.WriterCategories.AsNoTracking()
                .Where(c => c.UserId == userId)
                .Select(c => new { c.Slug, c.NormalizedName, c.SortOrder })
                .ToListAsync(ct);
            if (existing.Count >= WriterCategory.MaxPerWriter) return WriterCategoryErrors.Limit;
            if (existing.Any(c => c.NormalizedName == key)) return WriterCategoryErrors.NameTaken;

            var slug = TagNames.UniqueSlug(WriterCategoryNames.SlugBase(name), existing.Select(c => c.Slug).ToHashSet(StringComparer.Ordinal));
            var sortOrder = existing.Count == 0 ? 1 : existing.Max(c => c.SortOrder) + 1;
            var category = new WriterCategory(userId, name, key, slug, sortOrder, clock.GetUtcNow().UtcDateTime);
            db.WriterCategories.Add(category);
            try
            {
                await db.SaveChangesAsync(ct);
            }
            catch (DbUpdateException)
            {
                // A rename on another device took the same name meanwhile (unique index).
                if (await db.WriterCategories.AnyAsync(c => c.UserId == userId && c.NormalizedName == key, ct))
                    return WriterCategoryErrors.NameTaken;
                throw;
            }
            return new WriterCategoryDto(category.Id, category.Slug, category.Name, 0, existing.Count + 1);
        }, cancellationToken);

        if (result.IsSuccess)
        {
            await reader.InvalidateAsync(userId, [], cancellationToken);
            if (screened.Value.Count > 0)
            {
                await screening.FlagAsync(Domain.Moderation.ReportTargetType.User, userId, screened.Value, cancellationToken);
                await db.SaveChangesAsync(cancellationToken);
            }
        }
        return result;
    }
}

internal sealed class RenameWriterCategoryCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, WriterCategoryReader reader, ContentFilter.ContentScreening screening)
    : ICommandHandler<RenameWriterCategoryCommand, Result<WriterCategoryDto>>
{
    public async ValueTask<Result<WriterCategoryDto>> Handle(RenameWriterCategoryCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var category = await db.WriterCategories.FirstOrDefaultAsync(c => c.Id == command.CategoryId, cancellationToken);
        if (category is null) return WriterCategoryErrors.NotFound;
        if (category.UserId != userId) return WriterCategoryErrors.NotOwner;

        var name = WriterCategoryNames.Clean(command.Name);
        var key = WriterCategoryNames.Normalize(name);
        if (await IsTakenAsync(userId, key, category.Id, cancellationToken)) return WriterCategoryErrors.NameTaken;

        if (category.Name != name)
        {
            // F37: the new name is public text; a flag reports the writer.
            var screened = await screening.ScreenAsync([new ContentFilter.ScreenedField("name", name)], cancellationToken);
            if (screened.IsFailure) return screened.Error;
            await screening.FlagAsync(Domain.Moderation.ReportTargetType.User, userId, screened.Value, cancellationToken);
            category.Rename(name, key);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                if (await IsTakenAsync(userId, key, category.Id, cancellationToken)) return WriterCategoryErrors.NameTaken;
                throw;
            }
            // The reader of each of its articles shows the name ("في قسم {name}").
            await reader.InvalidateAsync(userId, await reader.ArticleSlugsAsync(category.Id, cancellationToken), cancellationToken);
        }

        return (await reader.LoadAsync(userId, cancellationToken)).Items.Single(c => c.Id == category.Id);
    }

    private Task<bool> IsTakenAsync(Guid userId, string key, Guid exceptId, CancellationToken ct) =>
        db.WriterCategories.AnyAsync(c => c.UserId == userId && c.NormalizedName == key && c.Id != exceptId, ct);
}

internal sealed class DeleteWriterCategoryCommandHandler(IAppDbContext db, ICurrentUser currentUser, WriterCategoryReader reader)
    : ICommandHandler<DeleteWriterCategoryCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteWriterCategoryCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var category = await db.WriterCategories.FirstOrDefaultAsync(c => c.Id == command.CategoryId, cancellationToken);
        if (category is null) return WriterCategoryErrors.NotFound;
        if (category.UserId != userId) return WriterCategoryErrors.NotOwner;

        var slugs = await reader.ArticleSlugsAsync(category.Id, cancellationToken);
        // Its articles lose the category in the database (Articles.WriterCategoryId ON DELETE SET NULL).
        db.WriterCategories.Remove(category);
        await db.SaveChangesAsync(cancellationToken);
        await reader.InvalidateAsync(userId, slugs, cancellationToken);
        return Result.Success();
    }
}

internal sealed class ReorderWriterCategoriesCommandHandler(IAppDbContext db, ICurrentUser currentUser, WriterCategoryReader reader)
    : ICommandHandler<ReorderWriterCategoriesCommand, Result<WriterCategoryListDto>>
{
    public async ValueTask<Result<WriterCategoryListDto>> Handle(ReorderWriterCategoriesCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var categories = await db.WriterCategories
            .Where(c => c.UserId == userId)
            .OrderBy(c => c.SortOrder).ThenBy(c => c.CreatedAt).ThenBy(c => c.Id)
            .ToListAsync(cancellationToken);

        var byId = categories.ToDictionary(c => c.Id);
        var ordered = command.CategoryIds!.Distinct().Where(byId.ContainsKey).Select(id => byId[id]).ToList();
        ordered.AddRange(categories.Except(ordered));
        for (var position = 0; position < ordered.Count; position++) ordered[position].MoveTo(position + 1);

        await db.SaveChangesAsync(cancellationToken);
        await reader.InvalidateAsync(userId, [], cancellationToken);
        return await reader.LoadAsync(userId, cancellationToken);
    }
}

internal sealed class SetArticleCategoryCommandHandler(IAppDbContext db, ICurrentUser currentUser, WriterCategoryReader reader)
    : ICommandHandler<SetArticleCategoryCommand, Result>
{
    public async ValueTask<Result> Handle(SetArticleCategoryCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var article = await db.Articles.AsNoTracking()
            .Where(a => a.Id == command.ArticleId)
            .Select(a => new { a.AuthorId, a.Slug, a.WriterCategoryId })
            .FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        if (article.AuthorId != userId) return ArticleErrors.NotOwner;

        var categoryId = command.CategoryId;
        if (categoryId is not null)
        {
            var ownerId = await db.WriterCategories.Where(c => c.Id == categoryId).Select(c => (Guid?)c.UserId).FirstOrDefaultAsync(cancellationToken);
            if (ownerId is null) return WriterCategoryErrors.NotFound;
            if (ownerId != userId) return WriterCategoryErrors.NotOwner;
        }
        if (article.WriterCategoryId == categoryId) return Result.Success();

        // One statement, outside the article's concurrency token: the category is not part of the editor's working copy,
        // so an autosave on another device never conflicts with it. A category deleted meanwhile is not found.
        var updated = await db.Articles
            .Where(a => a.Id == command.ArticleId &&
                        (categoryId == null || db.WriterCategories.Any(c => c.Id == categoryId && c.UserId == userId)))
            .ExecuteUpdateAsync(s => s.SetProperty(a => a.WriterCategoryId, categoryId), cancellationToken);
        if (updated == 0) return WriterCategoryErrors.NotFound;

        await reader.InvalidateAsync(userId, [article.Slug], cancellationToken);
        return Result.Success();
    }
}
