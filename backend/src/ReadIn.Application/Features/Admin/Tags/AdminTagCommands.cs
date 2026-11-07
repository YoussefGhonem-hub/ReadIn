using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Admin.Tags;

// Tags in the admin console (SPEC F23, F32): list, rename, merge, hide. A rename keeps the slug; when the normalized name
// changes, the old spelling becomes an alias. A merge moves the articles and makes the merged tag's name and slug aliases.

/// <summary>GET /admin/tags?q=&amp;status=&amp;origin=&amp;sort=&amp;page=&amp;pageSize=.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record GetAdminTagsQuery(string? Query, string? Status, string? Origin, string? Sort, int? Page, int? PageSize)
    : IQuery<Result<PagedList<AdminTagDto>>>
{
    public const int MaxQueryLength = 64;
}

/// <summary>PUT /admin/tags/{id}: a new spelling; the slug never changes.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record RenameTagCommand(Guid Id, string? Name) : ICommand<Result<AdminTagDto>>;

/// <summary>POST /admin/tags/{id}/merge: tag {id} goes into <see cref="IntoTagId"/> and is deleted; it can't be undone.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record MergeTagCommand(Guid Id, Guid IntoTagId) : ICommand<Result<AdminTagDto>>;

/// <summary>PUT (hide) / DELETE (unhide) /admin/tags/{id}/hidden; idempotent.</summary>
[Authenticated]
[RequirePermission(Permissions.Taxonomy.Manage)]
public sealed record SetTagHiddenCommand(Guid Id, bool Hidden) : ICommand<Result<AdminTagDto>>;

/// <summary>The console's tag rows: counts, the creator and the aliases.</summary>
internal sealed class AdminTagReader(IAppDbContext db)
{
    // Member-initialized (not a constructor) so SQL can sort on the projected counts.
    private sealed class TagRow
    {
        public Guid Id { get; init; }
        public string Slug { get; init; } = default!;
        public string Name { get; init; } = default!;
        public string NormalizedName { get; init; } = default!;
        public int ArticleCount { get; init; }
        public int TaggedCount { get; init; }
        public bool IsHidden { get; init; }
        public bool IsSystem { get; init; }
        public DateTime CreatedAt { get; init; }
        public Guid? CreatedById { get; init; }
        public string? CreatedByUsername { get; init; }
        public DateTime? EmptySince { get; init; }
    }

    public async Task<PagedList<AdminTagDto>> PageAsync(
        IQueryable<Tag> tags, string sort, int page, int pageSize, CancellationToken ct)
    {
        var rows = Project(tags);
        rows = sort switch
        {
            AdminTagSorts.Name => rows.OrderBy(r => r.NormalizedName).ThenBy(r => r.Id),
            AdminTagSorts.Newest => rows.OrderByDescending(r => r.CreatedAt).ThenBy(r => r.Id),
            _ => rows.OrderByDescending(r => r.ArticleCount).ThenBy(r => r.Name).ThenBy(r => r.Id),
        };
        var found = await rows.ToPagedListAsync(page, pageSize, ct);
        var aliases = await AliasesAsync([.. found.Items.Select(r => r.Id)], ct);
        return new PagedList<AdminTagDto>([.. found.Items.Select(r => ToDto(r, aliases))], found.Page, found.PageSize, found.TotalCount);
    }

    public async Task<AdminTagDto> OneAsync(Guid id, CancellationToken ct)
    {
        var row = await Project(db.Tags.AsNoTracking().Where(t => t.Id == id)).SingleAsync(ct);
        return ToDto(row, await AliasesAsync([id], ct));
    }

    private IQueryable<TagRow> Project(IQueryable<Tag> tags)
    {
        // As TagDto: published articles readers can see; taggedCount: every article that carries it (what a merge moves).
        var visible = db.Articles.AsNoTracking().Visible().Where(a => a.PublishedAt != null);
        var all = db.Articles.AsNoTracking();
        var users = db.Users.AsNoTracking();
        return tags.Select(t => new TagRow
        {
            Id = t.Id,
            Slug = t.Slug,
            Name = t.Name,
            NormalizedName = t.NormalizedName,
            ArticleCount = visible.Count(a => a.Tags.Any(x => x.TagId == t.Id)),
            TaggedCount = all.Count(a => a.Tags.Any(x => x.TagId == t.Id)),
            IsHidden = t.IsHidden,
            IsSystem = t.IsSystem,
            CreatedAt = t.CreatedAt,
            CreatedById = t.CreatedById,
            CreatedByUsername = users.Where(u => u.Id == t.CreatedById).Select(u => u.Username).FirstOrDefault(),
            EmptySince = t.EmptySince,
        });
    }

