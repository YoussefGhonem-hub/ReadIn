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
    public const string Writes = "writes";
    public const string Uploads = "uploads";
}
