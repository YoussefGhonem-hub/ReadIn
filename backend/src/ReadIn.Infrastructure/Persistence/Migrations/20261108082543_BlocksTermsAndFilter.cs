using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class BlocksTermsAndFilter : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reports_ReporterId_TargetType_TargetId",
                table: "Reports");

            migrationBuilder.AddColumn<bool>(
                name: "IsReviewAccount",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "TermsAcceptedAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TermsVersion",
                table: "Users",
                type: "varchar(16)",
                unicode: false,
                maxLength: 16,
                nullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "ReporterId",
                table: "Reports",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AddColumn<string>(
                name: "MatchedTerms",
                table: "Reports",
                type: "nvarchar(400)",
                maxLength: 400,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ContentFilterTerms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Term = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NormalizedTerm = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false, collation: "Latin1_General_100_BIN2"),
                    Language = table.Column<string>(type: "varchar(2)", unicode: false, maxLength: 2, nullable: false),
                    Level = table.Column<byte>(type: "tinyint", nullable: false),
                    Source = table.Column<byte>(type: "tinyint", nullable: false),
                    IsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    CustomizedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ContentFilterTerms", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserBlocks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BlockerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BlockedId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserBlocks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserBlocks_Users_BlockedId",
                        column: x => x.BlockedId,
                        principalTable: "Users",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_UserBlocks_Users_BlockerId",
                        column: x => x.BlockerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Reports_ReporterId_TargetType_TargetId",
                table: "Reports",
                columns: new[] { "ReporterId", "TargetType", "TargetId" },
                unique: true,
                filter: "[ReporterId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_System_Target",
                table: "Reports",
                columns: new[] { "TargetType", "TargetId" },
                unique: true,
                filter: "[ReporterId] IS NULL");

            migrationBuilder.CreateIndex(
                name: "IX_ContentFilterTerms_NormalizedTerm",
                table: "ContentFilterTerms",
                column: "NormalizedTerm",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserBlocks_BlockedId_BlockerId",
                table: "UserBlocks",
                columns: new[] { "BlockedId", "BlockerId" });

            migrationBuilder.CreateIndex(
                name: "IX_UserBlocks_BlockerId_BlockedId",
                table: "UserBlocks",
                columns: new[] { "BlockerId", "BlockedId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ContentFilterTerms");

            migrationBuilder.DropTable(
                name: "UserBlocks");

            migrationBuilder.DropIndex(
                name: "IX_Reports_ReporterId_TargetType_TargetId",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Reports_System_Target",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "IsReviewAccount",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TermsAcceptedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TermsVersion",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "MatchedTerms",
                table: "Reports");

            migrationBuilder.AlterColumn<Guid>(
                name: "ReporterId",
                table: "Reports",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reports_ReporterId_TargetType_TargetId",
                table: "Reports",
                columns: new[] { "ReporterId", "TargetType", "TargetId" },
                unique: true);
        }
    }
}
