using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Notifications;

/// <summary>When a push may go out (SPEC F17, §21.1): at once, or at the end of the user's quiet hours.</summary>
public static class NotificationSchedule
{
    /// <summary>Quiet hours as stored on the user; off, or an empty window, is none.</summary>
    public static QuietHours? QuietHoursOf(bool enabled, TimeOnly start, TimeOnly end) =>
        enabled && start != end ? new QuietHours(start, end) : null;

    /// <summary>
    /// <paramref name="utcNow"/>, or the end of the quiet hours the user is in right now (their time zone).
    /// <c>security_alert</c> ignores quiet hours.
    /// </summary>
    public static DateTime PushAfter(string type, DateTime utcNow, string? timeZone, QuietHours? quietHours)
    {
        if (NotificationTypes.IgnoresQuietHours(type) || quietHours is not { } quiet) return utcNow;

        var zone = DailySchedule.Zone(timeZone);
        var localNow = DailySchedule.LocalNow(utcNow, timeZone);
        if (!quiet.Contains(TimeOnly.FromDateTime(localNow))) return utcNow;

        var end = DateOnly.FromDateTime(localNow).ToDateTime(quiet.End);
        if (end <= localNow) end = end.AddDays(1);
        // A wall-clock time skipped by daylight saving starts at the first valid minute after it.
        while (zone.IsInvalidTime(end)) end = end.AddMinutes(15);
        var utc = TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(end, DateTimeKind.Unspecified), zone);
        return utc > utcNow ? utc : utcNow;
    }
}

/// <summary>Who hears about a new or edited comment, and as what (SPEC F17).</summary>
public static class CommentRecipients
{
    /// <summary>
    /// One notification per recipient per comment, by precedence <c>mention</c> &gt; <c>comment_reply</c> &gt;
    /// <c>article_comment</c>. A new top-level comment tells the article's author, a reply tells the author of the comment
    /// it answers, and every mentioned user gets a mention. An edit only tells users it mentions now; mentions already
    /// notified are dropped by their dedupe key, and the author it already told as article author or replied-to is
    /// skipped. Nobody is told about their own comment.
    /// </summary>
    public static IReadOnlyList<(Guid UserId, string Type)> Resolve(
        CommentChange change,
        Guid commentAuthorId,
        Guid? articleAuthorId,
        Guid? parentAuthorId,
        bool isReply,
        IReadOnlyCollection<Guid> mentioned)
    {
        if (change is not (CommentChange.Created or CommentChange.Edited)) return [];

        var recipients = new List<(Guid, string)>();
        var told = new HashSet<Guid> { commentAuthorId };
        var addressee = isReply ? parentAuthorId : articleAuthorId;

        foreach (var userId in mentioned)
        {
            if (change == CommentChange.Edited && userId == addressee) continue;
            if (told.Add(userId)) recipients.Add((userId, NotificationTypes.Mention));
        }

        if (change == CommentChange.Created && addressee is { } author && told.Add(author))
            recipients.Add((author, isReply ? NotificationTypes.CommentReply : NotificationTypes.ArticleComment));

        return recipients;
    }
}

/// <summary>
/// A <c>mention</c> in an article (SPEC F17): the entry has the article and no comment, links to the article, and each
/// user is told once per article, ever (a comment mention's key is <c>mention:{commentId}</c>).
/// </summary>
public static class ArticleMentions
{
    public static string DedupeKey(Guid articleId) => $"{NotificationTypes.Mention}:article:{articleId}";
}

/// <summary>The reaction milestones of SPEC F17: told once per article and threshold, ever.</summary>
public static class ReactionMilestones
{
    public static readonly IReadOnlyList<int> Thresholds = [10, 50, 100];

    /// <summary>
    /// The milestone to tell the author about at <paramref name="total"/> reactions: the highest one reached, unless that
    /// one or a higher one was told already (a lower one is never told after a higher one).
    /// </summary>
    public static int? Due(int total, IReadOnlyCollection<int> alreadyTold)
    {
        var reached = Thresholds.Where(t => t <= total).DefaultIfEmpty(0).Max();
        if (reached == 0 || alreadyTold.Any(t => t >= reached)) return null;
        return reached;
    }

