using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Users;

public sealed class UserTests
{
    private static readonly Guid MemberRole = Guid.CreateVersion7();

    private static User NewUser() =>
        User.Register("uid-1", "Reader.One@ReadIn.test", "Reader One", "reader_one", null, MemberRole);

    [Fact]
    public void Register_normalizes_email_assigns_member_and_raises_event()
    {
        var user = NewUser();

        user.Email.Should().Be("reader.one@readin.test");
        user.HasRole(MemberRole).Should().BeTrue();
        user.UiLanguage.Should().Be(UiLanguages.Arabic);
        user.ReminderTime.Should().Be(new TimeOnly(8, 0));
        user.DomainEvents.Should().ContainSingle(e => e is UserRegisteredDomainEvent);
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
    public void Username_rules(string username, bool valid) => User.IsValidUsername(username).Should().Be(valid);

    [Theory]
    [InlineData("reviewer.dotnet@readin.test", "reviewer_dotnet")]
    [InlineData("a@x.com", "reader_a")]
    [InlineData("Ahmed.Ali+news@gmail.com", "ahmed_ali_news")]
    public void Suggested_usernames_are_valid(string email, string expected)
    {
        var suggestion = User.SuggestUsername(email);

        suggestion.Should().Be(expected);
        User.IsValidUsername(suggestion).Should().BeTrue();
    }

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
        var role = Guid.CreateVersion7();
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
        var now = new DateTime(2026, 11, 2, 0, 0, 0, DateTimeKind.Utc);

        user.Suspend(until: now.AddDays(3));

        user.IsSuspendedAt(now).Should().BeTrue();
        user.IsSuspendedAt(now.AddDays(4)).Should().BeFalse();
    }

    [Fact]
    public void Registering_the_same_device_token_only_refreshes_it()
    {
        var user = NewUser();
        var now = DateTime.UtcNow;

        user.RegisterDevice("token", DevicePlatform.Android, now);
        user.RegisterDevice("token", DevicePlatform.Android, now.AddHours(1));

        user.Devices.Should().ContainSingle().Which.LastSeenAt.Should().Be(now.AddHours(1));
    }
}
