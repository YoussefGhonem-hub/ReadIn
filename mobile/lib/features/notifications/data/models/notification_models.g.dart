// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationActorModel _$NotificationActorModelFromJson(
  Map<String, dynamic> json,
) => _NotificationActorModel(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$NotificationActorModelToJson(
  _NotificationActorModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'username': instance.username,
  'avatarUrl': ?instance.avatarUrl,
  'isVerified': instance.isVerified,
};

_NotificationArticleModel _$NotificationArticleModelFromJson(
  Map<String, dynamic> json,
) => _NotificationArticleModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  title: json['title'] as String,
  language: json['language'] as String? ?? 'ar-EG',
);

Map<String, dynamic> _$NotificationArticleModelToJson(
  _NotificationArticleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'language': instance.language,
};

_NotificationCommentModel _$NotificationCommentModelFromJson(
  Map<String, dynamic> json,
) => _NotificationCommentModel(
  id: json['id'] as String,
  parentId: json['parentId'] as String?,
  excerpt: json['excerpt'] as String? ?? '',
);

Map<String, dynamic> _$NotificationCommentModelToJson(
  _NotificationCommentModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'parentId': ?instance.parentId,
  'excerpt': instance.excerpt,
};

_NotificationDataModel _$NotificationDataModelFromJson(
  Map<String, dynamic> json,
) => _NotificationDataModel(
  threshold: (json['threshold'] as num?)?.toInt(),
  streakDays: (json['streakDays'] as num?)?.toInt(),
  securityChange: json['securityChange'],
  approved: json['approved'] as bool?,
);

Map<String, dynamic> _$NotificationDataModelToJson(
  _NotificationDataModel instance,
) => <String, dynamic>{
  'threshold': ?instance.threshold,
  'streakDays': ?instance.streakDays,
  'securityChange': ?instance.securityChange,
  'approved': ?instance.approved,
};

_NotificationModel _$NotificationModelFromJson(
  Map<String, dynamic> json,
) => _NotificationModel(
  id: json['id'] as String,
  type: json['type'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isRead: json['isRead'] as bool? ?? false,
  actor: json['actor'] == null
      ? null
      : NotificationActorModel.fromJson(json['actor'] as Map<String, dynamic>),
  actorCount: (json['actorCount'] as num?)?.toInt() ?? 0,
  article: json['article'] == null
      ? null
      : NotificationArticleModel.fromJson(
          json['article'] as Map<String, dynamic>,
        ),
  comment: json['comment'] == null
      ? null
      : NotificationCommentModel.fromJson(
          json['comment'] as Map<String, dynamic>,
        ),
  data: json['data'] == null
      ? null
      : NotificationDataModel.fromJson(json['data'] as Map<String, dynamic>),
  link: json['link'] as String? ?? '',
);

Map<String, dynamic> _$NotificationModelToJson(_NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isRead': instance.isRead,
      'actor': ?instance.actor?.toJson(),
      'actorCount': instance.actorCount,
      'article': ?instance.article?.toJson(),
      'comment': ?instance.comment?.toJson(),
      'data': ?instance.data?.toJson(),
      'link': instance.link,
    };

_NotificationPageModel _$NotificationPageModelFromJson(
  Map<String, dynamic> json,
) => _NotificationPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NotificationModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$NotificationPageModelToJson(
  _NotificationPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_UnreadCountModel _$UnreadCountModelFromJson(Map<String, dynamic> json) =>
    _UnreadCountModel(unread: (json['unread'] as num?)?.toInt() ?? 0);

Map<String, dynamic> _$UnreadCountModelToJson(_UnreadCountModel instance) =>
    <String, dynamic>{'unread': instance.unread};

_QuietHoursModel _$QuietHoursModelFromJson(Map<String, dynamic> json) =>
    _QuietHoursModel(
      enabled: json['enabled'] as bool? ?? true,
      start: json['start'] as String? ?? '23:00',
      end: json['end'] as String? ?? '07:00',
    );

Map<String, dynamic> _$QuietHoursModelToJson(_QuietHoursModel instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'start': instance.start,
      'end': instance.end,
    };

_NotificationSettingsModel _$NotificationSettingsModelFromJson(
  Map<String, dynamic> json,
) => _NotificationSettingsModel(
  quietHours: json['quietHours'] == null
      ? const QuietHoursModel()
      : QuietHoursModel.fromJson(json['quietHours'] as Map<String, dynamic>),
  types:
      (json['types'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
);

Map<String, dynamic> _$NotificationSettingsModelToJson(
  _NotificationSettingsModel instance,
) => <String, dynamic>{
  'quietHours': instance.quietHours.toJson(),
  'types': instance.types,
};