    private async Task<ILookup<Guid, string>> AliasesAsync(List<Guid> tagIds, CancellationToken ct) =>
        (await db.TagAliases.AsNoTracking()
            .Where(a => tagIds.Contains(a.TagId))
            .OrderBy(a => a.CreatedAt).ThenBy(a => a.Name)
            .Select(a => new { a.TagId, a.Name })
            .ToListAsync(ct))
        .ToLookup(a => a.TagId, a => a.Name);

    private static AdminTagDto ToDto(TagRow row, ILookup<Guid, string> aliases) => new(
        row.Id, row.Slug, row.Name, row.ArticleCount, row.TaggedCount, row.IsHidden, row.IsSystem, row.CreatedAt,
        row.CreatedById is { } creator && row.CreatedByUsername is { } username ? new AdminTagCreatorDto(creator, username) : null,
        row.EmptySince, [.. aliases[row.Id]]);
}

internal static class AdminTagSorts
{
    public const string Articles = "articles";
    public const string Name = "name";
    public const string Newest = "newest";
}

/// <summary>Tag names are on cards, the reader, tag pages and suggestions: every cached page that shows them goes.</summary>
internal sealed class TagCaches(HybridCache cache)
{
    public ValueTask DropAsync(CancellationToken ct) => cache.RemoveByTagAsync([CacheTags.Tags, CacheTags.Feed, CacheTags.Articles], ct);
}

internal sealed class GetAdminTagsQueryHandler(IAppDbContext db, AdminTagReader reader)
    : IQueryHandler<GetAdminTagsQuery, Result<PagedList<AdminTagDto>>>
{
    public async ValueTask<Result<PagedList<AdminTagDto>>> Handle(GetAdminTagsQuery query, CancellationToken cancellationToken)
    {
        var status = query.Status ?? "all";
        var origin = query.Origin ?? "all";
        var sort = query.Sort ?? AdminTagSorts.Articles;
        if (status is not ("all" or "visible" or "hidden")) return AdminErrors.InvalidParameter("status");
        if (origin is not ("all" or "system" or "user")) return AdminErrors.InvalidParameter("origin");
        if (sort is not (AdminTagSorts.Articles or AdminTagSorts.Name or AdminTagSorts.Newest)) return AdminErrors.InvalidParameter("sort");
        if (query.Query is { Length: > GetAdminTagsQuery.MaxQueryLength }) return ValidationErrors.For("q", ["validation.max_length"]);

        var tags = db.Tags.AsNoTracking();
        if (status == "visible") tags = tags.Where(t => !t.IsHidden);
        else if (status == "hidden") tags = tags.Where(t => t.IsHidden);
        if (origin == "system") tags = tags.Where(t => t.IsSystem);
        else if (origin == "user") tags = tags.Where(t => !t.IsSystem);

        var cleaned = TagNames.Clean(query.Query);
        var key = TagNames.Normalize(cleaned);
        if (key.Length > 0)
        {
            var slug = TagNames.SlugText(cleaned);
            var aliases = db.TagAliases.AsNoTracking();
            tags = tags.Where(t => t.NormalizedName.Contains(key)
                || (slug.Length > 0 && t.Slug.Contains(slug))
                || aliases.Any(a => a.TagId == t.Id && a.NormalizedName.Contains(key)));
        }

        var (page, pageSize) = AdminPaging.Normalize(query.Page, query.PageSize);
        return await reader.PageAsync(tags, sort, page, pageSize, cancellationToken);
    }
}

