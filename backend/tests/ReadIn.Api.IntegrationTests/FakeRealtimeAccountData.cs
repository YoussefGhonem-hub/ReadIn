using System.Collections.Concurrent;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Stands in for Firebase Auth and the Realtime Database; a test marks an account in <see cref="Unreachable"/> to make Firebase fail.</summary>
internal sealed class FakeRealtimeAccountData : IRealtimeAccountData
{
    public ConcurrentDictionary<Guid, bool> Unreachable { get; } = new();
    public ConcurrentQueue<Guid> DeletedIdentities { get; } = new();
    public ConcurrentQueue<Guid> DeletedLiveData { get; } = new();

    public Task<Result> DeleteIdentityAsync(Guid userId, CancellationToken cancellationToken)
    {
        if (Unreachable.ContainsKey(userId)) return Task.FromResult<Result>(UserErrors.DeletionUnavailable);
        DeletedIdentities.Enqueue(userId);
        return Task.FromResult(Result.Success());
    }

    public Task DeleteLiveDataAsync(Guid userId, CancellationToken cancellationToken)
    {
        DeletedLiveData.Enqueue(userId);
        return Task.CompletedTask;
    }
}
