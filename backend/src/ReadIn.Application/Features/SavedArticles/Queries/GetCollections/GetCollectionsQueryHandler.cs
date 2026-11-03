using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Queries.GetCollections;

internal sealed class GetCollectionsQueryHandler(IAppDbContext db, ICurrentUser currentUser)
    : IQueryHandler<GetCollectionsQuery, Result<IReadOnlyList<CollectionDto>>>
{
    public async ValueTask<Result<IReadOnlyList<CollectionDto>>> Handle(GetCollectionsQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var collections = await db.Collections.AsNoTracking()
            .Where(c => c.UserId == userId)
            .OrderBy(c => c.Name)
            .ThenBy(c => c.CreatedAt)
            .ToDtos(db)
            .ToListAsync(cancellationToken);
        return collections;
    }
}
