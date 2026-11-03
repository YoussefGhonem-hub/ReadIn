using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

/// <summary>Token hashes are hex SHA-256 (64 characters); the tokens themselves are never stored (SPEC §9.3).</summary>
internal static class TokenHashColumn
{
    public const int Length = 64;
}

internal sealed class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.ToTable("RefreshTokens");
        builder.HasKey(t => t.Id);
        builder.Property(t => t.TokenHash).HasMaxLength(TokenHashColumn.Length).IsUnicode(false).IsFixedLength().IsRequired();
        builder.HasIndex(t => t.TokenHash).IsUnique();
        builder.HasIndex(t => new { t.UserId, t.RevokedAt });
        builder.HasIndex(t => t.FamilyId);
        builder.Property(t => t.CreatedByIp).HasMaxLength(45).IsUnicode(false);
        builder.Property(t => t.DeviceName).HasMaxLength(200);
        builder.HasOne<User>().WithMany().HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class PasswordResetTokenConfiguration : IEntityTypeConfiguration<PasswordResetToken>
{
    public void Configure(EntityTypeBuilder<PasswordResetToken> builder)
    {
        builder.ToTable("PasswordResetTokens");
        builder.HasKey(t => t.Id);
        builder.Property(t => t.TokenHash).HasMaxLength(TokenHashColumn.Length).IsUnicode(false).IsFixedLength().IsRequired();
        builder.HasIndex(t => t.TokenHash).IsUnique();
        builder.Property(t => t.CreatedByIp).HasMaxLength(45).IsUnicode(false);
        builder.HasOne<User>().WithMany().HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class RecoveryAttemptConfiguration : IEntityTypeConfiguration<RecoveryAttempt>
{
    public void Configure(EntityTypeBuilder<RecoveryAttempt> builder)
    {
        builder.ToTable("RecoveryAttempts");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.PhoneNumberHash).HasMaxLength(TokenHashColumn.Length).IsUnicode(false).IsFixedLength().IsRequired();
        builder.Property(a => a.Ip).HasMaxLength(45).IsUnicode(false);
        // Per-number limit: attempts for one number in the last hour (SPEC §9.5).
        builder.HasIndex(a => new { a.PhoneNumberHash, a.CreatedAt });
        builder.HasIndex(a => a.CreatedAt);
        builder.HasOne<User>().WithMany().HasForeignKey(a => a.UserId).OnDelete(DeleteBehavior.SetNull);
    }
}

internal sealed class AuditLogConfiguration : IEntityTypeConfiguration<AuditLog>
{
    public void Configure(EntityTypeBuilder<AuditLog> builder)
    {
        // No foreign keys: the log outlives what it describes.
        builder.ToTable("AuditLogs");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Action).HasMaxLength(64).IsUnicode(false).IsRequired();
        builder.Property(a => a.Ip).HasMaxLength(45).IsUnicode(false);
        builder.HasIndex(a => new { a.UserId, a.CreatedAt });
        builder.HasIndex(a => a.CreatedAt);
    }
}
