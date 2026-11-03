using System.Text.Json;
using ReadIn.Api.Endpoints;
using ReadIn.Application.Features.Users.Commands.UpdateProfile;

namespace ReadIn.Api.IntegrationTests;

/// <summary>PATCH /me changes the avatar only when the body names it (no server needed).</summary>
public sealed class UpdateProfileRequestTests
{
    private static readonly Guid AssetId = Guid.Parse("0195f3a0-0000-7000-8000-0000000000aa");

    private static UpdateProfileCommand Parse(string avatarJson) =>
        JsonSerializer.Deserialize<UpdateProfileRequest>(
            $$"""{ "displayName": "Mona", "username": "mona" {{avatarJson}} }""",
            new JsonSerializerOptions(JsonSerializerDefaults.Web))!.ToCommand();

    [Fact]
    public void Omitting_every_avatar_field_keeps_the_avatar() => Parse("").Avatar.Should().BeNull();

    [Fact]
    public void An_asset_id_sets_the_avatar() =>
        Parse($""", "avatarAssetId": "{AssetId}" """).Avatar.Should().Be(new AvatarChange(AssetId, null));

    [Fact]
    public void A_null_asset_id_removes_the_avatar() =>
        Parse(""", "avatarAssetId": null""").Avatar.Should().Be(AvatarChange.Remove);

    [Fact]
    public void The_previous_release_avatar_url_still_works()
    {
        Parse(""", "avatarUrl": "https://example.com/me.png" """).Avatar.Should().Be(new AvatarChange(null, "https://example.com/me.png"));
        Parse(""", "avatarUrl": null""").Avatar.Should().Be(AvatarChange.Remove);
    }

    [Fact]
    public void An_asset_id_wins_over_a_url_and_a_url_over_a_null_asset_id()
    {
        Parse($""", "avatarAssetId": "{AssetId}", "avatarUrl": "https://example.com/me.png" """).Avatar.Should().Be(new AvatarChange(AssetId, null));
        Parse(""", "avatarAssetId": null, "avatarUrl": "https://example.com/me.png" """).Avatar.Should().Be(new AvatarChange(null, "https://example.com/me.png"));
    }

    [Fact]
    public void Omitted_expertise_is_unchanged_and_an_empty_list_clears_it()
    {
        Parse("").ExpertiseFieldIds.Should().BeNull();
        Parse(""", "expertiseFieldIds": []""").ExpertiseFieldIds.Should().BeEmpty();
    }
}
