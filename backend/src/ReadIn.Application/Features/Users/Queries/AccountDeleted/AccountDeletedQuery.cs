using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Identity;

namespace ReadIn.Application.Features.Users.Queries.AccountDeleted;

/// <summary>
/// True when this account was deleted (its <see cref="AuditActions.AccountDeleted"/> record exists), so a retried
/// <c>DELETE /me</c> whose genuine token outlived the account answers like the first one did (SPEC F01).
/// </summary>
public sealed record AccountDeletedQuery(Guid UserId) : IQuery<bool>;

internal sealed class AccountDeletedQueryHandler(IAppDbContext db) : IQueryHandler<AccountDeletedQuery, bool>
{
    public async ValueTask<bool> Handle(AccountDeletedQuery query, CancellationToken cancellationToken) =>
        !await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Id == query.UserId, cancellationToken) &&
        await db.AuditLogs.AnyAsync(l => l.UserId == query.UserId && l.Action == AuditActions.AccountDeleted, cancellationToken);
}
