using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Users;

namespace ReadIn.Application.UnitTests.Notifications;

/// <summary>
/// SPEC F17's rules without a database: who hears about a comment and as what, reaction milestones, quiet hours, links,
/// push texts in both languages, the stored data and the push job's limits.
/// </summary>
public sealed class NotificationRulesTests
{
    private static readonly Guid Commenter = Guid.NewGuid();
    private static readonly Guid ArticleAuthor = Guid.NewGuid();
    private static readonly Guid ParentAuthor = Guid.NewGuid();
    private static readonly Guid Reader = Guid.NewGuid();

    // ---- Comment recipients: mention > comment_reply > article_comment ----

    [Fact]
    public void A_new_comment_tells_the_article_author_and_a_reply_tells_the_comment_it_answers()
    {
        CommentRecipients.Resolve(CommentChange.Created, Commenter, ArticleAuthor, null, isReply: false, [])
            .Should().Equal((ArticleAuthor, NotificationTypes.ArticleComment));
        CommentRecipients.Resolve(CommentChange.Created, Commenter, ArticleAuthor, ParentAuthor, isReply: true, [])
            .Should().Equal((ParentAuthor, NotificationTypes.CommentReply));
    }

    [Fact]
    public void A_mention_wins_over_the_other_types_and_nobody_hears_about_their_own_comment()
    {
        CommentRecipients.Resolve(CommentChange.Created, Commenter, ArticleAuthor, null, isReply: false, [ArticleAuthor, Reader, Commenter])
            .Should().Equal((ArticleAuthor, NotificationTypes.Mention), (Reader, NotificationTypes.Mention));
        CommentRecipients.Resolve(CommentChange.Created, Commenter, ArticleAuthor, ParentAuthor, isReply: true, [ParentAuthor])
            .Should().Equal((ParentAuthor, NotificationTypes.Mention));

        CommentRecipients.Resolve(CommentChange.Created, ArticleAuthor, ArticleAuthor, null, isReply: false, []).Should().BeEmpty();
        CommentRecipients.Resolve(CommentChange.Created, ParentAuthor, ArticleAuthor, ParentAuthor, isReply: true, []).Should().BeEmpty();
    }

    [Fact]
    public void An_edit_only_tells_mentioned_users_not_the_one_the_comment_already_told()
    {
        CommentRecipients.Resolve(CommentChange.Edited, Commenter, ArticleAuthor, null, isReply: false, [ArticleAuthor, Reader])
            .Should().Equal((Reader, NotificationTypes.Mention));
        CommentRecipients.Resolve(CommentChange.Edited, Commenter, ArticleAuthor, ParentAuthor, isReply: true, [ParentAuthor, ArticleAuthor])
            .Should().Equal((ArticleAuthor, NotificationTypes.Mention));
        CommentRecipients.Resolve(CommentChange.Edited, Commenter, ArticleAuthor, null, isReply: false, []).Should().BeEmpty();
    }

    [Theory]
    [InlineData(CommentChange.Deleted)]
    [InlineData(CommentChange.Hidden)]
    [InlineData(CommentChange.Liked)]
    [InlineData(CommentChange.Pinned)]
    public void Other_comment_changes_tell_nobody(CommentChange change) =>
        CommentRecipients.Resolve(change, Commenter, ArticleAuthor, null, isReply: false, [Reader]).Should().BeEmpty();

    // ---- Reaction milestones ----

    [Theory]
    [InlineData(9, new int[0], null)]
    [InlineData(10, new int[0], 10)]
    [InlineData(11, new int[0], 10)]
    [InlineData(10, new[] { 10 }, null)]
    [InlineData(50, new[] { 10 }, 50)]
    [InlineData(57, new int[0], 50)]
    [InlineData(100, new[] { 10, 50 }, 100)]
    [InlineData(250, new[] { 100 }, null)]
    [InlineData(49, new[] { 100 }, null)]
    public void The_highest_milestone_reached_is_told_once_and_never_after_a_higher_one(int total, int[] told, int? expected) =>
        ReactionMilestones.Due(total, told).Should().Be(expected);

    // ---- Quiet hours ----

    private static readonly QuietHours Night = new(new TimeOnly(23, 0), new TimeOnly(7, 0));

    [Fact]
    public void Outside_quiet_hours_a_push_goes_now()
    {
        var noonCairo = new DateTime(2026, 11, 4, 10, 0, 0, DateTimeKind.Utc); // 12:00 in Cairo (UTC+2 in November)

        NotificationSchedule.PushAfter(NotificationTypes.NewFollower, noonCairo, "Africa/Cairo", Night).Should().Be(noonCairo);
        NotificationSchedule.PushAfter(NotificationTypes.NewFollower, noonCairo, "Africa/Cairo", null).Should().Be(noonCairo);
    }

