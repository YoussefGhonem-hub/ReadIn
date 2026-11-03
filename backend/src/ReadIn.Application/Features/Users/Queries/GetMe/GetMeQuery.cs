using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Queries.GetMe;

[Authenticated]
public sealed record GetMeQuery : IQuery<Result<MeDto>>;
