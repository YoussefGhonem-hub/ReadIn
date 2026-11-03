namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// Push notifications through Firebase Cloud Messaging (SPEC §21.1, ADR 0008). Called only from Hangfire jobs and outbox
/// handlers, never inside a request. A failed device never fails the call: it is reported in the outcome, and the caller
/// removes the tokens FCM rejected as unregistered or invalid.
/// </summary>
public interface IPushSender
{
    /// <returns>One outcome per notification, in the same order.</returns>
    Task<IReadOnlyList<PushOutcome>> SendAsync(IReadOnlyList<PushNotification> notifications, CancellationToken cancellationToken = default);
}

/// <summary>One notification for one user, sent to every device token of that user (multicast).</summary>
/// <param name="Title">Already in the user's UI language (SPEC §21.1).</param>
/// <param name="Data">String key/values delivered to the app (<c>type</c>, ids, <c>link</c>); see docs/api/contract-v1.md.</param>
/// <param name="CollapseKey">Notifications with the same key replace each other on the device (e.g. <c>daily_article</c>).</param>
/// <param name="TimeToLive">How long FCM keeps trying an offline device before dropping the notification.</param>
public sealed record PushNotification(
    IReadOnlyList<string> Tokens,
    string Title,
    string Body,
    IReadOnlyDictionary<string, string> Data,
    string CollapseKey,
    TimeSpan TimeToLive);

/// <param name="Sent">Devices FCM accepted the notification for.</param>
/// <param name="InvalidTokens">Tokens FCM reported as unregistered or invalid; delete them.</param>
/// <param name="Failed">Devices that failed for another reason (FCM unavailable, quota): worth retrying later.</param>
public sealed record PushOutcome(int Sent, IReadOnlyList<string> InvalidTokens, int Failed)
{
    /// <summary>Nothing reached a device, and at least one failure was temporary.</summary>
    public bool ShouldRetry => Sent == 0 && Failed > 0;
}
