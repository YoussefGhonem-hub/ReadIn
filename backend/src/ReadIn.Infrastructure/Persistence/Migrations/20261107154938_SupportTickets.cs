using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SupportTickets : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SupportTickets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Number = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Category = table.Column<string>(type: "varchar(16)", unicode: false, maxLength: 16, nullable: false),
                    Subject = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false, collation: "Arabic_100_CI_AI"),
                    Status = table.Column<byte>(type: "tinyint", nullable: false),
                    Platform = table.Column<string>(type: "varchar(8)", unicode: false, maxLength: 8, nullable: true),
                    OsVersion = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: true),
                    AppVersion = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: true),
                    Language = table.Column<string>(type: "varchar(2)", unicode: false, maxLength: 2, nullable: true),
                    Screen = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastUserMessageAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastAdminReplyAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ClosedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ClosedById = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ClosedBy = table.Column<byte>(type: "tinyint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportTickets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SupportTickets_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SupportMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TicketId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AuthorId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    FromSupport = table.Column<bool>(type: "bit", nullable: false),
                    IsInternalNote = table.Column<bool>(type: "bit", nullable: false),
                    Body = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SupportMessages_SupportTickets_TicketId",
                        column: x => x.TicketId,
                        principalTable: "SupportTickets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SupportAttachments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MessageId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Position = table.Column<byte>(type: "tinyint", nullable: false),
                    FilePath = table.Column<string>(type: "varchar(200)", unicode: false, maxLength: 200, nullable: false),
                    ContentType = table.Column<string>(type: "varchar(16)", unicode: false, maxLength: 16, nullable: false),
                    SizeBytes = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportAttachments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SupportAttachments_SupportMessages_MessageId",
                        column: x => x.MessageId,
                        principalTable: "SupportMessages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SupportAttachments_MessageId",
                table: "SupportAttachments",
                column: "MessageId");

            migrationBuilder.CreateIndex(
                name: "IX_SupportMessages_AuthorId",
                table: "SupportMessages",
                column: "AuthorId");

            migrationBuilder.CreateIndex(
                name: "IX_SupportMessages_TicketId_CreatedAt",
                table: "SupportMessages",
                columns: new[] { "TicketId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_Number",
                table: "SupportTickets",
                column: "Number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_Status_ClosedAt",
                table: "SupportTickets",
                columns: new[] { "Status", "ClosedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_Status_LastAdminReplyAt",
                table: "SupportTickets",
                columns: new[] { "Status", "LastAdminReplyAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_Status_LastUserMessageAt",
                table: "SupportTickets",
                columns: new[] { "Status", "LastUserMessageAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_UserId_CreatedAt",
                table: "SupportTickets",
                columns: new[] { "UserId", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SupportAttachments");

            migrationBuilder.DropTable(
                name: "SupportMessages");

            migrationBuilder.DropTable(
                name: "SupportTickets");
        }
    }
}
