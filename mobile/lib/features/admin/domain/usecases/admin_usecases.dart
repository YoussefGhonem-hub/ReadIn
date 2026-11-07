import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../verification/domain/entities/verification.dart';
import '../entities/admin_content.dart';
import '../entities/admin_dashboard.dart';
import '../entities/admin_user.dart';
import '../entities/admin_verification.dart';
import '../entities/paged_list.dart';
import '../repositories/admin_repository.dart';

/// The console entry's badge (F23).
@injectable
class GetAdminSummary {
  const GetAdminSummary(this._repository);

  final AdminRepository _repository;

  Future<Result<AdminSummary>> call() => _repository.summary();
}

@injectable
class GetAdminDashboard {
  const GetAdminDashboard(this._repository);

  final AdminRepository _repository;

  Future<Result<AdminDashboard>> call(AdminPeriod period) => _repository.dashboard(period);
}

/// The console's Users, 50 a page.
@injectable
class GetAdminUsers {
  const GetAdminUsers(this._repository);

  final AdminRepository _repository;

  static const pageSize = 50;

  Future<Result<PagedList<AdminUserRow>>> call(AdminUserQuery query, {int page = 1}) =>
      _repository.users(query, page: page, pageSize: pageSize);
}

@injectable
class GetAdminUser {
  const GetAdminUser(this._repository);

  final AdminRepository _repository;

  Future<Result<AdminUser>> call(String id) => _repository.user(id);
}

/// A user's account actions that aren't moderation (F23): reveal the phone number, sign out of all devices, reset the
/// password, remove the Verified badge. Warn, suspend and hide go through `POST /moderation/actions`.
@injectable
class AdminUserCommands {
  const AdminUserCommands(this._repository);

  final AdminRepository _repository;

  Future<Result<String?>> revealPhone(String userId) => _repository.revealPhone(userId);

  Future<Result<void>> logoutAll(String userId) => _repository.logoutAll(userId);

  Future<Result<String>> resetPassword(String userId) => _repository.resetPassword(userId);

  Future<Result<void>> removeBadge(String userId) => _repository.removeBadge(userId);
}

/// Content's articles, 50 a page.
@injectable
class GetAdminArticles {
  const GetAdminArticles(this._repository);

  final AdminRepository _repository;

  static const pageSize = 50;

  Future<Result<PagedList<AdminArticleRow>>> call(AdminArticleQuery query, {int page = 1}) =>
      _repository.articles(query, page: page, pageSize: pageSize);
}

@injectable
class GetAdminArticle {
  const GetAdminArticle(this._repository);

  final AdminRepository _repository;

  Future<Result<AdminArticleRow>> call(String id) => _repository.article(id);
}

/// "Latest comments", 50 a page.
@injectable
class GetAdminComments {
  const GetAdminComments(this._repository);

  final AdminRepository _repository;

  static const pageSize = 50;

  Future<Result<PagedList<AdminCommentRow>>> call(AdminCommentQuery query, {int page = 1}) =>
      _repository.comments(query, page: page, pageSize: pageSize);
}

/// Feature an article on Explore, or stop featuring it (`articles.feature`).
@injectable
class SetArticleFeatured {
  const SetArticleFeatured(this._repository);

  final AdminRepository _repository;

  Future<Result<void>> call(String articleId, {required bool featured}) =>
      _repository.setFeatured(articleId, featured: featured);
}

/// The verification queue (F19): one status, 20 a page.
@injectable
class GetVerificationQueue {
  const GetVerificationQueue(this._repository);

  final AdminRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<AdminVerificationRequest>>> call(VerificationRequestStatus status, {String? cursor}) =>
      _repository.verificationRequests(status, cursor: cursor, limit: pageSize);
}

/// One verification request: read it, approve or reject it, save its proof file, remove a badge.
@injectable
class VerificationReview {
  const VerificationReview(this._repository);

  final AdminRepository _repository;

  Future<Result<AdminVerificationRequest>> get(String id) => _repository.verificationRequest(id);

  Future<Result<void>> approve(String id) => _repository.approve(id);

  Future<Result<void>> reject(String id, String reason) => _repository.reject(id, reason.trim());

  Future<Result<Uint8List>> proof(String id) => _repository.proof(id);

  Future<Result<void>> removeBadge(String userId) => _repository.removeBadge(userId);
}
