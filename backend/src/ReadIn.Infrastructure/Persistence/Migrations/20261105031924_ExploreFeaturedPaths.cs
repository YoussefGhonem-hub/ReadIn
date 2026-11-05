using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ExploreFeaturedPaths : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "FeaturedOrder",
                table: "LearningPaths",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsFeatured",
                table: "LearningPaths",
                type: "bit",
                nullable: false,
                defaultValue: false);

            // Explore's "Featured paths" (F15) starts with the editorial paths, in their sort order; new editorial paths
            // are created featured by the seeder, and F23 will manage the flag. Through EXEC because a SQL script compiles
            // the whole migration as one batch, before the new columns exist.
            migrationBuilder.Sql("EXEC(N'UPDATE [LearningPaths] SET [IsFeatured] = 1, [FeaturedOrder] = [SortOrder] WHERE [IsEditorial] = 1;');");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FeaturedOrder",
                table: "LearningPaths");

            migrationBuilder.DropColumn(
                name: "IsFeatured",
                table: "LearningPaths");
        }
    }
}
