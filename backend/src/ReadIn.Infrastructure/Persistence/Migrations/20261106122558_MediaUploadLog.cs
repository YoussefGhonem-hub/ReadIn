using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class MediaUploadLog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MediaUploads",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MediaUploads", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MediaUploads_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MediaUploads_UserId_CreatedAt",
                table: "MediaUploads",
                columns: new[] { "UserId", "CreatedAt" });

            // The daily quota counts this log from now on (contract-v1 "Media"): the uploads of the last two days that still
            // exist are logged once, keyed by their asset id, so the quota holds right after the update. Through EXEC: an
            // idempotent script compiles this batch even where the table doesn't exist yet.
            migrationBuilder.Sql("""
                EXEC(N'INSERT INTO [MediaUploads] ([Id], [UserId], [CreatedAt])
                SELECT m.[Id], m.[OwnerId], m.[CreatedAt]
                FROM [MediaAssets] m
                WHERE m.[OwnerId] IS NOT NULL
                  AND m.[CreatedAt] >= DATEADD(day, -2, SYSUTCDATETIME())
                  AND NOT EXISTS (SELECT 1 FROM [MediaUploads] u WHERE u.[Id] = m.[Id]);');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MediaUploads");
        }
    }
}
