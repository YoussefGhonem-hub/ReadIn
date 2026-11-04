using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AccountHardDelete : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AnonymizedAt",
                table: "Users");

            migrationBuilder.AddColumn<string>(
                name: "ProviderClientId",
                table: "UserExternalLogins",
                type: "varchar(255)",
                unicode: false,
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProviderRefreshToken",
                table: "UserExternalLogins",
                type: "varchar(2048)",
                unicode: false,
                maxLength: 2048,
                nullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "OwnerId",
                table: "MediaAssets",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AlterColumn<Guid>(
                name: "AuthorId",
                table: "Articles",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ProviderClientId",
                table: "UserExternalLogins");

            migrationBuilder.DropColumn(
                name: "ProviderRefreshToken",
                table: "UserExternalLogins");

            migrationBuilder.AddColumn<DateTime>(
                name: "AnonymizedAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "OwnerId",
                table: "MediaAssets",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "AuthorId",
                table: "Articles",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);
        }
    }
}
