using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using Asp.Versioning;
using Hangfire;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.OpenApi;
using ReadIn.Api.Auth;
using ReadIn.Api.Endpoints;
using ReadIn.Api.Errors;
using ReadIn.Api.Uploads;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure;
using Scalar.AspNetCore;

namespace ReadIn.Api;

public static class ApiSetup
{
    private const string CorsPolicy = "clients";

    public static IServiceCollection AddApi(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUser, HttpCurrentUser>();
        services.AddScoped<IClientInfo, HttpClientInfo>();
        services.AddJwtAuthentication(configuration, environment);

        services.ConfigureHttpJsonOptions(options =>
        {
            options.SerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
            options.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.Never;
        });

        services.AddProblemDetails(options => options.CustomizeProblemDetails = context =>
        {
            context.ProblemDetails.Extensions.TryAdd("code", ProblemResults.CodeForStatus(context.ProblemDetails.Status));
            context.ProblemDetails.Extensions.TryAdd("traceId", System.Diagnostics.Activity.Current?.Id ?? context.HttpContext.TraceIdentifier);
        });
        services.AddExceptionHandler<GlobalExceptionHandler>();

        services.AddApiVersioning(options =>
            {
                options.DefaultApiVersion = new ApiVersion(1);
                options.ReportApiVersions = true;
                options.ApiVersionReader = new UrlSegmentApiVersionReader();
            })
            .AddApiExplorer(options =>
            {
                options.GroupNameFormat = "'v'V";
                options.SubstituteApiVersionInUrl = true;
            })
            .AddOpenApi(options => options.Document.AddDocumentTransformer((document, _, _) =>
        {
            document.Info = new OpenApiInfo
            {
                Title = "ReadIn API",
                Version = "v1",
                Description = "ReadIn — مقال كل يوم يفرق معاك. Sign in with POST /auth/login and send the access token as a Bearer token.",
            };
            document.Components ??= new OpenApiComponents();
            document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
            document.Components.SecuritySchemes["Bearer"] = new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT (15 minutes)",
            };
            return Task.CompletedTask;
        }));

        var origins = configuration.GetSection("Cors:Origins").Get<string[]>() ?? [];
        services.AddCors(options =>
        {
            // Credentials: the web's refresh token travels as an HttpOnly cookie on /auth calls (SPEC §9.3).
            // Content-Disposition: the web names a downloaded article PDF (SPEC F33) and a quote card (F24) after the server's file name.
            options.AddPolicy(CorsPolicy, policy => policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod().AllowCredentials()
                .WithExposedHeaders("Content-Disposition"));
            options.AddPolicy(UploadsStaticFiles.CorsPolicy, policy => policy.WithOrigins(origins).WithMethods("GET", "HEAD"));
        });

