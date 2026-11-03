using Mediator;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Queries.GetMe;

internal sealed class GetMeQueryHandler(ICurrentUser currentUser, MeReader meReader)
    : IQueryHandler<GetMeQuery, Result<MeDto>>
{
    public async ValueTask<Result<MeDto>> Handle(GetMeQuery query, CancellationToken cancellationToken) =>
        await meReader.ReadAsync(currentUser.FirebaseUid!, cancellationToken);
}
