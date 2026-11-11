using ReadIn.Domain.Devotions;

namespace ReadIn.Application.Features.Devotions;

/// <summary>
/// One of your du'as in the private corner (SPEC F38, <c>docs/api/contract-v1.md</c> "Private devotions (F38)").
/// </summary>
/// <param name="Title">At most 100 characters on one line, or null.</param>
/// <param name="Text">1–2,000 characters, as written (line breaks kept).</param>
/// <param name="Repeat">How many times it is said (1–1,000): the app counts it down.</param>
/// <param name="UpdatedAt">Equals <paramref name="CreatedAt"/> until the first edit.</param>
public sealed record PersonalDuaDto(Guid Id, string? Title, string Text, int Repeat, DateTime CreatedAt, DateTime UpdatedAt)
{
    internal static PersonalDuaDto From(PersonalDua dua) => new(dua.Id, dua.Title, dua.Text, dua.Repeat, dua.CreatedAt, dua.UpdatedAt);
}
