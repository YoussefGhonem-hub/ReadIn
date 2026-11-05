using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Users;

/// <summary>The social links and the title on a profile (SPEC F14, contract "Title and social links").</summary>
public sealed class ProfileLinkTests
{
    private static User NewUser() => User.Register("+12015550101", "password-hash", "reader_abc123", Guid.NewGuid());

    private static IReadOnlyDictionary<string, string[]> Errors(params ProfileLink[] links)
    {
        var result = ProfileLinkRules.Check(links);
        result.IsFailure.Should().BeTrue();
        result.Error!.Code.Should().Be("validation.failed");
        return result.Error.Details!;
    }

    private static IReadOnlyList<ProfileLink> Valid(params ProfileLink[] links)
    {
        var result = ProfileLinkRules.Check(links);
        result.IsSuccess.Should().BeTrue(result.IsFailure ? string.Join(", ", result.Error.Details!.Select(e => $"{e.Key}={e.Value[0]}")) : "");
        return result.Value;
    }

    [Theory]
    [InlineData("linkedin", "https://www.linkedin.com/in/mona")]
    [InlineData("linkedin", "https://eg.linkedin.com/in/mona")]
    [InlineData("linkedin", "https://lnkd.in/abc")]
    [InlineData("x", "https://x.com/mona")]
    [InlineData("x", "https://twitter.com/mona")]
    [InlineData("instagram", "https://www.instagram.com/mona")]
    [InlineData("instagram", "https://instagr.am/mona")]
    [InlineData("facebook", "https://m.facebook.com/mona")]
    [InlineData("facebook", "https://fb.me/mona")]
    [InlineData("youtube", "https://www.youtube.com/@mona")]
    [InlineData("youtube", "https://youtu.be/abc")]
    [InlineData("tiktok", "https://www.tiktok.com/@mona")]
    [InlineData("snapchat", "https://www.snapchat.com/add/mona")]
    [InlineData("threads", "https://www.threads.net/@mona")]
    [InlineData("threads", "https://threads.com/@mona")]
    [InlineData("telegram", "https://t.me/mona")]
    [InlineData("telegram", "https://telegram.me/mona")]
    [InlineData("github", "https://github.com/mona")]
    [InlineData("medium", "https://medium.com/@mona")]
    [InlineData("medium", "https://mona.medium.com")]
    [InlineData("behance", "https://www.behance.net/mona")]
    [InlineData("website", "https://mona.dev/about")]
    [InlineData("website", "https://مثال.مصر/صفحة")]
    public void A_platform_accepts_its_own_hosts_and_their_subdomains(string platform, string url) =>
        Valid(new ProfileLink(platform, url)).Should().Equal(new ProfileLink(platform, url));

    [Theory]
    [InlineData("linkedin", "https://linkedin.com.evil.io/in/mona")]
    [InlineData("x", "https://notx.com/mona")]
    [InlineData("instagram", "https://facebook.com/mona")]
    [InlineData("github", "https://gitlab.com/mona")]
    [InlineData("github", "https://evilgithub.com/mona")]
    [InlineData("telegram", "https://telegram.org/mona")]
    [InlineData("medium", "https://mona.dev")]
    public void A_named_platform_refuses_other_sites(string platform, string url) =>
        Errors(new ProfileLink(platform, url))["links[0].url"].Should().Equal("link.host_mismatch");

    [Fact]
    public void Website_and_other_accept_any_https_site()
    {
        Valid(
                new ProfileLink("website", "https://example.com"),
                new ProfileLink("other", "https://kaggle.com/mona", "Kaggle"),
                new ProfileLink("other", "https://dev.to/mona", "DEV"))
            .Select(l => l.Platform).Should().Equal("website", "other", "other");
    }

    [Fact]
    public void A_link_without_a_scheme_gets_https_and_is_trimmed()
    {
        Valid(new ProfileLink("instagram", "  instagram.com/name  ")).Single().Url.Should().Be("https://instagram.com/name");
    }

    [Theory]
    [InlineData("http://github.com/mona")]
    [InlineData("ftp://github.com/mona")]
    [InlineData("javascript://github.com/%0aalert(1)")]
    public void Only_https_is_accepted(string url) =>
        Errors(new ProfileLink("github", url))["links[0].url"].Should().Equal("link.https_required");

