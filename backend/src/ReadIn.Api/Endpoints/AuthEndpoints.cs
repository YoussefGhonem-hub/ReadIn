using Mediator;
using ReadIn.Api.Auth;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Auth.Commands.ExternalSignIn;
using ReadIn.Application.Features.Auth.Commands.RefreshSession;
using ReadIn.Application.Features.Auth.Commands.Register;
using ReadIn.Application.Features.Auth.Commands.ResetPassword;
using ReadIn.Application.Features.Auth.Commands.SignIn;
using ReadIn.Application.Features.Auth.Commands.SignOut;
using ReadIn.Application.Features.Auth.Commands.SignOutEverywhere;
using ReadIn.Application.Features.Auth.Commands.VerifyRecoveryPin;
using ReadIn.Application.Features.Auth.Queries.GetAuthConfig;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// Phone + password or Google/Apple sign in, rotating refresh tokens and PIN recovery (SPEC §9, ADR 0007, ADR 0012).
/// </summary>
internal sealed class AuthEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var auth = api.MapGroup("/auth").WithTags("Auth").AllowAnonymous();

        auth.MapGet("/config", async (ISender sender, CancellationToken ct) => TypedResults.Ok(await sender.Send(new GetAuthConfigQuery(), ct)))
            .WithSummary("PIN length, password rules and the Google/Apple providers this server accepts");

        auth.MapPost("/register", async (RegisterCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToSession(http))
            .RequireRateLimiting(RateLimitPolicies.Register)
            .WithSummary("Create an account with phone, password and recovery PIN; signs in")
            .Produces<SessionResponse>();

        auth.MapPost("/login", async (SignInCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToSession(http))
            .RequireRateLimiting(RateLimitPolicies.SignIn)
            .WithSummary("Sign in with phone and password")
            .Produces<SessionResponse>();

        auth.MapPost("/external", async (ExternalSignInCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToSession(http))
            .RequireRateLimiting(RateLimitPolicies.SignIn)
            .WithSummary("Continue with Google or Apple: signs in, links by verified email or phone + password, or creates an account")
            .Produces<SessionResponse>();

        auth.MapPost("/refresh", async (RefreshTokenRequest? body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RefreshSessionCommand(RefreshCookie.Read(http, body), body?.RetryKey), ct)).ToSession(http))
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Rotate the refresh token (body on mobile, cookie on the web) and get a new access token; "
                + "an optional retryKey lets the same client repeat a refresh whose answer was lost")
            .Produces<SessionResponse>();

        auth.MapPost("/logout", async (RefreshTokenRequest? body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new SignOutCommand(RefreshCookie.Read(http, body)), ct);
                RefreshCookie.Clear(http);
                return result.ToHttp(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("End this device's session");

        auth.MapPost("/logout-all", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SignOutEverywhereCommand(), ct)).ToSession(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithSummary("Sign out of all other devices; returns a fresh session for this one")
            .Produces<SessionResponse>();

        var recovery = auth.MapGroup("/recovery").RequireRateLimiting(RateLimitPolicies.Recovery);

        recovery.MapPost("/verify-pin", async (VerifyRecoveryPinCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Forgot password, step 1: phone + recovery PIN → a 10-minute reset token")
            .Produces<PasswordResetTokenDto>();

        recovery.MapPost("/reset-password", async (ResetPasswordCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Forgot password, step 2: reset token + new password; signs out every session");
    }
}
