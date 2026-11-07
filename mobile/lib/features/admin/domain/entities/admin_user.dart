import 'package:equatable/equatable.dart';

import '../../../follow/domain/entities/follow.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../profile/domain/entities/profile_link.dart';
import '../../../support/domain/entities/support.dart';
import 'admin_verification.dart';

/// How an account signs in (`SignInMethod`): phone = phone number + password.
enum SignInMethod {
  phone,
  google,
  apple;

  static SignInMethod? fromWire(String? wire) => values.where((m) => m.name == wire).firstOrNull;
}

/// A row of the console's Users (`AdminUserRowDto`).
class AdminUserRow extends Equatable {
  const AdminUserRow({
    required this.id,
    required this.displayName,
    required this.username,
    required this.joinedAt,
    this.avatarUrl,
    this.isVerified = false,
    this.isSystemAccount = false,
    this.roles = const [],
    this.signInMethods = const [],
    this.phoneMasked,
    this.lastSeenAt,
    this.publishedArticles = 0,
    this.followers = 0,
    this.suspended = false,
    this.suspendedUntil,
    this.openReports = 0,
  });

  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isVerified;

  /// The official @readin account.
  final bool isSystemAccount;

  /// `["Member"]` or `["SuperAdmin"]`: display only.
  final List<String> roles;
  final List<SignInMethod> signInMethods;

  /// "+20***1234"; null without a phone number.
  final String? phoneMasked;
  final DateTime joinedAt;

  /// To the hour; null = not seen since F23 shipped.
  final DateTime? lastSeenAt;
  final int publishedArticles;
  final int followers;
  final bool suspended;

  /// While [suspended]: when it ends; null = permanently.
  final DateTime? suspendedUntil;
  final int openReports;

  @override
  List<Object?> get props => [
        id,
        displayName,
        username,
        avatarUrl,
        isVerified,
        isSystemAccount,
        roles,
        signInMethods,
        phoneMasked,
        joinedAt,
        lastSeenAt,
        publishedArticles,
        followers,
        suspended,
        suspendedUntil,
        openReports,
      ];
}

/// A user's numbers on their console page.
class AdminUserStats extends Equatable {
  const AdminUserStats({
    this.drafts = 0,
    this.comments = 0,
    this.following = 0,
    this.totalReads = 0,
    this.articlesRead = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  final int drafts;
  final int comments;
  final int following;

  /// Reads of their articles.
  final int totalReads;

  /// Their own reading.
  final int articlesRead;
  final int currentStreak;
  final int longestStreak;

  @override
  List<Object?> get props => [drafts, comments, following, totalReads, articlesRead, currentStreak, longestStreak];
}

/// Sign-in state: devices, recovery and lockout.
class AdminUserAccess extends Equatable {
  const AdminUserAccess({
    this.activeSessions = 0,
    this.hasRecoveryPin = false,
    this.recoveryDisabled = false,
    this.mustChangePassword = false,
    this.mustSetRecoveryPin = false,
    this.lockedOutUntil,
  });

  final int activeSessions;
  final bool hasRecoveryPin;
  final bool recoveryDisabled;
  final bool mustChangePassword;
  final bool mustSetRecoveryPin;
  final DateTime? lockedOutUntil;

  @override
  List<Object?> get props =>
      [activeSessions, hasRecoveryPin, recoveryDisabled, mustChangePassword, mustSetRecoveryPin, lockedOutUntil];
}

/// What this caller may do to this account now (permissions + protected accounts).
class AdminUserActions extends Equatable {
  const AdminUserActions({
    this.canSuspend = false,
    this.canWarn = false,
    this.canLogoutAll = false,
    this.canResetPassword = false,
    this.canRemoveBadge = false,
    this.canClearProfile = false,
    this.canRestoreContent = false,
    this.canRevealPhone = false,
  });

  final bool canSuspend;
  final bool canWarn;
  final bool canLogoutAll;
  final bool canResetPassword;
  final bool canRemoveBadge;
  final bool canClearProfile;
  final bool canRestoreContent;
  final bool canRevealPhone;

  @override
  List<Object?> get props =>
      [canSuspend, canWarn, canLogoutAll, canResetPassword, canRemoveBadge, canClearProfile, canRestoreContent, canRevealPhone];
}

/// Moderation of the user and their content (`moderation.manage` only).
class AdminUserModeration extends Equatable {
  const AdminUserModeration({
    this.warnings = 0,
    this.suspensions = 0,
    this.hiddenArticles = 0,
    this.hiddenComments = 0,
    this.hiddenWithAccount = 0,
    this.history = const [],
    this.historyTotal = 0,
  });

  final int warnings;
  final int suspensions;
  final int hiddenArticles;
  final int hiddenComments;

  /// What "Restore their content" brings back.
  final int hiddenWithAccount;

  /// Newest first, at most 20.
  final List<ModerationLogEntry> history;
  final int historyTotal;

  @override
  List<Object?> get props => [warnings, suspensions, hiddenArticles, hiddenComments, hiddenWithAccount, history, historyTotal];
}

/// A report about the user (or their content), or one they filed.
class AdminUserReport extends Equatable {
  const AdminUserReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.targetLabel,
    this.details,
    this.reporter,
  });

  final String id;
  final ModerationTargetType targetType;
  final String targetId;

