using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Learning;

namespace ReadIn.Application.Features.LearningPaths.Queries.GetPathBySlug;

/// <summary>
/// GET /paths/{slug} — a path with its articles in order (SPEC F09). <c>path.not_found</c> when it is unknown,
/// unpublished or has no article a reader can open. Guests are allowed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetPathBySlugQuery(string Slug, string UiLanguage) : IQuery<Result<PathDetailsDto>>;

internal sealed class GetPathBySlugQueryHandler(ICurrentUser currentUser, PathCards cards)
    : IQueryHandler<GetPathBySlugQuery, Result<PathDetailsDto>>
{
    public async ValueTask<Result<PathDetailsDto>> Handle(GetPathBySlugQuery query, CancellationToken ct)
    {
        var slug = query.Slug.Trim().ToLowerInvariant();
        var id = await cards.Listed().Where(p => p.Slug == slug).Select(p => (Guid?)p.Id).FirstOrDefaultAsync(ct);
        if (id is null) return LearningPathErrors.NotFound;

        var viewer = currentUser.UserId;
        var language = await cards.ArticleLanguageOfAsync(viewer, ct);
        var data = await cards.LoadAsync([id.Value], viewer, query.UiLanguage, language, ct);
        if (data is not [var path]) return LearningPathErrors.NotFound;

        var articles = (await cards.ArticleCardsAsync([.. path.Items.Select(i => i.Article.Id)], query.UiLanguage, language, ct))
            .ToDictionary(a => a.Id);
        var items = path.Items
            .Where(i => articles.ContainsKey(i.Article.Id))
            .Select(i => new PathItemDto(i.Article.Position, articles[i.Article.Id], viewer is not null && i.IsRead))
            .ToList();

        return PathDetails.From(path.Card, items);
    }
}

internal static class PathDetails
{
    public static PathDetailsDto From(PathCardDto card, IReadOnlyList<PathItemDto> items) => new()
    {
        Id = card.Id,
        Slug = card.Slug,
        Title = card.Title,
        Description = card.Description,
        Field = card.Field,
        ArticleCount = card.ArticleCount,
        ReadingTimeMinutes = card.ReadingTimeMinutes,
        CoverUrl = card.CoverUrl,
        Progress = card.Progress,
        Enrollment = card.Enrollment,
        Items = items,
    };
}
