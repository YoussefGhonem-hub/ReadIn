using Mapster;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.Logging.Abstractions;
using NSubstitute;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Profiles;
using ReadIn.Application.Features.Users;
using ReadIn.Application.Features.Users.Commands.UpdatePrivacy;
using ReadIn.Application.Features.Users.Commands.UpdateProfile;
using ReadIn.Domain.Media;
using ReadIn.Domain.Users;

namespace ReadIn.Application.UnitTests.Profiles;

public sealed class AvatarTests
{
    private const string Folder = "/uploads/avatars/2026/11/0123456789abcdef0123456789abcdef";

    private static MediaVariant Variant(int width) => new(width, width, $"{Folder}_{width}.webp", 100);

    private static IFileStorage Storage()
    {
        var storage = Substitute.For<IFileStorage>();
        storage.GetPublicUrl(Arg.Any<string>()).Returns(call => "https://api.readin.app" + call.Arg<string>());
        return storage;
    }

    [Fact]
    public void Every_avatar_size_has_its_own_variant()
    {
        var slots = Avatars.Slots([Variant(64), Variant(128), Variant(256), Variant(512)], Storage())!;

        slots.Keys.Should().Equal("64", "128", "256", "512");
        slots["256"].Should().Be($"https://api.readin.app{Folder}_256.webp");
        slots["512"].Should().EndWith("_512.webp");
    }

    [Fact]
    public void A_small_upload_fills_the_larger_sizes_with_its_largest_variant()
    {
        IReadOnlyList<MediaVariant> variants = [Variant(64), Variant(128), Variant(200)];

        Avatars.ForSlot(variants, Avatars.StoredWidth).Width.Should().Be(200);
        Avatars.ForSlot(variants, 64).Width.Should().Be(64);
        Avatars.Slots(variants, Storage())!.Values.Should().Equal(
            $"https://api.readin.app{Folder}_64.webp", $"https://api.readin.app{Folder}_128.webp",
            $"https://api.readin.app{Folder}_200.webp", $"https://api.readin.app{Folder}_200.webp");
    }

    [Fact]
    public void No_variants_means_no_slots() => Avatars.Slots([], Storage()).Should().BeNull();

    [Fact]
    public void Only_your_own_ready_avatar_uploads_are_usable()
    {
        var owner = Guid.NewGuid();
        var avatar = MediaAsset.StartImage(owner, MediaPurpose.Avatar, 1000);
        avatar.CompleteImage(512, 512, "L00000fQfQfQ", [Variant(64), Variant(512)]);
        var cover = MediaAsset.StartImage(owner, MediaPurpose.Cover, 1000);
        cover.CompleteImage(1200, 400, "L00000fQfQfQ", [new MediaVariant(1200, 400, "/uploads/covers/2026/11/x_1200.webp", 100)]);

        avatar.IsUsableBy(owner).Should().BeTrue();
        avatar.IsUsableBy(Guid.NewGuid()).Should().BeFalse("someone else's upload");
        cover.IsUsableBy(owner).Should().BeFalse("a cover is not an avatar");
        MediaAsset.StartImage(owner, MediaPurpose.Avatar, 1000).IsUsableBy(owner).Should().BeFalse("not processed");
    }
}

public sealed class ProfileLookupTests
{
    [Theory]
    [InlineData("mona", "mona")]
    [InlineData("@mona", "mona")]
    [InlineData("  @Mona_42 ", "mona_42")]
    [InlineData("MONA", "mona")]
    [InlineData("@@mona", null)]
    [InlineData("mo", null)]
    [InlineData("not-a-handle", null)]
    [InlineData("0195f3a0-0000-7000-8000-00000000e001", null)]
    [InlineData("", null)]
    [InlineData(null, null)]
    public void Usernames_ignore_case_and_one_leading_at(string? input, string? expected) =>
        ProfileUsers.Handle(input).Should().Be(expected);

    [Fact]
    public void Reading_stats_are_visible_to_the_owner_or_when_public()
    {
        var owner = Guid.NewGuid();

        new ProfileOwner(owner, PublicReadingStats: false).ReadingStatsVisibleTo(owner).Should().BeTrue();
        new ProfileOwner(owner, PublicReadingStats: false).ReadingStatsVisibleTo(Guid.NewGuid()).Should().BeFalse();
        new ProfileOwner(owner, PublicReadingStats: false).ReadingStatsVisibleTo(null).Should().BeFalse("guests");
        new ProfileOwner(owner, PublicReadingStats: true).ReadingStatsVisibleTo(null).Should().BeTrue();
    }
}

