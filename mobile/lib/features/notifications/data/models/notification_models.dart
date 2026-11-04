import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';

part 'notification_models.freezed.dart';
part 'notification_models.g.dart';

/// `NotificationDto.actor`.
@freezed
abstract class NotificationActorModel with _$NotificationActorModel {
  const NotificationActorModel._();

  const factory NotificationActorModel({
    required String id,
    required String displayName,
    required String username,
    String? avatarUrl,
    @Default(false) bool isVerified,
  }) = _NotificationActorModel;

  factory NotificationActorModel.fromJson(Map<String, dynamic> json) => _$NotificationActorModelFromJson(json);

  NotificationActor toEntity() =>
      NotificationActor(id: id, displayName: displayName, username: username, avatarUrl: avatarUrl, isVerified: isVerified);
}

/// `NotificationDto.article`.
@freezed
abstract class NotificationArticleModel with _$NotificationArticleModel {
  const NotificationArticleModel._();

  const factory NotificationArticleModel({
    required String id,
    required String slug,
    required String title,
    @Default('ar-EG') String language,
  }) = _NotificationArticleModel;

  factory NotificationArticleModel.fromJson(Map<String, dynamic> json) => _$NotificationArticleModelFromJson(json);

  NotificationArticle toEntity() => NotificationArticle(id: id, slug: slug, title: title, language: language);
}

/// `NotificationDto.comment`.
@freezed
abstract class NotificationCommentModel with _$NotificationCommentModel {
  const NotificationCommentModel._();

  const factory NotificationCommentModel({
    required String id,
    String? parentId,
    @Default('') String excerpt,
  }) = _NotificationCommentModel;

  factory NotificationCommentModel.fromJson(Map<String, dynamic> json) => _$NotificationCommentModelFromJson(json);

  NotificationComment toEntity() => NotificationComment(id: id, parentId: parentId, excerpt: excerpt);
}

/// `NotificationDto.data`. [securityChange] is read leniently: a value this app doesn't know shows the generic alert.
/// [approved] is the decision a `verification_result` is about (F19).
@freezed
abstract class NotificationDataModel with _$NotificationDataModel {
  const factory NotificationDataModel({
    int? threshold,
    int? streakDays,
    Object? securityChange,
    bool? approved,
  }) = _NotificationDataModel;

  factory NotificationDataModel.fromJson(Map<String, dynamic> json) => _$NotificationDataModelFromJson(json);
}

/// `NotificationDto` (F17).
@freezed
abstract class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    required String id,
    required String type,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isRead,
    NotificationActorModel? actor,
    @Default(0) int actorCount,
    NotificationArticleModel? article,
    NotificationCommentModel? comment,
    NotificationDataModel? data,
    @Default('') String link,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);

  AppNotification toEntity() => AppNotification(
        id: id,
        type: NotificationType.fromWire(type),
        createdAt: createdAt,
        updatedAt: updatedAt,
        isRead: isRead,
        actor: actor?.toEntity(),
        actorCount: actorCount,
        article: article?.toEntity(),
        comment: comment?.toEntity(),
        threshold: data?.threshold,
        streakDays: data?.streakDays,
        securityChange: SecurityChange.fromWire(data?.securityChange),
        approved: data?.approved,
        link: link,
      );
}

/// `CursorPage<NotificationDto>`.
@freezed
abstract class NotificationPageModel with _$NotificationPageModel {
  const factory NotificationPageModel({
    @Default(<NotificationModel>[]) List<NotificationModel> items,
    String? nextCursor,
  }) = _NotificationPageModel;

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) => _$NotificationPageModelFromJson(json);
}

/// `GET /me/notifications/unread-count`.
@freezed
abstract class UnreadCountModel with _$UnreadCountModel {
  const factory UnreadCountModel({@Default(0) int unread}) = _UnreadCountModel;

  factory UnreadCountModel.fromJson(Map<String, dynamic> json) => _$UnreadCountModelFromJson(json);
}

/// `NotificationSettingsDto.quietHours`: `HH:mm` in the user's time zone.
@freezed
abstract class QuietHoursModel with _$QuietHoursModel {
  const factory QuietHoursModel({
    @Default(true) bool enabled,
    @Default('23:00') String start,
    @Default('07:00') String end,
  }) = _QuietHoursModel;

  factory QuietHoursModel.fromJson(Map<String, dynamic> json) => _$QuietHoursModelFromJson(json);
}

/// `NotificationSettingsDto` (F17): `types` maps a configurable type (`new_follower`) to `all | inApp | off`.
@freezed
abstract class NotificationSettingsModel with _$NotificationSettingsModel {
  const NotificationSettingsModel._();

  const factory NotificationSettingsModel({
    @Default(QuietHoursModel()) QuietHoursModel quietHours,
    @Default(<String, String>{}) Map<String, String> types,
  }) = _NotificationSettingsModel;

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) => _$NotificationSettingsModelFromJson(json);

  /// Every type and mode this app knows; the rest are skipped.
  NotificationSettings toEntity() => NotificationSettings(
        quietHours: QuietHours(enabled: quietHours.enabled, start: quietHours.start, end: quietHours.end),
        types: {
          for (final MapEntry(:key, :value) in types.entries)
            if ((NotificationType.fromWire(key), NotificationMode.fromWire(value)) case (final type, final mode?)
                when type.isConfigurable)
              type: mode,
        },
      );

  /// The whole settings: quiet hours and the mode of every listed type.
  static NotificationSettingsModel fromEntity(NotificationSettings settings) => NotificationSettingsModel(
        quietHours: QuietHoursModel(
          enabled: settings.quietHours.enabled,
          start: settings.quietHours.start,
          end: settings.quietHours.end,
        ),
        types: {
          for (final MapEntry(:key, :value) in settings.types.entries)
            if (key.isConfigurable) key.wire: value.name,
        },
      );
}
