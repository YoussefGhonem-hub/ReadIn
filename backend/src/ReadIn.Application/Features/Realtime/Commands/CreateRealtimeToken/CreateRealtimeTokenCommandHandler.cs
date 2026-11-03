using Mediator;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Realtime.Commands.CreateRealtimeToken;

internal sealed class CreateRealtimeTokenCommandHandler(ICurrentUser currentUser, IRealtimeTokenIssuer issuer)
    : ICommandHandler<CreateRealtimeTokenCommand, Result<RealtimeTokenDto>>
{
    public async ValueTask<Result<RealtimeTokenDto>> Handle(CreateRealtimeTokenCommand command, CancellationToken cancellationToken)
    {
        var token = await issuer.IssueAsync(currentUser.RequireUserId(), cancellationToken);
        if (token.IsFailure) return token.Error;
        return new RealtimeTokenDto(token.Value);
    }
}