    public static string DedupeKey(Guid articleId, int threshold) => $"{NotificationTypes.ReactionsMilestone}:{articleId}:{threshold}";
}

/// <summary>
/// The official @readin account's new articles (SPEC F17, contract-v1 "The official @readin account's articles, grouped per
/// day"): instead of one <c>followed_writer_article</c> per article, each follower gets one entry per day of their time zone
/// that counts the account's articles (<see cref="NotificationData.ArticleIds"/>), shows the newest, and opens the
/// account's profile from two articles on. Other writers keep one entry per article.
/// </summary>
public static class OfficialArticles
{
    /// <summary>A batch of articles is one push: it goes out this long after the account's latest article.</summary>
    public static readonly TimeSpan PushDelay = TimeSpan.FromMinutes(10);

    /// <summary>Also the push's collapse key, so a newer push of the day replaces the older one.</summary>
    public static string GroupKey(Guid accountId, DateOnly followerLocalDate) =>
        $"{NotificationTypes.FollowedWriterArticle}:{accountId}:{followerLocalDate:yyyy-MM-dd}";

    /// <summary>How many articles an entry holds: its <see cref="NotificationData.ArticleIds"/>, or 1 for any other entry.</summary>
    public static int CountOf(NotificationData data) => data.ArticleIds is { Count: > 0 } ids ? ids.Count : 1;
}

/// <summary>The deep links of SPEC F17 (docs/api/contract-v1.md), the same in the list and in pushes.</summary>
public static class NotificationLinks
{
    public const string Center = "readin://notifications";
    public const string Stats = "readin://me/stats";
    public const string Account = "readin://settings/account";

    /// <summary>The writer verification page (F19): its status, and a rejection's reason.</summary>
    public const string Verification = "readin://verification";

    public static string Article(string slug) => $"readin://a/{Uri.EscapeDataString(slug)}";

    public static string Comment(string slug, Guid commentId) => $"{Article(slug)}#comment-{commentId}";

    public static string Profile(string username) => $"readin://u/{username}";

    public static string Followers(string username) => $"readin://u/{username}/followers";

    /// <summary>A learning path (F09), e.g. the link of an announcement (F23).</summary>
    public static string Path(string slug) => $"readin://paths/{Uri.EscapeDataString(slug)}";

    /// <summary>The member's ticket (F35, <c>support_reply</c>).</summary>
    public static string SupportTicket(Guid ticketId) => $"readin://support/{ticketId}";

    /// <summary>The ticket in the admin console (F35, <c>support_ticket</c>).</summary>
    public static string AdminSupportTicket(Guid ticketId) => $"readin://admin/support/{ticketId}";

    /// <param name="actorUsername">The latest actor's @username, when they still have an account.</param>
    /// <param name="myUsername">The recipient's @username.</param>
    /// <param name="articleSlug">The article's slug, when it is shown.</param>
    /// <param name="articleCount">The articles the entry holds (<see cref="OfficialArticles.CountOf"/>); 1 for most entries.</param>
    /// <param name="pathSlug">An announcement's learning path (F23), when it links to one.</param>
    /// <param name="ticketId">A support entry's ticket (F35).</param>
    public static string For(
        string type, int actorCount, string? actorUsername, string myUsername, string? articleSlug, Guid? commentId, int articleCount = 1,
        string? pathSlug = null, Guid? ticketId = null) =>
        type switch
        {
            NotificationTypes.NewFollower => actorCount == 1 && actorUsername is not null ? Profile(actorUsername) : Followers(myUsername),
            // The official account's day entry with several articles opens its profile, where they are newest first.
            NotificationTypes.FollowedWriterArticle when articleCount >= 2 && actorUsername is not null => Profile(actorUsername),
            NotificationTypes.ArticleComment or NotificationTypes.CommentReply or NotificationTypes.Mention =>
                articleSlug is null ? Center : commentId is { } id ? Comment(articleSlug, id) : Article(articleSlug),
            NotificationTypes.ReactionsMilestone or NotificationTypes.FollowedWriterArticle or NotificationTypes.DailyArticle
                or NotificationTypes.ArticleReposted =>
                articleSlug is null ? Center : Article(articleSlug),
            NotificationTypes.StreakReminder => Stats,
            NotificationTypes.SecurityAlert => Account,
            // A hidden article opens the article (its author sees the "hidden by moderators" banner); a warning opens the
            // center, and the app shows the notice itself from GET /me/moderation-notices.
            NotificationTypes.ModerationNotice => articleSlug is null ? Center : Article(articleSlug),
            NotificationTypes.VerificationResult => Verification,
            // An announcement opens its article, its path, or the center (F23).
            NotificationTypes.Announcement => articleSlug is not null ? Article(articleSlug) : pathSlug is not null ? Path(pathSlug) : Center,
            // A support reply opens the member's ticket, a new support message the console's ticket (F35).
            NotificationTypes.SupportReply => ticketId is { } replyTicket ? SupportTicket(replyTicket) : Center,
            NotificationTypes.SupportTicket => ticketId is { } adminTicket ? AdminSupportTicket(adminTicket) : Center,
            _ => Center,
        };
}

