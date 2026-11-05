using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class Highlights : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "ShowHighlights",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: true);

            migrationBuilder.CreateTable(
                name: "ArticleHighlights",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ArticleId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Language = table.Column<string>(type: "varchar(5)", unicode: false, maxLength: 5, nullable: false),
                    BlockId = table.Column<string>(type: "varchar(64)", unicode: false, maxLength: 64, nullable: false, collation: "Latin1_General_100_BIN2"),
                    StartOffset = table.Column<int>(type: "int", nullable: false),
                    EndOffset = table.Column<int>(type: "int", nullable: false),
                    Text = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false, collation: "Latin1_General_100_BIN2"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ArticleHighlights", x => x.Id);
                    table.CheckConstraint("CK_ArticleHighlights_Range", "[StartOffset] >= 0 AND [EndOffset] > [StartOffset] AND [EndOffset] - [StartOffset] <= 1000");
                    table.ForeignKey(
                        name: "FK_ArticleHighlights_Articles_ArticleId",
                        column: x => x.ArticleId,
                        principalTable: "Articles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ArticleHighlights_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ArticleHighlights_ArticleId_Language_BlockId_StartOffset_EndOffset",
                table: "ArticleHighlights",
                columns: new[] { "ArticleId", "Language", "BlockId", "StartOffset", "EndOffset" })
                .Annotation("SqlServer:Include", new[] { "UserId" });

            migrationBuilder.CreateIndex(
                name: "IX_ArticleHighlights_UserId_ArticleId_Language_BlockId_StartOffset_EndOffset",
                table: "ArticleHighlights",
                columns: new[] { "UserId", "ArticleId", "Language", "BlockId", "StartOffset", "EndOffset" },
                unique: true)
                .Annotation("SqlServer:Include", new[] { "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ArticleHighlights");

            migrationBuilder.DropColumn(
                name: "ShowHighlights",
                table: "Users");
        }
    }
}
