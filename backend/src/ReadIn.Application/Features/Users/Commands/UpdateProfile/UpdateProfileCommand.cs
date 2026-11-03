using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdateProfile;

/// <summary>PATCH /me (SPEC F14).</summary>
/// <param name="Avatar">Null keeps the current avatar.</param>
/// <param name="ExpertiseFieldIds">0–5 enabled field ids in the user's order; null keeps the current ones.</param>
[Authenticated]
public sealed record UpdateProfileCommand(
    string DisplayName,
    string Username,
    string? Bio,
    UserLinksDto? Links,
    AvatarChange? Avatar = null,
    IReadOnlyList<Guid>? ExpertiseFieldIds = null) : ICommand<Result>;

/// <summary>
/// A new avatar: an upload with purpose <c>avatar</c> (<see cref="AssetId"/>) or, from clients of the previous release,
/// a URL (<see cref="Url"/>: an uploaded avatar's URL or any external https image). Neither one removes the avatar.
/// </summary>
public sealed record AvatarChange(Guid? AssetId, string? Url)
{
    public static AvatarChange Remove { get; } = new(null, null);
}
