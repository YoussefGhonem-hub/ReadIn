using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class PostCardExcerpts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Excerpt",
                table: "ArticleTranslations",
                type: "nvarchar(400)",
                maxLength: 400,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ExcerptHasMore",
                table: "ArticleTranslations",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Excerpt",
                table: "ArticleTranslations");

            migrationBuilder.DropColumn(
                name: "ExcerptHasMore",
                table: "ArticleTranslations");
        }
    }
}
