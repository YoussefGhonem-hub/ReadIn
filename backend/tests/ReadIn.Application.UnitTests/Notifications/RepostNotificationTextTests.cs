using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.UnitTests.Notifications;

/// <summary><c>article_reposted</c> (SPEC F29, F17): its texts in both languages, its link and its setting.</summary>
public sealed class RepostNotificationTextTests
{
    private static string Isolated(string name) => (char)0x2068 + name + (char)0x2069;

    private static NotificationTexts.Input Input(string? actor, int actors) =>
        new(actor, actors, "RAG vs fine-tuning", null, NotificationData.Empty);

    [Fact]
    public void One_reposter_is_named_and_the_body_is_the_article_title()
    {
        NotificationTexts.For(NotificationTypes.ArticleReposted, english: false, Input("أحمد", 1))
            .Should().Be(($"أعاد {Isolated("أحمد")} نشر مقالك", "RAG vs fine-tuning"));
        NotificationTexts.For(NotificationTypes.ArticleReposted, english: true, Input("Ahmed", 1))
            .Should().Be(($"{Isolated("Ahmed")} reposted your article", "RAG vs fine-tuning"));
    }

    [Fact]
    public void Several_reposters_are_aggregated()
    {
        NotificationTexts.For(NotificationTypes.ArticleReposted, english: false, Input("Mona", 2)).Title
            .Should().Be($"أعاد {Isolated("Mona")} وشخص آخر نشر مقالك");
        NotificationTexts.For(NotificationTypes.ArticleReposted, english: false, Input("Mona", 6)).Title
            .Should().Be($"أعاد {Isolated("Mona")} و5 آخرون نشر مقالك");
        NotificationTexts.For(NotificationTypes.ArticleReposted, english: true, Input("Mona", 2)).Title
            .Should().Be($"{Isolated("Mona")} and 1 other reposted your article");
        NotificationTexts.For(NotificationTypes.ArticleReposted, english: true, Input("Mona", 4)).Title
            .Should().Be($"{Isolated("Mona")} and 3 others reposted your article");
        NotificationTexts.For(NotificationTypes.ArticleReposted, english: true, Input(null, 1)).Title
            .Should().Be($"{Isolated("Deleted user")} reposted your article");
    }

    [Fact]
    public void It_links_to_the_article_and_is_a_setting_of_its_own()
    {
        NotificationLinks.For(NotificationTypes.ArticleReposted, 3, "mona", "me", "rag-vs-fine-tuning", null)
            .Should().Be("readin://a/rag-vs-fine-tuning");
        NotificationLinks.For(NotificationTypes.ArticleReposted, 1, "mona", "me", null, null).Should().Be(NotificationLinks.Center);
        NotificationTypes.IsConfigurable(NotificationTypes.ArticleReposted).Should().BeTrue();
        NotificationTypes.IsKnown("article_reposted").Should().BeTrue();
        NotificationTypes.IgnoresQuietHours(NotificationTypes.ArticleReposted).Should().BeFalse();
    }
}
