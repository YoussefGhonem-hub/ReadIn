import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// `NotificationType` (F17): also the push `data.type`.
enum NotificationType {
  newFollower('new_follower'),
  articleComment('article_comment'),
  commentReply('comment_reply'),
  mention('mention'),
  reactionsMilestone('reactions_milestone'),
  followedWriterArticle('followed_writer_article'),
  dailyArticle('daily_article'),
  streakReminder('streak_reminder'),
  securityAlert('security_alert'),

  /// Writer verification (F19): approved or not ([AppNotification.approved]).
  verificationResult('verification_result'),
  moderationNotice('moderation_notice'),

  /// Someone reposted your article (F29): aggregated per article, opens the article.
  articleReposted('article_reposted'),

  /// News from the ReadIn team (F23): its own title and body; opens its article, its path or the center.
  announcement('announcement'),

  /// Support replied to your ticket or closed it (F35); it always comes, like a verification result.
  supportReply('support_reply'),

  /// A new ticket or a member's reply, for holders of `support.manage` (F35).
  supportTicket('support_ticket'),

  /// Something was reported, for holders of `moderation.manage` (F22 store additions); opens the console's case.
  reportNew('report_new'),

  /// A moderator closed the viewer's report (F22 store additions): a receipt in the center only, never pushed and
  /// never configurable; it never says who acted or what was done to a user.
  reportResolved('report_resolved'),

  /// A type this app version doesn't know yet: shown with generic text.
  unknown('');

  const NotificationType(this.wire);

  final String wire;

  static NotificationType fromWire(String? wire) =>
      values.where((type) => type != unknown && type.wire == wire).firstOrNull ?? unknown;

  /// The types with a mode in Settings (`NotificationSettingsDto.types`), in the order Settings lists them. Security
  /// alerts, moderation notices, verification results and support replies can't be turned off.
  static const configurable = [
    newFollower,
    articleComment,
    commentReply,
    mention,
    reactionsMilestone,
    followedWriterArticle,
    dailyArticle,
    streakReminder,
    articleReposted,
    announcement,
    supportTicket,
    reportNew,
  ];

  /// Configurable types Settings lists only when the API sends their mode: announcements (an API before F23 has
  /// none), new tickets (only holders of `support.manage` get them, F35) and new reports (holders of
  /// `moderation.manage`, F22 store additions).
  static const listedWhenSent = {announcement, supportTicket, reportNew};

  bool get isConfigurable => configurable.contains(this);
}

/// `report_resolved` (F22 store additions): the content was dealt with ([actioned]) or breaks no guideline
/// ([noViolation]).
enum ReportOutcome {
  actioned('actioned'),
  noViolation('no_violation');

  const ReportOutcome(this.wire);

  final String wire;

  static ReportOutcome? fromWire(Object? wire) => values.where((outcome) => outcome.wire == wire).firstOrNull;
}

/// `SecurityChange`: what a security alert is about (SPEC §9.5). [other] is a change this app version doesn't know.
enum SecurityChange {
  passwordChanged,
  passwordReset,
  recoveryPinChanged,
  phoneNumberChanged,
  recoveryLockedOut,
  externalLoginLinked,
  externalLoginUnlinked,
  phoneSignInAdded,
  other;

  /// The API's camelCase name (`passwordChanged`); case and `_` are ignored. Null when there is none.
  static SecurityChange? fromWire(Object? wire) {
    if (wire is! String || wire.trim().isEmpty) return null;
    final key = wire.replaceAll('_', '').toLowerCase();
    return values.where((change) => change != other && change.name.toLowerCase() == key).firstOrNull ?? other;
  }
}

