// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminSummaryModel _$AdminSummaryModelFromJson(Map<String, dynamic> json) =>
    _AdminSummaryModel(
      openReports: (json['openReports'] as num?)?.toInt(),
      openTickets: (json['openTickets'] as num?)?.toInt(),
      pendingVerifications: (json['pendingVerifications'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      openReportsOver24h: (json['openReportsOver24h'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AdminSummaryModelToJson(_AdminSummaryModel instance) =>
    <String, dynamic>{
      'openReports': ?instance.openReports,
      'openTickets': ?instance.openTickets,
      'pendingVerifications': ?instance.pendingVerifications,
      'total': instance.total,
      'openReportsOver24h': ?instance.openReportsOver24h,
    };

_DashboardValueModel _$DashboardValueModelFromJson(Map<String, dynamic> json) =>
    _DashboardValueModel(
      value: (json['value'] as num?)?.toInt() ?? 0,
      previous: (json['previous'] as num?)?.toInt() ?? 0,
      phone: (json['phone'] as num?)?.toInt() ?? 0,
      google: (json['google'] as num?)?.toInt() ?? 0,
      apple: (json['apple'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DashboardValueModelToJson(
  _DashboardValueModel instance,
) => <String, dynamic>{
  'value': instance.value,
  'previous': instance.previous,
  'phone': instance.phone,
  'google': instance.google,
  'apple': instance.apple,
};

_DashboardCardsModel _$DashboardCardsModelFromJson(
  Map<String, dynamic> json,
) => _DashboardCardsModel(
  articlesPublished: json['articlesPublished'] == null
      ? const DashboardValueModel()
      : DashboardValueModel.fromJson(
          json['articlesPublished'] as Map<String, dynamic>,
        ),
  newUsers: json['newUsers'] == null
      ? const DashboardValueModel()
      : DashboardValueModel.fromJson(json['newUsers'] as Map<String, dynamic>),
  activeReaders: json['activeReaders'] == null
      ? const DashboardValueModel()
      : DashboardValueModel.fromJson(
          json['activeReaders'] as Map<String, dynamic>,
        ),
  reads: json['reads'] == null
      ? const DashboardValueModel()
      : DashboardValueModel.fromJson(json['reads'] as Map<String, dynamic>),
  comments: json['comments'] == null
      ? const DashboardValueModel()
      : DashboardValueModel.fromJson(json['comments'] as Map<String, dynamic>),
  reactions: json['reactions'] == null
      ? const DashboardValueModel()
      : DashboardValueModel.fromJson(json['reactions'] as Map<String, dynamic>),
  reposts: json['reposts'] == null
      ? const DashboardValueModel()
      : DashboardValueModel.fromJson(json['reposts'] as Map<String, dynamic>),
  openReports: (json['openReports'] as num?)?.toInt(),
  openTickets: (json['openTickets'] as num?)?.toInt(),
  pendingVerifications: (json['pendingVerifications'] as num?)?.toInt(),
  suspendedNow: (json['suspendedNow'] as num?)?.toInt() ?? 0,
  openReportsOver24h: (json['openReportsOver24h'] as num?)?.toInt(),
);

Map<String, dynamic> _$DashboardCardsModelToJson(
  _DashboardCardsModel instance,
) => <String, dynamic>{
  'articlesPublished': instance.articlesPublished.toJson(),
  'newUsers': instance.newUsers.toJson(),
  'activeReaders': instance.activeReaders.toJson(),
  'reads': instance.reads.toJson(),
  'comments': instance.comments.toJson(),
  'reactions': instance.reactions.toJson(),
  'reposts': instance.reposts.toJson(),
  'openReports': ?instance.openReports,
  'openTickets': ?instance.openTickets,
  'pendingVerifications': ?instance.pendingVerifications,
  'suspendedNow': instance.suspendedNow,
  'openReportsOver24h': ?instance.openReportsOver24h,
};

_DashboardDayModel _$DashboardDayModelFromJson(Map<String, dynamic> json) =>
    _DashboardDayModel(
      date: json['date'] as String,
      newUsers: (json['newUsers'] as num?)?.toInt() ?? 0,
      activeReaders: (json['activeReaders'] as num?)?.toInt() ?? 0,
      articlesPublished: (json['articlesPublished'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DashboardDayModelToJson(_DashboardDayModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'newUsers': instance.newUsers,
      'activeReaders': instance.activeReaders,
      'articlesPublished': instance.articlesPublished,
    };

_DashboardArticleModel _$DashboardArticleModelFromJson(
  Map<String, dynamic> json,
) => _DashboardArticleModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  title: json['title'] as String? ?? '',
  language: json['language'] as String? ?? 'ar-EG',
  author: json['author'] == null
      ? null
      : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
  field: FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
  publishedAt: DateTime.parse(json['publishedAt'] as String),
  reads: (json['reads'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DashboardArticleModelToJson(
  _DashboardArticleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'language': instance.language,
  'author': ?instance.author?.toJson(),
  'field': instance.field.toJson(),
  'publishedAt': instance.publishedAt.toIso8601String(),
  'reads': instance.reads,
};

_DashboardWriterModel _$DashboardWriterModelFromJson(
  Map<String, dynamic> json,
) => _DashboardWriterModel(
  writer: AuthorModel.fromJson(json['writer'] as Map<String, dynamic>),
  reads: (json['reads'] as num?)?.toInt() ?? 0,
  articles: (json['articles'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DashboardWriterModelToJson(
  _DashboardWriterModel instance,
) => <String, dynamic>{
  'writer': instance.writer.toJson(),
  'reads': instance.reads,
  'articles': instance.articles,
};

_MissedSearchModel _$MissedSearchModelFromJson(Map<String, dynamic> json) =>
    _MissedSearchModel(
      query: json['query'] as String,
      language: json['language'] as String? ?? 'en',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MissedSearchModelToJson(_MissedSearchModel instance) =>
    <String, dynamic>{
      'query': instance.query,
      'language': instance.language,
      'count': instance.count,
    };

_StreakRetentionModel _$StreakRetentionModelFromJson(
  Map<String, dynamic> json,
) => _StreakRetentionModel(
  cohort: (json['cohort'] as num?)?.toInt() ?? 0,
  kept: (json['kept'] as num?)?.toInt() ?? 0,
  rate: (json['rate'] as num?)?.toDouble(),
);

Map<String, dynamic> _$StreakRetentionModelToJson(
  _StreakRetentionModel instance,
) => <String, dynamic>{
  'cohort': instance.cohort,
  'kept': instance.kept,
  'rate': ?instance.rate,
};

_ContentPipelineModel _$ContentPipelineModelFromJson(
  Map<String, dynamic> json,
) => _ContentPipelineModel(
  folders: (json['folders'] as num?)?.toInt() ?? 0,
  seeded: (json['seeded'] as num?)?.toInt() ?? 0,
  published: (json['published'] as num?)?.toInt() ?? 0,
  lastSeedRunAt: json['lastSeedRunAt'] == null
      ? null
      : DateTime.parse(json['lastSeedRunAt'] as String),
);

Map<String, dynamic> _$ContentPipelineModelToJson(
  _ContentPipelineModel instance,
) => <String, dynamic>{
  'folders': instance.folders,
  'seeded': instance.seeded,
  'published': instance.published,
  'lastSeedRunAt': ?instance.lastSeedRunAt?.toIso8601String(),
};

_AdminDashboardModel _$AdminDashboardModelFromJson(
  Map<String, dynamic> json,
) => _AdminDashboardModel(
  period: json['period'] as String,
  timeZone: json['timeZone'] as String? ?? 'Africa/Cairo',
  fromDate: json['fromDate'] as String? ?? '',
  toDate: json['toDate'] as String? ?? '',
  generatedAt: DateTime.parse(json['generatedAt'] as String),
  cards: json['cards'] == null
      ? const DashboardCardsModel()
      : DashboardCardsModel.fromJson(json['cards'] as Map<String, dynamic>),
  charts:
      (json['charts'] as List<dynamic>?)
          ?.map((e) => DashboardDayModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DashboardDayModel>[],
  topArticles:
      (json['topArticles'] as List<dynamic>?)
          ?.map(
            (e) => DashboardArticleModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <DashboardArticleModel>[],
  topWriters:
      (json['topWriters'] as List<dynamic>?)
          ?.map((e) => DashboardWriterModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DashboardWriterModel>[],
  missedSearches:
      (json['missedSearches'] as List<dynamic>?)
          ?.map((e) => MissedSearchModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MissedSearchModel>[],
  streakRetention: json['streakRetention'] == null
      ? const StreakRetentionModel()
      : StreakRetentionModel.fromJson(
          json['streakRetention'] as Map<String, dynamic>,
        ),
  contentPipeline: json['contentPipeline'] == null
      ? const ContentPipelineModel()
      : ContentPipelineModel.fromJson(
          json['contentPipeline'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$AdminDashboardModelToJson(
  _AdminDashboardModel instance,
) => <String, dynamic>{
  'period': instance.period,
  'timeZone': instance.timeZone,
  'fromDate': instance.fromDate,
  'toDate': instance.toDate,
  'generatedAt': instance.generatedAt.toIso8601String(),
  'cards': instance.cards.toJson(),
  'charts': instance.charts.map((e) => e.toJson()).toList(),
  'topArticles': instance.topArticles.map((e) => e.toJson()).toList(),
  'topWriters': instance.topWriters.map((e) => e.toJson()).toList(),
  'missedSearches': instance.missedSearches.map((e) => e.toJson()).toList(),
  'streakRetention': instance.streakRetention.toJson(),
  'contentPipeline': instance.contentPipeline.toJson(),
};

_AdminUserModel _$AdminUserModelFromJson(
  Map<String, dynamic> json,
) => _AdminUserModel(
  id: json['id'] as String,
  displayName: json['displayName'] as String? ?? '',
  username: json['username'] as String? ?? '',
  avatarUrl: json['avatarUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  isSystemAccount: json['isSystemAccount'] as bool? ?? false,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  signInMethods:
      (json['signInMethods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  phoneMasked: json['phoneMasked'] as String?,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  lastSeenAt: json['lastSeenAt'] == null
      ? null
      : DateTime.parse(json['lastSeenAt'] as String),
  publishedArticles: (json['publishedArticles'] as num?)?.toInt() ?? 0,
  followers: (json['followers'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? 'active',
  suspendedUntil: json['suspendedUntil'] == null
      ? null
      : DateTime.parse(json['suspendedUntil'] as String),
  openReports: (json['openReports'] as num?)?.toInt() ?? 0,
  headline: json['headline'] as String?,
  bio: json['bio'] as String?,
  links:
      (json['links'] as List<dynamic>?)
          ?.map((e) => ProfileLinkModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProfileLinkModel>[],
  uiLanguage: json['uiLanguage'] as String? ?? 'ar',
  signUpMethod: json['signUpMethod'] as String?,
  isStaff: json['isStaff'] as bool? ?? false,
  stats: json['stats'] == null
      ? null
      : AdminUserStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
  access: json['access'] == null
      ? null
      : AdminUserAccessModel.fromJson(json['access'] as Map<String, dynamic>),
  actions: json['actions'] == null
      ? null
      : AdminUserActionsModel.fromJson(json['actions'] as Map<String, dynamic>),
  moderation: json['moderation'] == null
      ? null
      : AdminUserModerationModel.fromJson(
          json['moderation'] as Map<String, dynamic>,
        ),
  reports: json['reports'] == null
      ? null
      : AdminUserReportsModel.fromJson(json['reports'] as Map<String, dynamic>),
  verification: json['verification'] == null
      ? null
      : AdminVerificationSectionModel.fromJson(
          json['verification'] as Map<String, dynamic>,
        ),
  tickets: json['tickets'] == null
      ? null
      : AdminTicketSectionModel.fromJson(
          json['tickets'] as Map<String, dynamic>,
        ),
  audit: json['audit'] == null
      ? null
      : AdminAuditSectionModel.fromJson(json['audit'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdminUserModelToJson(_AdminUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
      'avatarUrl': ?instance.avatarUrl,
      'isVerified': instance.isVerified,
      'isSystemAccount': instance.isSystemAccount,
      'roles': instance.roles,
      'signInMethods': instance.signInMethods,
      'phoneMasked': ?instance.phoneMasked,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'lastSeenAt': ?instance.lastSeenAt?.toIso8601String(),
      'publishedArticles': instance.publishedArticles,
      'followers': instance.followers,
      'status': instance.status,
      'suspendedUntil': ?instance.suspendedUntil?.toIso8601String(),
      'openReports': instance.openReports,
      'headline': ?instance.headline,
      'bio': ?instance.bio,
      'links': instance.links.map((e) => e.toJson()).toList(),
      'uiLanguage': instance.uiLanguage,
      'signUpMethod': ?instance.signUpMethod,
      'isStaff': instance.isStaff,
      'stats': ?instance.stats?.toJson(),
      'access': ?instance.access?.toJson(),
      'actions': ?instance.actions?.toJson(),
      'moderation': ?instance.moderation?.toJson(),
      'reports': ?instance.reports?.toJson(),
      'verification': ?instance.verification?.toJson(),
      'tickets': ?instance.tickets?.toJson(),
      'audit': ?instance.audit?.toJson(),
    };

_AdminUserStatsModel _$AdminUserStatsModelFromJson(Map<String, dynamic> json) =>
    _AdminUserStatsModel(
      drafts: (json['drafts'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      totalReads: (json['totalReads'] as num?)?.toInt() ?? 0,
      articlesRead: (json['articlesRead'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AdminUserStatsModelToJson(
  _AdminUserStatsModel instance,
) => <String, dynamic>{
  'drafts': instance.drafts,
  'comments': instance.comments,
  'following': instance.following,
  'totalReads': instance.totalReads,
  'articlesRead': instance.articlesRead,
  'currentStreak': instance.currentStreak,
  'longestStreak': instance.longestStreak,
};

_AdminUserAccessModel _$AdminUserAccessModelFromJson(
  Map<String, dynamic> json,
) => _AdminUserAccessModel(
  activeSessions: (json['activeSessions'] as num?)?.toInt() ?? 0,
  hasRecoveryPin: json['hasRecoveryPin'] as bool? ?? false,
  recoveryDisabled: json['recoveryDisabled'] as bool? ?? false,
  mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  mustSetRecoveryPin: json['mustSetRecoveryPin'] as bool? ?? false,
  lockedOutUntil: json['lockedOutUntil'] == null
      ? null
      : DateTime.parse(json['lockedOutUntil'] as String),
);

Map<String, dynamic> _$AdminUserAccessModelToJson(
  _AdminUserAccessModel instance,
) => <String, dynamic>{
  'activeSessions': instance.activeSessions,
  'hasRecoveryPin': instance.hasRecoveryPin,
  'recoveryDisabled': instance.recoveryDisabled,
  'mustChangePassword': instance.mustChangePassword,
  'mustSetRecoveryPin': instance.mustSetRecoveryPin,
  'lockedOutUntil': ?instance.lockedOutUntil?.toIso8601String(),
};

_AdminUserActionsModel _$AdminUserActionsModelFromJson(
  Map<String, dynamic> json,
) => _AdminUserActionsModel(
  canSuspend: json['canSuspend'] as bool? ?? false,
  canWarn: json['canWarn'] as bool? ?? false,
  canLogoutAll: json['canLogoutAll'] as bool? ?? false,
  canResetPassword: json['canResetPassword'] as bool? ?? false,
  canRemoveBadge: json['canRemoveBadge'] as bool? ?? false,
  canClearProfile: json['canClearProfile'] as bool? ?? false,
  canRestoreContent: json['canRestoreContent'] as bool? ?? false,
  canRevealPhone: json['canRevealPhone'] as bool? ?? false,
);

Map<String, dynamic> _$AdminUserActionsModelToJson(
  _AdminUserActionsModel instance,
) => <String, dynamic>{
  'canSuspend': instance.canSuspend,
  'canWarn': instance.canWarn,
  'canLogoutAll': instance.canLogoutAll,
  'canResetPassword': instance.canResetPassword,
  'canRemoveBadge': instance.canRemoveBadge,
  'canClearProfile': instance.canClearProfile,
  'canRestoreContent': instance.canRestoreContent,
  'canRevealPhone': instance.canRevealPhone,
};

_AdminUserModerationModel _$AdminUserModerationModelFromJson(
  Map<String, dynamic> json,
) => _AdminUserModerationModel(
  warnings: (json['warnings'] as num?)?.toInt() ?? 0,
  suspensions: (json['suspensions'] as num?)?.toInt() ?? 0,
  hiddenArticles: (json['hiddenArticles'] as num?)?.toInt() ?? 0,
  hiddenComments: (json['hiddenComments'] as num?)?.toInt() ?? 0,
  hiddenWithAccount: (json['hiddenWithAccount'] as num?)?.toInt() ?? 0,
  history:
      (json['history'] as List<dynamic>?)
          ?.map(
            (e) => ModerationActionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModerationActionModel>[],
  historyTotal: (json['historyTotal'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminUserModerationModelToJson(
  _AdminUserModerationModel instance,
) => <String, dynamic>{
  'warnings': instance.warnings,
  'suspensions': instance.suspensions,
  'hiddenArticles': instance.hiddenArticles,
  'hiddenComments': instance.hiddenComments,
  'hiddenWithAccount': instance.hiddenWithAccount,
  'history': instance.history.map((e) => e.toJson()).toList(),
  'historyTotal': instance.historyTotal,
};

_AdminUserReportModel _$AdminUserReportModelFromJson(
  Map<String, dynamic> json,
) => _AdminUserReportModel(
  id: json['id'] as String,
  targetType: json['targetType'] as String,
  targetId: json['targetId'] as String,
  targetLabel: json['targetLabel'] as String?,
  reason: json['reason'] as String? ?? 'other',
  details: json['details'] as String?,
  status: json['status'] as String? ?? 'open',
  createdAt: DateTime.parse(json['createdAt'] as String),
  reporter: json['reporter'] == null
      ? null
      : UserSummaryModel.fromJson(json['reporter'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdminUserReportModelToJson(
  _AdminUserReportModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'targetType': instance.targetType,
  'targetId': instance.targetId,
  'targetLabel': ?instance.targetLabel,
  'reason': instance.reason,
  'details': ?instance.details,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'reporter': ?instance.reporter?.toJson(),
};

_AdminUserReportsModel _$AdminUserReportsModelFromJson(
  Map<String, dynamic> json,
) => _AdminUserReportsModel(
  against:
      (json['against'] as List<dynamic>?)
          ?.map((e) => AdminUserReportModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AdminUserReportModel>[],
  againstTotal: (json['againstTotal'] as num?)?.toInt() ?? 0,
  filed:
      (json['filed'] as List<dynamic>?)
          ?.map((e) => AdminUserReportModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AdminUserReportModel>[],
  filedTotal: (json['filedTotal'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminUserReportsModelToJson(
  _AdminUserReportsModel instance,
) => <String, dynamic>{
  'against': instance.against.map((e) => e.toJson()).toList(),
  'againstTotal': instance.againstTotal,
  'filed': instance.filed.map((e) => e.toJson()).toList(),
  'filedTotal': instance.filedTotal,
};

_AdminVerificationSectionModel _$AdminVerificationSectionModelFromJson(
  Map<String, dynamic> json,
) => _AdminVerificationSectionModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => AdminVerificationRequestModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const <AdminVerificationRequestModel>[],
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminVerificationSectionModelToJson(
  _AdminVerificationSectionModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
};

_AdminTicketSectionModel _$AdminTicketSectionModelFromJson(
  Map<String, dynamic> json,
) => _AdminTicketSectionModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => AdminTicketModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AdminTicketModel>[],
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminTicketSectionModelToJson(
  _AdminTicketSectionModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
};

_AuditUserModel _$AuditUserModelFromJson(Map<String, dynamic> json) =>
    _AuditUserModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );

Map<String, dynamic> _$AuditUserModelToJson(_AuditUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
    };

_AuditEntryModel _$AuditEntryModelFromJson(Map<String, dynamic> json) =>
    _AuditEntryModel(
      id: json['id'] as String,
      action: json['action'] as String? ?? '',
      actor: json['actor'] == null
          ? null
          : AuditUserModel.fromJson(json['actor'] as Map<String, dynamic>),
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AuditEntryModelToJson(_AuditEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'actor': ?instance.actor?.toJson(),
      'details': ?instance.details,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_AdminAuditSectionModel _$AdminAuditSectionModelFromJson(
  Map<String, dynamic> json,
) => _AdminAuditSectionModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => AuditEntryModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AuditEntryModel>[],
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminAuditSectionModelToJson(
  _AdminAuditSectionModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
};

_AdminUserPageModel _$AdminUserPageModelFromJson(Map<String, dynamic> json) =>
    _AdminUserPageModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AdminUserModel>[],
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AdminUserPageModelToJson(_AdminUserPageModel instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page,
      'pageSize': instance.pageSize,
      'totalCount': instance.totalCount,
      'totalPages': instance.totalPages,
    };

_AdminPhoneModel _$AdminPhoneModelFromJson(Map<String, dynamic> json) =>
    _AdminPhoneModel(phoneNumber: json['phoneNumber'] as String?);

Map<String, dynamic> _$AdminPhoneModelToJson(_AdminPhoneModel instance) =>
    <String, dynamic>{'phoneNumber': ?instance.phoneNumber};

_TemporaryPasswordModel _$TemporaryPasswordModelFromJson(
  Map<String, dynamic> json,
) => _TemporaryPasswordModel(
  temporaryPassword: json['temporaryPassword'] as String? ?? '',
);

Map<String, dynamic> _$TemporaryPasswordModelToJson(
  _TemporaryPasswordModel instance,
) => <String, dynamic>{'temporaryPassword': instance.temporaryPassword};

_AdminArticleRowModel _$AdminArticleRowModelFromJson(
  Map<String, dynamic> json,
) => _AdminArticleRowModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  status: json['status'] as String? ?? 'published',
  title: json['title'] as String? ?? '',
  language: json['language'] as String? ?? 'ar-EG',
  author: json['author'] == null
      ? null
      : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
  field: FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
  topic: json['topic'] == null
      ? null
      : FieldRefModel.fromJson(json['topic'] as Map<String, dynamic>),
  publishedAt: json['publishedAt'] == null
      ? null
      : DateTime.parse(json['publishedAt'] as String),
  readCount: (json['readCount'] as num?)?.toInt() ?? 0,
  reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  hiddenAt: json['hiddenAt'] == null
      ? null
      : DateTime.parse(json['hiddenAt'] as String),
  featuredAt: json['featuredAt'] == null
      ? null
      : DateTime.parse(json['featuredAt'] as String),
  openReports: (json['openReports'] as num?)?.toInt() ?? 0,
  reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminArticleRowModelToJson(
  _AdminArticleRowModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'status': instance.status,
  'title': instance.title,
  'language': instance.language,
  'author': ?instance.author?.toJson(),
  'field': instance.field.toJson(),
  'topic': ?instance.topic?.toJson(),
  'publishedAt': ?instance.publishedAt?.toIso8601String(),
  'readCount': instance.readCount,
  'reactionCount': instance.reactionCount,
  'commentCount': instance.commentCount,
  'hiddenAt': ?instance.hiddenAt?.toIso8601String(),
  'featuredAt': ?instance.featuredAt?.toIso8601String(),
  'openReports': instance.openReports,
  'reportCount': instance.reportCount,
};

_AdminArticlePageModel _$AdminArticlePageModelFromJson(
  Map<String, dynamic> json,
) => _AdminArticlePageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => AdminArticleRowModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AdminArticleRowModel>[],
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
  totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
  totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminArticlePageModelToJson(
  _AdminArticlePageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page,
  'pageSize': instance.pageSize,
  'totalCount': instance.totalCount,
  'totalPages': instance.totalPages,
};

_AdminCommentArticleModel _$AdminCommentArticleModelFromJson(
  Map<String, dynamic> json,
) => _AdminCommentArticleModel(
  id: json['id'] as String,
  slug: json['slug'] as String? ?? '',
  title: json['title'] as String? ?? '',
  language: json['language'] as String? ?? 'ar-EG',
);

Map<String, dynamic> _$AdminCommentArticleModelToJson(
  _AdminCommentArticleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'language': instance.language,
};

_AdminCommentRowModel _$AdminCommentRowModelFromJson(
  Map<String, dynamic> json,
) => _AdminCommentRowModel(
  id: json['id'] as String,
  body: json['body'] as String? ?? '',
  author: json['author'] == null
      ? null
      : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
  article: AdminCommentArticleModel.fromJson(
    json['article'] as Map<String, dynamic>,
  ),
  parentId: json['parentId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  editedAt: json['editedAt'] == null
      ? null
      : DateTime.parse(json['editedAt'] as String),
  hiddenAt: json['hiddenAt'] == null
      ? null
      : DateTime.parse(json['hiddenAt'] as String),
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
  openReports: (json['openReports'] as num?)?.toInt() ?? 0,
  reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminCommentRowModelToJson(
  _AdminCommentRowModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'body': instance.body,
  'author': ?instance.author?.toJson(),
  'article': instance.article.toJson(),
  'parentId': ?instance.parentId,
  'createdAt': instance.createdAt.toIso8601String(),
  'editedAt': ?instance.editedAt?.toIso8601String(),
  'hiddenAt': ?instance.hiddenAt?.toIso8601String(),
  'likeCount': instance.likeCount,
  'replyCount': instance.replyCount,
  'openReports': instance.openReports,
  'reportCount': instance.reportCount,
};

_AdminCommentPageModel _$AdminCommentPageModelFromJson(
  Map<String, dynamic> json,
) => _AdminCommentPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => AdminCommentRowModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AdminCommentRowModel>[],
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
  totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
  totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdminCommentPageModelToJson(
  _AdminCommentPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page,
  'pageSize': instance.pageSize,
  'totalCount': instance.totalCount,
  'totalPages': instance.totalPages,
};

_AdminVerificationUserModel _$AdminVerificationUserModelFromJson(
  Map<String, dynamic> json,
) => _AdminVerificationUserModel(
  id: json['id'] as String,
  displayName: json['displayName'] as String? ?? '',
  username: json['username'] as String? ?? '',
  avatarUrl: json['avatarUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  headline: json['headline'] as String?,
);

Map<String, dynamic> _$AdminVerificationUserModelToJson(
  _AdminVerificationUserModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'username': instance.username,
  'avatarUrl': ?instance.avatarUrl,
  'isVerified': instance.isVerified,
  'headline': ?instance.headline,
};

_VerificationProofModel _$VerificationProofModelFromJson(
  Map<String, dynamic> json,
) => _VerificationProofModel(
  fileName: json['fileName'] as String? ?? '',
  contentType: json['contentType'] as String? ?? 'application/octet-stream',
  sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$VerificationProofModelToJson(
  _VerificationProofModel instance,
) => <String, dynamic>{
  'fileName': instance.fileName,
  'contentType': instance.contentType,
  'sizeBytes': instance.sizeBytes,
};

_VerificationDeciderModel _$VerificationDeciderModelFromJson(
  Map<String, dynamic> json,
) => _VerificationDeciderModel(
  id: json['id'] as String,
  username: json['username'] as String? ?? '',
);

Map<String, dynamic> _$VerificationDeciderModelToJson(
  _VerificationDeciderModel instance,
) => <String, dynamic>{'id': instance.id, 'username': instance.username};

_AdminVerificationRequestModel _$AdminVerificationRequestModelFromJson(
  Map<String, dynamic> json,
) => _AdminVerificationRequestModel(
  id: json['id'] as String,
  status: json['status'] as String,
  user: AdminVerificationUserModel.fromJson(
    json['user'] as Map<String, dynamic>,
  ),
  field: VerificationFieldModel.fromJson(json['field'] as Map<String, dynamic>),
  jobTitle: json['jobTitle'] as String? ?? '',
  proofUrl: json['proofUrl'] as String?,
  proof: json['proof'] == null
      ? null
      : VerificationProofModel.fromJson(json['proof'] as Map<String, dynamic>),
  note: json['note'] as String?,
  submittedAt: DateTime.parse(json['submittedAt'] as String),
  decidedAt: json['decidedAt'] == null
      ? null
      : DateTime.parse(json['decidedAt'] as String),
  decidedBy: json['decidedBy'] == null
      ? null
      : VerificationDeciderModel.fromJson(
          json['decidedBy'] as Map<String, dynamic>,
        ),
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$AdminVerificationRequestModelToJson(
  _AdminVerificationRequestModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'user': instance.user.toJson(),
  'field': instance.field.toJson(),
  'jobTitle': instance.jobTitle,
  'proofUrl': ?instance.proofUrl,
  'proof': ?instance.proof?.toJson(),
  'note': ?instance.note,
  'submittedAt': instance.submittedAt.toIso8601String(),
  'decidedAt': ?instance.decidedAt?.toIso8601String(),
  'decidedBy': ?instance.decidedBy?.toJson(),
  'rejectionReason': ?instance.rejectionReason,
};

_AdminVerificationPageModel _$AdminVerificationPageModelFromJson(
  Map<String, dynamic> json,
) => _AdminVerificationPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => AdminVerificationRequestModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const <AdminVerificationRequestModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$AdminVerificationPageModelToJson(
  _AdminVerificationPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_RejectVerificationRequest _$RejectVerificationRequestFromJson(
  Map<String, dynamic> json,
) => _RejectVerificationRequest(reason: json['reason'] as String);

Map<String, dynamic> _$RejectVerificationRequestToJson(
  _RejectVerificationRequest instance,
) => <String, dynamic>{'reason': instance.reason};
