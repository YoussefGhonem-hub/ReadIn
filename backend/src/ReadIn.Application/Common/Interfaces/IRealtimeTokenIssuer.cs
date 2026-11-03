using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// Mints the Firebase custom token of <c>POST /realtime/token</c> (SPEC §21.2, ADR 0008). Its <c>uid</c> is the ReadIn
/// user id, which is all <c>firebase/database.rules.json</c> needs to let the user read <c>/live/users/{uid}</c>. It is not
/// a sign-in: Firebase Auth has no providers, and nothing else in Firebase trusts it.
/// </summary>
public interface IRealtimeTokenIssuer
{
    /// <returns>The custom token, or <see cref="RealtimeErrors.Unavailable"/> when Firebase can't sign one.</returns>
    Task<Result<string>> IssueAsync(Guid userId, CancellationToken cancellationToken);
}

public static class RealtimeErrors
{
    /// <summary>Clients stay on REST and try again on the next sign in or page load.</summary>
    public static readonly Error Unavailable = Error.Failure("realtime.unavailable", "Live updates are unavailable right now.");
}
