using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// What Firebase keeps about a ReadIn account (SPEC §9.6): the Firebase Auth record that signing in with the custom token
/// of <c>POST /realtime/token</c> creates for its uid, and its <c>/live/users/{id}</c> data.
/// </summary>
public interface IRealtimeAccountData
{
    /// <summary>
    /// Deletes the Firebase Auth record; an account that never had one succeeds too. Fails when Firebase can't be reached,
    /// so account deletion stops before anything is deleted (UserErrors.DeletionUnavailable).
    /// </summary>
    Task<Result> DeleteIdentityAsync(Guid userId, CancellationToken cancellationToken);

    /// <summary>Removes <c>/live/users/{id}</c>. Best effort: those signals expire after 24 hours anyway.</summary>
    Task DeleteLiveDataAsync(Guid userId, CancellationToken cancellationToken);
}
