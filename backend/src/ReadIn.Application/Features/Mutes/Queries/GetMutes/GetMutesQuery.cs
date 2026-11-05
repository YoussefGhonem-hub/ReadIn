using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Mutes.Queries.GetMutes;

/// <summary>
/// GET /me/mutes — Settings → Muted (SPEC F18, F28): your muted writers, fields and topics, newest mute first; names in
/// <see cref="UiLanguage"/>.
/// </summary>
[Authenticated]
public sealed record GetMutesQuery(string UiLanguage) : IQuery<Result<MutesDto>>;
