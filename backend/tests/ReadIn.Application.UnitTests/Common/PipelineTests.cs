using Mapster;
using Mediator;
using NSubstitute;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Users.Commands.UpdateInterests;
using ReadIn.Application.Features.Users.Commands.UpdatePreferences;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.UnitTests.Common;

public sealed class MappingTests
{
    [Fact]
    public void Mapster_configuration_compiles() // SPEC §6.4 / §27: fail fast on bad mapping configs
    {
        var config = DependencyInjection.CreateMapperConfig();

        Action compile = () => config.Compile();

        compile.Should().NotThrow();
    }
}

public sealed class ValidatorTests
{
    [Fact]
    public void Preferences_validator_reports_codes_per_field()
    {
        var result = new UpdatePreferencesCommandValidator().Validate(
            new UpdatePreferencesCommand("fr", "ar-EG", ThemePreference.Dark, "Mars/Base", "25:00"));

        result.Errors.Select(e => (e.PropertyName, e.ErrorCode)).Should().BeEquivalentTo(new[]
        {
            ("UiLanguage", "user.language_invalid"),
            ("TimeZone", "user.timezone_invalid"),
            ("ReminderTime", "user.reminder_time_invalid"),
        });
    }

    [Fact]
    public void Preferences_validator_accepts_iana_time_zones()
    {
        new UpdatePreferencesCommandValidator()
            .Validate(new UpdatePreferencesCommand("ar", "ar-EG", ThemePreference.System, "Africa/Cairo", "08:00"))
            .IsValid.Should().BeTrue();
    }

    [Fact]
    public void Interests_validator_requires_three()
    {
        var result = new UpdateInterestsCommandValidator().Validate(new UpdateInterestsCommand([Guid.NewGuid()], [Guid.NewGuid()]));

        var error = ValidationErrors.From(result.Errors);
        error.Details!["interests"].Should().Equal("user.interests.min_three");
    }
}

public sealed class AuthorizationBehaviorTests
{
    [RequirePermission(Permissions.Articles.Create)]
    public sealed record WriteCommand : ICommand<Result<int>>;

    [Authenticated]
    public sealed record MeQuery : IQuery<Result<int>>;

    public sealed record OpenQuery : IQuery<Result<int>>;

    private static readonly MessageHandlerDelegate<WriteCommand, Result<int>> WriteOk = (_, _) => ValueTask.FromResult(Result.Success(1));
    private static readonly MessageHandlerDelegate<MeQuery, Result<int>> MeOk = (_, _) => ValueTask.FromResult(Result.Success(1));

    private static ICurrentUser User(bool authenticated, Guid? userId = null, params string[] permissions)
    {
        var user = Substitute.For<ICurrentUser>();
        user.IsAuthenticated.Returns(authenticated);
        user.UserId.Returns(userId);
        user.Permissions.Returns(permissions.ToHashSet());
        return user;
    }

    private static IUserAccessService Access(params string[] guestPermissions)
    {
        var access = Substitute.For<IUserAccessService>();
        access.GetGuestPermissionsAsync(Arg.Any<CancellationToken>()).Returns(guestPermissions.ToHashSet());
        return access;
    }

    [Fact]
    public async Task Guest_without_the_permission_is_unauthorized()
    {
        var behavior = new AuthorizationBehavior<WriteCommand, Result<int>>(User(false), Access(Permissions.Articles.Read));

        var result = await behavior.Handle(new WriteCommand(), WriteOk, CancellationToken.None);

        result.Error.Should().Be(AuthErrors.Unauthorized);
    }

    [Fact]
    public async Task Signed_in_user_without_the_permission_is_forbidden()
    {
        var behavior = new AuthorizationBehavior<WriteCommand, Result<int>>(User(true, Guid.NewGuid(), Permissions.Articles.Read), Access());

        var result = await behavior.Handle(new WriteCommand(), WriteOk, CancellationToken.None);

        result.Error.Should().Be(AuthErrors.Forbidden);
    }

    [Fact]
    public async Task Signed_in_user_with_the_permission_passes()
    {
        var behavior = new AuthorizationBehavior<WriteCommand, Result<int>>(User(true, Guid.NewGuid(), Permissions.Articles.Create), Access());

        var result = await behavior.Handle(new WriteCommand(), WriteOk, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task Authenticated_messages_need_a_user_id()
    {
        var behavior = new AuthorizationBehavior<MeQuery, Result<int>>(User(true, userId: null), Access());

        var result = await behavior.Handle(new MeQuery(), MeOk, CancellationToken.None);

        result.Error.Should().Be(AuthErrors.Unauthorized);
    }

    [Fact]
    public async Task Messages_without_requirements_are_open()
    {
        var behavior = new AuthorizationBehavior<OpenQuery, Result<int>>(User(false), Access());

        var result = await behavior.Handle(new OpenQuery(), (_, _) => ValueTask.FromResult(Result.Success(7)), CancellationToken.None);

        result.Value.Should().Be(7);
    }
}

public sealed class RoleMatrixTests
{
    [Fact]
    public void Matrix_only_uses_known_permissions() =>
        RoleMatrix.Roles.SelectMany(r => r.Permissions).Should().OnlyContain(p => Permissions.All.ContainsKey(p));

    [Fact]
    public void Only_super_admin_has_system_settings() =>
        RoleMatrix.Roles.Where(r => r.Permissions.Contains(Permissions.System.Settings)).Select(r => r.Name)
            .Should().Equal(RoleNames.SuperAdmin);

    [Fact]
    public void Guests_can_only_read() =>
        RoleMatrix.Roles.Single(r => r.Name == RoleNames.Guest).Permissions.Should().Equal(Permissions.Articles.Read);

    [Fact]
    public void The_only_roles_are_guest_member_and_super_admin() =>
        RoleMatrix.Roles.Select(r => r.Name).Should().Equal(RoleNames.Guest, RoleNames.Member, RoleNames.SuperAdmin);

    [Fact]
    public void The_super_admin_moderates_suspends_verifies_and_has_every_permission()
    {
        var superAdmin = RoleMatrix.Roles.Single(r => r.Name == RoleNames.SuperAdmin).Permissions;

        superAdmin.Should().Contain([Permissions.Moderation.Manage, Permissions.Users.Suspend, Permissions.Verification.Manage]);
        superAdmin.Should().BeEquivalentTo(Permissions.All.Keys);
    }

    [Fact]
    public void Members_have_no_staff_permissions_and_nobody_manages_roles()
    {
        var member = RoleMatrix.Roles.Single(r => r.Name == RoleNames.Member).Permissions;

        member.Should().NotContain([
            Permissions.Moderation.Manage, Permissions.Users.Suspend, Permissions.Users.ResetPassword, Permissions.Users.ReadPii,
            Permissions.Verification.Manage, Permissions.Taxonomy.Manage, Permissions.Paths.Manage, Permissions.Articles.Feature,
            Permissions.System.Settings,
        ]);
        Permissions.All.Keys.Should().NotContain("roles.manage", "roles are not managed (SPEC §10)");
    }

    [Fact]
    public void Every_member_may_write_and_publish_and_there_is_no_reviewer_role()
    {
        RoleMatrix.Roles.Where(r => r.Name != RoleNames.Guest).Should()
            .OnlyContain(r => r.Permissions.Contains(Permissions.Articles.Create), "anyone publishes in any field (ADR 0015)");
        RoleMatrix.Roles.Select(r => r.Name).Should().NotContain("Reviewer");
        Permissions.All.Keys.Should().NotContain(["articles.review", "articles.publish.sensitive"]);
    }
}
