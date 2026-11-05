// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReportRequest _$ReportRequestFromJson(Map<String, dynamic> json) =>
    _ReportRequest(
      targetType: json['targetType'] as String,
      targetId: json['targetId'] as String,
      reason: json['reason'] as String,
      details: json['details'] as String?,
    );

Map<String, dynamic> _$ReportRequestToJson(_ReportRequest instance) =>
    <String, dynamic>{
      'targetType': instance.targetType,
      'targetId': instance.targetId,
      'reason': instance.reason,
      'details': ?instance.details,
    };

_ModerationTargetRefModel _$ModerationTargetRefModelFromJson(
  Map<String, dynamic> json,
) => _ModerationTargetRefModel(
  targetType: json['targetType'] as String,
  targetId: json['targetId'] as String,
);

Map<String, dynamic> _$ModerationTargetRefModelToJson(
  _ModerationTargetRefModel instance,
) => <String, dynamic>{
  'targetType': instance.targetType,
  'targetId': instance.targetId,
};

_ModerationActionRequest _$ModerationActionRequestFromJson(
  Map<String, dynamic> json,
) => _ModerationActionRequest(
  action: json['action'] as String,
  targetType: json['targetType'] as String,
  targetId: json['targetId'] as String,
  note: json['note'] as String?,
  durationDays: (json['durationDays'] as num?)?.toInt(),
  resolveReportsOf: json['resolveReportsOf'] == null
      ? null
      : ModerationTargetRefModel.fromJson(
          json['resolveReportsOf'] as Map<String, dynamic>,
        ),
  categoryId: json['categoryId'] as String?,
);

Map<String, dynamic> _$ModerationActionRequestToJson(
  _ModerationActionRequest instance,
) => <String, dynamic>{
  'action': instance.action,
  'targetType': instance.targetType,
  'targetId': instance.targetId,
  'note': ?instance.note,
  'durationDays': ?instance.durationDays,
  'resolveReportsOf': ?instance.resolveReportsOf?.toJson(),
  'categoryId': ?instance.categoryId,
};

