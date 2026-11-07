import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../../follow/data/models/follow_models.dart';
import '../../../moderation/data/models/moderation_models.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../profile/data/models/profile_models.dart' show ProfileLinkModel;
import '../../../support/data/models/support_models.dart';
import '../../../verification/data/models/verification_models.dart';
import '../../../verification/domain/entities/verification.dart';
import '../../domain/entities/admin_content.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/admin_verification.dart';
import '../../domain/entities/paged_list.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

// ── Summary and dashboard ────────────────────────────────────────────────────────────────────────────────────────────

/// `GET /admin/summary`.
@freezed
abstract class AdminSummaryModel with _$AdminSummaryModel {
  const AdminSummaryModel._();

  const factory AdminSummaryModel({int? openReports, int? openTickets, int? pendingVerifications, @Default(0) int total}) =
      _AdminSummaryModel;

  factory AdminSummaryModel.fromJson(Map<String, dynamic> json) => _$AdminSummaryModelFromJson(json);

  AdminSummary toEntity() => AdminSummary(
        openReports: openReports,
        openTickets: openTickets,
        pendingVerifications: pendingVerifications,
        total: total,
      );
}

/// `DashboardValueDto`, and `newUsers` with its split by sign-up method.
@freezed
abstract class DashboardValueModel with _$DashboardValueModel {
  const DashboardValueModel._();

  const factory DashboardValueModel({
    @Default(0) int value,
    @Default(0) int previous,
    @Default(0) int phone,
    @Default(0) int google,
    @Default(0) int apple,
  }) = _DashboardValueModel;

  factory DashboardValueModel.fromJson(Map<String, dynamic> json) => _$DashboardValueModelFromJson(json);

  DashboardValue toEntity() => DashboardValue(value: value, previous: previous);

  NewUsersValue toNewUsers() => NewUsersValue(value: value, previous: previous, phone: phone, google: google, apple: apple);
}

/// `DashboardCardsDto`.
@freezed
abstract class DashboardCardsModel with _$DashboardCardsModel {
  const DashboardCardsModel._();

  const factory DashboardCardsModel({
    @Default(DashboardValueModel()) DashboardValueModel articlesPublished,
    @Default(DashboardValueModel()) DashboardValueModel newUsers,
    @Default(DashboardValueModel()) DashboardValueModel activeReaders,
    @Default(DashboardValueModel()) DashboardValueModel reads,
    @Default(DashboardValueModel()) DashboardValueModel comments,
    @Default(DashboardValueModel()) DashboardValueModel reactions,
    @Default(DashboardValueModel()) DashboardValueModel reposts,
    int? openReports,
    int? openTickets,
    int? pendingVerifications,
    @Default(0) int suspendedNow,
  }) = _DashboardCardsModel;

  factory DashboardCardsModel.fromJson(Map<String, dynamic> json) => _$DashboardCardsModelFromJson(json);

  DashboardCards toEntity() => DashboardCards(
        articlesPublished: articlesPublished.toEntity(),
        newUsers: newUsers.toNewUsers(),
        activeReaders: activeReaders.toEntity(),
        reads: reads.toEntity(),
        comments: comments.toEntity(),
        reactions: reactions.toEntity(),
        reposts: reposts.toEntity(),
        openReports: openReports,
        openTickets: openTickets,
        pendingVerifications: pendingVerifications,
        suspendedNow: suspendedNow,
      );
}

/// `DashboardDayDto`.
@freezed
abstract class DashboardDayModel with _$DashboardDayModel {
  const DashboardDayModel._();

  const factory DashboardDayModel({
    required String date,
    @Default(0) int newUsers,
    @Default(0) int activeReaders,
    @Default(0) int articlesPublished,
  }) = _DashboardDayModel;

  factory DashboardDayModel.fromJson(Map<String, dynamic> json) => _$DashboardDayModelFromJson(json);

  DashboardDay toEntity() =>
      DashboardDay(date: date, newUsers: newUsers, activeReaders: activeReaders, articlesPublished: articlesPublished);
}

/// `DashboardArticleDto`.
@freezed
abstract class DashboardArticleModel with _$DashboardArticleModel {
  const DashboardArticleModel._();

