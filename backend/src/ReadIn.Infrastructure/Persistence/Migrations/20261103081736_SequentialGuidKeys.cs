using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReadIn.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// No schema change: Guid keys are now generated client-side by EF Core's sequential GUID generator (ADR 0006)
    /// instead of Guid.CreateVersion7() in the domain. This migration records that in the model snapshot.
    /// </summary>
    public partial class SequentialGuidKeys : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
