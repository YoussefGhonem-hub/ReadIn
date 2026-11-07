using System.Globalization;
using Mediator;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;

namespace ReadIn.Application.Features.Admin.Realtime;

/// <summary>
/// POST /admin/realtime/rebuild-counters — recomputes every article's counters from SQL and republishes them to the
/// Realtime Database (SPEC §21.2 "a rebuild command"), e.g. after RTDB was reset or unreachable. Audited
/// <c>admin.counters_rebuilt</c> with the article count (SPEC F23).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.System.Settings)]
public sealed record RebuildArticleCountersCommand : ICommand<Result<CountersRebuiltDto>>;

public sealed record CountersRebuiltDto(int ArticleCount);

internal sealed class RebuildArticleCountersCommandHandler(ArticleCounters counters, AuditTrail audit, IAppDbContext db)
    : ICommandHandler<RebuildArticleCountersCommand, Result<CountersRebuiltDto>>
{
    public async ValueTask<Result<CountersRebuiltDto>> Handle(RebuildArticleCountersCommand command, CancellationToken cancellationToken)
    {
        var count = await counters.RebuildAllAsync(cancellationToken);
        audit.Record(AuditActions.CountersRebuilt, null, null, null, $"{count.ToString(CultureInfo.InvariantCulture)} articles");
        await db.SaveChangesAsync(cancellationToken);
        return new CountersRebuiltDto(count);
    }
}
