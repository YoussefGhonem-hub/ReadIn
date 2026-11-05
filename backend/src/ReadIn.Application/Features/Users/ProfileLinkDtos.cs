using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

/// <summary>
/// One social link on a profile (SPEC F14): <see cref="Platform"/> is one of the lower-case platform names
/// (<c>linkedin</c>, <c>x</c>, … <c>website</c>, <c>other</c>), <see cref="Url"/> the normalized https URL and
/// <see cref="Label"/> the member's name for an <c>other</c> link (null for every other platform).
/// </summary>
public sealed record ProfileLinkDto(string Platform, string Url, string? Label);

/// <summary>A link as PATCH /me receives it; checked by <see cref="ProfileLinkRules"/> (contract: Profile → "Title and social links").</summary>
public sealed record ProfileLinkInput(string? Platform, string? Url, string? Label = null);

/// <summary>A new title for PATCH /me and PUT /me/profile/complete; <see cref="Value"/> null or blank clears it.</summary>
public sealed record HeadlineChange(string? Value);

public static class ProfileLinkMapping
{
    public static IReadOnlyList<ProfileLinkDto> ToDtos(this IReadOnlyList<ProfileLink> links) =>
        [.. links.Select(l => new ProfileLinkDto(l.Platform, l.Url, l.Label))];

    /// <summary>The request's links as the domain checks them; a missing platform or URL stays empty and is reported.</summary>
    public static IReadOnlyList<ProfileLink> ToDomain(this IReadOnlyList<ProfileLinkInput> links) =>
        [.. links.Select(l => new ProfileLink(l?.Platform ?? string.Empty, l?.Url ?? string.Empty, l?.Label))];
}
