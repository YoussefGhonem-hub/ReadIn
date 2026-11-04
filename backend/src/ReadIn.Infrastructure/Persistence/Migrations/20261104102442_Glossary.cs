using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class Glossary : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "GlossaryTerms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Slug = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    TermEn = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false, collation: "Arabic_100_CI_AI"),
                    DefinitionEn = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: false),
                    ExplanationAr = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GlossaryTerms", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ArticleTerms",
                columns: table => new
                {
                    ArticleId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TermId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ArticleTerms", x => new { x.ArticleId, x.TermId });
                    table.ForeignKey(
                        name: "FK_ArticleTerms_Articles_ArticleId",
                        column: x => x.ArticleId,
                        principalTable: "Articles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ArticleTerms_GlossaryTerms_TermId",
                        column: x => x.TermId,
                        principalTable: "GlossaryTerms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ArticleTerms_TermId",
                table: "ArticleTerms",
                column: "TermId");

            migrationBuilder.CreateIndex(
                name: "IX_GlossaryTerms_Slug",
                table: "GlossaryTerms",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_GlossaryTerms_TermEn",
                table: "GlossaryTerms",
                column: "TermEn");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ArticleTerms");

            migrationBuilder.DropTable(
                name: "GlossaryTerms");
        }
    }
}
