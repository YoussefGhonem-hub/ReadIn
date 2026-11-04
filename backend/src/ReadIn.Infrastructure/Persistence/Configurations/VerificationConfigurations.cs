using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;
using ReadIn.Domain.Verification;

namespace ReadIn.Infrastructure.Persistence.Configurations;

// Writer verification (SPEC F19, §16.2). Deleting a user deletes their requests (UserId cascade; AccountEraser deletes
// the proof files). DecidedById has no foreign key: a second cascade path from Users, which SQL Server refuses; account
// deletion nulls it instead.

internal sealed class VerificationRequestConfiguration : IEntityTypeConfiguration<VerificationRequest>
{
    public const string OnePendingPerUserIndex = "IX_VerificationRequests_UserId_Pending";

    public void Configure(EntityTypeBuilder<VerificationRequest> builder)
    {
        builder.ToTable("VerificationRequests");
        builder.HasKey(r => r.Id);
        builder.Property(r => r.JobTitle).HasMaxLength(VerificationRequest.MaxJobTitleLength).IsRequired();
        builder.Property(r => r.ProofUrl).HasMaxLength(VerificationRequest.MaxProofUrlLength);
        builder.Property(r => r.ProofFilePath).HasMaxLength(VerificationRequest.MaxProofPathLength).IsUnicode(false);
        builder.Property(r => r.ProofFileContentType).HasMaxLength(40).IsUnicode(false);
        builder.Property(r => r.ProofFileName).HasMaxLength(VerificationRequest.MaxProofFileNameLength);
        builder.Property(r => r.Note).HasMaxLength(VerificationRequest.MaxNoteLength);
        builder.Property(r => r.RejectionReason).HasMaxLength(VerificationRequest.MaxRejectionReasonLength);
        // A concurrency token: two admins deciding at once, or a withdrawal racing a decision, can't both win.
        builder.Property(r => r.Status).HasConversion<string>().HasMaxLength(20).IsUnicode(false).IsConcurrencyToken();
        builder.Ignore(r => r.IsPending);
        builder.Ignore(r => r.HasProofFile);

        // The admin queue: pending oldest first, decided newest first.
        builder.HasIndex(r => new { r.Status, r.SubmittedAt });
        // GET /me/verification: the user's latest request.
        builder.HasIndex(r => new { r.UserId, r.SubmittedAt });
        // At most one pending request per user, even with two submits at once.
        builder.HasIndex(r => r.UserId, OnePendingPerUserIndex).IsUnique().HasFilter("[Status] = 'Pending'");

        builder.HasOne<User>().WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Field>().WithMany().HasForeignKey(r => r.FieldId).OnDelete(DeleteBehavior.NoAction);
    }
}