    [Theory]
    [InlineData(21, 30, 2026, 11, 5, 5)] // 23:30 Cairo: tomorrow 07:00 Cairo
    [InlineData(1, 0, 2026, 11, 4, 5)] // 03:00 Cairo: today 07:00 Cairo
    [InlineData(4, 59, 2026, 11, 4, 5)] // 06:59 Cairo
    public void Inside_quiet_hours_a_push_waits_for_their_end(int utcHour, int utcMinute, int year, int month, int day, int endUtcHour)
    {
        var now = new DateTime(2026, 11, 4, utcHour, utcMinute, 0, DateTimeKind.Utc);

        NotificationSchedule.PushAfter(NotificationTypes.Mention, now, "Africa/Cairo", Night)
            .Should().Be(new DateTime(year, month, day, endUtcHour, 0, 0, DateTimeKind.Utc));
    }

    [Fact]
    public void The_end_is_exclusive_security_alerts_ignore_quiet_hours_and_windows_need_not_span_midnight()
    {
        var sevenCairo = new DateTime(2026, 11, 4, 5, 0, 0, DateTimeKind.Utc);
        NotificationSchedule.PushAfter(NotificationTypes.Mention, sevenCairo, "Africa/Cairo", Night).Should().Be(sevenCairo);

        var night = new DateTime(2026, 11, 4, 22, 0, 0, DateTimeKind.Utc);
        NotificationSchedule.PushAfter(NotificationTypes.SecurityAlert, night, "Africa/Cairo", Night).Should().Be(night);

        var lunch = new QuietHours(new TimeOnly(13, 0), new TimeOnly(14, 30));
        NotificationSchedule.PushAfter(NotificationTypes.StreakReminder, new DateTime(2026, 11, 4, 13, 15, 0, DateTimeKind.Utc), "UTC", lunch)
            .Should().Be(new DateTime(2026, 11, 4, 14, 30, 0, DateTimeKind.Utc));
    }

    [Fact]
    public void Quiet_hours_off_or_empty_are_none()
    {
        NotificationSchedule.QuietHoursOf(false, new TimeOnly(23, 0), new TimeOnly(7, 0)).Should().BeNull();
        NotificationSchedule.QuietHoursOf(true, new TimeOnly(7, 0), new TimeOnly(7, 0)).Should().BeNull();
        NotificationSchedule.QuietHoursOf(true, new TimeOnly(23, 0), new TimeOnly(7, 0)).Should().Be(Night);
    }

    // ---- Links ----

    [Fact]
    public void Links_follow_the_contract()
    {
        var comment = Guid.NewGuid();

        NotificationLinks.For(NotificationTypes.NewFollower, 1, "ahmed", "me", null, null).Should().Be("readin://u/ahmed");
        NotificationLinks.For(NotificationTypes.NewFollower, 3, "ahmed", "me", null, null).Should().Be("readin://u/me/followers");
        NotificationLinks.For(NotificationTypes.NewFollower, 1, null, "me", null, null).Should().Be("readin://u/me/followers");
        foreach (var type in new[] { NotificationTypes.ArticleComment, NotificationTypes.CommentReply, NotificationTypes.Mention })
            NotificationLinks.For(type, 1, "ahmed", "me", "rag-vs-fine-tuning", comment).Should().Be($"readin://a/rag-vs-fine-tuning#comment-{comment}");
        foreach (var type in new[] { NotificationTypes.ReactionsMilestone, NotificationTypes.FollowedWriterArticle, NotificationTypes.DailyArticle })
            NotificationLinks.For(type, 0, null, "me", "rag-vs-fine-tuning", null).Should().Be("readin://a/rag-vs-fine-tuning");
        NotificationLinks.For(NotificationTypes.StreakReminder, 0, null, "me", null, null).Should().Be("readin://me/stats");
        NotificationLinks.For(NotificationTypes.SecurityAlert, 0, null, "me", null, null).Should().Be("readin://settings/account");
        NotificationLinks.For(NotificationTypes.ModerationNotice, 0, null, "me", "hidden-one", null).Should().Be("readin://a/hidden-one");
        NotificationLinks.For(NotificationTypes.ModerationNotice, 0, null, "me", null, null).Should().Be("readin://notifications");
        NotificationLinks.For(NotificationTypes.VerificationResult, 0, null, "me", null, null).Should().Be("readin://verification");
        NotificationLinks.Article("مقال عربي").Should().Be("readin://a/%D9%85%D9%82%D8%A7%D9%84%20%D8%B9%D8%B1%D8%A8%D9%8A");
    }

    // ---- Push texts ----

