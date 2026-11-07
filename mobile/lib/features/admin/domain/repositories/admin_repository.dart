import 'dart:typed_data';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../verification/domain/entities/verification.dart';
import '../entities/admin_content.dart';
import '../entities/admin_dashboard.dart';
import '../entities/admin_user.dart';
import '../entities/admin_verification.dart';
import '../entities/paged_list.dart';

/// The admin console (F23). Every call needs the permission of its section; a Member gets `403 auth.forbidden`.
abstract interface class AdminRepository {
  /// `GET /admin/summary`: the console entry's badge.
  Future<Result<AdminSummary>> summary();

  /// `GET /admin/dashboard?period=`.
  Future<Result<AdminDashboard>> dashboard(AdminPeriod period);

  /// `GET /admin/users` (`users.read`).
  Future<Result<PagedList<AdminUserRow>>> users(AdminUserQuery query, {int page = 1, int pageSize = 50});

  /// `GET /admin/users/{id}`. `404 user.not_found`.
  Future<Result<AdminUser>> user(String id);

  /// `GET /admin/users/{id}/phone` (`users.read.pii`, audited): the full number, null for a Google/Apple-only account.
  Future<Result<String?>> revealPhone(String userId);

  /// `POST /admin/users/{id}/logout-all` (`users.suspend`): ends every session of the account.
  Future<Result<void>> logoutAll(String userId);

  /// `POST /admin/users/{id}/reset-password` (`users.reset_password`): the temporary password, shown once.
  Future<Result<String>> resetPassword(String userId);

  /// `DELETE /admin/users/{id}/verification` (`verification.manage`). `409 verification.not_verified`,
  /// `verification.system_account`.
  Future<Result<void>> removeBadge(String userId);

  /// `GET /admin/articles` (`moderation.manage`).
  Future<Result<PagedList<AdminArticleRow>>> articles(AdminArticleQuery query, {int page = 1, int pageSize = 50});

  /// `GET /admin/articles/{id}`. `404 article.not_found`.
  Future<Result<AdminArticleRow>> article(String id);

  /// `GET /admin/comments` ("Latest comments").
  Future<Result<PagedList<AdminCommentRow>>> comments(AdminCommentQuery query, {int page = 1, int pageSize = 50});

  /// `PUT` / `DELETE /admin/articles/{id}/featured` (`articles.feature`).
  Future<Result<void>> setFeatured(String articleId, {required bool featured});

  /// `GET /admin/verification-requests` (`verification.manage`), cursor paged.
  Future<Result<CursorPage<AdminVerificationRequest>>> verificationRequests(
    VerificationRequestStatus status, {
    String? cursor,
    int limit = 20,
  });

  /// `GET /admin/verification-requests/{id}`.
  Future<Result<AdminVerificationRequest>> verificationRequest(String id);

  /// `POST /admin/verification-requests/{id}/approve`. `409 verification.already_decided`.
  Future<Result<void>> approve(String requestId);

  /// `POST /admin/verification-requests/{id}/reject` with a reason (5–500).
  Future<Result<void>> reject(String requestId, String reason);

  /// `GET /admin/verification-requests/{id}/proof`: the private file's bytes.
  Future<Result<Uint8List>> proof(String requestId);
}
