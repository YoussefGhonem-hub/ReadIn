using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Users;

public sealed class UserTests
{
    private static readonly Guid MemberRole = Guid.NewGuid();
    private static readonly DateTime Now = new(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc);

    private static User NewUser() => User.Register("+12015550101", "password-hash", "reader_abc123", MemberRole);

    [Fact]
    public void Register_starts_an_incomplete_profile_that_must_set_a_pin()
    {
        var user = NewUser();

        user.PhoneNumber.Should().Be("+12015550101");
        user.Username.Should().Be("reader_abc123");
        user.IsProfileComplete.Should().BeFalse();
        user.MustSetRecoveryPin.Should().BeTrue("the handler sets the PIN right after EF Core assigns the id");
        user.CanSignIn.Should().BeTrue();
        user.SecurityStamp.Should().NotBeNullOrWhiteSpace();
        user.HasRole(MemberRole).Should().BeTrue();
        user.UiLanguage.Should().Be(UiLanguages.Arabic);
        user.ReminderTime.Should().Be(new TimeOnly(8, 0));
        user.DomainEvents.Should().ContainSingle(e => e is UserRegisteredDomainEvent);
    }

    [Fact]
    public void Setting_the_pin_clears_the_requirement()
    {
        var user = NewUser();

        user.SetRecoveryPin("pin-hash", Now);

        user.HasRecoveryPin.Should().BeTrue();
        user.MustSetRecoveryPin.Should().BeFalse();
        user.RecoveryPinSetAt.Should().Be(Now);
    }

    [Fact]
    public void Complete_profile_validates_the_username()
    {
        var user = NewUser();

        user.CompleteProfile("Reader One", "Bad Name", null).Error.Should().Be(UserErrors.InvalidUsername);
        user.IsProfileComplete.Should().BeFalse();

        user.CompleteProfile("  Reader One ", "reader_one", "/uploads/avatars/2026/11/x_512.webp").IsSuccess.Should().BeTrue();
        user.IsProfileComplete.Should().BeTrue();
        user.DisplayName.Should().Be("Reader One");
    }

    [Fact]
    public void Five_wrong_passwords_lock_sign_in_for_15_minutes()
    {
        var user = NewUser();

        for (var i = 0; i < 4; i++) user.RecordFailedSignIn(Now).Should().BeFalse();
        user.RecordFailedSignIn(Now).Should().BeTrue();

        user.IsLockedOutAt(Now.AddMinutes(14)).Should().BeTrue();
        user.IsLockedOutAt(Now.AddMinutes(15)).Should().BeFalse();
        user.FailedLoginCount.Should().Be(0, "the counter starts over after a lockout");
    }

    [Fact]
    public void A_successful_sign_in_resets_the_counter()
    {
        var user = NewUser();
        user.RecordFailedSignIn(Now);
        user.RecordFailedSignIn(Now);

        user.RecordSuccessfulSignIn();

        user.FailedLoginCount.Should().Be(0);
        user.LockoutEndAt.Should().BeNull();
    }

    [Fact]
    public void Five_wrong_pins_lock_recovery_for_an_hour()
    {
        var user = NewUser();

        for (var i = 0; i < 4; i++) user.RecordFailedRecovery(Now).Should().BeFalse();
        user.RecordFailedRecovery(Now).Should().BeTrue();

        user.IsRecoveryLockedAt(Now.AddMinutes(59)).Should().BeTrue();
        user.IsRecoveryLockedAt(Now.AddHours(1)).Should().BeFalse();
        user.RecoveryDisabled.Should().BeFalse();
        user.DomainEvents.OfType<UserSecurityChangedDomainEvent>().Should().ContainSingle(e => e.Change == SecurityChange.RecoveryLockedOut);
    }

    [Fact]
    public void The_third_recovery_lockout_within_7_days_disables_recovery()
    {
        var user = NewUser();

        LockRecovery(user, Now);
        LockRecovery(user, Now.AddDays(2));
        user.RecoveryDisabled.Should().BeFalse();
        LockRecovery(user, Now.AddDays(6));

        user.RecoveryDisabled.Should().BeTrue();
    }

    [Fact]
    public void Lockouts_more_than_7_days_apart_start_a_new_window()
    {
        var user = NewUser();

        LockRecovery(user, Now);
        LockRecovery(user, Now.AddDays(2));
        LockRecovery(user, Now.AddDays(10));

        user.RecoveryDisabled.Should().BeFalse();
        user.RecoveryLockoutCount.Should().Be(1);
    }

    [Fact]
    public void Credential_changes_rotate_the_security_stamp()
    {
        var user = NewUser();
        var stamps = new List<string> { user.SecurityStamp };

        user.ChangePassword("new-hash");
        stamps.Add(user.SecurityStamp);
        user.ChangePhoneNumber("+12015550102");
        stamps.Add(user.SecurityStamp);
        user.ResetPassword("reset-hash");
        stamps.Add(user.SecurityStamp);
        user.RotateSecurityStamp();
        stamps.Add(user.SecurityStamp);

        stamps.Should().OnlyHaveUniqueItems();
        user.DomainEvents.OfType<UserSecurityChangedDomainEvent>().Select(e => e.Change)
            .Should().Equal(SecurityChange.PasswordChanged, SecurityChange.PhoneNumberChanged, SecurityChange.PasswordReset);
    }

