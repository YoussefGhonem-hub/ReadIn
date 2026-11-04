using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.LearningPaths.Queries.GetPaths;

/// <summary>GET /paths?field= — published paths in editorial order (SPEC F09). Guests are allowed.</summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetPathsQuery(string? FieldSlug, string UiLanguage) : IQuery<Result<IReadOnlyList<PathCardDto>>>;

internal sealed class GetPathsQueryHandler(IAppDbContext db, ICurrentUser currentUser, PathCards cards)
    : IQueryHandler<GetPathsQuery, Result<IReadOnlyList<PathCardDto>>>
{
    public async ValueTask<Result<IReadOnlyList<PathCardDto>>> Handle(GetPathsQuery query, CancellationToken ct)
    {
        var paths = cards.Listed();
        if (!string.IsNullOrWhiteSpace(query.FieldSlug))
        {
            var slug = query.FieldSlug.Trim();
            paths = paths.Where(p => db.Fields.Any(f => f.Id == p.FieldId && f.Slug == slug));
        }

        var ids = await paths.OrderBy(p => p.SortOrder).ThenBy(p => p.Slug).Select(p => p.Id).ToListAsync(ct);
        var viewer = currentUser.UserId;
        var language = await cards.ArticleLanguageOfAsync(viewer, query.UiLanguage, ct);
        return await cards.BuildAsync(ids, viewer, query.UiLanguage, language, ct);
    }
}
