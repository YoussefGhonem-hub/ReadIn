using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Search;

/// <summary>
/// <c>GET /search/suggest</c> (contract-v1 "Search"): the first <see cref="SearchLimits.SuggestionsPerType"/> results of
/// every type for the as-you-type dropdown, ranked as in <c>/search</c>, without filters or paging.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record SearchSuggestionsQuery(string? Q, string UiLanguage) : IQuery<Result<SearchSuggestionsDto>>;

internal sealed class SearchSuggestionsQueryHandler(ArticleSearch articles, PeopleSearch people, TopicSearch topics, TagSearch tags)
    : IQueryHandler<SearchSuggestionsQuery, Result<SearchSuggestionsDto>>
{
    public async ValueTask<Result<SearchSuggestionsDto>> Handle(SearchSuggestionsQuery query, CancellationToken ct)
    {
        var parsed = SearchTerms.Parse(query.Q);
        if (parsed.IsFailure) return parsed.Error!;
        var terms = parsed.Value;
        const int count = SearchLimits.SuggestionsPerType;

        // One DbContext: the four searches run one after another.
        var ranked = await articles.RankAsync(terms, ArticleSearchFilters.None, query.UiLanguage, ct);
        var articleCards = await articles.CardsAsync(ranked.Take(count).ToList(), query.UiLanguage, ct);
        var (users, _) = await people.FindAsync(terms, cursor: null, count, ct);
        var (fieldsAndTopics, _) = await topics.FindAsync(terms, cursor: null, count, query.UiLanguage, ct);
        var (tagList, _) = await tags.FindAsync(terms, cursor: null, count, ct);

        return new SearchSuggestionsDto(articleCards, users, fieldsAndTopics, tagList);
    }
}
