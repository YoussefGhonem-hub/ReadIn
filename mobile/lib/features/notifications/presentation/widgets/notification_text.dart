import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';

/// Types whose row is about a person: their avatar leads it and their name starts the sentence.
bool isActorNotification(NotificationType type) => switch (type) {
      NotificationType.newFollower ||
      NotificationType.articleComment ||
      NotificationType.commentReply ||
      NotificationType.mention ||
      NotificationType.followedWriterArticle ||
      NotificationType.articleReposted ||
      // A new ticket or a member's reply (F35): the member leads the row.
      NotificationType.supportTicket =>
        true,
      _ => false,
    };

/// The sentence of [notification] in the UI language (F17): "Ahmed and 9 others commented on your article" for an
/// aggregated row (ICU plurals), "Deleted user" for an actor whose account is gone. [name] replaces the actor's name
/// (the tile passes a marker to set the name in bold).
String notificationMessage(AppLocalizations l10n, AppNotification notification, {String? name}) {
  final actor = name ?? notification.actor?.displayName ?? l10n.deletedUser;
  final others = notification.otherActors;
  return switch (notification.type) {
    NotificationType.newFollower => l10n.notifNewFollower(actor, others),
    NotificationType.articleComment => l10n.notifArticleComment(actor, others),
    NotificationType.commentReply => l10n.notifCommentReply(actor, others),
    // A mention without a comment is in an article: the author, once per article (its title follows).
    NotificationType.mention =>
      notification.comment == null ? l10n.notifMentionArticle(actor) : l10n.notifMention(actor, others),
    // The official @readin account's day entry with 2 or more articles: "نشر ReadIn 3 مقالات جديدة"; the newest title
    // follows, and the row opens its link (the account's profile).
    NotificationType.followedWriterArticle => switch (notification.articleCount) {
        final count? when count >= 2 => l10n.notifFollowedWriterArticles(actor, count),
        _ => l10n.notifFollowedWriterArticle(actor),
      },
    // "Ahmed reposted your article" / "Ahmed and 2 others reposted your article"; the title follows.
    NotificationType.articleReposted => l10n.notifArticleReposted(actor, others),
    NotificationType.reactionsMilestone => switch (notification.threshold) {
        final threshold? when threshold > 0 => l10n.notifReactionsMilestone(threshold),
        _ => l10n.notifReactionsMilestoneGeneric,
      },
    NotificationType.dailyArticle => l10n.notifDailyArticle,
    NotificationType.streakReminder => switch (notification.streakDays) {
        final days? when days > 0 => l10n.notifStreakReminder(days),
        _ => l10n.notifStreakReminderGeneric,
      },
    NotificationType.securityAlert => securityChangeMessage(l10n, notification.securityChange),
    // The reason of a rejection is only on the verification page (F19).
    NotificationType.verificationResult => switch (notification.approved) {
        true => l10n.notifVerificationApproved,
        false => l10n.notifVerificationRejected,
        null => l10n.notifVerificationResult,
      },
    // A notice about an article means it was hidden; one without is a warning (F22).
    NotificationType.moderationNotice =>
      notification.article == null ? l10n.notifModerationWarning : l10n.notifModerationArticleHidden,
    // An announcement's own title, in the UI language (F23); its body follows ([notificationDetail]).
    NotificationType.announcement => switch (notification.title?.trim()) {
        final title? when title.isNotEmpty => title,
        _ => l10n.adminNotifAnnouncement,
      },
    // Support stays anonymous (F35); "#12 · subject" follows.
    NotificationType.supportReply => notification.closed ? l10n.supportNotifClosed : l10n.supportNotifReply,
    NotificationType.supportTicket => l10n.supportNotifTicket(actor),
    // F22 store additions: "New report: comment"; the target's label follows.
    NotificationType.reportNew => l10n.notifReportNew(notification.reportTargetType ?? 'other'),
    // Never who acted, nor what was done to a user.
    NotificationType.reportResolved => switch (notification.reportOutcome) {
        ReportOutcome.actioned when notification.reportTargetType == 'user' => l10n.notifReportResolvedUser,
        ReportOutcome.actioned => l10n.notifReportResolvedRemoved,
        ReportOutcome.noViolation => l10n.notifReportResolvedNoViolation,
        null => l10n.notifReportResolved,
      },
    NotificationType.unknown => l10n.notifGeneric,
  };
}

