using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ReadingStats : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "StartedAt",
                table: "ReadingProgress",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            // Rows from before this column: the earliest time we know of is the last report. Through EXEC because a SQL
            // script compiles the whole migration as one batch, before the new column exists.
            migrationBuilder.Sql("EXEC(N'UPDATE [ReadingProgress] SET [StartedAt] = [UpdatedAt];');");

            migrationBuilder.CreateTable(
                name: "ReadingDays",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    ArticlesRead = table.Column<int>(type: "int", nullable: false),
                    ActiveSeconds = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReadingDays", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ReadingDays_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserStats",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CurrentStreak = table.Column<int>(type: "int", nullable: false),
                    LongestStreak = table.Column<int>(type: "int", nullable: false),
                    LastReadDate = table.Column<DateOnly>(type: "date", nullable: true),
                    LastFreezeDate = table.Column<DateOnly>(type: "date", nullable: true),
                    TotalArticles = table.Column<int>(type: "int", nullable: false),
                    TotalSeconds = table.Column<int>(type: "int", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserStats", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_UserStats_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ReadingDays_UserId_Date",
                table: "ReadingDays",
                columns: new[] { "UserId", "Date" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ReadingDays");

            migrationBuilder.DropTable(
                name: "UserStats");

            migrationBuilder.DropColumn(
                name: "StartedAt",
                table: "ReadingProgress");
        }
    }
}