  const factory DashboardArticleModel({
    required String id,
    required String slug,
    @Default('') String title,
    @Default('ar-EG') String language,
    AuthorModel? author,
    required FieldRefModel field,
    required DateTime publishedAt,
    @Default(0) int reads,
  }) = _DashboardArticleModel;

  factory DashboardArticleModel.fromJson(Map<String, dynamic> json) => _$DashboardArticleModelFromJson(json);

  DashboardArticle toEntity() => DashboardArticle(
        id: id,
        slug: slug,
        title: title,
        language: language,
        author: author?.toEntity(),
        field: field.toEntity(),
        publishedAt: publishedAt,
        reads: reads,
      );
}

/// `DashboardWriterDto`.
@freezed
abstract class DashboardWriterModel with _$DashboardWriterModel {
  const DashboardWriterModel._();

  const factory DashboardWriterModel({required AuthorModel writer, @Default(0) int reads, @Default(0) int articles}) =
      _DashboardWriterModel;

  factory DashboardWriterModel.fromJson(Map<String, dynamic> json) => _$DashboardWriterModelFromJson(json);

  DashboardWriter toEntity() => DashboardWriter(writer: writer.toEntity(), reads: reads, articles: articles);
}

/// `DashboardMissedSearchDto`.
@freezed
abstract class MissedSearchModel with _$MissedSearchModel {
  const MissedSearchModel._();

  const factory MissedSearchModel({required String query, @Default('en') String language, @Default(0) int count}) =
      _MissedSearchModel;

  factory MissedSearchModel.fromJson(Map<String, dynamic> json) => _$MissedSearchModelFromJson(json);

  MissedSearch toEntity() => MissedSearch(query: query, language: language, count: count);
}

/// `streakRetention`.
@freezed
abstract class StreakRetentionModel with _$StreakRetentionModel {
  const StreakRetentionModel._();

  const factory StreakRetentionModel({@Default(0) int cohort, @Default(0) int kept, double? rate}) = _StreakRetentionModel;

  factory StreakRetentionModel.fromJson(Map<String, dynamic> json) => _$StreakRetentionModelFromJson(json);

  StreakRetention toEntity() => StreakRetention(cohort: cohort, kept: kept, rate: rate);
}

/// `ContentPipelineDto`.
@freezed
abstract class ContentPipelineModel with _$ContentPipelineModel {
  const ContentPipelineModel._();

  const factory ContentPipelineModel({
    @Default(0) int folders,
    @Default(0) int seeded,
    @Default(0) int published,
    DateTime? lastSeedRunAt,
  }) = _ContentPipelineModel;

  factory ContentPipelineModel.fromJson(Map<String, dynamic> json) => _$ContentPipelineModelFromJson(json);

  ContentPipeline toEntity() =>
      ContentPipeline(folders: folders, seeded: seeded, published: published, lastSeedRunAt: lastSeedRunAt);
}

/// `AdminDashboardDto`.
@freezed
abstract class AdminDashboardModel with _$AdminDashboardModel {
  const AdminDashboardModel._();

  const factory AdminDashboardModel({
    required String period,
    @Default('Africa/Cairo') String timeZone,
    @Default('') String fromDate,
    @Default('') String toDate,
    required DateTime generatedAt,
    @Default(DashboardCardsModel()) DashboardCardsModel cards,
    @Default(<DashboardDayModel>[]) List<DashboardDayModel> charts,
    @Default(<DashboardArticleModel>[]) List<DashboardArticleModel> topArticles,
    @Default(<DashboardWriterModel>[]) List<DashboardWriterModel> topWriters,
    @Default(<MissedSearchModel>[]) List<MissedSearchModel> missedSearches,
    @Default(StreakRetentionModel()) StreakRetentionModel streakRetention,
    @Default(ContentPipelineModel()) ContentPipelineModel contentPipeline,
  }) = _AdminDashboardModel;

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) => _$AdminDashboardModelFromJson(json);

  AdminDashboard toEntity() => AdminDashboard(
        period: AdminPeriod.fromWire(period),
        timeZone: timeZone,
        fromDate: fromDate,
        toDate: toDate,
        generatedAt: generatedAt,
        cards: cards.toEntity(),
        charts: [for (final day in charts) day.toEntity()],
        topArticles: [for (final a in topArticles) a.toEntity()],
        topWriters: [for (final w in topWriters) w.toEntity()],
        missedSearches: [for (final s in missedSearches) s.toEntity()],
        streakRetention: streakRetention.toEntity(),
        contentPipeline: contentPipeline.toEntity(),
      );
}

