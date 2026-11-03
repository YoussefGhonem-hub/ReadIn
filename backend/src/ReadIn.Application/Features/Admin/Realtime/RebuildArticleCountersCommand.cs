using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Admin.Realtime;

/// <summary>
/// POST /admin/realtime/rebuild-counters — recomputes every article's counters from SQL and republishes them to the
/// Realtime Database (SPEC §21.2 "a rebuild command"), e.g. after RTDB was reset or unreachable.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.System.Settings)]
public sealed record RebuildArticleCountersCommand : ICommand<Result<CountersRebuiltDto>>;

public sealed record CountersRebuiltDto(int ArticleCount);

internal sealed class RebuildArticleCountersCommandHandler(ArticleCounters counters)
    : ICommandHandler<RebuildArticleCountersCommand, Result<CountersRebuiltDto>>
{
    public async ValueTask<Result<CountersRebuiltDto>> Handle(RebuildArticleCountersCommand command, CancellationToken cancellationToken) =>
        new CountersRebuiltDto(await counters.RebuildAllAsync(cancellationToken));
}
