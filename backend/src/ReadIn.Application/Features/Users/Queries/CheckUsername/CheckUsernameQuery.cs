using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Queries.CheckUsername;

/// <param name="Valid">False when the handle breaks the format rules (3–30 of a–z, 0–9, _).</param>
public sealed record UsernameAvailabilityDto(string Username, bool Valid, bool Available);

/// <summary>Live @username check on "complete profile" and "edit profile" (SPEC §9.2). Your own handle counts as available.</summary>
public sealed record CheckUsernameQuery(string? Username) : IQuery<UsernameAvailabilityDto>;

internal sealed class CheckUsernameQueryHandler(IAppDbContext db, ICurrentUser currentUser)
    : IQueryHandler<CheckUsernameQuery, UsernameAvailabilityDto>
{
    public async ValueTask<UsernameAvailabilityDto> Handle(CheckUsernameQuery query, CancellationToken cancellationToken)
    {
        var username = query.Username?.Trim().ToLowerInvariant() ?? string.Empty;
        if (!User.IsValidUsername(username)) return new UsernameAvailabilityDto(username, Valid: false, Available: false);

        var owner = await db.Users.IgnoreQueryFilters()
            .Where(u => u.Username == username)
            .Select(u => (Guid?)u.Id)
            .FirstOrDefaultAsync(cancellationToken);
        return new UsernameAvailabilityDto(username, Valid: true, Available: owner is null || owner == currentUser.UserId);
    }
}
