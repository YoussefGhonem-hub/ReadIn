using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.RegisterDevice;

/// <summary>POST /me/devices — upserts an FCM token for push notifications (SPEC §21).</summary>
[Authenticated]
public sealed record RegisterDeviceCommand(string Token, DevicePlatform Platform) : ICommand<Result>;
