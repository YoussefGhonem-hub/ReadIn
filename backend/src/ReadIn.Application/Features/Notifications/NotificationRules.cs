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

    /// <param name="actorUsername">The latest actor's @username, when they still have an account.</param>
    /// <param name="myUsername">The recipient's @username.</param>
    /// <param name="articleSlug">The article's slug, when it is shown.</param>
    public static string For(string type, int actorCount, string? actorUsername, string myUsername, string? articleSlug, Guid? commentId) =>
        type switch
        {
            NotificationTypes.NewFollower => actorCount == 1 && actorUsername is not null ? Profile(actorUsername) : Followers(myUsername),
            NotificationTypes.ArticleComment or NotificationTypes.CommentReply or NotificationTypes.Mention =>
                articleSlug is null ? Center : commentId is { } id ? Comment(articleSlug, id) : Article(articleSlug),
            NotificationTypes.ReactionsMilestone or NotificationTypes.FollowedWriterArticle or NotificationTypes.DailyArticle =>
                articleSlug is null ? Center : Article(articleSlug),
            NotificationTypes.StreakReminder => Stats,
            NotificationTypes.SecurityAlert => Account,
            // A hidden article opens the article (its author sees the "hidden by moderators" banner); a warning opens the
            // center, and the app shows the notice itself from GET /me/moderation-notices.
            NotificationTypes.ModerationNotice => articleSlug is null ? Center : Article(articleSlug),
            NotificationTypes.VerificationResult => Verification,
            _ => Center,
        };
}

