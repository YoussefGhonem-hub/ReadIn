using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Search;

/// <summary>
/// <c>GET /search?type=topics</c> (contract-v1 "Search"): enabled fields and their topics whose Arabic or English name
/// holds every word of <see cref="Q"/>, or whose slug starts with its slug. An exact name first, then fields, then the
/// most articles.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record TopicSearchQuery(string? Q, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<SearchTopicDto>>>;

/// <summary>
/// The taxonomy is small (tens of fields, a few hundred topics), so names are matched in memory with the same
/// normalization as everywhere; only the article counts of the matches are queried.
/// </summary>
public sealed class TopicSearch(IAppDbContext db, ICurrentUser currentUser)
{
    public async Task<(List<SearchTopicDto> Page, string? Next)> FindAsync(
        SearchTerms terms, string? cursor, int limit, string uiLanguage, CancellationToken ct)
    {
        var viewerId = currentUser.UserId;
        var english = UiLanguages.Normalize(uiLanguage) == UiLanguages.English;

        var fields = await db.Fields.AsNoTracking().Where(f => f.IsEnabled).WithoutMutedFor(viewerId)
            .Select(f => new { f.Id, f.Slug, f.NameAr, f.NameEn, f.Icon, f.Color })
            .ToListAsync(ct);
        var fieldIds = fields.Select(f => f.Id).ToList();
        var topics = await db.Topics.AsNoTracking().Where(t => fieldIds.Contains(t.FieldId)).WithoutMutedFor(viewerId)
            .Select(t => new { t.Id, t.FieldId, t.Slug, t.NameAr, t.NameEn })
            .ToListAsync(ct);

        bool Matches(string slug, string nameAr, string nameEn) =>
            terms.AllWordsStartWordsIn(ArabicNormalizer.Normalize(nameAr))
            || terms.AllWordsStartWordsIn(ArabicNormalizer.Normalize(nameEn))
            || (terms.Slug.Length > 0 && slug.StartsWith(terms.Slug, StringComparison.Ordinal));

        bool Exact(string nameAr, string nameEn) =>
            ArabicNormalizer.Normalize(nameAr) == terms.Phrase || ArabicNormalizer.Normalize(nameEn) == terms.Phrase;

        var byId = fields.ToDictionary(f => f.Id);
        var matches = fields
            .Where(f => Matches(f.Slug, f.NameAr, f.NameEn))
            .Select(f => (Kind: SearchTopicKind.Field, f.Id, Field: f, TopicSlug: (string?)null, f.NameAr, f.NameEn))
            .Concat(topics
                .Where(t => Matches(t.Slug, t.NameAr, t.NameEn))
                .Select(t => (Kind: SearchTopicKind.Topic, t.Id, Field: byId[t.FieldId], TopicSlug: (string?)t.Slug, t.NameAr, t.NameEn)))
            .ToList();
        if (matches.Count == 0) return ([], null);

        // Published articles readers can see, the same for everyone (like FieldDto counts).
        var visible = db.Articles.AsNoTracking().Visible().Where(a => a.PublishedAt != null);
        var matchedFields = matches.Where(m => m.Kind == SearchTopicKind.Field).Select(m => m.Id).ToList();
        var matchedTopics = matches.Where(m => m.Kind == SearchTopicKind.Topic).Select(m => m.Id).ToList();
        var fieldCounts = matchedFields.Count == 0
            ? new Dictionary<Guid, int>()
            : await visible.Where(a => matchedFields.Contains(a.FieldId))
                .GroupBy(a => a.FieldId).Select(g => new { g.Key, Count = g.Count() })
                .ToDictionaryAsync(g => g.Key, g => g.Count, ct);
        var topicCounts = matchedTopics.Count == 0
            ? new Dictionary<Guid, int>()
            : await visible.Where(a => a.TopicId != null && matchedTopics.Contains(a.TopicId.Value))
                .GroupBy(a => a.TopicId!.Value).Select(g => new { g.Key, Count = g.Count() })
                .ToDictionaryAsync(g => g.Key, g => g.Count, ct);

        var ranked = matches
            .Select(m =>
            {
                var count = (m.Kind == SearchTopicKind.Field ? fieldCounts : topicCounts).GetValueOrDefault(m.Id);
                var dto = new SearchTopicDto(
                    m.Kind, m.Id,
                    english ? m.NameEn : m.NameAr, m.NameAr, m.NameEn,
                    m.Field.Slug, m.TopicSlug,
                    english ? m.Field.NameEn : m.Field.NameAr,
                    m.Field.Icon, m.Field.Color, count);
                return (Dto: dto, Exact: Exact(m.NameAr, m.NameEn));
            })
            .OrderByDescending(m => m.Exact)
            .ThenBy(m => m.Dto.Kind)
            .ThenByDescending(m => m.Dto.ArticleCount)
            .ThenBy(m => m.Dto.Name, StringComparer.Ordinal)
            .ThenBy(m => m.Dto.Id)
            .Select(m => m.Dto)
            .Take(SearchLimits.MaxResults)
            .ToList();

        var (page, next) = SearchPaging.Page(ranked, cursor, limit);
        return (page.ToList(), next);
    }
}

internal sealed class TopicSearchQueryHandler(TopicSearch topics) : IQueryHandler<TopicSearchQuery, Result<CursorPage<SearchTopicDto>>>
{
    public async ValueTask<Result<CursorPage<SearchTopicDto>>> Handle(TopicSearchQuery query, CancellationToken ct)
    {
        var terms = SearchTerms.Parse(query.Q);
        if (terms.IsFailure) return terms.Error!;

        var (page, next) = await topics.FindAsync(terms.Value, query.Cursor, query.Limit, query.UiLanguage, ct);
        return new CursorPage<SearchTopicDto>(page, next);
    }
}
