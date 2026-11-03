using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure.Persistence.Seeding;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.UnitTests.Storage;

/// <summary>Demo avatars (SPEC §18): deterministic, so re-seeding reuses the stored files, and accepted by the real pipeline.</summary>
public sealed class DemoAvatarTests
{
    [Fact]
    public void The_same_handle_always_draws_the_same_avatar()
    {
        DemoAvatars.Draw("reviewer.dotnet").Should().Equal(DemoAvatars.Draw("reviewer.dotnet"));
        DemoAvatars.Draw("reviewer.dotnet").Should().NotEqual(DemoAvatars.Draw("writer1"));
    }

    [Fact]
    public void Demo_avatars_become_the_four_square_avatar_variants()
    {
        var bytes = DemoAvatars.Draw("writer1");

        var result = new SkiaImageProcessor().Process(new MemoryStream(bytes), ImageFormat.Png, UploadPurpose.Avatar);

        result.IsSuccess.Should().BeTrue(result.Error?.Code);
        result.Value.Variants.Select(v => (v.Width, v.Height)).Should().Equal((64, 64), (128, 128), (256, 256), (512, 512));
    }
}