    private static NotificationTexts.Input Input(string? actor, int actors, NotificationData? data = null) =>
        new(actor, actors, "RAG vs fine-tuning", "تعليق قصير", data ?? NotificationData.Empty);

    [Fact]
    public void Aggregated_texts_say_who_and_how_many_others()
    {
        NotificationTexts.For(NotificationTypes.ArticleComment, english: false, Input("أحمد", 10))
            .Should().Be(("⁨أحمد⁩ و9 غيره علّقوا على مقالك", "تعليق قصير"));
        NotificationTexts.For(NotificationTypes.ArticleComment, english: true, Input("Ahmed", 10)).Title
            .Should().Be("⁨Ahmed⁩ and 9 others commented on your article");
        NotificationTexts.For(NotificationTypes.ArticleComment, english: true, Input("Ahmed", 2)).Title
            .Should().Be("⁨Ahmed⁩ and 1 other commented on your article");
        NotificationTexts.For(NotificationTypes.ArticleComment, english: false, Input("Ahmed", 1)).Title
            .Should().Be("⁨Ahmed⁩ علّق على مقالك");
        NotificationTexts.For(NotificationTypes.CommentReply, english: false, Input("Mona", 2)).Title
            .Should().Be("⁨Mona⁩ وشخص تاني ردّوا على تعليقك");
        NotificationTexts.For(NotificationTypes.NewFollower, english: true, Input("Sara", 3))
            .Should().Be(("⁨Sara⁩ and 2 others started following you", ""));
        NotificationTexts.For(NotificationTypes.NewFollower, english: false, Input("سارة", 1)).Title.Should().Be("⁨سارة⁩ بدأ يتابعك");
    }

    [Fact]
    public void A_deleted_actor_is_deleted_user()
    {
        NotificationTexts.For(NotificationTypes.Mention, english: true, Input(null, 0)).Title
            .Should().Be("⁨Deleted user⁩ mentioned you in a comment");
        NotificationTexts.For(NotificationTypes.Mention, english: false, Input(null, 0)).Title
            .Should().Be("⁨مستخدم محذوف⁩ عمل لك منشن في تعليق");
    }

    [Fact]
    public void Other_types_have_their_own_texts()
    {
        NotificationTexts.For(NotificationTypes.ReactionsMilestone, english: true, Input(null, 0, new NotificationData { Threshold = 50 }))
            .Should().Be(("Your article reached 50 reactions 🎉", "RAG vs fine-tuning"));
        NotificationTexts.For(NotificationTypes.ReactionsMilestone, english: false, Input(null, 0, new NotificationData { Threshold = 10 })).Title
            .Should().Be("مقالك وصل لـ 10 رياكشن 🎉");
        NotificationTexts.For(NotificationTypes.FollowedWriterArticle, english: true, Input("Mona", 1))
            .Should().Be(("⁨Mona⁩ published a new article", "RAG vs fine-tuning"));
        NotificationTexts.For(NotificationTypes.DailyArticle, english: false, Input(null, 0)).Title.Should().Be(DailyArticlePush.TitleAr);
        NotificationTexts.For(NotificationTypes.StreakReminder, english: true, Input(null, 0, new NotificationData { StreakDays = 1 })).Body
            .Should().Be("Your streak is 1 day. Read an article today to keep it going.");
        NotificationTexts.For(NotificationTypes.StreakReminder, english: false, Input(null, 0, new NotificationData { StreakDays = 5 })).Body
            .Should().Be("الـ streak بتاعك 5 أيام. اقرا مقال النهارده عشان تكمّل.");
        NotificationTexts.For(NotificationTypes.StreakReminder, english: false, Input(null, 0, new NotificationData { StreakDays = 12 })).Body
            .Should().StartWith("الـ streak بتاعك 12 يوم.");
        foreach (var change in Enum.GetValues<SecurityChange>())
        {
            var (title, body) = NotificationTexts.For(NotificationTypes.SecurityAlert, english: false,
                Input(null, 0, new NotificationData { SecurityChange = change }));
            title.Should().Be("تنبيه أمان");
            body.Should().NotBeNullOrWhiteSpace().And.NotBe("حاجة اتغيّرت في أمان حسابك.", $"{change} has its own text");
        }
    }

    [Fact]
    public void A_mention_in_an_article_says_so_with_the_title_as_the_body()
    {
        var inArticle = new NotificationTexts.Input("Mona", 1, "RAG vs fine-tuning", null, NotificationData.Empty);

        NotificationTexts.For(NotificationTypes.Mention, english: true, inArticle)
            .Should().Be(("⁨Mona⁩ mentioned you in an article", "RAG vs fine-tuning"));
        NotificationTexts.For(NotificationTypes.Mention, english: false, inArticle)
            .Should().Be(("⁨Mona⁩ عمل لك منشن في مقال", "RAG vs fine-tuning"));
        NotificationTexts.For(NotificationTypes.Mention, english: true, Input("Mona", 1))
            .Should().Be(("⁨Mona⁩ mentioned you in a comment", "تعليق قصير"), "a comment's mention keeps its text");
    }