/// <summary>
/// Push titles and bodies in the user's UI language (SPEC F17, §21.1): Egyptian Arabic with English technical terms, or
/// English. Names are wrapped in Unicode isolates so a Latin name keeps its place in an Arabic sentence.
/// </summary>
public static class NotificationTexts
{
    public const string ModerationWarningTitleAr = "وصلك تحذير من فريق الإشراف";
    public const string ModerationWarningTitleEn = "You received a warning from the moderators";
    public const string ArticleHiddenTitleAr = "فريق الإشراف خفى مقالك";
    public const string ArticleHiddenTitleEn = "The moderators hid your article";
    public const string VerificationApprovedTitleAr = "بقيت كاتب موثّق ✓";
    public const string VerificationApprovedTitleEn = "You're now a verified writer ✓";
    public const string VerificationRejectedTitleAr = "طلب التوثيق بتاعك ماتقبلش";
    public const string VerificationRejectedTitleEn = "Your verification request wasn't approved";
    public const string VerificationRejectedBodyAr = "افتحه عشان تعرف السبب";
    public const string VerificationRejectedBodyEn = "Open it to see why";

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
                : others == 0 ? $"{name} بدأ يتابعك" : $"{name}{OthersAr(others)} بدأوا يتابعوك", string.Empty),
            NotificationTypes.ArticleComment => (english
                ? $"{name}{OthersEn(others)} commented on your article"
                : others == 0 ? $"{name} علّق على مقالك" : $"{name}{OthersAr(others)} علّقوا على مقالك", comment),
            NotificationTypes.CommentReply => (english
                ? $"{name}{OthersEn(others)} replied to your comment"
                : others == 0 ? $"{name} ردّ على تعليقك" : $"{name}{OthersAr(others)} ردّوا على تعليقك", comment),
            NotificationTypes.Mention when input.CommentExcerpt is null =>
                (english ? $"{name} mentioned you in an article" : $"{name} عمل لك منشن في مقال", article),
            NotificationTypes.Mention => (english ? $"{name} mentioned you in a comment" : $"{name} عمل لك منشن في تعليق", comment),
            NotificationTypes.ReactionsMilestone => (english
                ? $"Your article reached {input.Data.Threshold} reactions 🎉"
                : $"مقالك وصل لـ {input.Data.Threshold} رياكشن 🎉", article),
            NotificationTypes.FollowedWriterArticle => (english ? $"{name} published a new article" : $"{name} نشر مقال جديد", article),
            NotificationTypes.DailyArticle => (english ? DailyArticlePush.TitleEn : DailyArticlePush.TitleAr, article),
            NotificationTypes.StreakReminder => StreakReminder(english, input.Data.StreakDays ?? 1),
            NotificationTypes.SecurityAlert => (english ? "Security alert" : "تنبيه أمان", SecurityBody(english, input.Data)),
            NotificationTypes.ModerationNotice => input.Data.NoticeKind == NoticeKinds.ArticleHidden
                ? (english ? ArticleHiddenTitleEn : ArticleHiddenTitleAr, input.NoticeLabel ?? input.NoticeNote ?? article)
                : (english ? ModerationWarningTitleEn : ModerationWarningTitleAr, input.NoticeNote ?? string.Empty),
            // The reason of a rejection is only on the verification page, never in a push.
            NotificationTypes.VerificationResult => input.Data.Approved switch
            {
                true => (english ? VerificationApprovedTitleEn : VerificationApprovedTitleAr, string.Empty),
                false => english
                    ? (VerificationRejectedTitleEn, VerificationRejectedBodyEn)
                    : (VerificationRejectedTitleAr, VerificationRejectedBodyAr),
                null => (english ? "Your verification request has an answer" : "طلب التوثيق بتاعك اترد عليه", string.Empty),
            },
            _ => ("ReadIn", string.Empty),
        };
    }

    /// <summary>"Ahmed and 9 others" / "أحمد و9 غيره" (SPEC §21.1).</summary>
    private static string OthersEn(int others) => others switch
    {
        0 => string.Empty,
        1 => " and 1 other",
        _ => $" and {others} others",
    };

    private static string OthersAr(int others) => others == 1 ? " وشخص تاني" : $" و{others} غيره";

    private static (string, string) StreakReminder(bool english, int days) => english
        ? ("Don't lose your streak 🔥", $"Your streak is {days} {(days == 1 ? "day" : "days")}. Read an article today to keep it going.")
        : ("متضيّعش الـ streak بتاعك 🔥", $"الـ streak بتاعك {days} {(days is >= 3 and <= 10 ? "أيام" : "يوم")}. اقرا مقال النهارده عشان تكمّل.");

    private static string SecurityBody(bool english, NotificationData data) => data.SecurityChange switch
    {
        Domain.Users.SecurityChange.PasswordChanged => english
            ? "Your password was changed. If this wasn't you, reset it now."
            : "كلمة السر بتاعتك اتغيّرت. لو مش إنت، غيّرها فورًا.",
        Domain.Users.SecurityChange.PasswordReset => english
            ? "Your password was reset with your recovery PIN. If this wasn't you, contact support."
            : "كلمة السر بتاعتك اتغيّرت بالـ PIN بتاع الاسترجاع. لو مش إنت، كلّم الدعم.",
        Domain.Users.SecurityChange.RecoveryPinChanged => english
            ? "Your recovery PIN was changed. If this wasn't you, change your password."
            : "الـ PIN بتاع الاسترجاع اتغيّر. لو مش إنت، غيّر كلمة السر.",
        Domain.Users.SecurityChange.PhoneNumberChanged => english
            ? "Your account's phone number was changed. If this wasn't you, contact support."
            : "رقم التليفون بتاع حسابك اتغيّر. لو مش إنت، كلّم الدعم.",
        Domain.Users.SecurityChange.RecoveryLockedOut => english
            ? "Someone entered a wrong recovery PIN too many times, so recovery is locked for an hour."
            : "حد دخّل PIN استرجاع غلط كذا مرة، فوقفنا الاسترجاع لمدة ساعة.",
        Domain.Users.SecurityChange.ExternalLoginLinked => english
            ? "A Google or Apple account was linked to your account."
            : "اتربط حساب Google أو Apple بحسابك.",
        Domain.Users.SecurityChange.ExternalLoginUnlinked => english
            ? "A Google or Apple account was unlinked from your account."
            : "اتشال ربط حساب Google أو Apple من حسابك.",
        Domain.Users.SecurityChange.PhoneSignInAdded => english
            ? "Sign in with a phone number and password was added to your account."
            : "اتضاف دخول برقم تليفون وكلمة سر لحسابك.",
        _ => english ? "Something changed in your account's security." : "حاجة اتغيّرت في أمان حسابك.",
    };

    /// <summary>First-strong isolate … pop: the name takes its own direction without moving the words around it.</summary>
    private static string Isolate(string text) => $"⁨{text}⁩";
}
