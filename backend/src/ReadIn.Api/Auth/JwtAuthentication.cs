using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;

namespace ReadIn.Api.Auth;

/// <summary>The API's own access tokens (SPEC §9.3, ADR 0007).</summary>
public sealed class JwtOptions
{
    public const string Section = "Jwt";

    public string Issuer { get; set; } = "https://api.readin.app";
    public string Audience { get; set; } = "readin";

    /// <summary>HMAC-SHA256 key, at least 32 bytes. Secrets only; rotating it signs every access token out (refresh still works).</summary>
    public string SigningKey { get; set; } = string.Empty;

    public TimeSpan AccessTokenLifetime { get; set; } = TimeSpan.FromMinutes(15);

    internal SymmetricSecurityKey Key => new(Encoding.UTF8.GetBytes(SigningKey));
}

public static class JwtAuthentication
{
    /// <summary>Marks the committed Development key and pepper, so they can never be used on a server.</summary>
    private const string DevelopmentMarker = "dev-only";

    /// <summary>
    /// Validates the API's access tokens (issuer, audience, lifetime, HS256 key), then checks the <c>security_stamp</c> against
    /// SQL Server and adds the user's roles and permissions (cached, see <see cref="IUserAccessService"/>).
    /// </summary>
    public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        var jwt = configuration.GetSection(JwtOptions.Section).Get<JwtOptions>() ?? new JwtOptions();
        if (Encoding.UTF8.GetByteCount(jwt.SigningKey) < 32)
            throw new InvalidOperationException("Jwt:SigningKey must be set to at least 32 bytes (user-secrets locally, the secret store on servers).");

        var local = environment.IsDevelopment() || environment.IsEnvironment("Testing");
        if (!local && (jwt.SigningKey.Contains(DevelopmentMarker, StringComparison.Ordinal) ||
                       configuration["Security:RecoveryPinPepper"]?.Contains(DevelopmentMarker, StringComparison.Ordinal) == true))
            throw new InvalidOperationException("The Development Jwt:SigningKey or Security:RecoveryPinPepper must not be used outside Development.");

        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.Section));
        services.AddSingleton<IAccessTokenIssuer, JwtAccessTokenIssuer>();

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.MapInboundClaims = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = jwt.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwt.Audience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromSeconds(30),
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = jwt.Key,
                    ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                    NameClaimType = JwtClaims.Subject,
                };
                options.Events = new JwtBearerEvents { OnTokenValidated = AddReadInClaimsAsync };
            });

        services.AddAuthorization();
        return services;
    }

    /// <summary>
    /// Rejects tokens whose <c>security_stamp</c> no longer matches (password/phone change, reset, sign out everywhere) or whose
    /// user is gone, then adds roles, permissions and the suspended flag from SQL Server (SPEC §9.3).
    /// </summary>
    private static async Task AddReadInClaimsAsync(TokenValidatedContext context)
    {
        var principal = context.Principal!;
        if (!Guid.TryParse(principal.FindFirst(JwtClaims.Subject)?.Value, out var userId))
        {
            context.Fail("The token has no valid subject.");
            return;
        }

        var access = context.HttpContext.RequestServices.GetRequiredService<IUserAccessService>();
        var userAccess = await access.GetAsync(userId, context.HttpContext.RequestAborted);
        if (userAccess is null || userAccess.SecurityStamp != principal.FindFirst(JwtClaims.SecurityStamp)?.Value)
        {
            context.Fail("The session has ended.");
            return;
        }

        var clock = context.HttpContext.RequestServices.GetRequiredService<TimeProvider>();
        var claims = new List<Claim>();
        claims.AddRange(userAccess.Roles.Select(r => new Claim(ReadInClaims.Role, r)));
        claims.AddRange(userAccess.Permissions.Select(p => new Claim(ReadInClaims.Permission, p)));
        if (userAccess.IsSuspendedAt(clock.GetUtcNow().UtcDateTime)) claims.Add(new Claim(ReadInClaims.Suspended, "true"));
        principal.AddIdentity(new ClaimsIdentity(claims));
    }
}

internal sealed class JwtAccessTokenIssuer(IOptions<JwtOptions> options, TimeProvider clock) : IAccessTokenIssuer
{
    private readonly JsonWebTokenHandler _handler = new();

    public AccessToken Issue(Guid userId, string securityStamp)
    {
        var jwt = options.Value;
        var now = clock.GetUtcNow().UtcDateTime;
        var expires = now + jwt.AccessTokenLifetime;

        var token = _handler.CreateToken(new SecurityTokenDescriptor
        {
            Issuer = jwt.Issuer,
            Audience = jwt.Audience,
            IssuedAt = now,
            NotBefore = now,
            Expires = expires,
            Claims = new Dictionary<string, object>
            {
                [JwtClaims.Subject] = userId.ToString(),
                [JwtClaims.SecurityStamp] = securityStamp,
                [JwtClaims.TokenId] = Guid.NewGuid().ToString("N"),
            },
            SigningCredentials = new SigningCredentials(jwt.Key, SecurityAlgorithms.HmacSha256),
        });
        return new AccessToken(token, expires);
    }
}

/// <summary>Claims in the API's access tokens.</summary>
public static class JwtClaims
{
    public const string Subject = "sub";
    public const string SecurityStamp = "security_stamp";
    public const string TokenId = "jti";
}

/// <summary>Claims added from SQL Server when a token is validated.</summary>
public static class ReadInClaims
{
    public const string Role = "readin:role";
    public const string Permission = "readin:permission";
    public const string Suspended = "readin:suspended";
}