/// `NotificationDto.actor`: the latest actor. Null when that account was deleted ("Deleted user").
class NotificationActor extends Equatable {
  const NotificationActor({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String displayName;

  /// Without the `@`.
  final String username;
  final String? avatarUrl;
  final bool isVerified;

  @override
  List<Object?> get props => [id, displayName, username, avatarUrl, isVerified];
}

/// `NotificationDto.article`, in the viewer's article language.
class NotificationArticle extends Equatable {
  const NotificationArticle({required this.id, required this.slug, required this.title, required this.language});

  final String id;
  final String slug;
  final String title;

  /// `ar-EG` | `en`: the title is laid out in this language's direction.
  final String language;

  @override
  List<Object?> get props => [id, slug, title, language];
}

/// `NotificationDto.comment`: a plain-text excerpt (at most 140 characters).
class NotificationComment extends Equatable {
  const NotificationComment({required this.id, this.parentId, required this.excerpt});

  final String id;
  final String? parentId;
  final String excerpt;

  @override
  List<Object?> get props => [id, parentId, excerpt];
}

/// One row of the notification center (`NotificationDto`, F17). Aggregated rows (new followers of a day, comments on
/// an article, replies to a comment) carry the latest [actor] and the number of distinct actors.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
    this.actor,
    this.actorCount = 0,
    this.article,
    this.comment,
    this.threshold,
    this.streakDays,
    this.securityChange,
    this.approved,
    this.articleCount,
    this.link = '',
    this.title,
    this.body,
    this.ticketNumber,
    this.subject,
    this.closed = false,
    this.reportTargetType,
    this.targetLabel,
    this.reportCount,
    this.systemReport = false,
    this.reportOutcome,
  });

  final String id;
  final NotificationType type;
  final DateTime createdAt;

  /// The last activity: the list is ordered by it, newest first.
  final DateTime updatedAt;
  final bool isRead;
  final NotificationActor? actor;

  /// Distinct actors (at least 1 for actor-based types).
  final int actorCount;
  final NotificationArticle? article;
  final NotificationComment? comment;

  /// `reactions_milestone`: 10, 50 or 100.
  final int? threshold;

  /// `streak_reminder`: the streak at stake.
  final int? streakDays;

  /// `security_alert`.
  final SecurityChange? securityChange;

  /// `verification_result`: whether the request was approved. Null when the API doesn't say (generic text).
  final bool? approved;

  /// `followed_writer_article` of the official @readin account: its new articles that day in one entry (≥ 1, with the
  /// newest as [article]). Null for every other writer, one entry per article.
  final int? articleCount;

  /// `readin://…`, the same link a push of this notification opens.
  final String link;

  /// `announcement` (F23): its title and body in the UI language.
  final String? title;
  final String? body;

  /// `support_reply` and `support_ticket` (F35): the ticket's number ("#12") and subject.
  final int? ticketNumber;
  final String? subject;

  /// `support_reply`: support closed the ticket.
  final bool closed;

  /// `report_new` / `report_resolved` (F22 store additions): what was reported (`article` | `comment` | `user` |
  /// `repost`) and its label (a title, a comment's start, `@username` or a caption).
  final String? reportTargetType;
  final String? targetLabel;

  /// `report_new`: the reports in the entry so far.
  final int? reportCount;

  /// `report_new`: filed by the content filter (F37).
  final bool systemReport;

  /// `report_resolved`: how the report was closed.
  final ReportOutcome? reportOutcome;

  /// The "and N others" of an aggregated row.
  int get otherActors => math.max(0, actorCount - 1);

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isRead: isRead ?? this.isRead,
        actor: actor,
        actorCount: actorCount,
        article: article,
        comment: comment,
        threshold: threshold,
        streakDays: streakDays,
        securityChange: securityChange,
        approved: approved,
        articleCount: articleCount,
        link: link,
        title: title,
        body: body,
        ticketNumber: ticketNumber,
        subject: subject,
        closed: closed,
        reportTargetType: reportTargetType,
        targetLabel: targetLabel,
        reportCount: reportCount,
        systemReport: systemReport,
        reportOutcome: reportOutcome,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        createdAt,
        updatedAt,
        isRead,
        actor,
        actorCount,
        article,
        comment,
        threshold,
        streakDays,
        securityChange,
        approved,
        articleCount,
        link,
        title,
        body,
        ticketNumber,
        subject,
        closed,
        reportTargetType,
        targetLabel,
        reportCount,
        systemReport,
        reportOutcome,
      ];
}
