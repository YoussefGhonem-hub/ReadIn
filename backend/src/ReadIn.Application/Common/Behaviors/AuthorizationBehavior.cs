using System.Reflection;
using Mediator;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Common.Behaviors;

public static class AuthErrors
{
    public static readonly Error Unauthorized = Error.Unauthorized("auth.unauthorized", "Sign in to continue.");
    public static readonly Error Forbidden = Error.Forbidden("auth.forbidden", "You don't have permission to do this.");
}

/// <summary>Enforces <see cref="RequirePermissionAttribute"/> and <see cref="AuthenticatedAttribute"/> on every message.</summary>
internal sealed class AuthorizationBehavior<TMessage, TResponse>(ICurrentUser currentUser, IUserAccessService access)
    : IPipelineBehavior<TMessage, TResponse>
    where TMessage : notnull, IMessage
{
    private static readonly string[] RequiredPermissions = typeof(TMessage)
        .GetCustomAttributes<RequirePermissionAttribute>()
        .Select(a => a.Permission)
        .ToArray();

    private static readonly bool RequiresUser = typeof(TMessage).GetCustomAttribute<AuthenticatedAttribute>() is not null;

    public async ValueTask<TResponse> Handle(TMessage message, MessageHandlerDelegate<TMessage, TResponse> next, CancellationToken cancellationToken)
    {
        if (RequiresUser)
        {
            if (!currentUser.IsAuthenticated) return ResultFailure<TResponse>.Create(AuthErrors.Unauthorized);
            if (currentUser.UserId is null) return ResultFailure<TResponse>.Create(UserErrors.NotSynced);
        }

        if (RequiredPermissions.Length > 0)
        {
            var granted = currentUser.IsAuthenticated
                ? currentUser.Permissions
                : await access.GetGuestPermissionsAsync(cancellationToken);

            if (!RequiredPermissions.All(granted.Contains))
            {
                var error = currentUser.IsAuthenticated ? AuthErrors.Forbidden : AuthErrors.Unauthorized;
                return ResultFailure<TResponse>.Create(error);
            }
        }

        return await next(message, cancellationToken);
    }
}