    [Theory]
    [InlineData("https://user:pass@github.com/mona")]
    [InlineData("https://mona@github.com/mona")]
    [InlineData("https://127.0.0.1/mona")]
    [InlineData("https://localhost/mona")]
    [InlineData("https://github.com:8443/mona")]
    [InlineData("https://git hub.com/mona")]
    [InlineData("https://")]
    public void A_link_needs_a_real_host_without_credentials_or_a_port(string url) =>
        Errors(new ProfileLink("website", url))["links[0].url"].Should().Equal("link.url_invalid");

    [Fact]
    public void A_link_has_at_most_500_characters()
    {
        var path = new string('a', ProfileLinkRules.MaxUrlLength - "https://github.com/".Length);
        Valid(new ProfileLink("github", "https://github.com/" + path));
        Errors(new ProfileLink("github", "https://github.com/" + path + "a"))["links[0].url"].Should().Equal("link.too_long");
        // Measured after https:// is added.
        Errors(new ProfileLink("github", "github.com/" + path + "a"))["links[0].url"].Should().Equal("link.too_long");
    }

    [Fact]
    public void An_empty_url_is_required() =>
        Errors(new ProfileLink("github", "  "))["links[0].url"].Should().Equal("validation.required");

    [Theory]
    [InlineData("")]
    [InlineData("GitHub")]
    [InlineData("mastodon")]
    public void The_platform_is_one_of_the_fourteen(string platform) =>
        Errors(new ProfileLink(platform, "https://github.com/mona"))["links[0].platform"].Should().Equal("link.platform_invalid");

    [Fact]
    public void At_most_eight_links()
    {
        var eight = Enumerable.Range(0, 8).Select(i => new ProfileLink("other", $"https://site{i}.com", $"Site {i}")).ToArray();
        Valid(eight).Should().HaveCount(8);
        Errors([.. eight, new ProfileLink("website", "https://nine.com")])["links"].Should().Equal("link.too_many");
    }

    [Fact]
    public void One_link_per_platform_but_other_repeats()
    {
        var errors = Errors(
            new ProfileLink("github", "https://github.com/a"),
            new ProfileLink("other", "https://a.com", "One"),
            new ProfileLink("github", "https://github.com/b"),
            new ProfileLink("other", "https://b.com", "Two"));

        errors.Keys.Should().BeEquivalentTo("links[2].platform");
        errors["links[2].platform"].Should().Equal("link.duplicate_platform");
    }

    [Fact]
    public void Other_needs_a_label_of_two_to_thirty_characters_on_one_line()
    {
        Errors(new ProfileLink("other", "https://a.com"))["links[0].label"].Should().Equal("link.label_required");
        Errors(new ProfileLink("other", "https://a.com", "  "))["links[0].label"].Should().Equal("link.label_required");
        Errors(new ProfileLink("other", "https://a.com", "A"))["links[0].label"].Should().Equal("link.label_invalid");
        Errors(new ProfileLink("other", "https://a.com", new string('a', 31)))["links[0].label"].Should().Equal("link.label_invalid");
        Errors(new ProfileLink("other", "https://a.com", "two\nlines"))["links[0].label"].Should().Equal("link.label_invalid");
        Errors(new ProfileLink("other", "https://a.com", "abc" + (char)0x202E + "def"))["links[0].label"].Should().Equal("link.label_invalid");

        Valid(new ProfileLink("other", "https://a.com", "  مدونتي Blog  ")).Single().Label.Should().Be("مدونتي Blog");
        Valid(new ProfileLink("other", "https://a.com", new string('a', 30)));
        Valid(new ProfileLink("other", "https://a.com", "AB"));
    }

    [Fact]
    public void A_named_platform_takes_no_label() =>
        Errors(new ProfileLink("github", "https://github.com/a", "My code"))["links[0].label"].Should().Equal("link.label_not_allowed");

    [Fact]
    public void Every_broken_rule_is_reported_under_its_index()
    {
        var errors = Errors(
            new ProfileLink("github", "https://github.com/ok"),
            new ProfileLink("x", "http://x.com/a"),
            new ProfileLink("nope", "https://a.com"),
            new ProfileLink("other", "https://b.com"));

        errors.Should().ContainKeys("links[1].url", "links[2].platform", "links[3].label").And.HaveCount(3);
    }

    [Fact]
    public void Links_keep_the_order_sent()
    {
        var user = NewUser();
        user.SetLinks(
        [
            new ProfileLink("website", "mona.dev"),
            new ProfileLink("linkedin", "https://linkedin.com/in/mona"),
            new ProfileLink("github", "https://github.com/mona"),
        ]).IsSuccess.Should().BeTrue();

        user.Links.Select(l => l.Platform).Should().Equal("website", "linkedin", "github");
        user.Links[0].Url.Should().Be("https://mona.dev");
    }

