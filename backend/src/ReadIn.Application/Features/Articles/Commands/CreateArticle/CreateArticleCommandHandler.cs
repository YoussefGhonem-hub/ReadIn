using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Articles.Commands.CreateArticle;

internal sealed class CreateArticleCommandHandler(IAppDbContext db, ICurrentUser currentUser, IRDocProcessor rdoc)
    : ICommandHandler<CreateArticleCommand, Result<Guid>>
{
    private static readonly Error FieldNotFound = Error.Validation("field.not_found", "Field not found.");
    private static readonly Error TopicNotInField = Error.Validation("topic.not_in_field", "The topic does not belong to this field.");

    public async ValueTask<Result<Guid>> Handle(CreateArticleCommand cmd, CancellationToken ct)
    {
        var field = await db.Fields.AsNoTracking().FirstOrDefaultAsync(f => f.Id == cmd.FieldId && f.IsEnabled, ct);
        if (field is null) return FieldNotFound;
        if (cmd.TopicId is { } topicId && !await db.Topics.AnyAsync(t => t.Id == topicId && t.FieldId == field.Id, ct))
            return TopicNotInField;

        var content = rdoc.Process(cmd.Content, cmd.Language, cmd.Title); // validates + sanitizes
        if (content.IsFailure) return content.Error;

        var article = Article.CreateDraft(currentUser.RequireUserId(), cmd.FieldId, cmd.TopicId, await UniqueSlugAsync(cmd.Title, ct));

        var added = article.AddTranslation(cmd.Language, cmd.Title, cmd.Subtitle, content.Value.Content);
        if (added.IsFailure) return added.Error;

        var tags = await UpsertTagsAsync(cmd.Tags ?? [], ct);
        var tagged = article.SetTags(tags);
        if (tagged.IsFailure) return tagged.Error;

        article.SetSources((cmd.Sources ?? []).Select(s => (s.Title, s.Url)));
        article.SetMetadata(cmd.CoverUrl, cmd.VersionBadge, cmd.IsAiAssisted);

        db.Articles.Add(article);
        await db.SaveChangesAsync(ct);
        return article.Id;
    }

    private async Task<string> UniqueSlugAsync(string title, CancellationToken ct)
    {
        var baseSlug = SlugGenerator.FromTitle(title);
        if (baseSlug.Length < 3) baseSlug = $"article-{Guid.CreateVersion7().ToString("N")[^8..]}";

        var taken = await db.Articles.IgnoreQueryFilters().AsNoTracking()
            .Where(a => a.Slug.StartsWith(baseSlug))
            .Select(a => a.Slug)
            .ToListAsync(ct);
        if (!taken.Contains(baseSlug)) return baseSlug;

        for (var i = 2; ; i++)
        {
            var candidate = $"{baseSlug}-{i}";
            if (!taken.Contains(candidate)) return candidate;
        }
    }

    private async Task<List<Guid>> UpsertTagsAsync(IReadOnlyList<string> names, CancellationToken ct)
    {
        var bySlug = names
            .Select(n => n.Trim())
            .Where(n => n.Length > 0)
            .GroupBy(Tag.ToSlug)
            .Where(g => g.Key.Length > 0)
            .ToDictionary(g => g.Key, g => g.First());
        var slugs = bySlug.Keys.ToList();

        var existing = await db.Tags.Where(t => slugs.Contains(t.Slug)).ToListAsync(ct);
        foreach (var slug in slugs.Except(existing.Select(t => t.Slug)))
        {
            var tag = new Tag(slug, bySlug[slug]);
            db.Tags.Add(tag);
            existing.Add(tag);
        }
        return [.. existing.Select(t => t.Id)];
    }
}
