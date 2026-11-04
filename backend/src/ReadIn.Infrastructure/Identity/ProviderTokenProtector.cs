using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Infrastructure.Identity;

/// <summary>
/// AES-256-GCM for provider tokens at rest (Apple refresh tokens, SPEC F01). The key is derived with HKDF-SHA256 from
/// <see cref="SecurityOptions.RecoveryPinPepper"/> under its own label, so no extra secret has to be deployed; rotating the
/// pepper makes stored tokens unreadable, and those accounts then confirm with Apple when they are deleted.
/// Format: <c>v1.</c> + base64url(nonce | ciphertext | tag).
/// </summary>
internal sealed class AesGcmProviderTokenProtector(IOptions<SecurityOptions> options) : IProviderTokenProtector
{
    private const string Prefix = "v1.";
    private const int NonceSize = 12;
    private const int TagSize = 16;

    private readonly byte[] _key = HKDF.DeriveKey(
        HashAlgorithmName.SHA256,
        Encoding.UTF8.GetBytes(options.Value.RecoveryPinPepper),
        outputLength: 32,
        info: "ReadIn provider tokens v1"u8.ToArray());

    public string Protect(string token)
    {
        var plain = Encoding.UTF8.GetBytes(token);
        var sealedBytes = new byte[NonceSize + plain.Length + TagSize];
        var nonce = sealedBytes.AsSpan(0, NonceSize);
        RandomNumberGenerator.Fill(nonce);

        using var aes = new AesGcm(_key, TagSize);
        aes.Encrypt(nonce, plain, sealedBytes.AsSpan(NonceSize, plain.Length), sealedBytes.AsSpan(NonceSize + plain.Length));
        return Prefix + Convert.ToBase64String(sealedBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }

    public string? Unprotect(string protectedToken)
    {
        if (!protectedToken.StartsWith(Prefix, StringComparison.Ordinal)) return null;

        try
        {
            var base64 = protectedToken[Prefix.Length..].Replace('-', '+').Replace('_', '/');
            var sealedBytes = Convert.FromBase64String(base64.PadRight(base64.Length + (4 - base64.Length % 4) % 4, '='));
            if (sealedBytes.Length < NonceSize + TagSize) return null;

            var cipherLength = sealedBytes.Length - NonceSize - TagSize;
            var plain = new byte[cipherLength];
            using var aes = new AesGcm(_key, TagSize);
            aes.Decrypt(
                sealedBytes.AsSpan(0, NonceSize),
                sealedBytes.AsSpan(NonceSize, cipherLength),
                sealedBytes.AsSpan(NonceSize + cipherLength),
                plain);
            return Encoding.UTF8.GetString(plain);
        }
        catch (Exception ex) when (ex is FormatException or CryptographicException)
        {
            return null;
        }
    }
}