// ── Users ────────────────────────────────────────────────────────────────────────────────────────────────────────────

/// `AdminUserRowDto`, and `AdminUserDto` with the page's parts.
@freezed
abstract class AdminUserModel with _$AdminUserModel {
  const AdminUserModel._();

  const factory AdminUserModel({
    required String id,
    @Default('') String displayName,
    @Default('') String username,
    String? avatarUrl,
    @Default(false) bool isVerified,
    @Default(false) bool isSystemAccount,
    @Default(<String>[]) List<String> roles,
    @Default(<String>[]) List<String> signInMethods,
    String? phoneMasked,
    required DateTime joinedAt,
    DateTime? lastSeenAt,
    @Default(0) int publishedArticles,
    @Default(0) int followers,
    @Default('active') String status,
    DateTime? suspendedUntil,
    @Default(0) int openReports,
    // The page (`GET /admin/users/{id}`).
    String? headline,
    String? bio,
    @Default(<ProfileLinkModel>[]) List<ProfileLinkModel> links,
    @Default('ar') String uiLanguage,
    String? signUpMethod,
    @Default(false) bool isStaff,
    AdminUserStatsModel? stats,
    AdminUserAccessModel? access,
    AdminUserActionsModel? actions,
    AdminUserModerationModel? moderation,
    AdminUserReportsModel? reports,
    AdminVerificationSectionModel? verification,
    AdminTicketSectionModel? tickets,
    AdminAuditSectionModel? audit,
  }) = _AdminUserModel;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) => _$AdminUserModelFromJson(json);

  AdminUserRow toRow() => AdminUserRow(
        id: id,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        isVerified: isVerified,
        isSystemAccount: isSystemAccount,
        roles: roles,
        signInMethods: [for (final m in signInMethods) ?SignInMethod.fromWire(m)],
        phoneMasked: phoneMasked,
        joinedAt: joinedAt,
        lastSeenAt: lastSeenAt,
        publishedArticles: publishedArticles,
        followers: followers,
        suspended: status == 'suspended',
        suspendedUntil: suspendedUntil,
        openReports: openReports,
      );

  AdminUser toEntity() => AdminUser(
        row: toRow(),
        headline: headline,
        bio: bio,
        links: ProfileLinkModel.entities(links),
        uiLanguage: uiLanguage,
        signUpMethod: SignInMethod.fromWire(signUpMethod),
        isStaff: isStaff,
        stats: stats?.toEntity() ?? const AdminUserStats(),
        access: access?.toEntity() ?? const AdminUserAccess(),
        actions: actions?.toEntity() ?? const AdminUserActions(),
        moderation: moderation?.toEntity(),
        reportsAgainst: reports == null
            ? null
            : AdminSection(items: [for (final r in reports!.against) ?r.toEntity()], total: reports!.againstTotal),
        reportsFiled: reports == null
            ? null
            : AdminSection(items: [for (final r in reports!.filed) ?r.toEntity()], total: reports!.filedTotal),
        verification: verification == null
            ? null
            : AdminSection(items: [for (final v in verification!.items) v.toEntity()], total: verification!.total),
        tickets:
            tickets == null ? null : AdminSection(items: [for (final t in tickets!.items) t.toRow()], total: tickets!.total),
        audit: audit == null ? null : AdminSection(items: [for (final a in audit!.items) a.toEntity()], total: audit!.total),
      );
}

@freezed
abstract class AdminUserStatsModel with _$AdminUserStatsModel {
  const AdminUserStatsModel._();

  const factory AdminUserStatsModel({
    @Default(0) int drafts,
    @Default(0) int comments,
    @Default(0) int following,
    @Default(0) int totalReads,
    @Default(0) int articlesRead,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
  }) = _AdminUserStatsModel;

  factory AdminUserStatsModel.fromJson(Map<String, dynamic> json) => _$AdminUserStatsModelFromJson(json);

  AdminUserStats toEntity() => AdminUserStats(
        drafts: drafts,
        comments: comments,
        following: following,
        totalReads: totalReads,
        articlesRead: articlesRead,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
      );
}

