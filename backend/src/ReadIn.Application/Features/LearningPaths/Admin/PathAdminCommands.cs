using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Learning;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.LearningPaths.Admin;

// Path admin (SPEC F09: "Paths are created by Admins"). Backend only until the F23 Admin Console; editorial paths
// (content/taxonomy.yaml) are managed in the content repo and are read-only here.

/// <summary>GET /admin/paths — every path, unpublished included, in editorial order.</summary>
[Authenticated]
[RequirePermission(Permissions.Paths.Manage)]
public sealed record GetAdminPathsQuery : IQuery<Result<IReadOnlyList<AdminPathDto>>>;

/// <summary>Body of POST /admin/paths and PUT /admin/paths/{id}.</summary>
public sealed record UpsertPathRequest(
    string Slug,
    Guid FieldId,
    string TitleAr,
    string TitleEn,
    string? DescriptionAr,
    string? DescriptionEn,
    int SortOrder,
    bool IsPublished);

public sealed record CreatedPath(Guid Id, string Slug);

/// <summary>POST /admin/paths — a new (admin) path, unpublished until it has items.</summary>
[Authenticated]
[RequirePermission(Permissions.Paths.Manage)]
public sealed record CreatePathCommand(UpsertPathRequest Path) : ICommand<Result<CreatedPath>>;

/// <summary>PUT /admin/paths/{id} — edit an admin path; publishing needs at least one item.</summary>
[Authenticated]
[RequirePermission(Permissions.Paths.Manage)]
public sealed record UpdatePathCommand(Guid Id, UpsertPathRequest Path) : ICommand<Result>;

/// <summary>PUT /admin/paths/{id}/items — the path's articles in order (1–100 different published articles).</summary>
[Authenticated]
[RequirePermission(Permissions.Paths.Manage)]
public sealed record SetPathItemsCommand(Guid Id, IReadOnlyList<Guid> ArticleIds) : ICommand<Result>;

/// <summary>DELETE /admin/paths/{id} — an admin path and its enrollments.</summary>
[Authenticated]
[RequirePermission(Permissions.Paths.Manage)]
public sealed record DeletePathCommand(Guid Id) : ICommand<Result>;

internal sealed class UpsertPathRequestValidator : AbstractValidator<UpsertPathRequest>
{
    public UpsertPathRequestValidator()
    {
        RuleFor(p => p.Slug).NotEmpty().Length(3, 100).Matches("^[a-z0-9]+(-[a-z0-9]+)*$").WithErrorCode("validation.slug");
        RuleFor(p => p.FieldId).NotEmpty();
        RuleFor(p => p.TitleAr).NotEmpty().MaximumLength(200);
        RuleFor(p => p.TitleEn).NotEmpty().MaximumLength(200);
        RuleFor(p => p.DescriptionAr).MaximumLength(500);
        RuleFor(p => p.DescriptionEn).MaximumLength(500);
        RuleFor(p => p.SortOrder).GreaterThanOrEqualTo(0);
    }
}

internal sealed class CreatePathCommandValidator : AbstractValidator<CreatePathCommand>
{
    public CreatePathCommandValidator() => RuleFor(c => c.Path).NotNull().SetValidator(new UpsertPathRequestValidator());
}

internal sealed class UpdatePathCommandValidator : AbstractValidator<UpdatePathCommand>
{
    public UpdatePathCommandValidator() => RuleFor(c => c.Path).NotNull().SetValidator(new UpsertPathRequestValidator());
}

internal sealed class GetAdminPathsQueryHandler(IAppDbContext db) : IQueryHandler<GetAdminPathsQuery, Result<IReadOnlyList<AdminPathDto>>>
{
    public async ValueTask<Result<IReadOnlyList<AdminPathDto>>> Handle(GetAdminPathsQuery query, CancellationToken ct)
    {
        var paths = await db.LearningPaths.AsNoTracking()
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.Slug)
            .Select(p => new AdminPathDto(
                p.Id, p.Slug, p.FieldId, p.TitleAr, p.TitleEn, p.DescriptionAr, p.DescriptionEn, p.SortOrder,
                p.IsPublished, p.IsEditorial,
                p.Items.OrderBy(i => i.Order).Select(i => i.ArticleId).ToList(),
                db.PathEnrollments.Count(e => e.PathId == p.Id)))
            .ToListAsync(ct);
        return paths;
    }
}

