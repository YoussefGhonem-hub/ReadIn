using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ProfileLinksHeadlineAndReposts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Headline",
                table: "Users",
                type: "nvarchar(120)",
                maxLength: 120,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RepostCount",
                table: "Articles",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Reposts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ArticleId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reposts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reposts_Articles_ArticleId",
                        column: x => x.ArticleId,
                        principalTable: "Articles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reposts_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Reposts_ArticleId_CreatedAt",
                table: "Reposts",
                columns: new[] { "ArticleId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_Reposts_UserId_ArticleId",
                table: "Reposts",
                columns: new[] { "UserId", "ArticleId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reposts_UserId_CreatedAt",
                table: "Reposts",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            // F14: Users.Links was the object {"GitHub":…,"LinkedIn":…,"Website":…}; it becomes the ordered array
            // [{"platform":"github","url":…,"label":null}, …] (github, linkedin, website; empty values dropped). Rows that
            // already hold an array are left alone, so the script can run twice.
            migrationBuilder.Sql("""
                UPDATE u SET [Links] = COALESCE((
                    SELECT l.[platform], l.[url], CAST(NULL AS nvarchar(30)) AS [label]
                    FROM (VALUES
                        (1, N'github', JSON_VALUE(u.[Links], '$.GitHub')),
                        (2, N'linkedin', JSON_VALUE(u.[Links], '$.LinkedIn')),
                        (3, N'website', JSON_VALUE(u.[Links], '$.Website'))) AS l([order], [platform], [url])
                    WHERE NULLIF(LTRIM(RTRIM(l.[url])), N'') IS NOT NULL
                    ORDER BY l.[order]
                    FOR JSON PATH, INCLUDE_NULL_VALUES), N'[]')
                FROM [Users] AS u
                WHERE ISJSON(u.[Links]) = 1 AND LEFT(LTRIM(u.[Links]), 1) = N'{';
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Back to {"GitHub":…,"LinkedIn":…,"Website":…}; links of the other platforms can't be kept.
            migrationBuilder.Sql("""
                UPDATE u SET [Links] = (
                    SELECT
                        (SELECT TOP (1) JSON_VALUE(j.[value], '$.url') FROM OPENJSON(u.[Links]) AS j
                         WHERE JSON_VALUE(j.[value], '$.platform') = N'github') AS [GitHub],
                        (SELECT TOP (1) JSON_VALUE(j.[value], '$.url') FROM OPENJSON(u.[Links]) AS j
                         WHERE JSON_VALUE(j.[value], '$.platform') = N'linkedin') AS [LinkedIn],
                        (SELECT TOP (1) JSON_VALUE(j.[value], '$.url') FROM OPENJSON(u.[Links]) AS j
                         WHERE JSON_VALUE(j.[value], '$.platform') = N'website') AS [Website]
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                FROM [Users] AS u
                WHERE ISJSON(u.[Links]) = 1 AND LEFT(LTRIM(u.[Links]), 1) = N'[';
                """);

            migrationBuilder.DropTable(
                name: "Reposts");

            migrationBuilder.DropColumn(
                name: "Headline",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "RepostCount",
                table: "Articles");
        }
    }
}