@freezed
abstract class AdminUserAccessModel with _$AdminUserAccessModel {
  const AdminUserAccessModel._();

  const factory AdminUserAccessModel({
    @Default(0) int activeSessions,
    @Default(false) bool hasRecoveryPin,
    @Default(false) bool recoveryDisabled,
    @Default(false) bool mustChangePassword,
    @Default(false) bool mustSetRecoveryPin,
    DateTime? lockedOutUntil,
  }) = _AdminUserAccessModel;

  factory AdminUserAccessModel.fromJson(Map<String, dynamic> json) => _$AdminUserAccessModelFromJson(json);

  AdminUserAccess toEntity() => AdminUserAccess(
        activeSessions: activeSessions,
        hasRecoveryPin: hasRecoveryPin,
        recoveryDisabled: recoveryDisabled,
        mustChangePassword: mustChangePassword,
        mustSetRecoveryPin: mustSetRecoveryPin,
        lockedOutUntil: lockedOutUntil,
      );
}

@freezed
abstract class AdminUserActionsModel with _$AdminUserActionsModel {
  const AdminUserActionsModel._();

  const factory AdminUserActionsModel({
    @Default(false) bool canSuspend,
    @Default(false) bool canWarn,
    @Default(false) bool canLogoutAll,
    @Default(false) bool canResetPassword,
    @Default(false) bool canRemoveBadge,
    @Default(false) bool canClearProfile,
    @Default(false) bool canRestoreContent,
    @Default(false) bool canRevealPhone,
  }) = _AdminUserActionsModel;

  factory AdminUserActionsModel.fromJson(Map<String, dynamic> json) => _$AdminUserActionsModelFromJson(json);

  AdminUserActions toEntity() => AdminUserActions(
        canSuspend: canSuspend,
        canWarn: canWarn,
        canLogoutAll: canLogoutAll,
        canResetPassword: canResetPassword,
        canRemoveBadge: canRemoveBadge,
        canClearProfile: canClearProfile,
        canRestoreContent: canRestoreContent,
        canRevealPhone: canRevealPhone,
      );
}

@freezed
abstract class AdminUserModerationModel with _$AdminUserModerationModel {
  const AdminUserModerationModel._();

  const factory AdminUserModerationModel({
    @Default(0) int warnings,
    @Default(0) int suspensions,
    @Default(0) int hiddenArticles,
    @Default(0) int hiddenComments,
    @Default(0) int hiddenWithAccount,
    @Default(<ModerationActionModel>[]) List<ModerationActionModel> history,
    @Default(0) int historyTotal,
  }) = _AdminUserModerationModel;

  factory AdminUserModerationModel.fromJson(Map<String, dynamic> json) => _$AdminUserModerationModelFromJson(json);

  AdminUserModeration toEntity() => AdminUserModeration(
        warnings: warnings,
        suspensions: suspensions,
        hiddenArticles: hiddenArticles,
        hiddenComments: hiddenComments,
        hiddenWithAccount: hiddenWithAccount,
        history: [for (final h in history) ?h.toEntity()],
        historyTotal: historyTotal,
      );
}

/// `AdminUserReportDto`.
@freezed
abstract class AdminUserReportModel with _$AdminUserReportModel {
  const AdminUserReportModel._();

  const factory AdminUserReportModel({
    required String id,
    required String targetType,
    required String targetId,
    String? targetLabel,
    @Default('other') String reason,
    String? details,
    @Default('open') String status,
    required DateTime createdAt,
    UserSummaryModel? reporter,
  }) = _AdminUserReportModel;

  factory AdminUserReportModel.fromJson(Map<String, dynamic> json) => _$AdminUserReportModelFromJson(json);

  /// Null for a target type this app version doesn't know.
  AdminUserReport? toEntity() {
    final type = enumFromWire(ModerationTargetType.values, targetType);
    if (type == null) return null;
    return AdminUserReport(
      id: id,
      targetType: type,
      targetId: targetId,
      targetLabel: targetLabel,
      reason: enumFromWire(ReportReason.values, reason) ?? ReportReason.other,
      details: details,
      status: enumFromWire(ReportStatus.values, status) ?? ReportStatus.open,
      createdAt: createdAt,
      reporter: reporter?.toEntity(),
    );
  }
}