/// <summary>
/// Push titles and bodies in the user's UI language (SPEC F17, §21.1, §14.4): Modern Standard Arabic, worded as the
/// clients' notification center words them, or English. Names are wrapped in Unicode isolates so a Latin name keeps its
/// place in an Arabic sentence.
/// </summary>
public static class NotificationTexts
{
    public const string ModerationWarningTitleAr = "تلقّيت تحذيرًا من فريق الإشراف";
    public const string ModerationWarningTitleEn = "You received a warning from the moderators";
    public const string ArticleHiddenTitleAr = "أخفى فريق الإشراف مقالك";
    public const string ArticleHiddenTitleEn = "The moderators hid your article";
    public const string VerificationApprovedTitleAr = "أصبحت الآن كاتبًا موثّقًا ✓";
    public const string VerificationApprovedTitleEn = "You're now a verified writer ✓";
    public const string VerificationRejectedTitleAr = "لم تتم الموافقة على طلب توثيقك";
    public const string VerificationRejectedTitleEn = "Your verification request wasn't approved";
    public const string VerificationRejectedBodyAr = "افتحه لمعرفة السبب";
    public const string VerificationRejectedBodyEn = "Open it to see why";
    public const string SupportReplyTitleAr = "ردّ فريق الدعم على تذكرتك";
    public const string SupportReplyTitleEn = "Support replied to your ticket";
    public const string SupportClosedTitleAr = "أُغلقت تذكرتك";
    public const string SupportClosedTitleEn = "Your ticket was closed";

    /// <param name="ActorName">The latest actor's display name; null when they deleted their account.</param>
    /// <param name="ActorCount">Distinct actors.</param>
    /// <param name="ArticleTitle">In the version the user reads.</param>
    /// <param name="CommentExcerpt">The comment, on one line; null for an entry without one (a <c>mention</c> in an article).</param>
    /// <param name="NoticeNote">A moderation notice's note (what the user did wrong).</param>
    /// <param name="NoticeLabel">A moderation notice's target as it was (the hidden article's title).</param>
    public sealed record Input(
        string? ActorName,
        int ActorCount,
        string? ArticleTitle,
        string? CommentExcerpt,
        NotificationData Data,
        string? NoticeNote = null,
        string? NoticeLabel = null);

