using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Verification;

/// <summary>
/// After a decision commits: <c>verification_result</c> for the requester (SPEC F17, F19). Not configurable, quiet hours
/// apply, no actor (admins stay anonymous) and no article; <c>data.approved</c> says which. The reason is never in the
/// notification or its push: the verification page shows it. Once per request (dedupe key), so outbox retries change nothing.
/// </summary>
internal sealed class VerificationResultNotificationHandler(NotificationWriter writer) : IDomainEventHandler<VerificationDecidedDomainEvent>
{
    public Task Handle(VerificationDecidedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        writer.WriteAsync(new NotificationRequest(domainEvent.UserId, NotificationTypes.VerificationResult)
        {
            DedupeKey = DedupeKey(domainEvent.RequestId),
            Data = new NotificationData { Approved = domainEvent.Approved },
        }, cancellationToken);

    public static string DedupeKey(Guid requestId) => $"{NotificationTypes.VerificationResult}:{requestId}";
}
