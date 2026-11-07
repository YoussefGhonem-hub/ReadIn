import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../verification/domain/entities/verification.dart';
import '../../domain/entities/admin_content.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/admin_verification.dart';
import '../../domain/entities/paged_list.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_api.dart';
import '../datasources/verification_proof_data_source.dart';
import '../models/admin_models.dart';

@LazySingleton(as: AdminRepository)
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._api, this._proofs);

  final AdminApi _api;
  final VerificationProofDataSource _proofs;

  @override
  Future<Result<AdminSummary>> summary() => guardApi(() async => (await _api.summary()).toEntity());

  @override
  Future<Result<AdminDashboard>> dashboard(AdminPeriod period) =>
      guardApi(() async => (await _api.dashboard(period.wire)).toEntity());

  @override
  Future<Result<PagedList<AdminUserRow>>> users(AdminUserQuery query, {int page = 1, int pageSize = 50}) => guardApi(
        () async => (await _api.users({...query.toQuery(), 'page': page, 'pageSize': pageSize})).toEntity(),
      );

  @override
  Future<Result<AdminUser>> user(String id) => guardApi(() async => (await _api.user(id)).toEntity());

  @override
  Future<Result<String?>> revealPhone(String userId) => guardApi(() async => (await _api.phone(userId)).phoneNumber);

  @override
  Future<Result<void>> logoutAll(String userId) => guardApi(() => _api.logoutAll(userId));

  @override
  Future<Result<String>> resetPassword(String userId) =>
      guardApi(() async => (await _api.resetPassword(userId)).temporaryPassword);

  @override
  Future<Result<void>> removeBadge(String userId) => guardApi(() => _api.removeBadge(userId));

  @override
  Future<Result<PagedList<AdminArticleRow>>> articles(AdminArticleQuery query, {int page = 1, int pageSize = 50}) =>
      guardApi(() async => (await _api.articles({...query.toQuery(), 'page': page, 'pageSize': pageSize})).toEntity());

  @override
  Future<Result<AdminArticleRow>> article(String id) => guardApi(() async => (await _api.article(id)).toEntity());

  @override
  Future<Result<PagedList<AdminCommentRow>>> comments(AdminCommentQuery query, {int page = 1, int pageSize = 50}) =>
      guardApi(() async {
        final result = await _api.comments({
          if (query.hidden case final hidden?) 'hidden': '$hidden',
          'page': page,
          'pageSize': pageSize,
        });
        return result.toEntity();
      });

  @override
  Future<Result<void>> setFeatured(String articleId, {required bool featured}) =>
      guardApi(() => featured ? _api.feature(articleId) : _api.unfeature(articleId));

  @override
  Future<Result<CursorPage<AdminVerificationRequest>>> verificationRequests(
    VerificationRequestStatus status, {
    String? cursor,
    int limit = 20,
  }) =>
      guardApi(() async {
        final page = await _api.verificationRequests(status.name, cursor, limit);
        return CursorPage(items: [for (final r in page.items) r.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<AdminVerificationRequest>> verificationRequest(String id) =>
      guardApi(() async => (await _api.verificationRequest(id)).toEntity());

  @override
  Future<Result<void>> approve(String requestId) => guardApi(() => _api.approve(requestId));

  @override
  Future<Result<void>> reject(String requestId, String reason) =>
      guardApi(() => _api.reject(requestId, RejectVerificationRequest(reason: reason.trim())));

  @override
  Future<Result<Uint8List>> proof(String requestId) => guardApi(() => _proofs.download(requestId));
}