    [Fact]
    public void Password_reset_clears_every_lockout()
    {
        var user = NewUser();
        for (var i = 0; i < 5; i++) user.RecordFailedSignIn(Now);
        user.RecordFailedRecovery(Now);

        user.ResetPassword("reset-hash");

        user.IsLockedOutAt(Now).Should().BeFalse();
        user.RecoveryFailedCount.Should().Be(0);
    }

    [Fact]
    public void Admin_reset_forces_a_new_password_and_pin_and_reenables_recovery()
    {
        var user = NewUser();
        user.SetRecoveryPin("pin-hash", Now);
        LockRecovery(user, Now);
        LockRecovery(user, Now);
        LockRecovery(user, Now);
        var stamp = user.SecurityStamp;

        user.ResetByAdmin("temporary-hash");

        user.MustChangePassword.Should().BeTrue();
        user.MustSetRecoveryPin.Should().BeTrue();
        user.HasRecoveryPin.Should().BeFalse();
        user.RecoveryDisabled.Should().BeFalse();
        user.IsRecoveryLockedAt(Now).Should().BeFalse();
        user.SecurityStamp.Should().NotBe(stamp);
    }

    [Fact]
    public void Require_recovery_pin_only_flags_accounts_without_one()
    {
        var withPin = NewUser();
        withPin.SetRecoveryPin("pin-hash", Now);
        withPin.RequireRecoveryPin();
        withPin.MustSetRecoveryPin.Should().BeFalse();

        var seeded = User.CreateSeeded("+12025550119", "Reader 10", "reader10");
        seeded.RequireRecoveryPin();
        seeded.MustSetRecoveryPin.Should().BeTrue();
    }

    [Fact]
    public void Onboarding_needs_at_least_three_interests()
    {
        var user = NewUser();

        user.SetInterests([Guid.NewGuid(), Guid.NewGuid()], []).Error.Should().Be(UserErrors.InterestsMinThree);
        user.OnboardingCompleted.Should().BeFalse();

        user.SetInterests([Guid.NewGuid(), Guid.NewGuid()], [Guid.NewGuid()]).IsSuccess.Should().BeTrue();
        user.OnboardingCompleted.Should().BeTrue();
    }

    [Fact]
    public void Duplicate_interests_do_not_count_twice()
    {
        var field = Guid.NewGuid();

        NewUser().SetInterests([field, field, field], []).Error.Should().Be(UserErrors.InterestsMinThree);
    }

    [Theory]
    [InlineData("reader_1", true)]
    [InlineData("ab", false)]
    [InlineData("Reader", false)]
    [InlineData("قارئ", false)]
    [InlineData("a_very_long_username_that_exceeds_30", false)]
    [InlineData("suggested", false)]
    public void Username_rules(string username, bool valid) => User.IsValidUsername(username).Should().Be(valid);

    [Fact]
    public void Preferences_validate_languages()
    {
        var user = NewUser();

        user.SetPreferences("fr", "en", ThemePreference.Dark, "Africa/Cairo", new TimeOnly(7, 0)).Error.Should().Be(UserErrors.InvalidLanguage);
        user.SetPreferences("en", "ar-EG", ThemePreference.Dark, "Africa/Cairo", new TimeOnly(7, 0)).IsSuccess.Should().BeTrue();
        user.ThemePref.Should().Be(ThemePreference.Dark);
    }

    [Fact]
    public void Granting_a_role_twice_is_idempotent()
    {
        var user = NewUser();
        var role = Guid.NewGuid();
        user.ClearDomainEvents();

        user.GrantRole(role);
        user.GrantRole(role);

        user.Roles.Count(r => r.RoleId == role).Should().Be(1);
        user.DomainEvents.Should().ContainSingle(e => e is UserRolesChangedDomainEvent);
    }

    [Fact]
    public void Temporary_suspension_expires()
    {
        var user = NewUser();

        user.Suspend(until: Now.AddDays(3));

        user.IsSuspendedAt(Now).Should().BeTrue();
        user.IsSuspendedAt(Now.AddDays(4)).Should().BeFalse();
    }

    [Fact]
    public void Registering_the_same_device_token_only_refreshes_it()
    {
        var user = NewUser();

        user.RegisterDevice("token", DevicePlatform.Android, Now);
        user.RegisterDevice("token", DevicePlatform.Android, Now.AddHours(1));

        user.Devices.Should().ContainSingle().Which.LastSeenAt.Should().Be(Now.AddHours(1));
        user.UnregisterDevice("token").Should().BeTrue();
        user.UnregisterDevice("token").Should().BeFalse();
    }

    [Fact]
    public void The_verified_badge_is_not_a_role_and_keeps_its_first_date()
    {
        var user = NewUser();
        user.IsVerified.Should().BeFalse();

        user.Verify(Now);
        user.Verify(Now.AddDays(3));

        (user.IsVerified, user.VerifiedAt).Should().Be((true, (DateTime?)Now), "approving again keeps the first date");
        user.Roles.Select(r => r.RoleId).Should().Equal([MemberRole], "the badge changes no role (SPEC §10.1)");
        user.DomainEvents.Should().NotContain(e => e is UserRolesChangedDomainEvent);

        user.RemoveVerification().Should().BeTrue();
        (user.IsVerified, user.VerifiedAt).Should().Be((false, (DateTime?)null));
        user.RemoveVerification().Should().BeFalse("there is no badge left to remove");
        user.HasRole(MemberRole).Should().BeTrue();
    }

    private static void LockRecovery(User user, DateTime at)
    {
        for (var i = 0; i < AccountSecurity.MaxFailedRecoveries; i++) user.RecordFailedRecovery(at);
    }
}
