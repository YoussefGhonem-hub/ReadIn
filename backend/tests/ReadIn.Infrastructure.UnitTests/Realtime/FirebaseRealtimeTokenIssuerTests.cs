using System.Text;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Realtime;

namespace ReadIn.Infrastructure.UnitTests.Realtime;

/// <summary>
/// The Admin SDK path of <c>POST /realtime/token</c> against the Auth emulator: the SDK mints an unsigned custom token
/// locally, so no emulator has to run. (Sets <c>FIREBASE_AUTH_EMULATOR_HOST</c> for this test process, as the API does.)
/// </summary>
public sealed class FirebaseRealtimeTokenIssuerTests
{
    [Fact]
    public async Task The_emulator_token_carries_the_readin_user_id_as_its_uid()
    {
        var userId = Guid.CreateVersion7();
        var issuer = new FirebaseRealtimeTokenIssuer(
            Options.Create(new FirebaseOptions { ProjectId = "demo-readin", UseEmulator = true, AuthEmulatorHost = "127.0.0.1:9099" }),
            NullLogger<FirebaseRealtimeTokenIssuer>.Instance);

        var result = await issuer.IssueAsync(userId, TestContext.Current.CancellationToken);

        result.IsSuccess.Should().BeTrue();
        var parts = result.Value.Split('.');
        parts.Should().HaveCount(3);
        Decode(parts[0])["alg"]!.GetValue<string>().Should().Be("none", "the Auth emulator accepts unsigned tokens");
        var payload = Decode(parts[1]);
        payload["uid"]!.GetValue<string>().Should().Be(userId.ToString(), "the rules compare auth.uid with the lowercase id in /live/users/{id}");
        payload["aud"]!.GetValue<string>().Should().Contain("identitytoolkit");
        Environment.GetEnvironmentVariable(FirebaseRealtimeTokenIssuer.AuthEmulatorVariable).Should().Be("127.0.0.1:9099");
    }

    private static JsonObject Decode(string segment)
    {
        var base64 = segment.Replace('-', '+').Replace('_', '/');
        base64 = base64.PadRight(base64.Length + (4 - base64.Length % 4) % 4, '=');
        return JsonNode.Parse(Encoding.UTF8.GetString(Convert.FromBase64String(base64)))!.AsObject();
    }
}
