using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.UnitTests.Notifications;

/// <summary><c>announcement</c> (SPEC F23, F17): its text in the reader's language, its link, its data and its setting.</summary>
public sealed class AnnouncementNotificationTests
{
    private static readonly Guid AnnouncementId = Guid.Parse("0195f3a0-0000-7000-8000-0000000000a1");

    private static readonly NotificationData Data = new()
    {
        AnnouncementId = AnnouncementId,
        TitleAr = "مسارات جديدة",
        TitleEn = "New learning paths",
        BodyAr = "أضفنا ثلاثة مسارات في الذكاء الاصطناعي.",
        BodyEn = "We added three AI paths.",
    };

    [Fact]
    public void The_push_is_the_announcements_own_text_in_the_users_language()
    {
        var input = new NotificationTexts.Input(null, 0, null, null, Data);

        NotificationTexts.For(NotificationTypes.Announcement, english: false, input)
            .Should().Be(("مسارات جديدة", "أضفنا ثلاثة مسارات في الذكاء الاصطناعي."));
        NotificationTexts.For(NotificationTypes.Announcement, english: true, input)
            .Should().Be(("New learning paths", "We added three AI paths."));
    }

    [Fact]
    public void It_opens_its_article_its_path_or_the_center()
    {
        NotificationLinks.For(NotificationTypes.Announcement, 0, null, "me", "rag-vs-fine-tuning", null).Should().Be("readin://a/rag-vs-fine-tuning");
        NotificationLinks.For(NotificationTypes.Announcement, 0, null, "me", null, null, pathSlug: "dotnet-basics")
            .Should().Be("readin://paths/dotnet-basics");
        NotificationLinks.For(NotificationTypes.Announcement, 0, null, "me", null, null).Should().Be(NotificationLinks.Center);
        NotificationLinks.Path("أساسيات").Should().Be("readin://paths/%D8%A3%D8%B3%D8%A7%D8%B3%D9%8A%D8%A7%D8%AA");
    }

    [Fact]
    public void Clients_get_the_text_in_their_ui_language_and_the_data_round_trips()
    {
        var parsed = NotificationData.Parse(Data.Serialize());
        parsed.Should().Be(Data);

        var arabic = parsed.ToDto("ar");
        (arabic.AnnouncementId, arabic.Title, arabic.Body).Should().Be((AnnouncementId, "مسارات جديدة", "أضفنا ثلاثة مسارات في الذكاء الاصطناعي."));
        var english = parsed.ToDto("en");
        (english.Title, english.Body).Should().Be(("New learning paths", "We added three AI paths."));

        // Other types carry none of it.
        var other = new NotificationData { Threshold = 10 }.ToDto("en");
        (other.AnnouncementId, other.Title, other.Body).Should().Be(((Guid?)null, (string?)null, (string?)null));
    }

    [Fact]
    public void It_is_a_setting_of_its_own_and_quiet_hours_apply()
    {
        NotificationTypes.IsKnown("announcement").Should().BeTrue();
        NotificationTypes.IsConfigurable(NotificationTypes.Announcement).Should().BeTrue();
        NotificationTypes.IgnoresQuietHours(NotificationTypes.Announcement).Should().BeFalse();
    }
}
