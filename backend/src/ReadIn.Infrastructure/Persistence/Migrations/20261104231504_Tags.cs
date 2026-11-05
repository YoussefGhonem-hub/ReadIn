using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class Tags : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Slug",
                table: "Tags",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(64)",
                oldMaxLength: 64);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Tags",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<Guid>(
                name: "CreatedById",
                table: "Tags",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmptySince",
                table: "Tags",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsHidden",
                table: "Tags",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsSystem",
                table: "Tags",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "NormalizedName",
                table: "Tags",
                type: "nvarchar(64)",
                maxLength: 64,
                nullable: false,
                defaultValue: "",
                collation: "Latin1_General_100_BIN2");

            migrationBuilder.AddColumn<int>(
                name: "Position",
                table: "ArticleTags",
                type: "int",
                nullable: false,
                defaultValue: 0);

            // Tags made before F32 (SPEC F32). Their age is their first article's (merges keep the oldest), and their
            // names, slugs and origin are fixed in C# by LegacyTagsUpgrade right after the migrations: until then the
            // placeholder ('~' + id) keeps NormalizedName and Slug unique, and marks the rows to upgrade.
            migrationBuilder.Sql("""
                UPDATE [t] SET
                    [CreatedAt] = COALESCE(
                        (SELECT MIN([a].[CreatedAt]) FROM [ArticleTags] AS [at] INNER JOIN [Articles] AS [a] ON [a].[Id] = [at].[ArticleId] WHERE [at].[TagId] = [t].[Id]),
                        SYSUTCDATETIME()),
                    [NormalizedName] = N'~' + LOWER(CONVERT(nvarchar(36), [t].[Id])),
                    [Slug] = N'~' + LOWER(CONVERT(nvarchar(36), [t].[Id]))
                FROM [Tags] AS [t];
                """);

            // The writer's order was not stored before; cards showed tags by id, so that order stays.
            migrationBuilder.Sql("""
                WITH [ordered] AS (
                    SELECT [Position], ROW_NUMBER() OVER (PARTITION BY [ArticleId] ORDER BY [TagId]) - 1 AS [N] FROM [ArticleTags])
                UPDATE [ordered] SET [Position] = [N];
                """);

            migrationBuilder.CreateIndex(
                name: "IX_Tags_CreatedById_CreatedAt",
                table: "Tags",
                columns: new[] { "CreatedById", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Tags_NormalizedName",
                table: "Tags",
                column: "NormalizedName",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Tags_CreatedById_CreatedAt",
                table: "Tags");

            migrationBuilder.DropIndex(
                name: "IX_Tags_NormalizedName",
                table: "Tags");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Tags");

            migrationBuilder.DropColumn(
                name: "CreatedById",
                table: "Tags");

            migrationBuilder.DropColumn(
                name: "EmptySince",
                table: "Tags");

            migrationBuilder.DropColumn(
                name: "IsHidden",
                table: "Tags");

            migrationBuilder.DropColumn(
                name: "IsSystem",
                table: "Tags");

            migrationBuilder.DropColumn(
                name: "NormalizedName",
                table: "Tags");

            migrationBuilder.DropColumn(
                name: "Position",
                table: "ArticleTags");

            migrationBuilder.AlterColumn<string>(
                name: "Slug",
                table: "Tags",
                type: "nvarchar(64)",
                maxLength: 64,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);
        }
    }
}