        var authLimits = configuration.GetSection(AuthRateLimits.Section).Get<AuthRateLimits>() ?? new AuthRateLimits();
        var globalPerMinute = configuration.GetValue("RateLimits:GlobalPerMinute", 300);
        var searchPerMinute = configuration.GetValue("RateLimits:SearchPerMinute", 60);
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            // Per IP (SPEC §9.5). The per-number limits live in the handlers, which know the number.
            options.AddPolicy(RateLimitPolicies.SignIn, context => IpWindow(context, authLimits.SignInPerMinute, TimeSpan.FromMinutes(1)));
            options.AddPolicy(RateLimitPolicies.Register, context => IpWindow(context, authLimits.RegisterPerHour, TimeSpan.FromHours(1)));
            options.AddPolicy(RateLimitPolicies.Recovery, context => IpWindow(context, authLimits.RecoveryPerHour, TimeSpan.FromHours(1)));
            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = globalPerMinute,
                    Window = TimeSpan.FromMinutes(1),
                }));
            options.AddPolicy(RateLimitPolicies.Auth, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 20,
                    Window = TimeSpan.FromMinutes(1),
                }));
            options.AddPolicy(RateLimitPolicies.UsernameCheck, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 60,
                    Window = TimeSpan.FromMinutes(1),
                }));
            options.AddPolicy(RateLimitPolicies.Writes, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 30,
                    Window = TimeSpan.FromMinutes(1),
                }));
            options.AddPolicy(RateLimitPolicies.Uploads, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 20,
                    Window = TimeSpan.FromMinutes(1),
                }));
            // Per user: every call signs a token (locally, or through the IAM API when keyless).
            options.AddPolicy(RateLimitPolicies.RealtimeToken, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 10,
                    Window = TimeSpan.FromMinutes(1),
                }));
            options.AddPolicy(RateLimitPolicies.ReadingProgress, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 60,
                    Window = TimeSpan.FromMinutes(1),
                }));
            // SPEC F11: 10 comments a minute per user (comments and replies together).
            options.AddPolicy(RateLimitPolicies.Comments, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 10,
                    Window = TimeSpan.FromMinutes(1),
                }));
            // SPEC F16, §24: /search and /search/suggest together, per user (guests: per IP). Clients debounce typing.
            options.AddPolicy(RateLimitPolicies.Search, context =>
                RateLimitPartition.GetFixedWindowLimiter(PartitionKey(context), _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = searchPerMinute,
                    Window = TimeSpan.FromMinutes(1),
                }));
            // SPEC F33: 10 article PDFs per user per hour, answered with 429 article.pdf_limit.
            options.AddPolicy<string, ArticlePdfRateLimitPolicy>(ArticlePdfRateLimitPolicy.Name);
            // SPEC F24: 30 quote cards per user per hour (guests per IP), answered with 429 quote.limit.
            options.AddPolicy<string, QuoteCardRateLimitPolicy>(QuoteCardRateLimitPolicy.Name);
        });

        services.AddResponseCompression(options =>
        {
            options.EnableForHttps = true;
            options.Providers.Add<BrotliCompressionProvider>();
            options.Providers.Add<GzipCompressionProvider>();
        });

        return services;
    }

    public static WebApplication UseApi(this WebApplication app)
    {
        app.UseExceptionHandler();
        app.UseStatusCodePages();

        if (!app.Environment.IsDevelopment() && !app.Environment.IsEnvironment("Testing"))
        {
            app.UseHsts();
            app.UseHttpsRedirection();
        }

        app.Use(SecurityHeaders);
        app.UseResponseCompression();
        // Public images: their own CORS policy, no auth and no rate limiting (ADR 0010).
        app.UseUploads();
        // Verification proofs (SPEC F19): never served as files; the API refuses to start if the folder could be.
        app.Services.PreparePrivateStorage();
        app.UseCors(CorsPolicy);
        app.UseAuthentication();
        app.Use(RejectSuspendedUsers);
        app.Use(TrackPresence);
        app.UseAuthorization();
        app.UseRateLimiter();

        if (!app.Environment.IsProduction())
        {
            app.MapOpenApi().WithDocumentPerVersion();
            app.MapScalarApiReference("/docs", options => options.WithTitle("ReadIn API"));
            if (Infrastructure.DependencyInjection.IsHangfireEnabled(app.Configuration)) app.UseHangfireDashboard("/hangfire");
        }

        app.MapHealthChecks("/health").AllowAnonymous();

        var versions = app.NewApiVersionSet().HasApiVersion(new ApiVersion(1)).ReportApiVersions().Build();
        app.MapGroup("/api/v{version:apiVersion}")
            .WithApiVersionSet(versions)
            .HasApiVersion(new ApiVersion(1))
            .MapEndpointGroups();

        return app;
    }

    private static string PartitionKey(HttpContext context) =>
        context.User.FindFirst(JwtClaims.Subject)?.Value
        ?? context.Connection.RemoteIpAddress?.ToString()
        ?? "anonymous";

    private static RateLimitPartition<string> IpWindow(HttpContext context, int limit, TimeSpan window) =>
        RateLimitPartition.GetFixedWindowLimiter(context.Connection.RemoteIpAddress?.ToString() ?? "anonymous", _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = limit,
            Window = window,
        });

    /// <summary>
    /// Suspended users get 403 <c>user.suspended</c> on every authenticated call (SPEC §9.2 step 6), with
    /// <c>suspendedUntil</c> (null = permanent) so clients can say when it ends (F22).
    /// </summary>
    /// <summary>"Last seen" (SPEC F23): any signed-in request; the tracker writes at most once an hour per account.</summary>
    private static async Task TrackPresence(HttpContext context, RequestDelegate next)
    {
        if (context.User.Identity?.IsAuthenticated == true &&
            Guid.TryParse(context.User.FindFirst(JwtClaims.Subject)?.Value, out var userId))
        {
            await context.RequestServices.GetRequiredService<Application.Features.Admin.Users.IPresenceTracker>()
                .SeenAsync(userId, context.RequestAborted);
        }
        await next(context);
    }

    private static async Task RejectSuspendedUsers(HttpContext context, RequestDelegate next)
    {
        if (context.User.HasClaim(ReadInClaims.Suspended, "true"))
        {
            DateTime? until = context.User.FindFirst(ReadInClaims.SuspendedUntil)?.Value is { } value
                ? DateTime.Parse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
                : null;
            await Domain.Users.UserErrors.SuspendedUntil(until).ToProblem(context).ExecuteAsync(context);
            return;
        }
        await next(context);
    }

    private static Task SecurityHeaders(HttpContext context, RequestDelegate next)
    {
        var headers = context.Response.Headers;
        headers.XContentTypeOptions = "nosniff";
        headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
        headers.XFrameOptions = "DENY";

        var path = context.Request.Path;
        if (!path.StartsWithSegments("/docs") && !path.StartsWithSegments("/hangfire") && !path.StartsWithSegments("/openapi"))
            headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";

        return next(context);
    }
}
