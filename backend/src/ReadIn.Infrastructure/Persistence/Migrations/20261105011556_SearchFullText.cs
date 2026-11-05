using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Search (F16, SPEC §16.3, §22): the full-text catalog <c>ReadInSearch</c> and full-text indexes on
    /// <c>ArticleTranslations(SearchText)</c> and <c>MediaAssets(ExtractedText)</c>, only when the server has Full-Text
    /// Search (<c>SERVERPROPERTY('IsFullTextInstalled')</c>); otherwise nothing, and the API searches with its LIKE
    /// fallback. Full-text DDL can't run in a transaction. Kept in step with <c>SearchEngineSetup.CreateSql</c>, which
    /// runs at startup too (a database migrated before its server had full-text).
    /// </summary>
    public partial class SearchFullText : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                IF CAST(ISNULL(SERVERPROPERTY('IsFullTextInstalled'), 0) AS int) = 1
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'ReadInSearch')
                        EXEC(N'CREATE FULLTEXT CATALOG [ReadInSearch]');
                    IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.ArticleTranslations'))
                        EXEC(N'CREATE FULLTEXT INDEX ON [dbo].[ArticleTranslations] ([SearchText] LANGUAGE 1025) KEY INDEX [PK_ArticleTranslations] ON [ReadInSearch] WITH (CHANGE_TRACKING = AUTO, STOPLIST = OFF)');
                    IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.MediaAssets'))
                        EXEC(N'CREATE FULLTEXT INDEX ON [dbo].[MediaAssets] ([ExtractedText] LANGUAGE 1025) KEY INDEX [PK_MediaAssets] ON [ReadInSearch] WITH (CHANGE_TRACKING = AUTO, STOPLIST = OFF)');
                END
                """, suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                IF EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.MediaAssets'))
                    EXEC(N'DROP FULLTEXT INDEX ON [dbo].[MediaAssets]');
                IF EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.ArticleTranslations'))
                    EXEC(N'DROP FULLTEXT INDEX ON [dbo].[ArticleTranslations]');
                IF EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'ReadInSearch')
                    EXEC(N'DROP FULLTEXT CATALOG [ReadInSearch]');
                """, suppressTransaction: true);
        }
    }
}