    public static (string Title, string Body) For(string type, bool english, Input input)
    {
        var name = Isolate(input.ActorName ?? (english ? "Deleted user" : "مستخدم محذوف"));
        var others = Math.Max(0, input.ActorCount - 1);
        var article = input.ArticleTitle ?? string.Empty;
        var comment = input.CommentExcerpt ?? string.Empty;

        return type switch
        {
            NotificationTypes.NewFollower => (english
                ? $"{name}{OthersEn(others)} started following you"
                : $"بدأ {name}{OthersAr(others)} متابعتك", string.Empty),
            NotificationTypes.ArticleComment => (english
                ? $"{name}{OthersEn(others)} commented on your article"
                : $"علّق {name}{OthersAr(others)} على مقالك", comment),
            NotificationTypes.CommentReply => (english
                ? $"{name}{OthersEn(others)} replied to your comment"
                : $"ردّ {name}{OthersAr(others)} على تعليقك", comment),
            NotificationTypes.Mention when input.CommentExcerpt is null =>
                (english ? $"{name} mentioned you in an article" : $"أشار إليك {name} في مقال", article),
            NotificationTypes.Mention => (english ? $"{name} mentioned you in a comment" : $"أشار إليك {name} في تعليق", comment),
            NotificationTypes.ReactionsMilestone => (english
                ? $"Your article reached {input.Data.Threshold} reactions 🎉"
                : $"{ReactionsAr(input.Data.Threshold ?? 0)} 🎉", article),
            // The official account's day entry with several articles (OfficialArticles); the body is the newest one's title.
            NotificationTypes.FollowedWriterArticle when OfficialArticles.CountOf(input.Data) is var n and >= 2 => (english
                ? $"{name} published {n} new articles"
                : $"نشر {name} {ArabicCount(n, "مقالًا جديدًا", "مقالين جديدين", "مقالات جديدة", "مقالًا جديدًا", "مقال جديد")}", article),
            NotificationTypes.FollowedWriterArticle => (english ? $"{name} published a new article" : $"نشر {name} مقالًا جديدًا", article),
            NotificationTypes.ArticleReposted => (english
                ? $"{name}{OthersEn(others)} reposted your article"
                : $"أعاد {name}{OthersAr(others)} نشر مقالك", article),
            NotificationTypes.DailyArticle => (english ? DailyArticlePush.TitleEn : DailyArticlePush.TitleAr, article),
            NotificationTypes.StreakReminder => StreakReminder(english, input.Data.StreakDays ?? 1),
            NotificationTypes.SecurityAlert => (english ? "Security alert" : "تنبيه أمني", SecurityBody(english, input.Data)),
            NotificationTypes.ModerationNotice => input.Data.NoticeKind == NoticeKinds.ArticleHidden
                ? (english ? ArticleHiddenTitleEn : ArticleHiddenTitleAr, input.NoticeLabel ?? input.NoticeNote ?? article)
                : (english ? ModerationWarningTitleEn : ModerationWarningTitleAr, input.NoticeNote ?? string.Empty),
            // The reason of a rejection is only on the verification page, never in a push.
            // An announcement is the team's own text, in the user's language (F23).
            NotificationTypes.Announcement => english
                ? (input.Data.TitleEn ?? "ReadIn", input.Data.BodyEn ?? string.Empty)
                : (input.Data.TitleAr ?? "ReadIn", input.Data.BodyAr ?? string.Empty),
            // Support stays anonymous to the member; the body is the ticket (F35).
            NotificationTypes.SupportReply => input.Data.Closed == true
                ? (english ? SupportClosedTitleEn : SupportClosedTitleAr, TicketLine(input.Data))
                : (english ? SupportReplyTitleEn : SupportReplyTitleAr, TicketLine(input.Data)),
            NotificationTypes.SupportTicket => (english ? $"New support message from {name}" : $"رسالة دعم جديدة من {name}", TicketLine(input.Data)),
            NotificationTypes.VerificationResult => input.Data.Approved switch
            {
                true => (english ? VerificationApprovedTitleEn : VerificationApprovedTitleAr, string.Empty),
                false => english
                    ? (VerificationRejectedTitleEn, VerificationRejectedBodyEn)
                    : (VerificationRejectedTitleAr, VerificationRejectedBodyAr),
                null => (english ? "Your verification request has an answer" : "تم الرد على طلب توثيقك", string.Empty),
            },
            _ => ("ReadIn", string.Empty),
        };
    }

    /// <summary>"#12 · Can't sign in": the ticket's number and subject (the subject isolated, it may be either language).</summary>
    public static string TicketLine(NotificationData data) =>
        data.TicketNumber is { } number ? $"#{number} · {Isolate(data.Subject ?? string.Empty)}" : Isolate(data.Subject ?? string.Empty);

