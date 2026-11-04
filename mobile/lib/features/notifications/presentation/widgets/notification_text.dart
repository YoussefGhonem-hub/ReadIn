import '../../../../core/l10n/l10n_x.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';

/// Types whose row is about a person: their avatar leads it and their name starts the sentence.
bool isActorNotification(NotificationType type) => switch (type) {
      NotificationType.newFollower ||
      NotificationType.articleComment ||
      NotificationType.commentReply ||
      NotificationType.mention ||
      NotificationType.followedWriterArticle =>
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
    NotificationType.mention => l10n.notifMention(actor, others),
    NotificationType.followedWriterArticle => l10n.notifFollowedWriterArticle(actor),
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
    NotificationType.verificationResult => l10n.notifVerificationResult,
    // A notice about an article means it was hidden; one without is a warning (F22).
    NotificationType.moderationNotice =>
      notification.article == null ? l10n.notifModerationWarning : l10n.notifModerationArticleHidden,
    NotificationType.unknown => l10n.notifGeneric,
  };
}

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
      NotificationType.securityAlert => l10n.notificationSecurityAlerts,
      _ => l10n.notifications,
    };

/// A mode as the settings menu lists it ("Push + in app"); [short] is the closed selector's ("Push").
String notificationModeLabel(AppLocalizations l10n, NotificationMode mode, {bool short = false}) => switch (mode) {
      NotificationMode.all => short ? l10n.notificationModeAllShort : l10n.notificationModeAll,
      NotificationMode.inApp => short ? l10n.notificationModeInAppShort : l10n.notificationModeInApp,
      NotificationMode.off => l10n.notificationModeOff,
    };
