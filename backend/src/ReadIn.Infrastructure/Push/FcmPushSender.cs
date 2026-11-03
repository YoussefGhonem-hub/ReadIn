using System.Globalization;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.Push;

/// <summary>
/// Sends pushes with the Firebase Admin SDK over FCM HTTP v1 (SPEC §21.1, ADR 0008). Each notification goes to every token
/// of its user; the messages of a whole batch go out <see cref="MaxMessagesPerCall"/> per call. Uses its own named
/// <see cref="FirebaseApp"/>, so it never collides with other Admin SDK users in the process.
/// </summary>
internal sealed partial class FcmPushSender(IOptions<FirebaseOptions> options, ILogger<FcmPushSender> logger) : IPushSender
{
    /// <summary>The channel the mobile app creates at start (<c>FirebasePushPlatform.channel</c>, AndroidManifest.xml).</summary>
    public const string AndroidChannelId = "readin_default";

    private const string AppName = "readin-messaging";

    /// <summary>FCM's limit for <see cref="FirebaseMessaging.SendEachAsync(IEnumerable{Message}, CancellationToken)"/>.</summary>
    private const int MaxMessagesPerCall = 500;

    private static readonly Lock AppGate = new();

    public async Task<IReadOnlyList<PushOutcome>> SendAsync(IReadOnlyList<PushNotification> notifications, CancellationToken cancellationToken = default)
    {
        var sent = new int[notifications.Count];
        var failed = new int[notifications.Count];
        var invalid = notifications.Select(_ => new List<string>()).ToArray();

        var messages = notifications
            .SelectMany((notification, index) => notification.Tokens.Select(token => (Index: index, Token: token, Message: ToMessage(notification, token))))
            .ToList();
        if (messages.Count == 0) return notifications.Select(_ => new PushOutcome(0, [], 0)).ToList();

        var messaging = FirebaseMessaging.GetMessaging(App());
        foreach (var chunk in messages.Chunk(MaxMessagesPerCall))
        {
            var response = await messaging.SendEachAsync(chunk.Select(m => m.Message), cancellationToken);
            for (var i = 0; i < chunk.Length; i++)
            {
                var (index, token, _) = chunk[i];
                var result = response.Responses[i];
                if (result.IsSuccess)
                {
                    sent[index]++;
                }
                else if (IsInvalidToken(result.Exception?.MessagingErrorCode, result.Exception?.Message))
                {
                    invalid[index].Add(token);
                }
                else
                {
                    failed[index]++;
                    LogSendFailed(logger, result.Exception, result.Exception?.MessagingErrorCode?.ToString() ?? "unknown");
                }
            }
        }

        return notifications.Select((_, i) => new PushOutcome(sent[i], invalid[i], failed[i])).ToList();
    }

    /// <summary>
    /// Tokens to delete (SPEC §21.1): FCM says the app instance is gone (<c>UNREGISTERED</c>), the token belongs to another
    /// project (<c>SENDER_ID_MISMATCH</c>), or the token itself is malformed. Any other <c>INVALID_ARGUMENT</c> is about the
    /// message, and must not cost the user their devices.
    /// </summary>
    internal static bool IsInvalidToken(MessagingErrorCode? code, string? message) => code switch
    {
        MessagingErrorCode.Unregistered or MessagingErrorCode.SenderIdMismatch => true,
        MessagingErrorCode.InvalidArgument => message?.Contains("registration token", StringComparison.OrdinalIgnoreCase) == true,
        _ => false,
    };

    internal static Message ToMessage(PushNotification notification, string token)
    {
        var ttlSeconds = (long)notification.TimeToLive.TotalSeconds;
        return new Message
        {
            // Devices register FCM registration tokens (POST /me/devices), not the newer installation IDs (Fid): both
            // clients get them from getToken(). Moving to installation IDs is a change for the API and both clients.
#pragma warning disable CS0618
            Token = token,
#pragma warning restore CS0618
            Notification = new Notification { Title = notification.Title, Body = notification.Body },
            Data = notification.Data,
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                CollapseKey = notification.CollapseKey,
                TimeToLive = notification.TimeToLive,
                Notification = new AndroidNotification { ChannelId = AndroidChannelId, Tag = notification.CollapseKey },
            },
            Apns = new ApnsConfig
            {
                Headers = new Dictionary<string, string>
                {
                    ["apns-push-type"] = "alert",
                    ["apns-priority"] = "10",
                    ["apns-collapse-id"] = notification.CollapseKey,
                    ["apns-expiration"] = DateTimeOffset.UtcNow.AddSeconds(ttlSeconds).ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture),
                },
                Aps = new Aps { Sound = "default", ThreadId = notification.CollapseKey },
            },
            Webpush = new WebpushConfig
            {
                Headers = new Dictionary<string, string>
                {
                    ["TTL"] = ttlSeconds.ToString(CultureInfo.InvariantCulture),
                    ["Urgency"] = "high",
                },
                // Replaces Data for browsers: firebase-messaging-sw.js uses `tag` so a newer push replaces the older one.
                Data = new Dictionary<string, string>(notification.Data) { ["tag"] = notification.CollapseKey },
            },
        };
    }

    private FirebaseApp App()
    {
        lock (AppGate)
        {
            if (FirebaseApp.GetInstance(AppName) is { } app) return app;

            var firebase = options.Value;
            return FirebaseApp.Create(new AppOptions
            {
                Credential = FirebaseCredentials.Create(firebase),
                ProjectId = string.IsNullOrWhiteSpace(firebase.ProjectId) ? null : firebase.ProjectId,
            }, AppName);
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "FCM could not deliver a push to one device ({ErrorCode}); retried on the next run")]
    private static partial void LogSendFailed(ILogger logger, Exception? exception, string errorCode);
}

/// <summary>
/// Development without an Admin SDK key, and every emulator setup (FCM has no emulator): pushes are only logged, never
/// sent, and count as delivered (docs/setup/firebase.md).
/// </summary>
internal sealed partial class LoggingPushSender(ILogger<LoggingPushSender> logger) : IPushSender
{
    public Task<IReadOnlyList<PushOutcome>> SendAsync(IReadOnlyList<PushNotification> notifications, CancellationToken cancellationToken = default)
    {
        foreach (var notification in notifications)
        {
            LogPush(logger, notification.Data.GetValueOrDefault("type") ?? notification.CollapseKey, notification.Tokens.Count,
                notification.Title, notification.Body, notification.Data.GetValueOrDefault("link"));
        }
        return Task.FromResult<IReadOnlyList<PushOutcome>>(notifications.Select(n => new PushOutcome(n.Tokens.Count, [], 0)).ToList());
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Push not sent (no FCM in this environment): {Type} to {Devices} devices: {Title} | {Body} -> {Link}")]
    private static partial void LogPush(ILogger logger, string type, int devices, string title, string body, string? link);
}
