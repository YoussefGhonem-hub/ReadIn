using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class Moderation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "HiddenAt",
                table: "Articles",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "HiddenById",
                table: "Articles",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ModerationActions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Action = table.Column<string>(type: "varchar(32)", unicode: false, maxLength: 32, nullable: false),
                    TargetType = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    TargetId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TargetUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ModeratorId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    TargetLabel = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Note = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    SuspendedUntil = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ReportsClosed = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    NoticeKind = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: true),
                    AcknowledgedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ModerationActions", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ModerationActions_ModeratorId_CreatedAt",
                table: "ModerationActions",
                columns: new[] { "ModeratorId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ModerationActions_Notices",
                table: "ModerationActions",
                columns: new[] { "TargetUserId", "AcknowledgedAt" },
                filter: "[NoticeKind] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_ModerationActions_TargetType_TargetId_CreatedAt",
                table: "ModerationActions",
                columns: new[] { "TargetType", "TargetId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ModerationActions_TargetUserId_CreatedAt",
                table: "ModerationActions",
                columns: new[] { "TargetUserId", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ModerationActions");

            migrationBuilder.DropColumn(
                name: "HiddenAt",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "HiddenById",
                table: "Articles");
        }
    }
}
