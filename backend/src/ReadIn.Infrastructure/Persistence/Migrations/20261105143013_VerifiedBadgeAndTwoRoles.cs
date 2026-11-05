using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class VerifiedBadgeAndTwoRoles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsVerified",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "VerifiedAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            // Roles change (SPEC §10, 2026-11-05): an account is a Member or the SuperAdmin, and Verified is a badge.
            // The steps that read or write the new columns run through EXEC: `dotnet ef migrations script` (plain or
            // --idempotent) writes the whole migration as one batch, and SQL Server binds an existing table's columns
            // when it compiles a batch, before the ALTER TABLE above has run ("Invalid column name 'IsVerified'").
            // EXEC compiles its text only when it runs. Quotes inside are doubled.
            // 1. Whoever had the VerifiedWriter role (a003) gets the badge, dated by their latest approved request, or now.
            migrationBuilder.Sql("""
                EXEC(N'UPDATE u SET u.[IsVerified] = 1, u.[VerifiedAt] = COALESCE(
                    (SELECT MAX(v.[DecidedAt]) FROM [VerificationRequests] v WHERE v.[UserId] = u.[Id] AND v.[Status] = ''Approved''),
                    SYSUTCDATETIME())
                FROM [Users] u
                WHERE EXISTS (SELECT 1 FROM [UserRoles] ur WHERE ur.[UserId] = u.[Id] AND ur.[RoleId] = ''0195f3a0-0000-7000-8000-00000000a003'');');
                """);

            // 2. VerifiedWriter (a003), Moderator (a005) and Admin (a006) go, with who had them and their permissions, and
            //    so does roles.manage. The role seeder keeps it that way on every start.
            migrationBuilder.Sql("""
                DELETE FROM [UserRoles] WHERE [RoleId] IN ('0195f3a0-0000-7000-8000-00000000a003', '0195f3a0-0000-7000-8000-00000000a005', '0195f3a0-0000-7000-8000-00000000a006');
                DELETE FROM [RolePermissions] WHERE [RoleId] IN ('0195f3a0-0000-7000-8000-00000000a003', '0195f3a0-0000-7000-8000-00000000a005', '0195f3a0-0000-7000-8000-00000000a006');
                DELETE FROM [Roles] WHERE [Id] IN ('0195f3a0-0000-7000-8000-00000000a003', '0195f3a0-0000-7000-8000-00000000a005', '0195f3a0-0000-7000-8000-00000000a006');
                DELETE FROM [RolePermissions] WHERE [PermissionId] IN (SELECT [Id] FROM [Permissions] WHERE [Code] = 'roles.manage');
                DELETE FROM [Permissions] WHERE [Code] = 'roles.manage';
                """);

            // 3. Every account left without a role is a Member (a002), e.g. the old demo admin and moderator.
            migrationBuilder.Sql("""
                INSERT INTO [UserRoles] ([UserId], [RoleId])
                SELECT u.[Id], '0195f3a0-0000-7000-8000-00000000a002' FROM [Users] u
                WHERE NOT EXISTS (SELECT 1 FROM [UserRoles] ur WHERE ur.[UserId] = u.[Id])
                  AND EXISTS (SELECT 1 FROM [Roles] r WHERE r.[Id] = '0195f3a0-0000-7000-8000-00000000a002');
                """);

            // 4. The official @readin account (e001) stays a Member, with the badge.
            migrationBuilder.Sql("""
                EXEC(N'UPDATE [Users] SET [IsVerified] = 1, [VerifiedAt] = COALESCE([VerifiedAt], SYSUTCDATETIME())
                WHERE [Id] = ''0195f3a0-0000-7000-8000-00000000e001'';');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Best effort: the badge back as the VerifiedWriter role (the previous role seeder gives it its permissions).
            // Who was an Admin or a Moderator is not known any more. Through EXEC for the same reason as in Up: an
            // idempotent script compiles this batch even where the columns are already gone.
            migrationBuilder.Sql("""
                EXEC(N'IF NOT EXISTS (SELECT 1 FROM [Roles] WHERE [Id] = ''0195f3a0-0000-7000-8000-00000000a003'')
                    INSERT INTO [Roles] ([Id], [Name], [Description])
                    VALUES (''0195f3a0-0000-7000-8000-00000000a003'', ''VerifiedWriter'', ''Identity/expertise verified writer (badge only; anyone may publish).'');
                INSERT INTO [UserRoles] ([UserId], [RoleId])
                SELECT u.[Id], ''0195f3a0-0000-7000-8000-00000000a003'' FROM [Users] u
                WHERE u.[IsVerified] = 1
                  AND NOT EXISTS (SELECT 1 FROM [UserRoles] ur WHERE ur.[UserId] = u.[Id] AND ur.[RoleId] = ''0195f3a0-0000-7000-8000-00000000a003'');');
                """);

            migrationBuilder.DropColumn(
                name: "IsVerified",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "VerifiedAt",
                table: "Users");
        }
    }
}