/// `AdminUserDto.reports`.
@freezed
abstract class AdminUserReportsModel with _$AdminUserReportsModel {
  const factory AdminUserReportsModel({
    @Default(<AdminUserReportModel>[]) List<AdminUserReportModel> against,
    @Default(0) int againstTotal,
    @Default(<AdminUserReportModel>[]) List<AdminUserReportModel> filed,
    @Default(0) int filedTotal,
  }) = _AdminUserReportsModel;

  factory AdminUserReportsModel.fromJson(Map<String, dynamic> json) => _$AdminUserReportsModelFromJson(json);
}

@freezed
abstract class AdminVerificationSectionModel with _$AdminVerificationSectionModel {
  const factory AdminVerificationSectionModel({
    @Default(<AdminVerificationRequestModel>[]) List<AdminVerificationRequestModel> items,
    @Default(0) int total,
  }) = _AdminVerificationSectionModel;

  factory AdminVerificationSectionModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationSectionModelFromJson(json);
}

@freezed
abstract class AdminTicketSectionModel with _$AdminTicketSectionModel {
  const factory AdminTicketSectionModel({
    @Default(<AdminTicketModel>[]) List<AdminTicketModel> items,
    @Default(0) int total,
  }) = _AdminTicketSectionModel;

  factory AdminTicketSectionModel.fromJson(Map<String, dynamic> json) => _$AdminTicketSectionModelFromJson(json);
}

/// `AuditUserDto`.
@freezed
abstract class AuditUserModel with _$AuditUserModel {
  const factory AuditUserModel({required String id, @Default('') String displayName, @Default('') String username}) =
      _AuditUserModel;

  factory AuditUserModel.fromJson(Map<String, dynamic> json) => _$AuditUserModelFromJson(json);
}

/// `AuditEntryDto`, as a user's page lists it.
@freezed
abstract class AuditEntryModel with _$AuditEntryModel {
  const AuditEntryModel._();

  const factory AuditEntryModel({
    required String id,
    @Default('') String action,
    AuditUserModel? actor,
    String? details,
    required DateTime createdAt,
  }) = _AuditEntryModel;

  factory AuditEntryModel.fromJson(Map<String, dynamic> json) => _$AuditEntryModelFromJson(json);

  AdminAuditEntry toEntity() =>
      AdminAuditEntry(id: id, action: action, actorName: actor?.displayName, details: details, createdAt: createdAt);
}

@freezed
abstract class AdminAuditSectionModel with _$AdminAuditSectionModel {
  const factory AdminAuditSectionModel({
    @Default(<AuditEntryModel>[]) List<AuditEntryModel> items,
    @Default(0) int total,
  }) = _AdminAuditSectionModel;

  factory AdminAuditSectionModel.fromJson(Map<String, dynamic> json) => _$AdminAuditSectionModelFromJson(json);
}

/// `PagedList<AdminUserRowDto>`.
@freezed
abstract class AdminUserPageModel with _$AdminUserPageModel {
  const AdminUserPageModel._();

  const factory AdminUserPageModel({
    @Default(<AdminUserModel>[]) List<AdminUserModel> items,
    @Default(1) int page,
    @Default(50) int pageSize,
    @Default(0) int totalCount,
    @Default(0) int totalPages,
  }) = _AdminUserPageModel;

  factory AdminUserPageModel.fromJson(Map<String, dynamic> json) => _$AdminUserPageModelFromJson(json);

  PagedList<AdminUserRow> toEntity() => PagedList(
        items: [for (final u in items) u.toRow()],
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
      );
}

/// `GET /admin/users/{id}/phone`.
@freezed
abstract class AdminPhoneModel with _$AdminPhoneModel {
  const factory AdminPhoneModel({String? phoneNumber}) = _AdminPhoneModel;

  factory AdminPhoneModel.fromJson(Map<String, dynamic> json) => _$AdminPhoneModelFromJson(json);
}

/// `POST /admin/users/{id}/reset-password`.
@freezed
abstract class TemporaryPasswordModel with _$TemporaryPasswordModel {
  const factory TemporaryPasswordModel({@Default('') String temporaryPassword}) = _TemporaryPasswordModel;

