using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdateProfile;

[Authenticated]
public sealed record UpdateProfileCommand(
    string DisplayName,
    string Username,
    string? Bio,
    string? AvatarUrl,
    UserLinksDto? Links) : ICommand<Result>;
