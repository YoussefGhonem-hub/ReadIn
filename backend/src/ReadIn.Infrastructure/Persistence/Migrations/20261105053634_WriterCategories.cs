using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class WriterCategories : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "WriterCategoryId",
                table: "Articles",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "WriterCategories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false, collation: "Arabic_100_CI_AI"),
                    NormalizedName = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false, collation: "Latin1_General_100_BIN2"),
                    Slug = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false, collation: "Latin1_General_100_BIN2"),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WriterCategories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WriterCategories_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Articles_WriterCategoryId_PublishedAt",
                table: "Articles",
                columns: new[] { "WriterCategoryId", "PublishedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_WriterCategories_UserId_NormalizedName",
                table: "WriterCategories",
                columns: new[] { "UserId", "NormalizedName" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WriterCategories_UserId_Slug",
                table: "WriterCategories",
                columns: new[] { "UserId", "Slug" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Articles_WriterCategories_WriterCategoryId",
                table: "Articles",
                column: "WriterCategoryId",
                principalTable: "WriterCategories",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Articles_WriterCategories_WriterCategoryId",
                table: "Articles");

            migrationBuilder.DropTable(
                name: "WriterCategories");

            migrationBuilder.DropIndex(
                name: "IX_Articles_WriterCategoryId_PublishedAt",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "WriterCategoryId",
                table: "Articles");
        }
    }
}
