using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RepostsFeedCandidatesIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reposts_UserId_CreatedAt",
                table: "Reposts");

            migrationBuilder.CreateIndex(
                name: "IX_Reposts_UserId_CreatedAt",
                table: "Reposts",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true })
                .Annotation("SqlServer:Include", new[] { "ArticleId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reposts_UserId_CreatedAt",
                table: "Reposts");

            migrationBuilder.CreateIndex(
                name: "IX_Reposts_UserId_CreatedAt",
                table: "Reposts",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });
        }
    }
}