    [Fact]
    public void A_mention_in_an_article_opens_the_article_and_is_told_once_per_article()
    {
        var article = Guid.NewGuid();

        NotificationLinks.For(NotificationTypes.Mention, 1, "mona", "me", "rag-vs-fine-tuning", commentId: null)
            .Should().Be("readin://a/rag-vs-fine-tuning");
        NotificationLinks.For(NotificationTypes.Mention, 1, "mona", "me", articleSlug: null, commentId: null)
            .Should().Be("readin://notifications");
        ArticleMentions.DedupeKey(article).Should().Be($"mention:article:{article}");
    }

    [Fact]
    public void Moderation_notices_keep_F22s_texts()
    {
        var warning = new NotificationTexts.Input(null, 0, null, null,
            new NotificationData { NoticeKind = NoticeKinds.Warning }, NoticeNote: "No spam.");
        NotificationTexts.For(NotificationTypes.ModerationNotice, english: true, warning)
            .Should().Be((NotificationTexts.ModerationWarningTitleEn, "No spam."));

        var hidden = new NotificationTexts.Input(null, 0, "Live title", null,
            new NotificationData { NoticeKind = NoticeKinds.ArticleHidden }, NoticeNote: "No sources.", NoticeLabel: "Title when hidden");
        NotificationTexts.For(NotificationTypes.ModerationNotice, english: false, hidden)
            .Should().Be((NotificationTexts.ArticleHiddenTitleAr, "Title when hidden"));
    }

    // ---- Stored data and excerpts ----

    [Fact]
    public void Data_round_trips_and_clients_see_only_their_fields()
    {
        var notice = Guid.NewGuid();
        var data = new NotificationData { SecurityChange = SecurityChange.PhoneNumberChanged, NoticeId = notice, NoticeKind = "warning" };

        var json = data.Serialize();
        json.Should().Contain("\"securityChange\":\"phoneNumberChanged\"").And.NotContain("threshold");
        NotificationData.Parse(json).Should().Be(data);
        data.ToDto().Should().Be(new NotificationDataDto(null, null, SecurityChange.PhoneNumberChanged));

        NotificationData.Empty.Serialize().Should().BeNull();
        NotificationData.Parse(null).Should().Be(NotificationData.Empty);
        NotificationData.Parse("{not json").Should().Be(NotificationData.Empty);
        NotificationData.Name(SecurityChange.ExternalLoginUnlinked).Should().Be("externalLoginUnlinked");
    }

    [Fact]
    public void An_excerpt_is_one_line_of_at_most_140_characters_and_never_splits_an_emoji()
    {
        NotificationExcerpt.Of("  سطر أول\n\nسطر   تاني ").Should().Be("سطر أول سطر تاني");
        NotificationExcerpt.Of(null).Should().BeEmpty();
        NotificationExcerpt.Of(new string('a', 200)).Should().HaveLength(NotificationExcerpt.MaxLength);

        var emojiAtTheEdge = new string('a', 139) + "🔥🔥";
        NotificationExcerpt.Of(emojiAtTheEdge).Should().Be(new string('a', 139));
    }

    // ---- The push job's limits and the streak reminder's clock ----

    [Fact]
    public void Pushes_are_dropped_after_24_hours_the_streak_reminder_after_4_and_retries_back_off()
    {
        NotificationPusher.MaxAgeOf(NotificationTypes.Mention).Should().Be(TimeSpan.FromHours(24));
        NotificationPusher.MaxAgeOf(NotificationTypes.StreakReminder).Should().Be(TimeSpan.FromHours(4));
        NotificationPusher.RetryDelay(1).Should().Be(TimeSpan.FromMinutes(1));
        NotificationPusher.RetryDelay(2).Should().Be(TimeSpan.FromMinutes(5));
    }

    [Theory]
    [InlineData(19, 59, false)]
    [InlineData(20, 0, true)]
    [InlineData(21, 30, true)]
    [InlineData(22, 0, true)]
    [InlineData(22, 1, false)]
    [InlineData(8, 0, false)]
    public void The_streak_reminder_is_due_from_20_00_to_22_00_local(int hour, int minute, bool due)
    {
        StreakReminders.IsDue(new DateTime(2026, 11, 4, hour, minute, 0)).Should().Be(due);
        StreakReminders.DedupeKey(new DateOnly(2026, 11, 4)).Should().Be("streak_reminder:2026-11-04");
    }
}