/// The line under the sentence that isn't an article or a comment: an announcement's body (F23), or a ticket's
/// "#12 · subject" (F35). Null for every other type.
String? notificationDetail(AppNotification notification) {
  switch (notification.type) {
    case NotificationType.announcement:
      final body = notification.body?.trim() ?? '';
      return body.isEmpty ? null : body;
    case NotificationType.supportReply || NotificationType.supportTicket:
      final subject = notification.subject?.trim() ?? '';
      final number = notification.ticketNumber;
      if (number == null) return subject.isEmpty ? null : subject;
      final tag = Bidi.ltrIsolate('#$number');
      return subject.isEmpty ? tag : '$tag · $subject';
    case NotificationType.reportNew || NotificationType.reportResolved:
      final label = notification.targetLabel?.trim() ?? '';
      return label.isEmpty ? null : label;
    default:
      return null;
  }
}

/// `report_new` of the content filter (F22, F37): «رصده فلتر المحتوى» under the sentence.
String? notificationSource(AppLocalizations l10n, AppNotification notification) =>
    notification.type == NotificationType.reportNew && notification.systemReport ? l10n.notifReportSystem : null;

String securityChangeMessage(AppLocalizations l10n, SecurityChange? change) => switch (change) {
      SecurityChange.passwordChanged => l10n.notifSecurityPasswordChanged,
      SecurityChange.passwordReset => l10n.notifSecurityPasswordReset,
      SecurityChange.recoveryPinChanged => l10n.notifSecurityRecoveryPinChanged,
      SecurityChange.phoneNumberChanged => l10n.notifSecurityPhoneNumberChanged,
      SecurityChange.recoveryLockedOut => l10n.notifSecurityRecoveryLockedOut,
      SecurityChange.externalLoginLinked => l10n.notifSecurityExternalLoginLinked,
      SecurityChange.externalLoginUnlinked => l10n.notifSecurityExternalLoginUnlinked,
      SecurityChange.phoneSignInAdded => l10n.notifSecurityPhoneSignInAdded,
      SecurityChange.other || null => l10n.notifSecurityGeneric,
    };

/// A configurable type's name in Settings.
String notificationTypeLabel(AppLocalizations l10n, NotificationType type) => switch (type) {
      NotificationType.newFollower => l10n.notificationTypeNewFollower,
      NotificationType.articleComment => l10n.notificationTypeArticleComment,
      NotificationType.commentReply => l10n.notificationTypeCommentReply,
      NotificationType.mention => l10n.notificationTypeMention,
      NotificationType.reactionsMilestone => l10n.notificationTypeReactionsMilestone,
      NotificationType.followedWriterArticle => l10n.notificationTypeFollowedWriterArticle,
      NotificationType.dailyArticle => l10n.notificationTypeDailyArticle,
      NotificationType.streakReminder => l10n.notificationTypeStreakReminder,
      NotificationType.articleReposted => l10n.notificationTypeArticleReposted,
      NotificationType.announcement => l10n.adminNotifTypeAnnouncement,
      NotificationType.supportTicket => l10n.supportNotifTypeTicket,
      NotificationType.reportNew => l10n.notifTypeReportNew,
      NotificationType.securityAlert => l10n.notificationSecurityAlerts,
      _ => l10n.notifications,
    };

/// What a configurable type covers, when its name alone doesn't say (Settings shows it under the name).
String? notificationTypeHint(AppLocalizations l10n, NotificationType type) => switch (type) {
      NotificationType.mention => l10n.notificationTypeMentionHint,
      NotificationType.articleReposted => l10n.notificationTypeArticleRepostedHint,
      NotificationType.announcement => l10n.adminNotifTypeAnnouncementHint,
      NotificationType.supportTicket => l10n.supportNotifTypeTicketHint,
      NotificationType.reportNew => l10n.notifTypeReportNewHint,
      _ => null,
    };

/// A mode as the settings menu lists it ("Push + in app"); [short] is the closed selector's ("Push").
String notificationModeLabel(AppLocalizations l10n, NotificationMode mode, {bool short = false}) => switch (mode) {
      NotificationMode.all => short ? l10n.notificationModeAllShort : l10n.notificationModeAll,
      NotificationMode.inApp => short ? l10n.notificationModeInAppShort : l10n.notificationModeInApp,
      NotificationMode.off => l10n.notificationModeOff,
    };
