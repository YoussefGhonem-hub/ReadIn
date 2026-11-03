using System.Security.Cryptography;
using System.Text;

namespace ReadIn.Application.Features.Auth;

/// <summary>Random 256-bit tokens (refresh, reset). Only their SHA-256 is stored (SPEC §9.3).</summary>
public static class SecretTokens
{
    public static (string Token, string Hash) Create()
    {
        var token = Base64UrlEncode(RandomNumberGenerator.GetBytes(32));
        return (token, Hash(token));
    }

    public static string Hash(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    private static string Base64UrlEncode(byte[] bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
