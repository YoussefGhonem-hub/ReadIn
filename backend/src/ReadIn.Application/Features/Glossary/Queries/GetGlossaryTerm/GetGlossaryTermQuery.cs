using Mediator;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Glossary.Queries.GetGlossaryTerm;

/// <summary>
/// GET /glossary/{slug}?lang= — the definition sheet a reader opens by tapping a term (SPEC F21). Cached; publishing or
/// deleting an article (the feed tag) and re-indexing terms (the glossary tag) invalidate it.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetGlossaryTermQuery(string Slug, string? Language, string UiLanguage)
    : IQuery<Result<GlossaryTermDto>>, ICachedQuery
{
    /// <summary>Most articles listed under a term; the reader drops the one that is open and shows five.</summary>
    public const int MaxArticles = 6;

    public string CacheKey => $"glossary:{Slug}:{Language ?? "source"}:{UiLanguage}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Glossary, Common.Behaviors.CacheTags.Feed];
    public TimeSpan Expiration => TimeSpan.FromMinutes(30);
}
