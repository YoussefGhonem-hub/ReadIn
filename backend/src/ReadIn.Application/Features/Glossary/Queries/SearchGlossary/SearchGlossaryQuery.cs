using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Glossary.Queries.SearchGlossary;

/// <summary>
/// GET /glossary?q=&amp;limit= — terms whose English name or slug contains <see cref="Q"/>, those that start with it first,
/// then A–Z; an empty query lists from A (the editor's term picker, SPEC F21).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record SearchGlossaryQuery(string? Q, int Limit) : IQuery<Result<IReadOnlyList<GlossaryTermSummaryDto>>>
{
    public const int DefaultLimit = 20;
    public const int MaxLimit = 50;
    public const int MaxQueryLength = 100;
}
