using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Admin.Users;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F23 Admin console, Users (SPEC §17.2 "Admin"): the users table, a user's page, revealing one phone number (audited) and
/// signing an account out of every device. Suspend, warn and the rest stay <c>POST /moderation/actions</c> (F22).
/// </summary>
internal sealed class AdminConsoleUserEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var users = api.MapGroup("/admin/users").RequireAuthorization().WithTags("Admin");

        users.MapGet("/", async (
                    string? q, string? status, string? verified, string? method, string? joinedFrom, string? joinedTo, string? hasReports,
                    string? sort, string? dir, int? page, int? pageSize, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminUsersQuery(q, status, verified, method, joinedFrom, joinedTo, hasReports, sort, dir, page, pageSize), ct))
                .ToHttp(http))
            .WithSummary("Admins (users.read): every account, 50 a page (≤ 100); q = name, @handle, id or (users.read.pii) a phone number; " +
                "status, verified, method, joinedFrom/joinedTo, hasReports; sort = joined | lastSeen | followers | openReports, dir")
            .Produces<PagedList<AdminUserRowDto>>();

        users.MapGet("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminUserQuery(id), ct)).ToHttp(http))
            .WithSummary("Admins (users.read): a user's page; each section only with its permission")
            .Produces<AdminUserDto>();

        users.MapGet("/{id:guid}/phone", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new RevealUserPhoneCommand(id), ct);
                http.Response.Headers.CacheControl = "no-store";
                return result.ToHttp(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins (users.read + users.read.pii): the full phone number, audited admin.pii_viewed")
            .Produces<AdminPhoneDto>();

        users.MapPost("/{id:guid}/logout-all", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new AdminSignOutUserCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins (users.suspend): end every session of the account; not yourself, staff or a system account");
    }
}
