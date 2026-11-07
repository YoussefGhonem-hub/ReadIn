using System.Text.RegularExpressions;
using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Admin.Taxonomy;

// Fields and topics in the admin console (SPEC F23, §18): add, rename in both languages, reorder, disable or enable. The
// first change marks a row customized, and the taxonomy seeder leaves it alone from then on. Nothing is deleted, and slugs
// never change.

/// <summary>POST /admin/fields: a new field, last in the order, customized from the start.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record CreateFieldCommand(
    string? Slug, string? NameAr, string? NameEn, string? Icon, string? Color, bool IsSensitive, bool RequiresSources, bool IsEnabled)
    : ICommand<Result<AdminFieldDto>>;

/// <summary>PUT /admin/fields/{id}: the whole row but the slug. A field keeps the icon or color it has, even one off the lists.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record UpdateFieldCommand(
    Guid Id, string? NameAr, string? NameEn, string? Icon, string? Color, bool IsSensitive, bool RequiresSources, bool IsEnabled)
    : ICommand<Result<AdminFieldDto>>;

/// <summary>PUT /admin/fields/order: every field once, in display order.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record ReorderFieldsCommand(IReadOnlyList<Guid> Ids) : ICommand<Result>;

/// <summary>POST /admin/topics: a new topic, last in its field (a disabled field may get topics too).</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record CreateTopicCommand(Guid FieldId, string? Slug, string? NameAr, string? NameEn, bool IsEnabled)
    : ICommand<Result<AdminTopicDto>>;

/// <summary>PUT /admin/topics/{id}: names and whether it is enabled.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record UpdateTopicCommand(Guid Id, string? NameAr, string? NameEn, bool IsEnabled) : ICommand<Result<AdminTopicDto>>;

/// <summary>PUT /admin/fields/{id}/topics/order: every topic of the field once, in display order.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record ReorderTopicsCommand(Guid FieldId, IReadOnlyList<Guid> Ids) : ICommand<Result>;

internal static partial class TaxonomyRules
{
    public const int MaxNameLength = 100;
    public const int MinSlugLength = 2;
    public const int MaxSlugLength = 64;

    public static bool IsSlug(string? slug) =>
        slug is { Length: >= MinSlugLength and <= MaxSlugLength } && SlugRegex().IsMatch(slug);

    public static string Name(string? name) => name?.Trim() ?? string.Empty;

    /// <summary>Required, ≤ 100 after trimming.</summary>
    public static void Names<T>(AbstractValidator<T> validator, Func<T, string?> nameAr, Func<T, string?> nameEn)
    {
        validator.RuleFor(c => nameAr(c)).NotEmpty().OverridePropertyName("nameAr");
        validator.RuleFor(c => Name(nameAr(c)).Length).LessThanOrEqualTo(MaxNameLength).WithErrorCode("validation.max_length")
            .OverridePropertyName("nameAr");
        validator.RuleFor(c => nameEn(c)).NotEmpty().OverridePropertyName("nameEn");
        validator.RuleFor(c => Name(nameEn(c)).Length).LessThanOrEqualTo(MaxNameLength).WithErrorCode("validation.max_length")
            .OverridePropertyName("nameEn");
    }

    /// <summary>A slug: kebab-case, 2–64 characters (<c>validation.slug</c>), required.</summary>
    public static void Slug<T>(AbstractValidator<T> validator, Func<T, string?> slug)
    {
        validator.RuleFor(c => slug(c)).NotEmpty().OverridePropertyName("slug");
        validator.RuleFor(c => slug(c)).Must(s => string.IsNullOrEmpty(s) || IsSlug(s)).WithErrorCode("validation.slug")
            .OverridePropertyName("slug");
    }

    [GeneratedRegex("^[a-z0-9]+(-[a-z0-9]+)*$", RegexOptions.CultureInvariant)]
    private static partial Regex SlugRegex();
}

internal sealed class CreateFieldCommandValidator : AbstractValidator<CreateFieldCommand>
{
    public CreateFieldCommandValidator()
    {
        TaxonomyRules.Slug(this, c => c.Slug);
        TaxonomyRules.Names(this, c => c.NameAr, c => c.NameEn);
        RuleFor(c => c.Icon).Must(i => i is not null && FieldStyles.Icons.Contains(i)).WithErrorCode(AdminErrors.FieldIconInvalid);
        RuleFor(c => c.Color).Must(c => c is not null && FieldStyles.Colors.Contains(c)).WithErrorCode(AdminErrors.FieldColorInvalid);
    }
}

internal sealed class UpdateFieldCommandValidator : AbstractValidator<UpdateFieldCommand>
{
    public UpdateFieldCommandValidator()
    {
        TaxonomyRules.Names(this, c => c.NameAr, c => c.NameEn);
        RuleFor(c => c.Icon).NotEmpty().WithErrorCode(AdminErrors.FieldIconInvalid);
        RuleFor(c => c.Color).NotEmpty().WithErrorCode(AdminErrors.FieldColorInvalid);
    }
}

