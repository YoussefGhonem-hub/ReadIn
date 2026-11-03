using ReadIn.Domain.Common;

namespace ReadIn.Domain.UnitTests.Common;

public sealed class LanguagesTests
{
    [Theory]
    [InlineData("ar", "ar-EG")]
    [InlineData("en", "en")]
    [InlineData("en-US", "en")]
    [InlineData(null, "ar-EG")]
    [InlineData("fr", "ar-EG")]
    public void A_guest_reads_the_version_that_matches_the_ui(string? uiLanguage, string expected) =>
        ArticleLanguages.ForUi(uiLanguage).Should().Be(expected);
}
