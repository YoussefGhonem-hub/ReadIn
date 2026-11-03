using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Api.Auth;

public static class FirebaseAuthentication
{
    /// <summary>
    /// Validates Firebase ID tokens as JWT bearer tokens (SPEC §9.2 step 3). With <c>Firebase:UseEmulator</c>
    /// (Development/Testing only) the unsigned tokens issued by the Auth emulator are accepted; issuer,
    /// audience and lifetime are still validated.
    /// </summary>
    public static IServiceCollection AddFirebaseAuthentication(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        var firebase = configuration.GetSection(FirebaseOptions.Section).Get<FirebaseOptions>() ?? new FirebaseOptions();
        var issuer = $"https://securetoken.google.com/{firebase.ProjectId}";

        if (firebase.UseEmulator && !(environment.IsDevelopment() || environment.IsEnvironment("Testing")))
            throw new InvalidOperationException("Firebase:UseEmulator is only allowed in Development and Testing.");
        if (!firebase.UseEmulator && string.IsNullOrWhiteSpace(firebase.ProjectId))
            throw new InvalidOperationException("Firebase:ProjectId must be set to the real Firebase project when Firebase:UseEmulator is false (docs/setup/firebase.md).");

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.MapInboundClaims = false;
                options.TokenValidationParameters = new()
                {
                    ValidateIssuer = true,
                    ValidIssuer = issuer,
                    ValidateAudience = true,
                    ValidAudience = firebase.ProjectId,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromMinutes(1),
                    NameClaimType = FirebaseClaims.Name,
                };

                if (firebase.UseEmulator)
                {
                    options.RequireHttpsMetadata = false;
                    options.Configuration = new OpenIdConnectConfiguration { Issuer = issuer };
                    options.TokenValidationParameters.ValidateIssuerSigningKey = false;
                    options.TokenValidationParameters.RequireSignedTokens = false;
                    options.TokenValidationParameters.SignatureValidator = (token, _) => new JsonWebToken(token);
                }
                else
                {
                    options.Authority = issuer;
                }
            });

        services.AddAuthorization();
        services.AddTransient<Microsoft.AspNetCore.Authentication.IClaimsTransformation, ReadInClaimsTransformation>();
        return services;
    }
}

/// <summary>Claim names in Firebase ID tokens.</summary>
public static class FirebaseClaims
{
    public const string UserId = "user_id";
    public const string Subject = "sub";
    public const string Email = "email";
    public const string Name = "name";
    public const string Picture = "picture";
}

/// <summary>Claims added from SQL Server by <see cref="ReadInClaimsTransformation"/>.</summary>
public static class ReadInClaims
{
    public const string UserId = "readin:uid";
    public const string Role = "readin:role";
    public const string Permission = "readin:permission";
    public const string Suspended = "readin:suspended";
}
