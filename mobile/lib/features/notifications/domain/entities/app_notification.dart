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

  /// A type this app version doesn't know yet: shown with generic text.
  unknown('');

  const NotificationType(this.wire);

  final String wire;

  static NotificationType fromWire(String? wire) =>
      values.where((type) => type != unknown && type.wire == wire).firstOrNull ?? unknown;

  /// The types with a mode in Settings (`NotificationSettingsDto.types`), in the order Settings lists them. Security
  /// alerts, moderation notices and verification results can't be turned off.
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
  ];

  bool get isConfigurable => configurable.contains(this);
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
      ];
}