_ModerationSummaryModel _$ModerationSummaryModelFromJson(
  Map<String, dynamic> json,
) => _ModerationSummaryModel(
  open: json['open'] == null
      ? const ModerationOpenCountsModel()
      : ModerationOpenCountsModel.fromJson(
          json['open'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ModerationSummaryModelToJson(
  _ModerationSummaryModel instance,
) => <String, dynamic>{'open': instance.open.toJson()};

_ModerationOpenCountsModel _$ModerationOpenCountsModelFromJson(
  Map<String, dynamic> json,
) => _ModerationOpenCountsModel(
  article: (json['article'] as num?)?.toInt() ?? 0,
  comment: (json['comment'] as num?)?.toInt() ?? 0,
  user: (json['user'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ModerationOpenCountsModelToJson(
  _ModerationOpenCountsModel instance,
) => <String, dynamic>{
  'article': instance.article,
  'comment': instance.comment,
  'user': instance.user,
  'total': instance.total,
};

_ModerationTargetModel _$ModerationTargetModelFromJson(
  Map<String, dynamic> json,
) => _ModerationTargetModel(
  state: json['state'] as String,
  author: json['author'] == null
      ? null
      : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
  title: json['title'] as String?,
  slug: json['slug'] as String?,
  language: json['language'] as String?,
  body: json['body'] as String?,
  articleId: json['articleId'] as String?,
  articleSlug: json['articleSlug'] as String?,
  articleTitle: json['articleTitle'] as String?,
  suspendedUntil: json['suspendedUntil'] == null
      ? null
      : DateTime.parse(json['suspendedUntil'] as String),
  warningCount: (json['warningCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ModerationTargetModelToJson(
  _ModerationTargetModel instance,
) => <String, dynamic>{
  'state': instance.state,
  'author': ?instance.author?.toJson(),
  'title': ?instance.title,
  'slug': ?instance.slug,
  'language': ?instance.language,
  'body': ?instance.body,
  'articleId': ?instance.articleId,
  'articleSlug': ?instance.articleSlug,
  'articleTitle': ?instance.articleTitle,
  'suspendedUntil': ?instance.suspendedUntil?.toIso8601String(),
  'warningCount': instance.warningCount,
};

_ModerationQueueItemModel _$ModerationQueueItemModelFromJson(
  Map<String, dynamic> json,
) => _ModerationQueueItemModel(
  targetType: json['targetType'] as String,
  targetId: json['targetId'] as String,
  status: json['status'] as String,
  reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
  reasons:
      (json['reasons'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  firstReportedAt: DateTime.parse(json['firstReportedAt'] as String),
  lastReportedAt: DateTime.parse(json['lastReportedAt'] as String),
  closedAt: json['closedAt'] == null
      ? null
      : DateTime.parse(json['closedAt'] as String),
  target: ModerationTargetModel.fromJson(
    json['target'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ModerationQueueItemModelToJson(
  _ModerationQueueItemModel instance,
) => <String, dynamic>{
  'targetType': instance.targetType,
  'targetId': instance.targetId,
  'status': instance.status,
  'reportCount': instance.reportCount,
  'reasons': instance.reasons,
  'firstReportedAt': instance.firstReportedAt.toIso8601String(),
  'lastReportedAt': instance.lastReportedAt.toIso8601String(),
  'closedAt': ?instance.closedAt?.toIso8601String(),
  'target': instance.target.toJson(),
};

_ModerationQueuePageModel _$ModerationQueuePageModelFromJson(
  Map<String, dynamic> json,
) => _ModerationQueuePageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => ModerationQueueItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModerationQueueItemModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$ModerationQueuePageModelToJson(
  _ModerationQueuePageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_ModerationReportModel _$ModerationReportModelFromJson(
  Map<String, dynamic> json,
) => _ModerationReportModel(
  id: json['id'] as String,
  reporter: json['reporter'] == null
      ? null
      : UserSummaryModel.fromJson(json['reporter'] as Map<String, dynamic>),
  reason: json['reason'] as String,
  details: json['details'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  closedAt: json['closedAt'] == null
      ? null
      : DateTime.parse(json['closedAt'] as String),
  closedBy: json['closedBy'] == null
      ? null
      : UserSummaryModel.fromJson(json['closedBy'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ModerationReportModelToJson(
  _ModerationReportModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'reporter': ?instance.reporter?.toJson(),
  'reason': instance.reason,
  'details': ?instance.details,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'closedAt': ?instance.closedAt?.toIso8601String(),
  'closedBy': ?instance.closedBy?.toJson(),
};

_ModerationActionModel _$ModerationActionModelFromJson(
  Map<String, dynamic> json,
) => _ModerationActionModel(
  id: json['id'] as String,
  action: json['action'] as String,
  targetType: json['targetType'] as String,
  targetId: json['targetId'] as String,
  targetLabel: json['targetLabel'] as String?,
  targetUser: json['targetUser'] == null
      ? null
      : UserSummaryModel.fromJson(json['targetUser'] as Map<String, dynamic>),
  moderator: json['moderator'] == null
      ? null
      : UserSummaryModel.fromJson(json['moderator'] as Map<String, dynamic>),
  note: json['note'] as String?,
  suspendedUntil: json['suspendedUntil'] == null
      ? null
      : DateTime.parse(json['suspendedUntil'] as String),
  reportsClosed: (json['reportsClosed'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ModerationActionModelToJson(
  _ModerationActionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'action': instance.action,
  'targetType': instance.targetType,
  'targetId': instance.targetId,
  'targetLabel': ?instance.targetLabel,
  'targetUser': ?instance.targetUser?.toJson(),
  'moderator': ?instance.moderator?.toJson(),
  'note': ?instance.note,
  'suspendedUntil': ?instance.suspendedUntil?.toIso8601String(),
  'reportsClosed': instance.reportsClosed,
  'createdAt': instance.createdAt.toIso8601String(),
};

_ModerationActionPageModel _$ModerationActionPageModelFromJson(
  Map<String, dynamic> json,
) => _ModerationActionPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => ModerationActionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModerationActionModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$ModerationActionPageModelToJson(
  _ModerationActionPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_ModerationCaseModel _$ModerationCaseModelFromJson(Map<String, dynamic> json) =>
    _ModerationCaseModel(
      item: ModerationQueueItemModel.fromJson(
        json['item'] as Map<String, dynamic>,
      ),
      reports:
          (json['reports'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ModerationReportModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ModerationReportModel>[],
      history:
          (json['history'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ModerationActionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ModerationActionModel>[],
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => WriterCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ModerationCaseModelToJson(
  _ModerationCaseModel instance,
) => <String, dynamic>{
  'item': instance.item.toJson(),
  'reports': instance.reports.map((e) => e.toJson()).toList(),
  'history': instance.history.map((e) => e.toJson()).toList(),
  'categories': ?instance.categories?.map((e) => e.toJson()).toList(),
};

_ModerationNoticeArticleModel _$ModerationNoticeArticleModelFromJson(
  Map<String, dynamic> json,
) => _ModerationNoticeArticleModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  title: json['title'] as String,
);

Map<String, dynamic> _$ModerationNoticeArticleModelToJson(
  _ModerationNoticeArticleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
};

_ModerationNoticeModel _$ModerationNoticeModelFromJson(
  Map<String, dynamic> json,
) => _ModerationNoticeModel(
  id: json['id'] as String,
  kind: json['kind'] as String,
  note: json['note'] as String?,
  article: json['article'] == null
      ? null
      : ModerationNoticeArticleModel.fromJson(
          json['article'] as Map<String, dynamic>,
        ),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ModerationNoticeModelToJson(
  _ModerationNoticeModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'note': ?instance.note,
  'article': ?instance.article?.toJson(),
  'createdAt': instance.createdAt.toIso8601String(),
};

_ModerationNoticesModel _$ModerationNoticesModelFromJson(
  Map<String, dynamic> json,
) => _ModerationNoticesModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => ModerationNoticeModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModerationNoticeModel>[],
);

Map<String, dynamic> _$ModerationNoticesModelToJson(
  _ModerationNoticesModel instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