internal sealed class CreateTopicCommandValidator : AbstractValidator<CreateTopicCommand>
{
    public CreateTopicCommandValidator()
    {
        TaxonomyRules.Slug(this, c => c.Slug);
        TaxonomyRules.Names(this, c => c.NameAr, c => c.NameEn);
    }
}

internal sealed class UpdateTopicCommandValidator : AbstractValidator<UpdateTopicCommand>
{
    public UpdateTopicCommandValidator() => TaxonomyRules.Names(this, c => c.NameAr, c => c.NameEn);
}

/// <summary>Field and topic names are on cards, the reader, field pages and Explore: every cached page that shows them goes.</summary>
internal sealed class TaxonomyCaches(HybridCache cache)
{
    public ValueTask DropAsync(CancellationToken ct) =>
        cache.RemoveByTagAsync([CacheTags.Taxonomy, CacheTags.Feed, CacheTags.Articles, CacheTags.Tags], ct);
}

internal sealed class CreateFieldCommandHandler(
    IAppDbContext db, AuditTrail audit, AdminClock clock, AdminTaxonomyReader reader, TaxonomyCaches caches)
    : ICommandHandler<CreateFieldCommand, Result<AdminFieldDto>>
{
    public async ValueTask<Result<AdminFieldDto>> Handle(CreateFieldCommand command, CancellationToken cancellationToken)
    {
        var slug = command.Slug!;
        if (await db.Fields.AnyAsync(f => f.Slug == slug, cancellationToken)) return AdminErrors.FieldSlugTaken;

        var last = await db.Fields.MaxAsync(f => (int?)f.SortOrder, cancellationToken) ?? 0;
        var field = Field.CreateByAdmin(slug, TaxonomyRules.Name(command.NameAr), TaxonomyRules.Name(command.NameEn), command.Icon!,
            command.Color!, last + 1, command.IsSensitive, command.RequiresSources, command.IsEnabled, clock.UtcNow);
        db.Fields.Add(field);
        audit.Record(AuditActions.FieldCreated, userId: null, AuditTargets.Field, field.Id, slug);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            return AdminErrors.FieldSlugTaken; // the same slug added at the same time
        }
        await caches.DropAsync(cancellationToken);
        return await reader.FieldAsync(field.Id, cancellationToken);
    }
}

internal sealed class UpdateFieldCommandHandler(
    IAppDbContext db, AuditTrail audit, AdminClock clock, AdminTaxonomyReader reader, TaxonomyCaches caches)
    : ICommandHandler<UpdateFieldCommand, Result<AdminFieldDto>>
{
    public async ValueTask<Result<AdminFieldDto>> Handle(UpdateFieldCommand command, CancellationToken cancellationToken)
    {
        var field = await db.Fields.FirstOrDefaultAsync(f => f.Id == command.Id, cancellationToken);
        if (field is null) return TaxonomyErrors.FieldNotFound;

        // A field keeps the icon or color it has (the taxonomy file may use one off the lists); a new one comes from the lists.
        var problems = new Dictionary<string, string[]>();
        if (command.Icon != field.Icon && !FieldStyles.Icons.Contains(command.Icon!)) problems["icon"] = [AdminErrors.FieldIconInvalid];
        if (command.Color != field.Color && !FieldStyles.Colors.Contains(command.Color!)) problems["color"] = [AdminErrors.FieldColorInvalid];
        if (problems.Count > 0) return Error.Validation(ValidationErrors.Code, "Validation failed.") with { Details = problems };

        var changed = field.EditByAdmin(TaxonomyRules.Name(command.NameAr), TaxonomyRules.Name(command.NameEn), command.Icon!, command.Color!,
            command.IsSensitive, command.RequiresSources, command.IsEnabled, clock.UtcNow);
        if (changed.Count > 0)
        {
            audit.Record(AuditActions.FieldUpdated, userId: null, AuditTargets.Field, field.Id, string.Join(", ", changed));
            await db.SaveChangesAsync(cancellationToken);
            await caches.DropAsync(cancellationToken);
        }
        return await reader.FieldAsync(field.Id, cancellationToken);
    }
}