internal sealed class CreatePathCommandHandler(IAppDbContext db) : ICommandHandler<CreatePathCommand, Result<CreatedPath>>
{
    public async ValueTask<Result<CreatedPath>> Handle(CreatePathCommand command, CancellationToken ct)
    {
        var request = command.Path;
        if (await db.CheckPathAsync(request, pathId: null, ct) is { } error) return error;

        var path = new LearningPath(request.Slug, request.FieldId, request.TitleAr.Trim(), request.TitleEn.Trim(), request.SortOrder);
        path.Update(request.FieldId, request.TitleAr.Trim(), request.TitleEn.Trim(), PathAdmin.Trimmed(request.DescriptionAr), PathAdmin.Trimmed(request.DescriptionEn), request.SortOrder);
        if (request.IsPublished && path.Publish() is { IsFailure: true } publish) return publish.Error;

        db.LearningPaths.Add(path);
        await db.SaveChangesAsync(ct);
        return new CreatedPath(path.Id, path.Slug);
    }
}

internal sealed class UpdatePathCommandHandler(IAppDbContext db) : ICommandHandler<UpdatePathCommand, Result>
{
    public async ValueTask<Result> Handle(UpdatePathCommand command, CancellationToken ct)
    {
        var path = await db.LearningPaths.Include(p => p.Items).FirstOrDefaultAsync(p => p.Id == command.Id, ct);
        if (path is null) return LearningPathErrors.NotFound;
        if (path.IsEditorial) return LearningPathErrors.Editorial;

        var request = command.Path;
        if (await db.CheckPathAsync(request, path.Id, ct) is { } error) return error;

        path.ChangeSlug(request.Slug);
        path.Update(request.FieldId, request.TitleAr.Trim(), request.TitleEn.Trim(), PathAdmin.Trimmed(request.DescriptionAr), PathAdmin.Trimmed(request.DescriptionEn), request.SortOrder);
        if (request.IsPublished)
        {
            if (path.Publish() is { IsFailure: true } publish) return publish;
        }
        else
        {
            path.Unpublish();
        }

        await db.SaveChangesAsync(ct);
        return Result.Success();
    }
}

internal sealed class SetPathItemsCommandHandler(IAppDbContext db) : ICommandHandler<SetPathItemsCommand, Result>
{
    public async ValueTask<Result> Handle(SetPathItemsCommand command, CancellationToken ct)
    {
        var path = await db.LearningPaths.Include(p => p.Items).FirstOrDefaultAsync(p => p.Id == command.Id, ct);
        if (path is null) return LearningPathErrors.NotFound;
        if (path.IsEditorial) return LearningPathErrors.Editorial;

        var ids = command.ArticleIds ?? [];
        if (ids.Count is 0 or > LearningPath.MaxItems || ids.Distinct().Count() != ids.Count) return LearningPathErrors.ItemsInvalid;
        var visible = await db.Articles.AsNoTracking().Visible().CountAsync(a => ids.Contains(a.Id), ct);
        if (visible != ids.Count) return LearningPathErrors.ItemsInvalid;

        path.SetItemsInOrder(ids);
        await db.SaveChangesAsync(ct);
        return Result.Success();
    }
}

internal sealed class DeletePathCommandHandler(IAppDbContext db) : ICommandHandler<DeletePathCommand, Result>
{
    public async ValueTask<Result> Handle(DeletePathCommand command, CancellationToken ct)
    {
        var path = await db.LearningPaths.FirstOrDefaultAsync(p => p.Id == command.Id, ct);
        if (path is null) return Result.Success(); // idempotent
        if (path.IsEditorial) return LearningPathErrors.Editorial;

        db.LearningPaths.Remove(path); // items and enrollments cascade
        await db.SaveChangesAsync(ct);
        return Result.Success();
    }
}

internal static class PathAdmin
{
    /// <summary>The field exists and no other path uses the slug.</summary>
    public static async Task<Error?> CheckPathAsync(this IAppDbContext db, UpsertPathRequest request, Guid? pathId, CancellationToken ct)
    {
        if (!await db.Fields.AsNoTracking().AnyAsync(f => f.Id == request.FieldId, ct)) return TaxonomyErrors.FieldNotFound;
        if (await db.LearningPaths.AsNoTracking().AnyAsync(p => p.Slug == request.Slug && p.Id != pathId, ct)) return LearningPathErrors.SlugTaken;
        return null;
    }

    public static string? Trimmed(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
