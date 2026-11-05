using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Features.Search;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Search;

/// <summary>Which <see cref="ISearchEngine"/> this API uses: decided once at startup by <see cref="SearchEngineSetup"/>.</summary>
public sealed class SearchEngineState
{
    /// <summary>The fallback until startup has looked at the server, so a search never needs full-text by chance.</summary>
    public SearchEngineKind Kind { get; internal set; } = SearchEngineKind.Like;
}

/// <summary>
/// The full-text catalog and indexes (SPEC §16.3, §22), created only on a server that has Full-Text Search
/// (<c>SERVERPROPERTY('IsFullTextInstalled')</c>), and the startup choice between the engines. <c>Search:Engine</c> =
/// <c>auto</c> (default: full-text when installed and indexed, else LIKE), <c>like</c> (always the fallback) or
/// <c>fulltext</c> (the same as auto, with a warning when it can't be used).
/// </summary>
public static class SearchEngineSetup
{
    public const string Catalog = "ReadInSearch";

    /// <summary>
    /// Idempotent DDL: the catalog and one index per searched column, with the Arabic word breaker, no stoplist (a
    /// common word is still a word people look for) and automatic change tracking. Full-text DDL can't run inside a
    /// transaction. The <c>SearchFullText</c> migration runs a copy of it; once a migration is applied it never changes,
    /// so a later change goes into a new migration and here.
    /// <para>A full-text indexed column can't be altered: a migration that changes <c>SearchText</c> or
    /// <c>ExtractedText</c> drops the index first and runs this again.</para>
    /// </summary>
    public const string CreateSql = """
        IF CAST(ISNULL(SERVERPROPERTY('IsFullTextInstalled'), 0) AS int) = 1
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'ReadInSearch')
                EXEC(N'CREATE FULLTEXT CATALOG [ReadInSearch]');
            IF OBJECT_ID(N'dbo.ArticleTranslations') IS NOT NULL
               AND NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.ArticleTranslations'))
                EXEC(N'CREATE FULLTEXT INDEX ON [dbo].[ArticleTranslations] ([SearchText] LANGUAGE 1025) KEY INDEX [PK_ArticleTranslations] ON [ReadInSearch] WITH (CHANGE_TRACKING = AUTO, STOPLIST = OFF)');
            IF OBJECT_ID(N'dbo.MediaAssets') IS NOT NULL
               AND NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.MediaAssets'))
                EXEC(N'CREATE FULLTEXT INDEX ON [dbo].[MediaAssets] ([ExtractedText] LANGUAGE 1025) KEY INDEX [PK_MediaAssets] ON [ReadInSearch] WITH (CHANGE_TRACKING = AUTO, STOPLIST = OFF)');
        END
        """;

    public const string DropSql = """
        IF EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.MediaAssets'))
            EXEC(N'DROP FULLTEXT INDEX ON [dbo].[MediaAssets]');
        IF EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.ArticleTranslations'))
            EXEC(N'DROP FULLTEXT INDEX ON [dbo].[ArticleTranslations]');
        IF EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'ReadInSearch')
            EXEC(N'DROP FULLTEXT CATALOG [ReadInSearch]');
        """;

    /// <summary>
    /// After the migrations: creates what is missing when full-text is installed (a database migrated before the server
    /// had it), then picks the engine. Any SQL error (no permission for the DDL, say) leaves the LIKE fallback.
    /// </summary>
    public static async Task ConfigureAsync(IServiceProvider services, CancellationToken ct = default)
    {
        var state = services.GetRequiredService<SearchEngineState>();
        var wanted = services.GetRequiredService<IConfiguration>()["Search:Engine"]?.Trim().ToLowerInvariant() ?? "auto";
        var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger(typeof(SearchEngineSetup));
        if (wanted == "like")
        {
            state.Kind = SearchEngineKind.Like;
            SearchLog.Engine(logger, state.Kind, "Search:Engine = like");
            return;
        }

        var db = services.GetRequiredService<AppDbContext>();
        try
        {
            var installed = await IsInstalledAsync(db, ct);
            if (installed) await db.Database.ExecuteSqlRawAsync(CreateSql, ct);
            state.Kind = installed && await IsReadyAsync(db, ct) ? SearchEngineKind.FullText : SearchEngineKind.Like;
            SearchLog.Engine(logger, state.Kind, state.Kind == SearchEngineKind.FullText ? "full-text indexes found"
                : installed ? "the full-text indexes are missing" : "this SQL Server has no Full-Text Search");
        }
        catch (SqlException exception)
        {
            state.Kind = SearchEngineKind.Like;
            SearchLog.SetupFailed(logger, exception);
        }

        if (wanted == "fulltext" && state.Kind != SearchEngineKind.FullText) SearchLog.FullTextUnavailable(logger);
    }

    /// <summary>Whether the server has Full-Text Search.</summary>
    public static async Task<bool> IsInstalledAsync(AppDbContext db, CancellationToken ct) =>
        await db.Database.SqlQueryRaw<int>("SELECT CAST(ISNULL(SERVERPROPERTY('IsFullTextInstalled'), 0) AS int) AS [Value]")
            .SingleAsync(ct) == 1;

    /// <summary>Whether both full-text indexes exist (they may still be populating).</summary>
    public static async Task<bool> IsReadyAsync(AppDbContext db, CancellationToken ct) =>
        await db.Database.SqlQueryRaw<int>("""
            SELECT COUNT(*) AS [Value] FROM sys.fulltext_indexes
            WHERE object_id IN (OBJECT_ID(N'dbo.ArticleTranslations'), OBJECT_ID(N'dbo.MediaAssets'))
            """).SingleAsync(ct) == 2;
}

internal static partial class SearchLog
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Search engine: {Kind} ({Reason})")]
    public static partial void Engine(ILogger logger, SearchEngineKind kind, string reason);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Full-text search could not be set up; searching with LIKE")]
    public static partial void SetupFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Search:Engine asks for full-text, but it isn't available on this SQL Server; searching with LIKE")]
    public static partial void FullTextUnavailable(ILogger logger);
}