  factory TemporaryPasswordModel.fromJson(Map<String, dynamic> json) => _$TemporaryPasswordModelFromJson(json);
}

// ── Content ──────────────────────────────────────────────────────────────────────────────────────────────────────────

/// `AdminArticleRowDto`.
@freezed
abstract class AdminArticleRowModel with _$AdminArticleRowModel {
  const AdminArticleRowModel._();

  const factory AdminArticleRowModel({
    required String id,
    required String slug,
    @Default('published') String status,
    @Default('') String title,
    @Default('ar-EG') String language,
    AuthorModel? author,
    required FieldRefModel field,
    FieldRefModel? topic,
    // Null: archived without ever being published (as built).
    DateTime? publishedAt,
    @Default(0) int readCount,
    @Default(0) int reactionCount,
    @Default(0) int commentCount,
    DateTime? hiddenAt,
    DateTime? featuredAt,
    @Default(0) int openReports,
    @Default(0) int reportCount,
  }) = _AdminArticleRowModel;

  factory AdminArticleRowModel.fromJson(Map<String, dynamic> json) => _$AdminArticleRowModelFromJson(json);

  AdminArticleRow toEntity() => AdminArticleRow(
        id: id,
        slug: slug,
        archived: status == 'archived',
        title: title,
        language: language,
        author: author?.toEntity(),
        field: field.toEntity(),
        topic: topic?.toEntity(),
        publishedAt: publishedAt,
        readCount: readCount,
        reactionCount: reactionCount,
        commentCount: commentCount,
        hiddenAt: hiddenAt,
        featuredAt: featuredAt,
        openReports: openReports,
        reportCount: reportCount,
      );
}

@freezed
abstract class AdminArticlePageModel with _$AdminArticlePageModel {
  const AdminArticlePageModel._();

  const factory AdminArticlePageModel({
    @Default(<AdminArticleRowModel>[]) List<AdminArticleRowModel> items,
    @Default(1) int page,
    @Default(50) int pageSize,
    @Default(0) int totalCount,
    @Default(0) int totalPages,
  }) = _AdminArticlePageModel;

  factory AdminArticlePageModel.fromJson(Map<String, dynamic> json) => _$AdminArticlePageModelFromJson(json);

  PagedList<AdminArticleRow> toEntity() => PagedList(
        items: [for (final a in items) a.toEntity()],
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
      );
}

/// `AdminCommentRowDto.article`.
@freezed
abstract class AdminCommentArticleModel with _$AdminCommentArticleModel {
  const factory AdminCommentArticleModel({
    required String id,
    @Default('') String slug,
    @Default('') String title,
    @Default('ar-EG') String language,
  }) = _AdminCommentArticleModel;

  factory AdminCommentArticleModel.fromJson(Map<String, dynamic> json) => _$AdminCommentArticleModelFromJson(json);
}

/// `AdminCommentRowDto`.
@freezed
abstract class AdminCommentRowModel with _$AdminCommentRowModel {
  const AdminCommentRowModel._();

  const factory AdminCommentRowModel({
    required String id,
    @Default('') String body,
    AuthorModel? author,
    required AdminCommentArticleModel article,
    String? parentId,
    required DateTime createdAt,
    DateTime? editedAt,
    DateTime? hiddenAt,
    @Default(0) int likeCount,
    @Default(0) int replyCount,
    @Default(0) int openReports,
    @Default(0) int reportCount,
  }) = _AdminCommentRowModel;

  factory AdminCommentRowModel.fromJson(Map<String, dynamic> json) => _$AdminCommentRowModelFromJson(json);

  AdminCommentRow toEntity() => AdminCommentRow(
        id: id,
        body: body,
        author: author?.toEntity(),
        article: AdminCommentArticle(id: article.id, slug: article.slug, title: article.title, language: article.language),
        parentId: parentId,
        createdAt: createdAt,
        editedAt: editedAt,
        hiddenAt: hiddenAt,
        likeCount: likeCount,
        replyCount: replyCount,
        openReports: openReports,
        reportCount: reportCount,
      );
}

@freezed
abstract class AdminCommentPageModel with _$AdminCommentPageModel {
  const AdminCommentPageModel._();