    /// <summary>"Ahmed and 9 others" / "أحمد و9 آخرون" (SPEC §21.1).</summary>
    private static string OthersEn(int others) => others switch
    {
        0 => string.Empty,
        1 => " and 1 other",
        _ => $" and {others} others",
    };

    /// <summary>The verb comes first in the Arabic sentence, so it stays singular: «علّق أحمد و9 آخرون على مقالك».</summary>
    private static string OthersAr(int others) => others switch
    {
        0 => string.Empty,
        1 => " وشخص آخر",
        2 => " وشخصان آخران",
        _ => $" و{others} آخرون",
    };

    /// <summary>Arabic plural categories (CLDR): 1, 2, few = n % 100 in 3..10, many = n % 100 in 11..99, other.</summary>
    private static string ArabicCount(int n, string one, string two, string few, string many, string other) => n switch
    {
        1 => one,
        2 => two,
        _ when n % 100 is >= 3 and <= 10 => $"{n} {few}",
        _ when n % 100 is >= 11 and <= 99 => $"{n} {many}",
        _ => $"{n} {other}",
    };

    private static string ReactionsAr(int n) => n == 1
        ? "تلقّى مقالك أول تفاعل"
        : $"بلغ مقالك {ArabicCount(n, "تفاعلًا واحدًا", "تفاعلين", "تفاعلات", "تفاعلًا", "تفاعل")}";

    private static (string, string) StreakReminder(bool english, int days) => english
        ? ("Don't lose your streak 🔥", $"Your streak is {days} {(days == 1 ? "day" : "days")}. Read an article today to keep it going.")
        : ("حافظ على سلسلة قراءتك 🔥",
            $"سلسلة قراءتك: {ArabicCount(days, "يوم واحد", "يومان", "أيام", "يومًا", "يوم")}. اقرأ مقال اليوم للحفاظ عليها.");

    private static string SecurityBody(bool english, NotificationData data) => data.SecurityChange switch
    {
        Domain.Users.SecurityChange.PasswordChanged => english
            ? "Your password was changed. If this wasn't you, reset it now."
            : "تم تغيير كلمة مرورك. إذا لم تقم بذلك، فأعد تعيينها الآن.",
        Domain.Users.SecurityChange.PasswordReset => english
            ? "Your password was reset with your recovery PIN. If this wasn't you, contact support."
            : "تمت إعادة تعيين كلمة مرورك باستخدام رمز الاسترداد (PIN). إذا لم تقم بذلك، فتواصل مع الدعم.",
        Domain.Users.SecurityChange.RecoveryPinChanged => english
            ? "Your recovery PIN was changed. If this wasn't you, change your password."
            : "تم تغيير رمز الاسترداد (PIN). إذا لم تقم بذلك، فغيّر كلمة المرور.",
        Domain.Users.SecurityChange.PhoneNumberChanged => english
            ? "Your account's phone number was changed. If this wasn't you, contact support."
            : "تم تغيير رقم هاتف حسابك. إذا لم تقم بذلك، فتواصل مع الدعم.",
        Domain.Users.SecurityChange.RecoveryLockedOut => english
            ? "Someone entered a wrong recovery PIN too many times, so recovery is locked for an hour."
            : "أدخل شخص ما رمز استرداد خاطئًا عدة مرات، لذا أُوقف الاسترداد لمدة ساعة.",
        Domain.Users.SecurityChange.ExternalLoginLinked => english
            ? "A Google or Apple account was linked to your account."
            : "تم ربط حساب Google أو Apple بحسابك.",
        Domain.Users.SecurityChange.ExternalLoginUnlinked => english
            ? "A Google or Apple account was unlinked from your account."
            : "تم إلغاء ربط حساب Google أو Apple بحسابك.",
        Domain.Users.SecurityChange.PhoneSignInAdded => english
            ? "Sign in with a phone number and password was added to your account."
            : "تمت إضافة تسجيل الدخول برقم الهاتف وكلمة المرور إلى حسابك.",
        _ => english ? "Something changed in your account's security." : "حدث تغيير أمني في حسابك.",
    };

    /// <summary>First-strong isolate … pop: the name takes its own direction without moving the words around it.</summary>
    private static string Isolate(string text) => $"⁨{text}⁩";
}
