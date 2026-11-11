using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Devotions;

/// <summary>GET /me/duas (SPEC F38): all your du'as, oldest first (created, then id). Not paged (at most 200), never cached.</summary>
[Authenticated]
[RequirePermission(Permissions.Devotions.Access)]
public sealed record GetMyDuasQuery : IQuery<Result<IReadOnlyList<PersonalDuaDto>>>;

internal sealed class GetMyDuasQueryHandler(IAppDbContext db, ICurrentUser currentUser)
    : IQueryHandler<GetMyDuasQuery, Result<IReadOnlyList<PersonalDuaDto>>>
{
    public async ValueTask<Result<IReadOnlyList<PersonalDuaDto>>> Handle(GetMyDuasQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var duas = await db.PersonalDuas.AsNoTracking()
            .Where(d => d.UserId == userId)
            .OrderBy(d => d.CreatedAt).ThenBy(d => d.Id)
            .Select(d => new PersonalDuaDto(d.Id, d.Title, d.Text, d.Repeat, d.CreatedAt, d.UpdatedAt))
            .ToListAsync(cancellationToken);
        return Result.Success<IReadOnlyList<PersonalDuaDto>>(duas);
    }
}