    [Fact]
    public void Bad_links_change_nothing()
    {
        var user = NewUser();
        user.SetLinks([new ProfileLink("github", "https://github.com/mona")]).IsSuccess.Should().BeTrue();

        var result = user.SetLinks([new ProfileLink("github", "http://github.com/mona")]);

        result.IsFailure.Should().BeTrue();
        result.Error!.Details!["links[0].url"].Should().Equal("link.https_required");
        user.Links.Should().Equal(new ProfileLink("github", "https://github.com/mona"));
    }

    [Fact]
    public void The_previous_links_map_to_github_linkedin_website()
    {
        var user = NewUser();

        user.UpdateProfile("Mona", "mona", null, null, new UserLinks
        {
            Website = "https://mona.dev",
            GitHub = "https://github.com/mona",
            LinkedIn = "  ",
        }).IsSuccess.Should().BeTrue();

        user.Links.Should().Equal(new ProfileLink("github", "https://github.com/mona"), new ProfileLink("website", "https://mona.dev"));
    }

    [Fact]
    public void Updating_the_profile_keeps_the_title_and_the_links()
    {
        var user = NewUser();
        user.SetHeadline("Engineer").IsSuccess.Should().BeTrue();
        user.SetLinks([new ProfileLink("github", "https://github.com/mona")]).IsSuccess.Should().BeTrue();

        user.UpdateProfile("Mona", "mona", "bio", null).IsSuccess.Should().BeTrue();

        user.Headline.Should().Be("Engineer");
        user.Links.Should().HaveCount(1);
    }

    [Fact]
    public void The_title_is_trimmed_and_blank_clears_it()
    {
        var user = NewUser();

        user.SetHeadline("  Senior Full Stack .NET Engineer | .NET | Angular  ").IsSuccess.Should().BeTrue();
        user.Headline.Should().Be("Senior Full Stack .NET Engineer | .NET | Angular");

        user.SetHeadline("مهندس برمجيات | .NET").IsSuccess.Should().BeTrue();
        user.Headline.Should().Be("مهندس برمجيات | .NET");

        user.SetHeadline("   ").IsSuccess.Should().BeTrue();
        user.Headline.Should().BeNull();
        user.SetHeadline(null).IsSuccess.Should().BeTrue();
        user.Headline.Should().BeNull();
    }

    [Fact]
    public void The_title_has_at_most_120_characters()
    {
        var user = NewUser();

        user.SetHeadline(new string('a', HeadlineRules.MaxLength)).IsSuccess.Should().BeTrue();
        var result = user.SetHeadline(new string('b', HeadlineRules.MaxLength + 1));

        result.Error!.Details!["headline"].Should().Equal("profile.headline_too_long");
        user.Headline.Should().Be(new string('a', HeadlineRules.MaxLength), "a failed change keeps the title");
        user.SetHeadline("  " + new string('c', HeadlineRules.MaxLength) + "  ").IsSuccess.Should().BeTrue("counted after trimming");
    }

    [Theory]
    [InlineData("two\nlines")]
    [InlineData("tab\there")]
    [InlineData("line\u2028separator")]
    public void The_title_is_one_line(string headline) =>
        NewUser().SetHeadline(headline).Error!.Details!["headline"].Should().Equal("profile.headline_invalid");

    [Theory]
    [InlineData(0x202E)] // right-to-left override
    [InlineData(0x202D)] // left-to-right override
    [InlineData(0x2066)] // left-to-right isolate
    [InlineData(0x200F)] // right-to-left mark
    public void The_title_has_no_direction_control_characters(int character) =>
        NewUser().SetHeadline("abc" + (char)character + "def").Error!.Details!["headline"].Should().Equal("profile.headline_invalid");

    [Fact]
    public void A_moderator_clears_the_links_and_the_title_only_when_there_is_something_to_clear()
    {
        var user = NewUser();
        user.ClearLinks().Should().BeFalse();
        user.ClearHeadline().Should().BeFalse();

        user.SetHeadline("Spam title").IsSuccess.Should().BeTrue();
        user.SetLinks([new ProfileLink("website", "https://spam.example")]).IsSuccess.Should().BeTrue();

        user.ClearLinks().Should().BeTrue();
        user.ClearHeadline().Should().BeTrue();
        user.Links.Should().BeEmpty();
        user.Headline.Should().BeNull();
    }
}
