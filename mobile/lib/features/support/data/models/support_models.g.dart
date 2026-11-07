// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupportConfigModel _$SupportConfigModelFromJson(Map<String, dynamic> json) =>
    _SupportConfigModel(
      email: json['email'] as String?,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      maxAttachments:
          (json['maxAttachments'] as num?)?.toInt() ??
          SupportLimits.maxScreenshots,
      maxAttachmentBytes:
          (json['maxAttachmentBytes'] as num?)?.toInt() ??
          SupportLimits.screenshotMaxBytes,
    );

Map<String, dynamic> _$SupportConfigModelToJson(_SupportConfigModel instance) =>
    <String, dynamic>{
      'email': ?instance.email,
      'categories': instance.categories,
      'maxAttachments': instance.maxAttachments,
      'maxAttachmentBytes': instance.maxAttachmentBytes,
    };

_SupportDeviceModel _$SupportDeviceModelFromJson(Map<String, dynamic> json) =>
    _SupportDeviceModel(
      platform: json['platform'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      language: json['language'] as String?,
      screen: json['screen'] as String?,
    );

Map<String, dynamic> _$SupportDeviceModelToJson(_SupportDeviceModel instance) =>
    <String, dynamic>{
      'platform': ?instance.platform,
      'osVersion': ?instance.osVersion,
      'appVersion': ?instance.appVersion,
      'language': ?instance.language,
      'screen': ?instance.screen,
    };

_SupportAttachmentModel _$SupportAttachmentModelFromJson(
  Map<String, dynamic> json,
) => _SupportAttachmentModel(
  id: json['id'] as String,
  contentType: json['contentType'] as String? ?? 'image/jpeg',
  sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SupportAttachmentModelToJson(
  _SupportAttachmentModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'contentType': instance.contentType,
  'sizeBytes': instance.sizeBytes,
};

_SupportPersonModel _$SupportPersonModelFromJson(Map<String, dynamic> json) =>
    _SupportPersonModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );

Map<String, dynamic> _$SupportPersonModelToJson(_SupportPersonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
    };

_SupportMessageModel _$SupportMessageModelFromJson(Map<String, dynamic> json) =>
    _SupportMessageModel(
      id: json['id'] as String,
      fromSupport: json['fromSupport'] as bool? ?? false,
      body: json['body'] as String? ?? '',
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SupportAttachmentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <SupportAttachmentModel>[],
      createdAt: DateTime.parse(json['createdAt'] as String),
      isInternalNote: json['isInternalNote'] as bool? ?? false,
      author: json['author'] == null
          ? null
          : SupportPersonModel.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SupportMessageModelToJson(
  _SupportMessageModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'fromSupport': instance.fromSupport,
  'body': instance.body,
  'attachments': instance.attachments.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'isInternalNote': instance.isInternalNote,
  'author': ?instance.author?.toJson(),
};

_SupportLastMessageModel _$SupportLastMessageModelFromJson(
  Map<String, dynamic> json,
) => _SupportLastMessageModel(
  fromSupport: json['fromSupport'] as bool? ?? false,
  isInternalNote: json['isInternalNote'] as bool? ?? false,
  excerpt: json['excerpt'] as String? ?? '',
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SupportLastMessageModelToJson(
  _SupportLastMessageModel instance,
) => <String, dynamic>{
  'fromSupport': instance.fromSupport,
  'isInternalNote': instance.isInternalNote,
  'excerpt': instance.excerpt,
  'createdAt': instance.createdAt.toIso8601String(),
};

_SupportTicketModel _$SupportTicketModelFromJson(Map<String, dynamic> json) =>
    _SupportTicketModel(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 0,
      category: json['category'] as String?,
      subject: json['subject'] as String? ?? '',
      status: json['status'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastMessage: json['lastMessage'] == null
          ? null
          : SupportLastMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            ),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      canReopen: json['canReopen'] as bool? ?? false,
      device: json['device'] == null
          ? null
          : SupportDeviceModel.fromJson(json['device'] as Map<String, dynamic>),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map(
                (e) => SupportMessageModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <SupportMessageModel>[],
    );

Map<String, dynamic> _$SupportTicketModelToJson(_SupportTicketModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'category': ?instance.category,
      'subject': instance.subject,
      'status': ?instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastMessage': ?instance.lastMessage?.toJson(),
      'closedAt': ?instance.closedAt?.toIso8601String(),
      'canReopen': instance.canReopen,
      'device': ?instance.device?.toJson(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
    };

_SupportTicketPageModel _$SupportTicketPageModelFromJson(
  Map<String, dynamic> json,
) => _SupportTicketPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SupportTicketModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$SupportTicketPageModelToJson(
  _SupportTicketPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_AdminTicketModel _$AdminTicketModelFromJson(
  Map<String, dynamic> json,
) => _AdminTicketModel(
  id: json['id'] as String,
  number: (json['number'] as num?)?.toInt() ?? 0,
  category: json['category'] as String?,
  subject: json['subject'] as String? ?? '',
  status: json['status'] as String?,
  user: AuthorModel.fromJson(json['user'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  waitingSince: json['waitingSince'] == null
      ? null
      : DateTime.parse(json['waitingSince'] as String),
  lastMessage: json['lastMessage'] == null
      ? null
      : SupportLastMessageModel.fromJson(
          json['lastMessage'] as Map<String, dynamic>,
        ),
  closedAt: json['closedAt'] == null
      ? null
      : DateTime.parse(json['closedAt'] as String),
  device: json['device'] == null
      ? null
      : SupportDeviceModel.fromJson(json['device'] as Map<String, dynamic>),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => SupportMessageModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SupportMessageModel>[],
  closedBy: json['closedBy'] as String?,
  member: json['member'] == null
      ? null
      : AdminTicketMemberModel.fromJson(json['member'] as Map<String, dynamic>),
  reportsFiled: json['reportsFiled'] == null
      ? null
      : AdminTicketReportsModel.fromJson(
          json['reportsFiled'] as Map<String, dynamic>,
        ),
  reportsAgainst: (json['reportsAgainst'] as num?)?.toInt(),
  moderation: (json['moderation'] as List<dynamic>?)
      ?.map(
        (e) => AdminTicketModerationModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$AdminTicketModelToJson(_AdminTicketModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'category': ?instance.category,
      'subject': instance.subject,
      'status': ?instance.status,
      'user': instance.user.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'waitingSince': ?instance.waitingSince?.toIso8601String(),
      'lastMessage': ?instance.lastMessage?.toJson(),
      'closedAt': ?instance.closedAt?.toIso8601String(),
      'device': ?instance.device?.toJson(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'closedBy': ?instance.closedBy,
      'member': ?instance.member?.toJson(),
      'reportsFiled': ?instance.reportsFiled?.toJson(),
      'reportsAgainst': ?instance.reportsAgainst,
      'moderation': ?instance.moderation?.map((e) => e.toJson()).toList(),
    };

_AdminTicketMemberModel _$AdminTicketMemberModelFromJson(
  Map<String, dynamic> json,
) => _AdminTicketMemberModel(
  status: json['status'] as String?,
  suspendedUntil: json['suspendedUntil'] == null
      ? null
      : DateTime.parse(json['suspendedUntil'] as String),
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  signInMethods:
      (json['signInMethods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  ticketCount: (json['ticketCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminTicketMemberModelToJson(
  _AdminTicketMemberModel instance,
) => <String, dynamic>{
  'status': ?instance.status,
  'suspendedUntil': ?instance.suspendedUntil?.toIso8601String(),
  'joinedAt': instance.joinedAt.toIso8601String(),
  'signInMethods': instance.signInMethods,
  'ticketCount': instance.ticketCount,
};

_AdminTicketReportsModel _$AdminTicketReportsModelFromJson(
  Map<String, dynamic> json,
) => _AdminTicketReportsModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => AdminTicketReportModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <AdminTicketReportModel>[],
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminTicketReportsModelToJson(
  _AdminTicketReportsModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
};

_AdminTicketReportModel _$AdminTicketReportModelFromJson(
  Map<String, dynamic> json,
) => _AdminTicketReportModel(
  id: json['id'] as String,
  targetType: json['targetType'] as String? ?? '',
  targetLabel: json['targetLabel'] as String?,
  reason: json['reason'] as String? ?? 'other',
  status: json['status'] as String? ?? 'open',
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$AdminTicketReportModelToJson(
  _AdminTicketReportModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'targetType': instance.targetType,
  'targetLabel': ?instance.targetLabel,
  'reason': instance.reason,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
};

_AdminTicketModerationModel _$AdminTicketModerationModelFromJson(
  Map<String, dynamic> json,
) => _AdminTicketModerationModel(
  id: json['id'] as String,
  action: json['action'] as String? ?? '',
  note: json['note'] as String?,
  suspendedUntil: json['suspendedUntil'] == null
      ? null
      : DateTime.parse(json['suspendedUntil'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$AdminTicketModerationModelToJson(
  _AdminTicketModerationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'action': instance.action,
  'note': ?instance.note,
  'suspendedUntil': ?instance.suspendedUntil?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
};

_AdminTicketPageModel _$AdminTicketPageModelFromJson(
  Map<String, dynamic> json,
) => _AdminTicketPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => AdminTicketModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AdminTicketModel>[],
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
  totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
  totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminTicketPageModelToJson(
  _AdminTicketPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page,
  'pageSize': instance.pageSize,
  'totalCount': instance.totalCount,
  'totalPages': instance.totalPages,
};

_AdminTicketMessageRequest _$AdminTicketMessageRequestFromJson(
  Map<String, dynamic> json,
) => _AdminTicketMessageRequest(
  body: json['body'] as String,
  internal: json['internal'] as bool,
);

Map<String, dynamic> _$AdminTicketMessageRequestToJson(
  _AdminTicketMessageRequest instance,
) => <String, dynamic>{'body': instance.body, 'internal': instance.internal};

_AdminTicketUpdateRequest _$AdminTicketUpdateRequestFromJson(
  Map<String, dynamic> json,
) => _AdminTicketUpdateRequest(
  status: json['status'] as String?,
  category: json['category'] as String?,
);

Map<String, dynamic> _$AdminTicketUpdateRequestToJson(
  _AdminTicketUpdateRequest instance,
) => <String, dynamic>{
  'status': ?instance.status,
  'category': ?instance.category,
};
