using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Admin.Dashboard;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// The admin console's badge and dashboard (SPEC F23, contract-v1 "Admin console (F23)"): <c>admin.access</c>, reads only.
/// </summary>
internal sealed class AdminDashboardEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var admin = api.MapGroup("/admin").RequireAuthorization().WithTags("Admin");

        admin.MapGet("/summary", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminSummaryQuery(), ct)).ToHttp(http))
            .WithSummary("Admins (admin.access): the console badge, open reports + open tickets + pending verification requests (each null without its permission)")
            .Produces<AdminSummaryDto>();

        admin.MapGet("/dashboard", async (string? period, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminDashboardQuery(period, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Admins (admin.access): the dashboard for period=today (default) | yesterday | 7d | 30d, days in Admin:TimeZone; cached 60 s")
            .Produces<AdminDashboardDto>();
    }
}
