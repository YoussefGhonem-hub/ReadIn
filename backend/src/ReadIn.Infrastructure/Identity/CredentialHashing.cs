using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Identity;

public sealed class SecurityOptions
{
    public const string Section = "Security";

    /// <summary>
    /// HMAC key mixed into every recovery PIN hash (SPEC §9.5). Secrets only, never in the database; changing it
    /// invalidates every PIN. At least 32 characters.
    /// </summary>
    public string RecoveryPinPepper { get; set; } = string.Empty;
}

/// <summary>ASP.NET Core Identity's PBKDF2 hasher, which also tells when a stored hash should be upgraded.</summary>
internal sealed class IdentityPasswordHasher : IPasswordHasher
{
    private readonly PasswordHasher<User> _hasher = new();
    private readonly Lazy<string> _dummyHash;

    public IdentityPasswordHasher() => _dummyHash = new Lazy<string>(() => Hash(Convert.ToHexString(RandomNumberGenerator.GetBytes(16))));

    public string Hash(string password) => _hasher.HashPassword(null!, password);

    public PasswordCheck Verify(string hash, string password) => _hasher.VerifyHashedPassword(null!, hash, password) switch
    {
        PasswordVerificationResult.Success => PasswordCheck.Success,
        PasswordVerificationResult.SuccessRehashNeeded => PasswordCheck.SuccessRehashNeeded,
        _ => PasswordCheck.Failed,
    };

    public void VerifyAgainstDummy(string password) => _hasher.VerifyHashedPassword(null!, _dummyHash.Value, password ?? string.Empty);
}

/// <summary><c>PasswordHasher(HMACSHA256(pepper, userId + ":" + pin))</c> (SPEC §9.5).</summary>
internal sealed class PepperedPinHasher(IOptions<SecurityOptions> options, IPasswordHasher passwords) : IRecoveryPinHasher
{
    private byte[] Pepper => Encoding.UTF8.GetBytes(options.Value.RecoveryPinPepper);

    public string Hash(Guid userId, string pin) => passwords.Hash(Peppered(userId, pin));

    public bool Verify(Guid userId, string hash, string pin) => passwords.Verify(hash, Peppered(userId, pin)) != PasswordCheck.Failed;

    public void VerifyAgainstDummy(string pin) => passwords.VerifyAgainstDummy(Peppered(Guid.Empty, pin));

    public string HashPhoneNumber(string phoneNumber) =>
        Convert.ToHexString(HMACSHA256.HashData(Pepper, Encoding.UTF8.GetBytes("phone:" + phoneNumber)));

    private string Peppered(Guid userId, string pin) =>
        Convert.ToBase64String(HMACSHA256.HashData(Pepper, Encoding.UTF8.GetBytes($"{userId:D}:{pin}")));
}

/// <summary>
/// In-memory fixed windows. Like the uploads folder (ADR 0010), this assumes one API instance; a scaled-out API would
/// move the counters to a shared cache.
/// </summary>
internal sealed class MemoryAttemptThrottle(IMemoryCache cache, TimeProvider clock) : IAttemptThrottle
{
    private sealed class Window(DateTime endsAt)
    {
        public DateTime EndsAt { get; } = endsAt;
        public int Count;
    }

    public bool TryAcquire(string key, int limit, TimeSpan window)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var cacheKey = $"throttle:{key}";
        var current = cache.Get<Window>(cacheKey);
        if (current is null || current.EndsAt <= now)
        {
            current = new Window(now + window);
            cache.Set(cacheKey, current, window);
        }
        return Interlocked.Increment(ref current.Count) <= limit;
    }
}
