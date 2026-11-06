using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RankingEngagementIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SavedArticles_ArticleId",
                table: "SavedArticles");

            migrationBuilder.DropIndex(
                name: "IX_ReadingProgress_ArticleId",
                table: "ReadingProgress");

            migrationBuilder.CreateIndex(
                name: "IX_SavedArticles_ArticleId_SavedAt",
                table: "SavedArticles",
                columns: new[] { "ArticleId", "SavedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ReadingProgress_ArticleId_CompletedAt",
                table: "ReadingProgress",
                columns: new[] { "ArticleId", "CompletedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SavedArticles_ArticleId_SavedAt",
                table: "SavedArticles");

            migrationBuilder.DropIndex(
                name: "IX_ReadingProgress_ArticleId_CompletedAt",
                table: "ReadingProgress");

            migrationBuilder.CreateIndex(
                name: "IX_SavedArticles_ArticleId",
                table: "SavedArticles",
                column: "ArticleId");

            migrationBuilder.CreateIndex(
                name: "IX_ReadingProgress_ArticleId",
                table: "ReadingProgress",
                column: "ArticleId");
        }
    }
}
