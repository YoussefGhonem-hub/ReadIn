using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class OpenPublishingAndEditor : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ADR 0015 removed review and scheduling. Anything that was waiting in that flow is a draft again.
            migrationBuilder.Sql("UPDATE [Articles] SET [Status] = 'Draft' WHERE [Status] NOT IN ('Draft', 'Published', 'Archived');");

            // The Reviewer role and its permissions are gone (the role seeder only adds and updates).
            migrationBuilder.Sql("""
                DECLARE @reviewer uniqueidentifier = '0195f3a0-0000-7000-8000-00000000a004';
                DELETE FROM [RolePermissions]
                WHERE [RoleId] = @reviewer
                   OR [PermissionId] IN (SELECT [Id] FROM [Permissions] WHERE [Code] IN ('articles.review', 'articles.publish.sensitive'));
                DELETE FROM [UserRoles] WHERE [RoleId] = @reviewer;
                DELETE FROM [Roles] WHERE [Id] = @reviewer;
                DELETE FROM [Permissions] WHERE [Code] IN ('articles.review', 'articles.publish.sensitive');
                """);

            // A revision is now the whole editor document of one publish (F05). The old per-language rows only came from
            // content re-imports, which git already versions, and their JSON is not a document: they go.
            migrationBuilder.Sql("DELETE FROM [ArticleRevisions];");

            migrationBuilder.DropForeignKey(
                name: "FK_Articles_Users_ReviewedById",
                table: "Articles");

            migrationBuilder.DropTable(
                name: "ReviewerFields");

            migrationBuilder.DropIndex(
                name: "IX_Articles_ReviewedById",
                table: "Articles");

            migrationBuilder.DropCheckConstraint(
                name: "CK_ArticleRevisions_ContentJson_IsJson",
                table: "ArticleRevisions");

            migrationBuilder.DropColumn(
                name: "LastReviewedAt",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "ReviewStatus",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "ReviewedById",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "ScheduledAt",
                table: "Articles");

            migrationBuilder.DropColumn(
                name: "Language",
                table: "ArticleRevisions");

            migrationBuilder.DropColumn(
                name: "Subtitle",
                table: "ArticleRevisions");

            migrationBuilder.RenameColumn(
                name: "ContentJson",
                table: "ArticleRevisions",
                newName: "DocumentJson");

            migrationBuilder.AlterColumn<Guid>(
                name: "CreatedBy",
                table: "ArticleRevisions",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AddColumn<string>(
                name: "Languages",
                table: "ArticleRevisions",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "ArticleDrafts",
                columns: table => new
                {
                    ArticleId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DocumentJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Version = table.Column<int>(type: "int", nullable: false),
                    HasChanges = table.Column<bool>(type: "bit", nullable: false),
                    SavedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ArticleDrafts", x => x.ArticleId);
                    table.CheckConstraint("CK_ArticleDrafts_DocumentJson_IsJson", "ISJSON([DocumentJson]) = 1");
                    table.ForeignKey(
                        name: "FK_ArticleDrafts_Articles_ArticleId",
                        column: x => x.ArticleId,
                        principalTable: "Articles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.AddCheckConstraint(
                name: "CK_ArticleRevisions_DocumentJson_IsJson",
                table: "ArticleRevisions",
                sql: "ISJSON([DocumentJson]) = 1");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ArticleDrafts");

            migrationBuilder.DropCheckConstraint(
                name: "CK_ArticleRevisions_DocumentJson_IsJson",
                table: "ArticleRevisions");

            migrationBuilder.DropColumn(
                name: "Languages",
                table: "ArticleRevisions");

            migrationBuilder.RenameColumn(
                name: "DocumentJson",
                table: "ArticleRevisions",
                newName: "ContentJson");

            migrationBuilder.AddColumn<DateTime>(
                name: "LastReviewedAt",
                table: "Articles",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReviewStatus",
                table: "Articles",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "ReviewedById",
                table: "Articles",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ScheduledAt",
                table: "Articles",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "CreatedBy",
                table: "ArticleRevisions",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Language",
                table: "ArticleRevisions",
                type: "nvarchar(5)",
                maxLength: 5,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Subtitle",
                table: "ArticleRevisions",
                type: "nvarchar(250)",
                maxLength: 250,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ReviewerFields",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FieldId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReviewerFields", x => new { x.UserId, x.FieldId });
                    table.ForeignKey(
                        name: "FK_ReviewerFields_Fields_FieldId",
                        column: x => x.FieldId,
                        principalTable: "Fields",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_ReviewerFields_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Articles_ReviewedById",
                table: "Articles",
                column: "ReviewedById");

            migrationBuilder.AddCheckConstraint(
                name: "CK_ArticleRevisions_ContentJson_IsJson",
                table: "ArticleRevisions",
                sql: "ISJSON([ContentJson]) = 1");

            migrationBuilder.CreateIndex(
                name: "IX_ReviewerFields_FieldId",
                table: "ReviewerFields",
                column: "FieldId");

            migrationBuilder.AddForeignKey(
                name: "FK_Articles_Users_ReviewedById",
                table: "Articles",
                column: "ReviewedById",
                principalTable: "Users",
                principalColumn: "Id");
        }
    }
}
