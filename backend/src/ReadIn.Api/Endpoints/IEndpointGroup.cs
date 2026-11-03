namespace ReadIn.Api.Endpoints;

/// <summary>A feature's minimal-API endpoints, mapped under <c>/api/v1</c> (SPEC §6.1, §17).</summary>
public interface IEndpointGroup
{
    void Map(RouteGroupBuilder api);
}

public static class EndpointGroupExtensions
{
    public static RouteGroupBuilder MapEndpointGroups(this RouteGroupBuilder api)
    {
        var groups = typeof(IEndpointGroup).Assembly.GetTypes()
            .Where(t => t is { IsAbstract: false, IsInterface: false } && typeof(IEndpointGroup).IsAssignableFrom(t))
            .Select(t => (IEndpointGroup)Activator.CreateInstance(t)!);

        foreach (var group in groups) group.Map(api);
        return api;
    }
}

public static class RateLimitPolicies
{
    public const string Auth = "auth";
    public const string SignIn = "auth-sign-in";
    public const string Register = "auth-register";
    public const string Recovery = "auth-recovery";

    /// <summary>The live @username check runs while typing, so it has its own budget instead of sharing <see cref="Auth"/>.</summary>
    public const string UsernameCheck = "username-check";
    public const string Writes = "writes";
    public const string Uploads = "uploads";
}

/// <summary>Per-IP limits of the anonymous auth endpoints (SPEC §9.5); tests raise them.</summary>
public sealed class AuthRateLimits
{
    public const string Section = "RateLimits:Auth";

    public int SignInPerMinute { get; set; } = 20;
    public int RegisterPerHour { get; set; } = 3;
    public int RecoveryPerHour { get; set; } = 10;
}
