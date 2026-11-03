using Mediator;
using Microsoft.AspNetCore.Mvc;
using ReadIn.Api.Auth;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Admin.Users;
using ReadIn.Application.Features.Users;
using ReadIn.Application.Features.Users.Commands.AddPhoneSignIn;
using ReadIn.Application.Features.Users.Commands.ChangePassword;
using ReadIn.Application.Features.Users.Commands.ChangePhoneNumber;
using ReadIn.Application.Features.Users.Commands.CompleteProfile;
using ReadIn.Application.Features.Users.Commands.DeleteAccount;
using ReadIn.Application.Features.Users.Commands.ExternalLogins;
using ReadIn.Application.Features.Users.Commands.RecoveryPin;
using ReadIn.Application.Features.Users.Commands.RegisterDevice;
using ReadIn.Application.Features.Users.Commands.UnregisterDevice;
using ReadIn.Application.Features.Users.Commands.UpdateInterests;
using ReadIn.Application.Features.Users.Commands.UpdatePreferences;
using ReadIn.Application.Features.Users.Commands.UpdateProfile;
using ReadIn.Application.Features.Users.Queries.CheckUsername;
using ReadIn.Application.Features.Users.Queries.GetMe;

namespace ReadIn.Api.Endpoints;

internal sealed class MeEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var me = api.MapGroup("/me").RequireAuthorization().WithTags("Me");

        me.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMeQuery(), ct)).ToHttp(http))
            .WithSummary("The signed-in user's profile, preferences, account flags, roles and permissions")
            .Produces<MeDto>();

        me.MapPatch("/", async (UpdateProfileRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body.ToCommand(), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Update profile (name, @username, bio, links, avatar upload, fields of expertise)");

        me.MapDelete("/", async ([FromBody] DeleteAccountCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(body, ct);
                if (result.IsSuccess) RefreshCookie.Clear(http);
                return result.ToHttp(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Delete the account (password, or Google/Apple for accounts without one); personal data is removed after 30 days");

        me.MapPut("/profile/complete", async (CompleteProfileCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("After sign up: display name, @username and optional avatar")
            .Produces<MeDto>();

        me.MapPut("/password", async (ChangePasswordCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToSession(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Change the password; other sessions are signed out and this one gets fresh tokens")
            .Produces<SessionResponse>();

        me.MapPut("/phone", async (ChangePhoneNumberCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToSession(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Change the phone number (requires the password); other sessions are signed out")
            .Produces<SessionResponse>();

        me.MapPost("/phone-sign-in", async (AddPhoneSignInCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToSession(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Google/Apple accounts: add phone + password + recovery PIN; other sessions are signed out")
            .Produces<SessionResponse>();

        me.MapPost("/external-logins", async (LinkExternalLoginCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Link Google or Apple (confirmed with the password or an already linked provider)")
            .Produces<MeDto>();

        me.MapDelete("/external-logins/{provider}", async (string provider, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UnlinkExternalLoginCommand(provider), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Unlink Google or Apple; refused when it's the only way to sign in")
            .Produces<MeDto>();

        me.MapPost("/recovery-pin", async (SetRecoveryPinCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Set the first recovery PIN (accounts with mustSetRecoveryPin)")
            .Produces<MeDto>();

        me.MapPut("/recovery-pin", async (ChangeRecoveryPinCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Change the recovery PIN (requires the password)");

        me.MapPut("/preferences", async (UpdatePreferencesCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Update UI/article language, theme, time zone and reminder time");

        me.MapPut("/interests", async (UpdateInterestsCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Replace followed fields/topics (at least 3)");

        me.MapPost("/devices", async (RegisterDeviceCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Register an FCM device token for push notifications");

        me.MapDelete("/devices/{token}", async (string token, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UnregisterDeviceCommand(token), ct)).ToHttp(http))
            .WithSummary("Stop push notifications to a device (on sign out)");
    }
}

internal sealed class UserEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/users/username-available", async (string? u, ISender sender, CancellationToken ct) =>
                TypedResults.Ok(await sender.Send(new CheckUsernameQuery(u), ct)))
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.UsernameCheck)
            .WithTags("Users")
            .WithSummary("Live @username check (format + availability)")
            .Produces<UsernameAvailabilityDto>();
    }
}

internal sealed class AdminUserEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var users = api.MapGroup("/admin/users").RequireAuthorization().WithTags("Admin");

        users.MapPost("/{id:guid}/reset-password", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new ResetUserPasswordCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("\"Forgot the PIN too\": temporary password, PIN cleared, sessions revoked (users.reset_password)")
            .Produces<TemporaryPasswordDto>();
    }
}

/// <summary>
/// Body of PATCH /me (SPEC F14). The avatar is changed only when the body names it: <c>avatarAssetId</c> (an upload with
/// purpose avatar) sets it and an explicit <c>null</c> removes it; <c>avatarUrl</c> is still accepted from the previous
/// release. Omitting both keeps the avatar; omitting <c>expertiseFieldIds</c> keeps the fields of expertise.
/// </summary>
internal sealed class UpdateProfileRequest
{
    // Set only by the JSON deserializer when the property is in the body, null included.
    private Guid? _avatarAssetId;
    private bool _avatarAssetIdSent;
    private string? _avatarUrl;
    private bool _avatarUrlSent;

    public string DisplayName { get; init; } = default!;
    public string Username { get; init; } = default!;
    public string? Bio { get; init; }
    public UserLinksDto? Links { get; init; }

    public Guid? AvatarAssetId
    {
        get => _avatarAssetId;
        init { _avatarAssetId = value; _avatarAssetIdSent = true; }
    }

    /// <summary>Previous release: an uploaded avatar's URL or an external https image; null removes the avatar.</summary>
    public string? AvatarUrl
    {
        get => _avatarUrl;
        init { _avatarUrl = value; _avatarUrlSent = true; }
    }

    public IReadOnlyList<Guid>? ExpertiseFieldIds { get; init; }

    public UpdateProfileCommand ToCommand() => new(DisplayName, Username, Bio, Links, Avatar(), ExpertiseFieldIds);

    private AvatarChange? Avatar() => (_avatarAssetId, _avatarUrlSent, _avatarAssetIdSent) switch
    {
        ({ } assetId, _, _) => new AvatarChange(assetId, null),
        (null, true, _) => new AvatarChange(null, _avatarUrl),
        (null, false, true) => AvatarChange.Remove,
        _ => null,
    };
}