internal sealed class RenameTagCommandHandler(
    IAppDbContext db, AuditTrail audit, AdminClock clock, AdminTagReader reader, TagCaches caches)
    : ICommandHandler<RenameTagCommand, Result<AdminTagDto>>
{
    public async ValueTask<Result<AdminTagDto>> Handle(RenameTagCommand command, CancellationToken cancellationToken)
    {
        var cleaned = TagNames.Clean(command.Name);
        if (!TagNames.IsValidNew(cleaned)) return ValidationErrors.For("name", [TaxonomyErrors.TagInvalid.Code]);

        var tag = await db.Tags.FirstOrDefaultAsync(t => t.Id == command.Id, cancellationToken);
        if (tag is null) return TaxonomyErrors.TagNotFound;
        if (cleaned == tag.Name) return await reader.OneAsync(tag.Id, cancellationToken);

        var key = TagNames.Normalize(cleaned);
        var oldName = tag.Name;
        if (key != tag.NormalizedName)
        {
            // The new name is another tag's, or leads to one: offer a merge instead.
            var other = await db.Tags.AsNoTracking().Where(t => t.NormalizedName == key && t.Id != tag.Id)
                .Select(t => new { t.Id, t.Slug }).FirstOrDefaultAsync(cancellationToken);
            if (other is not null) return AdminErrors.TagNameTakenBy(other.Id, other.Slug);
            var alias = await db.TagAliases.FirstOrDefaultAsync(a => a.NormalizedName == key, cancellationToken);
            if (alias is not null && alias.TagId != tag.Id)
            {
                var owner = await db.Tags.AsNoTracking().Where(t => t.Id == alias.TagId).Select(t => t.Slug).SingleAsync(cancellationToken);
                return AdminErrors.TagNameTakenBy(alias.TagId, owner);
            }

            // Its own alias becomes its name again; the old spelling becomes an alias, so it still leads here.
            if (alias is not null) db.TagAliases.Remove(alias);
            db.TagAliases.Add(new TagAlias(tag.Id, tag.Name, tag.NormalizedName, slug: null, clock.UtcNow));
        }
        tag.Rename(cleaned, key);
        audit.Record(AuditActions.TagRenamed, userId: null, AuditTargets.Tag, tag.Id, $"{oldName} → {cleaned}");
        await db.SaveChangesAsync(cancellationToken);
        await caches.DropAsync(cancellationToken);
        return await reader.OneAsync(tag.Id, cancellationToken);
    }
}

internal sealed class MergeTagCommandHandler(
    IAppDbContext db, AuditTrail audit, AdminClock clock, AdminTagReader reader, TagCaches caches)
    : ICommandHandler<MergeTagCommand, Result<AdminTagDto>>
{
    public async ValueTask<Result<AdminTagDto>> Handle(MergeTagCommand command, CancellationToken cancellationToken)
    {
        if (command.Id == command.IntoTagId) return AdminErrors.TagMergeSelf;
        var from = await db.Tags.FirstOrDefaultAsync(t => t.Id == command.Id, cancellationToken);
        var into = await db.Tags.FirstOrDefaultAsync(t => t.Id == command.IntoTagId, cancellationToken);
        if (from is null || into is null) return TaxonomyErrors.TagNotFound;

        // Every article that carries it, hidden and unpublished ones too; deleted ones lose the row with the tag.
        var articles = await db.Articles
            .Include(a => a.Tags)
            .Where(a => a.Tags.Any(t => t.TagId == from.Id))
            .ToListAsync(cancellationToken);
        foreach (var article in articles)
        {
            var ordered = article.Tags.OrderBy(t => t.Position).Select(t => t.TagId).ToList();
            article.SetTags(TagMerge.Replace(ordered, from.Id, into.Id));
        }

        // Its aliases follow it; its name and slug become aliases, so links, writers and the seed content reach the other tag.
        foreach (var alias in await db.TagAliases.Where(a => a.TagId == from.Id).ToListAsync(cancellationToken)) alias.MoveTo(into.Id);
        db.TagAliases.Add(new TagAlias(into.Id, from.Name, from.NormalizedName, from.Slug, clock.UtcNow));
        if (from.IsSystem) into.MarkSystem();
        db.Tags.Remove(from);

        audit.Record(AuditActions.TagMerged, userId: null, AuditTargets.Tag, into.Id, $"{from.Name} → {into.Name} ({articles.Count} articles)");
        await db.SaveChangesAsync(cancellationToken);
        await caches.DropAsync(cancellationToken);
        return await reader.OneAsync(into.Id, cancellationToken);
    }
}

internal sealed class SetTagHiddenCommandHandler(IAppDbContext db, AuditTrail audit, AdminTagReader reader, TagCaches caches)
    : ICommandHandler<SetTagHiddenCommand, Result<AdminTagDto>>
{
    public async ValueTask<Result<AdminTagDto>> Handle(SetTagHiddenCommand command, CancellationToken cancellationToken)
    {
        var tag = await db.Tags.FirstOrDefaultAsync(t => t.Id == command.Id, cancellationToken);
        if (tag is null) return TaxonomyErrors.TagNotFound;

        if (tag.IsHidden != command.Hidden)
        {
            if (command.Hidden) tag.Hide();
            else tag.Show();
            audit.Record(command.Hidden ? AuditActions.TagHidden : AuditActions.TagUnhidden, userId: null, AuditTargets.Tag, tag.Id, tag.Name);
            await db.SaveChangesAsync(cancellationToken);
            await caches.DropAsync(cancellationToken);
        }
        return await reader.OneAsync(tag.Id, cancellationToken);
    }
}
