using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class LearningPathEnrollments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsEditorial",
                table: "LearningPaths",
                type: "bit",
                nullable: false,
                defaultValue: false);

            // Every path so far came from content/taxonomy.yaml (seeder #7); version 2 of that seeder marks them too.
            // Through EXEC because a SQL script compiles the whole migration as one batch, before the new column exists.
            migrationBuilder.Sql("EXEC(N'UPDATE LearningPaths SET IsEditorial = 1;');");

            migrationBuilder.CreateTable(
                name: "PathEnrollments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PathId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    EnrolledAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastActivityAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PathEnrollments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PathEnrollments_LearningPaths_PathId",
                        column: x => x.PathId,
                        principalTable: "LearningPaths",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PathEnrollments_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PathEnrollments_PathId",
                table: "PathEnrollments",
                column: "PathId");

            migrationBuilder.CreateIndex(
                name: "IX_PathEnrollments_UserId_PathId",
                table: "PathEnrollments",
                columns: new[] { "UserId", "PathId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PathEnrollments");

            migrationBuilder.DropColumn(
                name: "IsEditorial",
                table: "LearningPaths");
        }
    }
}
