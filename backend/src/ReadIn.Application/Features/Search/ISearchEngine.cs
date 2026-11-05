namespace ReadIn.Application.Features.Search;

/// <summary>How the article text is searched (contract-v1 "Search", "Engines"). Chosen once at startup.</summary>
public enum SearchEngineKind
{
    /// <summary>The <c>LIKE</c> fallback over the normalized text: works on every SQL Server.</summary>
    Like = 0,

    /// <summary>SQL Server Full-Text Search (<c>CONTAINSTABLE</c>), when the server has it and the indexes exist.</summary>
    FullText = 1,
}

/// <summary>One row the engine found: its key and how well it matched.</summary>
public sealed class SearchHit
{
    /// <summary><c>ArticleTranslations.Id</c> or <c>MediaAssets.Id</c>.</summary>
    public Guid Key { get; init; }

    /// <summary>
    /// The <c>rank</c> of the ranking formula, 0–1. Full-text: the hit's <c>RANK</c> ÷ the highest <c>RANK</c> of the
    /// query's hits on that column; fallback: 1 when the text holds the whole query as one phrase, else 0.5.
    /// </summary>
    public double Rank { get; init; }
}

/// <summary>
/// The text search behind <c>GET /search?type=articles</c> (SPEC §22). Each method returns a composable query over the
/// same <see cref="Common.Interfaces.IAppDbContext"/> the handlers use, so visibility, filters and joins are added in
/// SQL. Infrastructure implements it twice: SQL Server Full-Text Search and a <c>LIKE</c> fallback.
/// </summary>
public interface ISearchEngine
{
    SearchEngineKind Kind { get; }

    /// <summary>Language versions (<c>ArticleTranslations</c>) whose <c>SearchText</c> (title + text) holds every word.</summary>
    IQueryable<SearchHit> ArticleVersions(SearchTerms terms);

    /// <summary>Uploads (<c>MediaAssets</c>) whose <c>ExtractedText</c> (an attached PDF's text) holds every word.</summary>
    IQueryable<SearchHit> Documents(SearchTerms terms);
}
