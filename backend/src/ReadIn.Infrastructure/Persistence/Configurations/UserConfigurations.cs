using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ReadIn.Domain.Authorization;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Configurations;

internal sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");
        builder.HasKey(u => u.Id);

        builder.Property(u => u.FirebaseUid).HasMaxLength(128).IsRequired();
        builder.HasIndex(u => u.FirebaseUid).IsUnique();

        builder.Property(u => u.Email).HasMaxLength(320).IsRequired();
        builder.HasIndex(u => u.Email).IsUnique();

        builder.Property(u => u.DisplayName).HasMaxLength(60).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.Property(u => u.Username).HasMaxLength(30).UseCollation(AppDbContext.SearchCollation).IsRequired();
        builder.HasIndex(u => u.Username).IsUnique();

        builder.Property(u => u.AvatarUrl).HasMaxLength(2048);
        builder.Property(u => u.Bio).HasMaxLength(300);
        builder.ComplexProperty(u => u.Links, links => links.ToJson());

        builder.Property(u => u.UiLanguage).HasMaxLength(5).IsRequired();
        builder.Property(u => u.ArticleLanguagePref).HasMaxLength(5).IsRequired();
        builder.Property(u => u.ThemePref).HasConversion<string>().HasMaxLength(10);
        builder.Property(u => u.TimeZone).HasMaxLength(64).IsRequired();

        builder.Ignore(u => u.OnboardingCompleted);

        builder.HasMany(u => u.Roles).WithOne().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(u => u.Interests).WithOne().HasForeignKey(i => i.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(u => u.Devices).WithOne().HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class UserRoleConfiguration : IEntityTypeConfiguration<UserRole>
{
    public void Configure(EntityTypeBuilder<UserRole> builder)
    {
        builder.ToTable("UserRoles");
        builder.HasKey(r => new { r.UserId, r.RoleId });
        builder.HasOne<Role>().WithMany().HasForeignKey(r => r.RoleId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class UserInterestConfiguration : IEntityTypeConfiguration<UserInterest>
{
    public void Configure(EntityTypeBuilder<UserInterest> builder)
    {
        builder.ToTable("UserInterests", t =>
            t.HasCheckConstraint("CK_UserInterests_Target", "([FieldId] IS NOT NULL AND [TopicId] IS NULL) OR ([FieldId] IS NULL AND [TopicId] IS NOT NULL)"));
        builder.HasKey(i => i.Id);
        // Exactly one target is set (check above), so uniqueness needs one filtered index per target.
        builder.HasIndex(i => new { i.UserId, i.FieldId }).IsUnique().HasFilter("[FieldId] IS NOT NULL");
        builder.HasIndex(i => new { i.UserId, i.TopicId }).IsUnique().HasFilter("[TopicId] IS NOT NULL");
        // NoAction avoids multiple cascade paths (Fields → Topics → UserInterests).
        builder.HasOne<Field>().WithMany().HasForeignKey(i => i.FieldId).OnDelete(DeleteBehavior.NoAction);
        builder.HasOne<Topic>().WithMany().HasForeignKey(i => i.TopicId).OnDelete(DeleteBehavior.NoAction);
    }
}

internal sealed class UserDeviceConfiguration : IEntityTypeConfiguration<UserDevice>
{
    public void Configure(EntityTypeBuilder<UserDevice> builder)
    {
        builder.ToTable("UserDevices");
        builder.HasKey(d => d.Id);
        builder.Property(d => d.Token).HasMaxLength(4096).IsRequired();
        builder.Property(d => d.Platform).HasConversion<string>().HasMaxLength(10);
        builder.HasIndex(d => d.UserId);
    }
}

internal sealed class ReviewerFieldConfiguration : IEntityTypeConfiguration<ReviewerField>
{
    public void Configure(EntityTypeBuilder<ReviewerField> builder)
    {
        builder.ToTable("ReviewerFields");
        builder.HasKey(r => new { r.UserId, r.FieldId });
        builder.HasOne<User>().WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Field>().WithMany().HasForeignKey(r => r.FieldId).OnDelete(DeleteBehavior.NoAction);
    }
}

internal sealed class RoleConfiguration : IEntityTypeConfiguration<Role>
{
    public void Configure(EntityTypeBuilder<Role> builder)
    {
        builder.ToTable("Roles");
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Name).HasMaxLength(50).IsRequired();
        builder.HasIndex(r => r.Name).IsUnique();
        builder.Property(r => r.Description).HasMaxLength(300);
        builder.HasMany(r => r.Permissions).WithOne().HasForeignKey(p => p.RoleId).OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class PermissionConfiguration : IEntityTypeConfiguration<Permission>
{
    public void Configure(EntityTypeBuilder<Permission> builder)
    {
        builder.ToTable("Permissions");
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Code).HasMaxLength(100).IsRequired();
        builder.HasIndex(p => p.Code).IsUnique();
        builder.Property(p => p.Description).HasMaxLength(300);
    }
}

internal sealed class RolePermissionConfiguration : IEntityTypeConfiguration<RolePermission>
{
    public void Configure(EntityTypeBuilder<RolePermission> builder)
    {
        builder.ToTable("RolePermissions");
        builder.HasKey(p => new { p.RoleId, p.PermissionId });
        builder.HasOne<Permission>().WithMany().HasForeignKey(p => p.PermissionId).OnDelete(DeleteBehavior.Cascade);
    }
}
