import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../comments/presentation/widgets/comment_body.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_text.dart';

/// The clock notification times and the Today / Earlier sections are measured against (golden tests freeze it).
abstract final class NotificationClock {
  static DateTime Function() now = DateTime.now;
}

/// One row of the notification center (F17): the actor's avatar (or the type's icon), the sentence with the actor's
/// name in bold, the article title in the article's own direction, the comment excerpt in its own direction, and how
/// long ago. Unread rows are tinted and carry a dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static const leadingSize = 44.0;

  /// The unread dot (tests find it by this key).
  static const unreadDotKey = ValueKey('notification-unread-dot');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final unread = !notification.isRead;
    final lang = Localizations.localeOf(context).languageCode;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final article = notification.article;
    final excerpt = notification.comment?.excerpt.trim() ?? '';

    return Material(
      color: unread ? colors.primaryContainer.withValues(alpha: context.isDark ? 0.28 : 0.4) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s5, ReadInSpace.s3, ReadInSpace.s4, ReadInSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Leading(notification: notification),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Sentence(notification: notification, unread: unread),
                    if (article != null && article.title.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _OwnDirection(
                        direction: article.language == 'en' ? TextDirection.ltr : TextDirection.rtl,
                        child: BidiText(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall?.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: ReadInSpace.s1),
                      _Excerpt(text: excerpt),
                    ],
                    // An announcement's body (F23), or a ticket's "#12 · subject" (F35), each in its own direction.
                    if (notificationDetail(notification) case final detail?) ...[
                      const SizedBox(height: 2),
                      _OwnDirection(
                        direction: Bidi.detect(detail) ?? Directionality.of(context),
                        child: BidiText(detail, maxLines: 3, overflow: TextOverflow.ellipsis, style: secondary),
                      ),
                    ],
                    if (notification.type == NotificationType.securityAlert) ...[
                      const SizedBox(height: 2),
                      Text(l10n.notifSecurityHint, style: secondary),
                    ],
                    // Like its push: the reason is on the verification page.
                    if (notification.type == NotificationType.verificationResult && notification.approved == false) ...[
                      const SizedBox(height: 2),
                      Text(l10n.notifVerificationRejectedHint, style: secondary),
                    ],
                    const SizedBox(height: ReadInSpace.s1),
                    Text(
                      commentTimeLabel(l10n, notification.updatedAt, now: NotificationClock.now(), languageCode: lang),
                      style: context.textTheme.labelSmall?.copyWith(color: unread ? colors.primary : colors.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: ReadInSpace.s5,
                child: unread
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Semantics(
                          label: l10n.notificationsUnreadDot,
                          child: Align(
                            alignment: AlignmentDirectional.topEnd,
                            child: Container(
                              key: unreadDotKey,
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sentence, with the actor's name (isolated, so a Latin name keeps its place in Arabic and the other way round)
/// in bold.
class _Sentence extends StatelessWidget {
  const _Sentence({required this.notification, required this.unread});

  final AppNotification notification;
  final bool unread;

  /// Stands in for the name while the sentence is translated, then is replaced by the bold name.
  static final _marker = String.fromCharCode(0xE000);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
      height: 1.5,
    );
    final spans = <InlineSpan>[];
    if (isActorNotification(notification.type)) {
      final name = notification.actor?.displayName ?? l10n.deletedUser;
      final parts = notificationMessage(l10n, notification, name: _marker).split(_marker);
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) {
          spans.add(TextSpan(
            text: '${Bidi.fsi}$name${Bidi.pdi}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: notification.actor == null ? context.colors.textSecondary : null,
            ),
          ));
          if (notification.actor?.isVerified ?? false) {
            spans.add(const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(padding: EdgeInsetsDirectional.only(start: 3), child: VerifiedMark(size: 14)),
            ));
          }
        }
        if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
      }
    } else {
      spans.add(TextSpan(text: notificationMessage(l10n, notification)));
    }
    return Text.rich(TextSpan(children: spans), style: style?.withEmoji());
  }
}

/// [child] laid out in [direction], e.g. an English article title in the Arabic UI.
class _OwnDirection extends StatelessWidget {
  const _OwnDirection({required this.direction, required this.child});

  final TextDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(textDirection: direction, child: child);
}

/// The comment's excerpt in its own direction, set off by a line on its start side.
class _Excerpt extends StatelessWidget {
  const _Excerpt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final direction = commentDirection(text, fallback: Directionality.of(context));
    return _OwnDirection(
      direction: direction,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s2),
        decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: colors.border, width: 3))),
        child: BidiText(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary, height: 1.5),
        ),
      ),
    );
  }
}

/// The actor's avatar with the type's icon at its corner, or the type's icon alone.
class _Leading extends StatelessWidget {
  const _Leading({required this.notification});

  final AppNotification notification;

  static const _size = NotificationTile.leadingSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, background, foreground) = notification.type == NotificationType.verificationResult && notification.approved == false
        ? (Icons.unpublished_outlined, colors.calloutWarning, colors.calloutWarningAccent)
        : _iconOf(notification.type, colors);
    if (!isActorNotification(notification.type)) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: foreground),
      );
    }
    final actor = notification.actor;
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (actor == null)
            const GenericAvatar(size: _size)
          else
            UserAvatar(name: actor.displayName, url: actor.avatarUrl, size: _size),
          PositionedDirectional(
            end: -4,
            bottom: -4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: Icon(icon, size: 12, color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, Color, Color) _iconOf(NotificationType type, ReadInColors colors) => switch (type) {
        NotificationType.newFollower => (Icons.person_add_alt_1_rounded, colors.primary, colors.onPrimary),
        NotificationType.articleComment => (Icons.chat_bubble_rounded, colors.primary, colors.onPrimary),
        NotificationType.commentReply => (Icons.reply_rounded, colors.primary, colors.onPrimary),
        NotificationType.mention => (Icons.alternate_email_rounded, colors.primary, colors.onPrimary),
        NotificationType.followedWriterArticle => (Icons.article_rounded, colors.primary, colors.onPrimary),
        NotificationType.reactionsMilestone => (Icons.emoji_events_outlined, colors.accentContainer, colors.textPrimary),
        NotificationType.dailyArticle => (Icons.wb_sunny_outlined, colors.accentContainer, colors.textPrimary),
        NotificationType.streakReminder => (Icons.local_fire_department_outlined, colors.accentContainer, colors.textPrimary),
        NotificationType.securityAlert => (Icons.shield_outlined, colors.calloutDanger, colors.calloutDangerAccent),
        NotificationType.verificationResult => (Icons.verified_outlined, colors.calloutTip, colors.success),
        NotificationType.moderationNotice => (Icons.gavel_rounded, colors.calloutWarning, colors.calloutWarningAccent),
        NotificationType.articleReposted => (Icons.repeat_rounded, colors.primary, colors.onPrimary),
        NotificationType.announcement => (Icons.campaign_outlined, colors.calloutInfo, colors.calloutInfoAccent),
        NotificationType.supportReply => (Icons.support_agent_rounded, colors.calloutTip, colors.success),
        NotificationType.supportTicket => (Icons.confirmation_number_outlined, colors.primary, colors.onPrimary),
        NotificationType.unknown => (Icons.notifications_none_rounded, colors.surfaceVariant, colors.textSecondary),
      };
}