internal sealed class ReorderFieldsCommandHandler(IAppDbContext db, AuditTrail audit, AdminClock clock, TaxonomyCaches caches)
    : ICommandHandler<ReorderFieldsCommand, Result>
{
    public async ValueTask<Result> Handle(ReorderFieldsCommand command, CancellationToken cancellationToken)
    {
        var fields = await db.Fields.ToListAsync(cancellationToken);
        if (!AdminOrder.IsPermutation(command.Ids, fields.Select(f => f.Id))) return AdminErrors.OrderInvalid;

        var byId = fields.ToDictionary(f => f.Id);
        var now = clock.UtcNow;
        var moved = 0;
        for (var i = 0; i < command.Ids.Count; i++)
            if (byId[command.Ids[i]].MoveTo(i + 1, now)) moved++;
        if (moved == 0) return Result.Success();

        audit.Record(AuditActions.FieldsReordered, userId: null, targetType: null, targetId: null, $"{moved} moved");
        await db.SaveChangesAsync(cancellationToken);
        await caches.DropAsync(cancellationToken);
        return Result.Success();
    }
}

internal sealed class CreateTopicCommandHandler(
    IAppDbContext db, AuditTrail audit, AdminClock clock, AdminTaxonomyReader reader, TaxonomyCaches caches)
    : ICommandHandler<CreateTopicCommand, Result<AdminTopicDto>>
{
    public async ValueTask<Result<AdminTopicDto>> Handle(CreateTopicCommand command, CancellationToken cancellationToken)
    {
        var field = await db.Fields.Include(f => f.Topics).FirstOrDefaultAsync(f => f.Id == command.FieldId, cancellationToken);
        if (field is null) return TaxonomyErrors.FieldNotFound;
        var slug = command.Slug!;
        if (field.Topics.Any(t => string.Equals(t.Slug, slug, StringComparison.OrdinalIgnoreCase))) return AdminErrors.TopicSlugTaken;

        var topic = field.AddTopicByAdmin(slug, TaxonomyRules.Name(command.NameAr), TaxonomyRules.Name(command.NameEn), command.IsEnabled,
            clock.UtcNow);
        db.Topics.Add(topic); // its key now, for the audit entry
        audit.Record(AuditActions.TopicCreated, userId: null, AuditTargets.Topic, topic.Id, $"{field.Slug}/{slug}");
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            return AdminErrors.TopicSlugTaken;
        }
        await caches.DropAsync(cancellationToken);
        return await reader.TopicAsync(topic.Id, cancellationToken);
    }
}

internal sealed class UpdateTopicCommandHandler(
    IAppDbContext db, AuditTrail audit, AdminClock clock, AdminTaxonomyReader reader, TaxonomyCaches caches)
    : ICommandHandler<UpdateTopicCommand, Result<AdminTopicDto>>
{
    public async ValueTask<Result<AdminTopicDto>> Handle(UpdateTopicCommand command, CancellationToken cancellationToken)
    {
        var topic = await db.Topics.FirstOrDefaultAsync(t => t.Id == command.Id, cancellationToken);
        if (topic is null) return TaxonomyErrors.TopicNotFound;

        var changed = topic.EditByAdmin(TaxonomyRules.Name(command.NameAr), TaxonomyRules.Name(command.NameEn), command.IsEnabled, clock.UtcNow);
        if (changed.Count > 0)
        {
            audit.Record(AuditActions.TopicUpdated, userId: null, AuditTargets.Topic, topic.Id, string.Join(", ", changed));
            await db.SaveChangesAsync(cancellationToken);
            await caches.DropAsync(cancellationToken);
        }
        return await reader.TopicAsync(topic.Id, cancellationToken);
    }
}

internal sealed class ReorderTopicsCommandHandler(IAppDbContext db, AuditTrail audit, AdminClock clock, TaxonomyCaches caches)
    : ICommandHandler<ReorderTopicsCommand, Result>
{
    public async ValueTask<Result> Handle(ReorderTopicsCommand command, CancellationToken cancellationToken)
    {
        var field = await db.Fields.Include(f => f.Topics).FirstOrDefaultAsync(f => f.Id == command.FieldId, cancellationToken);
        if (field is null) return TaxonomyErrors.FieldNotFound;
        if (!AdminOrder.IsPermutation(command.Ids, field.Topics.Select(t => t.Id))) return AdminErrors.OrderInvalid;

        var byId = field.Topics.ToDictionary(t => t.Id);
        var now = clock.UtcNow;
        var moved = 0;
        for (var i = 0; i < command.Ids.Count; i++)
            if (byId[command.Ids[i]].MoveTo(i + 1, now)) moved++;
        if (moved == 0) return Result.Success();

        audit.Record(AuditActions.TopicsReordered, userId: null, AuditTargets.Field, field.Id, $"{moved} moved");
        await db.SaveChangesAsync(cancellationToken);
        await caches.DropAsync(cancellationToken);
        return Result.Success();
    }
}

/// <summary>The console's order lists (SPEC F23): every item exactly once.</summary>
public static class AdminOrder
{
    public static bool IsPermutation(IReadOnlyList<Guid>? ids, IEnumerable<Guid> all)
    {
        if (ids is null) return false;
        var expected = all.ToHashSet();
        return ids.Count == expected.Count && ids.Distinct().Count() == ids.Count && ids.All(expected.Contains);
    }
}
