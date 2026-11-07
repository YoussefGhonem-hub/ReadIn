using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AdminConsole : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SignUpMethod",
                table: "Users",
                type: "varchar(8)",
                unicode: false,
                maxLength: 8,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CustomizedAt",
                table: "Topics",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsEnabled",
                table: "Topics",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "CustomizedAt",
                table: "Fields",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HiddenWithAccount",
                table: "Comments",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Details",
                table: "AuditLogs",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "TargetId",
                table: "AuditLogs",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TargetType",
                table: "AuditLogs",
                type: "varchar(16)",
                unicode: false,
                maxLength: 16,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FeaturedAt",
                table: "Articles",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "FeaturedById",
                table: "Articles",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HiddenWithAccount",
                table: "Articles",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "Announcements",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TitleAr = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    TitleEn = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    BodyAr = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    BodyEn = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    LinkType = table.Column<string>(type: "varchar(8)", unicode: false, maxLength: 8, nullable: true),
                    LinkId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    AudienceType = table.Column<string>(type: "varchar(8)", unicode: false, maxLength: 8, nullable: false),
                    FieldId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Language = table.Column<string>(type: "varchar(5)", unicode: false, maxLength: 5, nullable: true),
                    SentById = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    LocalDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Status = table.Column<byte>(type: "tinyint", nullable: false),
                    RecipientCount = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Announcements", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "JobRuns",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Job = table.Column<string>(type: "varchar(64)", unicode: false, maxLength: 64, nullable: false),
                    StartedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DurationMs = table.Column<int>(type: "int", nullable: false),
                    Succeeded = table.Column<bool>(type: "bit", nullable: false),
                    Error = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobRuns", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "PushDeliveryStats",
                columns: table => new
                {
                    Hour = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Sent = table.Column<int>(type: "int", nullable: false),
                    Failed = table.Column<int>(type: "int", nullable: false),
                    InvalidTokens = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PushDeliveryStats", x => x.Hour);
                });

            migrationBuilder.CreateTable(
                name: "SearchMisses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Language = table.Column<string>(type: "varchar(2)", unicode: false, maxLength: 2, nullable: false),
                    Query = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false, collation: "Latin1_General_100_BIN2"),
                    Count = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SearchMisses", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TagAliases",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TagId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false, collation: "Arabic_100_CI_AI"),
                    NormalizedName = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false, collation: "Latin1_General_100_BIN2"),
                    Slug = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TagAliases", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TagAliases_Tags_TagId",
                        column: x => x.TagId,
                        principalTable: "Tags",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserPresence",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LastSeenAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserPresence", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_UserPresence_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_CreatedAt",
                table: "Users",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Reposts_CreatedAt",
                table: "Reposts",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_ReadingProgress_CompletedAt",
                table: "ReadingProgress",
                column: "CompletedAt",
                filter: "[CompletedAt] IS NOT NULL")
                .Annotation("SqlServer:Include", new[] { "UserId", "ArticleId" });

            migrationBuilder.CreateIndex(
                name: "IX_Reactions_ReactedAt",
                table: "Reactions",
                column: "ReactedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Comments_CreatedAt",
                table: "Comments",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_ActorId_CreatedAt",
                table: "AuditLogs",
                columns: new[] { "ActorId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_TargetType_TargetId_CreatedAt",
                table: "AuditLogs",
                columns: new[] { "TargetType", "TargetId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Articles_FeaturedAt",
                table: "Articles",
                column: "FeaturedAt",
                descending: new bool[0],
                filter: "[FeaturedAt] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Announcements_CreatedAt",
                table: "Announcements",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Announcements_LocalDate",
                table: "Announcements",
                column: "LocalDate",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobRuns_Job_StartedAt",
                table: "JobRuns",
                columns: new[] { "Job", "StartedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_JobRuns_StartedAt",
                table: "JobRuns",
                column: "StartedAt");

            migrationBuilder.CreateIndex(
                name: "IX_SearchMisses_Date_Language_Query",
                table: "SearchMisses",
                columns: new[] { "Date", "Language", "Query" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TagAliases_NormalizedName",
                table: "TagAliases",
                column: "NormalizedName",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TagAliases_Slug",
                table: "TagAliases",
                column: "Slug",
                unique: true,
                filter: "[Slug] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_TagAliases_TagId",
                table: "TagAliases",
                column: "TagId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPresence_LastSeenAt",
                table: "UserPresence",
                column: "LastSeenAt");

            // Hand-written (SPEC F23). Existing topics are enabled (the column's default fits new rows only).
            migrationBuilder.Sql("EXEC(N'UPDATE [Topics] SET [IsEnabled] = 1');");

            // How existing accounts signed up, once: an external sign-up in the audit log → the provider of their oldest
            // Google/Apple link; system accounts none; every other account by phone. EXEC so the idempotent script compiles.
            migrationBuilder.Sql(
                """
                EXEC(N'
                UPDATE u SET [SignUpMethod] =
                    CASE
                        WHEN u.[IsSystemAccount] = 1 THEN NULL
                        WHEN EXISTS (SELECT 1 FROM [AuditLogs] a WHERE a.[UserId] = u.[Id] AND a.[Action] = ''auth.external_sign_up'')
                            THEN COALESCE((SELECT TOP 1 l.[Provider] FROM [UserExternalLogins] l WHERE l.[UserId] = u.[Id] ORDER BY l.[LinkedAt]), ''phone'')
                        WHEN u.[PhoneNumber] IS NULL
                            THEN COALESCE((SELECT TOP 1 l.[Provider] FROM [UserExternalLogins] l WHERE l.[UserId] = u.[Id] ORDER BY l.[LinkedAt]), ''phone'')
                        ELSE ''phone''
                    END
                FROM [Users] u
                WHERE u.[SignUpMethod] IS NULL');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Announcements");

            migrationBuilder.DropTable(
                name: "JobRuns");

            migrationBuilder.DropTable(
                name: "PushDeliveryStats");

            migrationBuilder.DropTable(
                name: "SearchMisses");

            migrationBuilder.DropTable(
                name: "TagAliases");

            migrationBuilder.DropTable(
                name: "UserPresence");

            migrationBuilder.DropIndex(
                name: "IX_Users_CreatedAt",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Reposts_CreatedAt",
                table: "Reposts");

            migrationBuilder.DropIndex(
                name: "IX_ReadingProgress_CompletedAt",
                table: "ReadingProgress");

            migrationBuilder.DropIndex(
                name: "IX_Reactions_ReactedAt",
                table: "Reactions");

            migrationBuilder.DropIndex(
                name: "IX_Comments_CreatedAt",
                table: "Comments");

            migrationBuilder.DropIndex(
                name: "IX_AuditLogs_ActorId_CreatedAt",
                table: "AuditLogs");

            migrationBuilder.DropIndex(
                name: "IX_AuditLogs_TargetType_TargetId_CreatedAt",
                table: "AuditLogs");

            migrationBuilder.DropIndex(
                name: "IX_Articles_FeaturedAt",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "SignUpMethod",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CustomizedAt",
                table: "Topics");

            migrationBuilder.DropColumn(
                name: "IsEnabled",
                table: "Topics");

            migrationBuilder.DropColumn(
                name: "CustomizedAt",
                table: "Fields");

            migrationBuilder.DropColumn(
                name: "HiddenWithAccount",
                table: "Comments");

            migrationBuilder.DropColumn(
                name: "Details",
                table: "AuditLogs");

            migrationBuilder.DropColumn(
                name: "TargetId",
                table: "AuditLogs");

            migrationBuilder.DropColumn(
                name: "TargetType",
                table: "AuditLogs");

            migrationBuilder.DropColumn(
                name: "FeaturedAt",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "FeaturedById",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "HiddenWithAccount",
                table: "Articles");
        }
    }
}
