using Mediator;
using Microsoft.Extensions.Options;

namespace ReadIn.Application.Features.MobileApp.Queries.GetUpdatePolicy;

public sealed record GetUpdatePolicyQuery : IQuery<UpdatePolicyDto>;

internal sealed class GetUpdatePolicyQueryHandler(IOptions<MobileAppOptions> options)
    : IQueryHandler<GetUpdatePolicyQuery, UpdatePolicyDto>
{
    public ValueTask<UpdatePolicyDto> Handle(GetUpdatePolicyQuery query, CancellationToken cancellationToken) =>
        ValueTask.FromResult(new UpdatePolicyDto(Policy(options.Value.Ios), Policy(options.Value.Android)));

    private static PlatformUpdatePolicyDto Policy(MobileAppPlatformOptions platform) =>
        new(platform.MinimumVersionOrNull, platform.StoreUrlOrNull);
}