public sealed class ProfileEditTests
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private readonly IFileStorage _storage = Substitute.For<IFileStorage>();
    private readonly IAppDbContext _db = Substitute.For<IAppDbContext>();

    public ProfileEditTests() =>
        _storage.GetPublicUrl(Arg.Any<string>()).Returns(call => "https://api.readin.app" + call.Arg<string>());

    private static UpdateProfileCommand Command(AvatarChange? avatar = null, IReadOnlyList<Guid>? expertise = null) =>
        new("Mona Adel", "mona", "Backend · .NET", [new ProfileLinkInput("github", "https://github.com/mona")], avatar, expertise);

    private Dictionary<string, string[]> Errors(UpdateProfileCommand command) =>
        ValidationErrors.From(new UpdateProfileCommandValidator(_storage).Validate(command).Errors).Details!.ToDictionary();

    [Fact]
    public void A_command_without_avatar_or_expertise_is_valid() =>
        new UpdateProfileCommandValidator(_storage).Validate(Command()).IsValid.Should().BeTrue();

    [Fact]
    public void An_avatar_asset_or_a_removal_needs_no_url_check()
    {
        var validator = new UpdateProfileCommandValidator(_storage);

        validator.Validate(Command(new AvatarChange(Guid.NewGuid(), null))).IsValid.Should().BeTrue();
        validator.Validate(Command(AvatarChange.Remove)).IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData("/uploads/avatars/2026/11/0123456789abcdef0123456789abcdef_256.webp", true)]
    [InlineData("https://api.readin.app/uploads/avatars/2026/11/0123456789abcdef0123456789abcdef_256.webp", true)]
    [InlineData("https://lh3.googleusercontent.com/a/photo", true)]
    [InlineData("/uploads/covers/2026/11/0123456789abcdef0123456789abcdef_400.webp", false)]
    [InlineData("http://example.com/me.png", false)]
    public void The_previous_release_avatar_url_is_still_checked(string url, bool valid)
    {
        var errors = Errors(Command(new AvatarChange(null, url)));

        if (valid) errors.Should().BeEmpty();
        else errors["avatarUrl"].Should().Equal("validation.url");
    }

    [Fact]
    public async Task More_than_five_fields_of_expertise_are_refused_before_any_query()
    {
        var currentUser = Substitute.For<ICurrentUser>();
        currentUser.UserId.Returns(Guid.NewGuid());
        var handler = new UpdateProfileCommandHandler(
            _db, currentUser, _storage, new UploadCleanup(new UploadReferences(_db), _db, _storage, NullLogger<UploadCleanup>.Instance),
            new AuthorCaches(_db, Substitute.For<HybridCache>()));

        var result = await handler.Handle(Command(expertise: [.. Enumerable.Range(0, 6).Select(_ => Guid.NewGuid())]), Ct);

        result.Error!.Code.Should().Be("profile.expertise_invalid");
        result.Error.Details!["expertiseFieldIds"].Should().Equal("profile.expertise_invalid");
        _db.ReceivedCalls().Should().BeEmpty();
    }

    [Fact]
    public void Privacy_needs_the_setting() =>
        ValidationErrors.From(new UpdatePrivacyCommandValidator().Validate(new UpdatePrivacyCommand(null)).Errors)
            .Details!["publicReadingStats"].Should().Equal("validation.required");

    [Fact]
    public void Privacy_takes_either_setting_alone()
    {
        var validator = new UpdatePrivacyCommandValidator();

        validator.Validate(new UpdatePrivacyCommand(true)).IsValid.Should().BeTrue();
        validator.Validate(new UpdatePrivacyCommand(null, MentionPolicy.Following)).IsValid.Should().BeTrue();
        validator.Validate(new UpdatePrivacyCommand(false, MentionPolicy.Nobody)).IsValid.Should().BeTrue();

        var neither = ValidationErrors.From(validator.Validate(new UpdatePrivacyCommand(null, null)).Errors).Details!;
        neither["whoCanMention"].Should().Equal("validation.required");
        ValidationErrors.From(validator.Validate(new UpdatePrivacyCommand(null, (MentionPolicy)7)).Errors)
            .Details!["whoCanMention"].Should().Equal("validation.invalid");
    }

    [Fact]
    public void Me_carries_the_privacy_setting()
    {
        var config = DependencyInjection.CreateMapperConfig();
        var user = User.CreateSeeded("+12025550110", "Reader 1", "reader1");

        user.Adapt<MeDto>(config).Privacy.Should().Be(new PrivacyDto(PublicReadingStats: false, MentionPolicy.Everyone));
        user.SetPrivacy(publicReadingStats: true);
        user.Adapt<MeDto>(config).Privacy.Should().Be(new PrivacyDto(PublicReadingStats: true, MentionPolicy.Everyone));
        user.SetPrivacy(whoCanMention: MentionPolicy.Following);
        user.Adapt<MeDto>(config).Privacy.Should().Be(new PrivacyDto(PublicReadingStats: true, MentionPolicy.Following));
    }
}