  const factory AdminCommentPageModel({
    @Default(<AdminCommentRowModel>[]) List<AdminCommentRowModel> items,
    @Default(1) int page,
    @Default(50) int pageSize,
    @Default(0) int totalCount,
    @Default(0) int totalPages,
  }) = _AdminCommentPageModel;

  factory AdminCommentPageModel.fromJson(Map<String, dynamic> json) => _$AdminCommentPageModelFromJson(json);

  PagedList<AdminCommentRow> toEntity() => PagedList(
        items: [for (final c in items) c.toEntity()],
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
      );
}

// ── Verification (F19) ───────────────────────────────────────────────────────────────────────────────────────────────

/// `AdminVerificationRequestDto.user`.
@freezed
abstract class AdminVerificationUserModel with _$AdminVerificationUserModel {
  const AdminVerificationUserModel._();

  const factory AdminVerificationUserModel({
    required String id,
    @Default('') String displayName,
    @Default('') String username,
    String? avatarUrl,
    @Default(false) bool isVerified,
    String? headline,
  }) = _AdminVerificationUserModel;

  factory AdminVerificationUserModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationUserModelFromJson(json);

  AdminVerificationUser toEntity() => AdminVerificationUser(
        id: id,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        isVerified: isVerified,
        headline: headline,
      );
}

/// `AdminVerificationRequestDto.proof`.
@freezed
abstract class VerificationProofModel with _$VerificationProofModel {
  const factory VerificationProofModel({
    @Default('') String fileName,
    @Default('application/octet-stream') String contentType,
    @Default(0) int sizeBytes,
  }) = _VerificationProofModel;

  factory VerificationProofModel.fromJson(Map<String, dynamic> json) => _$VerificationProofModelFromJson(json);
}

/// `AdminVerificationRequestDto.decidedBy`.
@freezed
abstract class VerificationDeciderModel with _$VerificationDeciderModel {
  const factory VerificationDeciderModel({required String id, @Default('') String username}) = _VerificationDeciderModel;

  factory VerificationDeciderModel.fromJson(Map<String, dynamic> json) => _$VerificationDeciderModelFromJson(json);
}

/// `AdminVerificationRequestDto`.
@freezed
abstract class AdminVerificationRequestModel with _$AdminVerificationRequestModel {
  const AdminVerificationRequestModel._();

  const factory AdminVerificationRequestModel({
    required String id,
    required String status,
    required AdminVerificationUserModel user,
    required VerificationFieldModel field,
    @Default('') String jobTitle,
    String? proofUrl,
    VerificationProofModel? proof,
    String? note,
    required DateTime submittedAt,
    DateTime? decidedAt,
    VerificationDeciderModel? decidedBy,
    String? rejectionReason,
  }) = _AdminVerificationRequestModel;

  factory AdminVerificationRequestModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationRequestModelFromJson(json);

  AdminVerificationRequest toEntity() => AdminVerificationRequest(
        id: id,
        status: VerificationRequestStatus.fromWire(status),
        user: user.toEntity(),
        field: field.toEntity(),
        jobTitle: jobTitle,
        proofUrl: proofUrl,
        proof: proof == null
            ? null
            : VerificationProofFile(fileName: proof!.fileName, contentType: proof!.contentType, sizeBytes: proof!.sizeBytes),
        note: note,
        submittedAt: submittedAt,
        decidedAt: decidedAt,
        decidedBy: decidedBy?.username,
        rejectionReason: rejectionReason,
      );
}

/// `CursorPage<AdminVerificationRequestDto>`.
@freezed
abstract class AdminVerificationPageModel with _$AdminVerificationPageModel {
  const factory AdminVerificationPageModel({
    @Default(<AdminVerificationRequestModel>[]) List<AdminVerificationRequestModel> items,
    String? nextCursor,
  }) = _AdminVerificationPageModel;

  factory AdminVerificationPageModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationPageModelFromJson(json);
}

/// `POST /admin/verification-requests/{id}/reject` body.
@freezed
abstract class RejectVerificationRequest with _$RejectVerificationRequest {
  const factory RejectVerificationRequest({required String reason}) = _RejectVerificationRequest;

  factory RejectVerificationRequest.fromJson(Map<String, dynamic> json) => _$RejectVerificationRequestFromJson(json);
}