  /// The article title, the start of the comment or `@username`; null once deleted.
  final String? targetLabel;
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;

  /// Reports about them: who reported; null in their own reports, or once the reporter is gone.
  final UserSummary? reporter;

  ModerationTargetRef get ref => ModerationTargetRef(targetType, targetId);

  @override
  List<Object?> get props => [id, targetType, targetId, targetLabel, reason, details, status, createdAt, reporter];
}

/// An entry of the audit log about the user (`audit.read` only).
class AdminAuditEntry extends Equatable {
  const AdminAuditEntry({required this.id, required this.action, required this.createdAt, this.actorName, this.details});

  final String id;

  /// e.g. `admin.pii_viewed`, `user.suspend`.
  final String action;

  /// Who did it; null for a job, an anonymous flow or a deleted account.
  final String? actorName;
  final String? details;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, action, actorName, details, createdAt];
}

/// A list of a user's page with its total (the page holds the newest 20).
class AdminSection<T> extends Equatable {
  const AdminSection({this.items = const [], this.total = 0});

  final List<T> items;
  final int total;

  @override
  List<Object?> get props => [items, total];
}

/// A user's console page (`AdminUserDto`). The sections are null without their permission.
class AdminUser extends Equatable {
  const AdminUser({
    required this.row,
    this.headline,
    this.bio,
    this.links = const [],
    this.uiLanguage = 'ar',
    this.signUpMethod,
    this.isStaff = false,
    this.stats = const AdminUserStats(),
    this.access = const AdminUserAccess(),
    this.actions = const AdminUserActions(),
    this.moderation,
    this.reportsAgainst,
    this.reportsFiled,
    this.verification,
    this.tickets,
    this.audit,
  });

  final AdminUserRow row;
  final String? headline;
  final String? bio;
  final List<ProfileLink> links;
  final String uiLanguage;
  final SignInMethod? signUpMethod;

  /// Yourself, a holder of `admin.access` / `moderation.manage`, or a system account.
  final bool isStaff;
  final AdminUserStats stats;
  final AdminUserAccess access;
  final AdminUserActions actions;
  final AdminUserModeration? moderation;
  final AdminSection<AdminUserReport>? reportsAgainst;
  final AdminSection<AdminUserReport>? reportsFiled;
  final AdminSection<AdminVerificationRequest>? verification;
  final AdminSection<AdminTicketRow>? tickets;
  final AdminSection<AdminAuditEntry>? audit;

  String get id => row.id;

  @override
  List<Object?> get props => [
        row,
        headline,
        bio,
        links,
        uiLanguage,
        signUpMethod,
        isStaff,
        stats,
        access,
        actions,
        moderation,
        reportsAgainst,
        reportsFiled,
        verification,
        tickets,
        audit,
      ];
}

/// `GET /admin/users` filters.
enum AdminUserStatusFilter { active, suspended }

enum AdminUserSort {
  joined('joined'),
  lastSeen('lastSeen'),
  followers('followers'),
  openReports('openReports');

  const AdminUserSort(this.wire);

  final String wire;
}

/// The Users list's search, filters and sort (newest first by default).
class AdminUserQuery extends Equatable {
  const AdminUserQuery({
    this.q = '',
    this.status,
    this.verified,
    this.method,
    this.hasReports = false,
    this.joinedFrom,
    this.joinedTo,
    this.sort = AdminUserSort.joined,
    this.ascending = false,
  });

  /// A name, `@handle`, an id, or (with `users.read.pii`) a phone number.
  final String q;
  final AdminUserStatusFilter? status;
  final bool? verified;
  final SignInMethod? method;
  final bool hasReports;

  /// Joined in a period: `YYYY-MM-DD` in `Admin:TimeZone`, both ends included (contract decision 4).
  final String? joinedFrom;
  final String? joinedTo;
  final AdminUserSort sort;
  final bool ascending;

  bool get hasJoinedPeriod => joinedFrom != null || joinedTo != null;

  /// The query string of `GET /admin/users` (without the page).
  Map<String, dynamic> toQuery() => {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (status case final status?) 'status': status.name,
        if (verified case final verified?) 'verified': '$verified',
        if (method case final method?) 'method': method.name,
        if (hasReports) 'hasReports': 'true',
        'joinedFrom': ?joinedFrom,
        'joinedTo': ?joinedTo,
        'sort': sort.wire,
        'dir': ascending ? 'asc' : 'desc',
      };

  AdminUserQuery copyWith({
    String? q,
    AdminUserStatusFilter? Function()? status,
    bool? Function()? verified,
    SignInMethod? Function()? method,
    bool? hasReports,
    String? Function()? joinedFrom,
    String? Function()? joinedTo,
    AdminUserSort? sort,
    bool? ascending,
  }) =>
      AdminUserQuery(
        q: q ?? this.q,
        status: status != null ? status() : this.status,
        verified: verified != null ? verified() : this.verified,
        method: method != null ? method() : this.method,
        hasReports: hasReports ?? this.hasReports,
        joinedFrom: joinedFrom != null ? joinedFrom() : this.joinedFrom,
        joinedTo: joinedTo != null ? joinedTo() : this.joinedTo,
        sort: sort ?? this.sort,
        ascending: ascending ?? this.ascending,
      );

  @override
  List<Object?> get props => [q, status, verified, method, hasReports, joinedFrom, joinedTo, sort, ascending];
}
