using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.UnitTests.Notifications;

/// <summary>
/// The official @readin account's day entry (contract-v1 "The official @readin account's articles, grouped per day"):
/// its group key, its link, its push texts in Modern Standard Arabic and English, and how the entry adds an article.
/// </summary>
public sealed class OfficialArticlesNotificationTests
{
    private static readonly Guid Account = Guid.Parse("0195f3a0-0000-7000-8000-00000000e001");

    private static NotificationData Holding(int articles) => new() { ArticleIds = [.. Enumerable.Range(0, articles).Select(_ => Guid.NewGuid())] };

    private static (string Title, string Body) Push(int articles, bool english) =>
        NotificationTexts.For(NotificationTypes.FollowedWriterArticle, english,
            new NotificationTexts.Input("ReadIn", 1, "The newest title", null, Holding(articles)));

    [Fact]
    public void The_group_is_one_day_of_one_account() =>
        OfficialArticles.GroupKey(Account, new DateOnly(2026, 11, 6))
            .Should().Be("followed_writer_article:0195f3a0-0000-7000-8000-00000000e001:2026-11-06");

    [Theory]
    [InlineData(1, "نشر ⁨ReadIn⁩ مقالًا جديدًا")]
    [InlineData(2, "نشر ⁨ReadIn⁩ مقالين جديدين")]
    [InlineData(3, "نشر ⁨ReadIn⁩ 3 مقالات جديدة")]
    [InlineData(10, "نشر ⁨ReadIn⁩ 10 مقالات جديدة")]
    [InlineData(11, "نشر ⁨ReadIn⁩ 11 مقالًا جديدًا")]
    [InlineData(99, "نشر ⁨ReadIn⁩ 99 مقالًا جديدًا")]
    [InlineData(100, "نشر ⁨ReadIn⁩ 100 مقال جديد")]
    [InlineData(103, "نشر ⁨ReadIn⁩ 103 مقالات جديدة")]
    public void The_arabic_title_counts_the_articles_verb_first(int articles, string title) =>
        Push(articles, english: false).Should().Be((title, "The newest title"));

    [Theory]
    [InlineData(1, "⁨ReadIn⁩ published a new article")]
    [InlineData(2, "⁨ReadIn⁩ published 2 new articles")]
    [InlineData(12, "⁨ReadIn⁩ published 12 new articles")]
    public void The_english_title_counts_the_articles(int articles, string title) =>
        Push(articles, english: true).Should().Be((title, "The newest title"));

    [Fact]
    public void Any_other_writers_entry_keeps_the_single_article_text()
    {
        var other = NotificationTexts.For(NotificationTypes.FollowedWriterArticle, english: false,
            new NotificationTexts.Input("Mona", 1, "A title", null, NotificationData.Empty));
        other.Should().Be(("نشر ⁨Mona⁩ مقالًا جديدًا", "A title"));
        OfficialArticles.CountOf(NotificationData.Empty).Should().Be(1);
    }

    [Fact]
    public void One_article_opens_it_and_more_open_the_accounts_profile()
    {
        NotificationLinks.For(NotificationTypes.FollowedWriterArticle, 1, "readin", "me", "rag-basics", null, articleCount: 1)
            .Should().Be("readin://a/rag-basics");
        NotificationLinks.For(NotificationTypes.FollowedWriterArticle, 1, "readin", "me", "rag-basics", null, articleCount: 2)
            .Should().Be("readin://u/readin");
        NotificationLinks.For(NotificationTypes.FollowedWriterArticle, 1, "readin", "me", "rag-basics", null)
            .Should().Be("readin://a/rag-basics", "every other entry holds one article");
    }

    [Fact]
    public void Clients_get_the_number_of_articles_and_never_their_ids()
    {
        var data = Holding(3);
        var stored = NotificationData.Parse(data.Serialize());

        stored.ArticleIds.Should().Equal(data.ArticleIds);
        stored.ToDto().ArticleCount.Should().Be(3);
        NotificationData.Empty.ToDto().ArticleCount.Should().BeNull("the key is only on the official account's entries");
    }

    [Fact]
    public void A_newer_article_moves_the_entry_up_and_a_late_older_one_only_joins_it()
    {
        var at = new DateTime(2026, 11, 6, 9, 0, 0, DateTimeKind.Utc);
        var (first, second, late) = (Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid());
        var entry = Notification.Create(Guid.NewGuid(), NotificationTypes.FollowedWriterArticle, at, at.AddMinutes(10),
            OfficialArticles.GroupKey(Account, DateOnly.FromDateTime(at)), articleId: first, actorId: Account, actorAt: at);
        entry.MarkRead(at.AddMinutes(1));

        entry.AddArticle(Account, at.AddHours(1), second, "{}", at.AddHours(1), at.AddHours(1).AddMinutes(10));
        entry.ArticleId.Should().Be(second, "the newest article is shown");
        (entry.IsRead, entry.SeenAt, entry.UpdatedAt).Should().Be((false, null, at.AddHours(1)));
        (entry.PushStatus, entry.PushAfter).Should().Be((NotificationPushStatus.Pending, at.AddHours(1).AddMinutes(10)));

        entry.AddArticle(Account, at.AddMinutes(30), late, "{}", at.AddHours(2), at.AddHours(2).AddMinutes(10));
        entry.ArticleId.Should().Be(second, "an older article that arrives late doesn't replace the newest");
        entry.UpdatedAt.Should().Be(at.AddHours(2));
        entry.Actors.Should().ContainSingle().Which.At.Should().Be(at.AddHours(1));
    }
}
