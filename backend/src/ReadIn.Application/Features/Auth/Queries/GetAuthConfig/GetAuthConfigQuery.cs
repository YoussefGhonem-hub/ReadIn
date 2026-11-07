using Mediator;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Queries.GetAuthConfig;

public sealed record GetAuthConfigQuery : IQuery<AuthConfigDto>;

internal sealed class GetAuthConfigQueryHandler(
    IOptions<RecoveryOptions> recovery, IExternalIdentityVerifier externalIdentities, IGoogleCodeExchanger googleCodes)
    : IQueryHandler<GetAuthConfigQuery, AuthConfigDto>
{
    public ValueTask<AuthConfigDto> Handle(GetAuthConfigQuery query, CancellationToken cancellationToken) =>
        ValueTask.FromResult(new AuthConfigDto(
            recovery.Value.PinLength,
            new PasswordRulesDto(PasswordRules.MinLength, PasswordRules.MaxLength, RequireLetter: true, RequireDigit: true),
            externalIdentities.EnabledProviders,
            GoogleCodeSignIn: googleCodes.IsConfigured && externalIdentities.EnabledProviders.Contains(ExternalProviders.Google)));
}
