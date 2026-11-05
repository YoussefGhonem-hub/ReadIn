using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Features.Search;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Search;

/// <summary>
/// SQL Server Full-Text Search over the normalized <c>ArticleTranslations.SearchText</c> and <c>MediaAssets.ExtractedText</c>
/// (SPEC §22): <c>CONTAINSTABLE</c> with every word as a quoted prefix term (<see cref="SearchTerms.FullTextCondition"/>),
/// sent as a parameter. The indexes use the Arabic word breaker (LCID 1025), which also breaks English words, and finds
/// Arabic words behind prefixes such as <c>ال</c> and <c>ب</c>. Indexing is asynchronous: a change is searchable a few
/// seconds after its commit.
/// </summary>
internal sealed class FullTextSearchEngine(AppDbContext db) : ISearchEngine
{
    public SearchEngineKind Kind => SearchEngineKind.FullText;

    public IQueryable<SearchHit> ArticleVersions(SearchTerms terms)
    {
        var condition = terms.FullTextCondition();
        return db.Database.SqlQuery<SearchHit>($"""
            SELECT ct.[KEY] AS [Key],
                   COALESCE(CAST(ct.[RANK] AS float) / NULLIF(MAX(ct.[RANK]) OVER (), 0), 1.0) AS [Rank]
            FROM CONTAINSTABLE([dbo].[ArticleTranslations], [SearchText], {condition}, LANGUAGE 1025) AS ct
            """);
    }

    public IQueryable<SearchHit> Documents(SearchTerms terms)
    {
        var condition = terms.FullTextCondition();
        return db.Database.SqlQuery<SearchHit>($"""
            SELECT ct.[KEY] AS [Key],
                   COALESCE(CAST(ct.[RANK] AS float) / NULLIF(MAX(ct.[RANK]) OVER (), 0), 1.0) AS [Rank]
            FROM CONTAINSTABLE([dbo].[MediaAssets], [ExtractedText], {condition}, LANGUAGE 1025) AS ct
            """);
    }
}

/// <summary>
/// The fallback for a SQL Server without Full-Text Search: escaped <c>LIKE '%word%'</c> for every word over the same
/// normalized text, so it may also match inside a word (<c>net</c> finds <c>internet</c>). <c>rank</c> is 1 when the text
/// holds the whole query as one phrase, else 0.5.
/// </summary>
internal sealed class LikeSearchEngine(AppDbContext db) : ISearchEngine
{
    public SearchEngineKind Kind => SearchEngineKind.Like;

    public IQueryable<SearchHit> ArticleVersions(SearchTerms terms)
    {
        var versions = db.ArticleTranslations.AsNoTracking();
        foreach (var word in terms.Words)
        {
            var pattern = SearchTerms.ContainsPattern(word);
            versions = versions.Where(t => EF.Functions.Like(t.SearchText, pattern, SearchTerms.LikeEscape));
        }

        var phrase = SearchTerms.ContainsPattern(terms.Phrase);
        return versions.Select(t => new SearchHit
        {
            Key = t.Id,
            Rank = EF.Functions.Like(t.SearchText, phrase, SearchTerms.LikeEscape) ? 1.0 : 0.5,
        });
    }

    public IQueryable<SearchHit> Documents(SearchTerms terms)
    {
        var documents = db.MediaAssets.AsNoTracking().Where(m => m.ExtractedText != null);
        foreach (var word in terms.Words)
        {
            var pattern = SearchTerms.ContainsPattern(word);
            documents = documents.Where(m => EF.Functions.Like(m.ExtractedText!, pattern, SearchTerms.LikeEscape));
        }

        var phrase = SearchTerms.ContainsPattern(terms.Phrase);
        return documents.Select(m => new SearchHit
        {
            Key = m.Id,
            Rank = EF.Functions.Like(m.ExtractedText!, phrase, SearchTerms.LikeEscape) ? 1.0 : 0.5,
        });
    }
}
