import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/admin_models.dart';

part 'admin_api.g.dart';

/// The admin console (F23): the badge, the dashboard, users, content, featuring and the verification queue (F19). Every
/// route needs a Bearer token and the permission of its section (`403 auth.forbidden` otherwise); writes use the
/// `writes` rate limit.
@lazySingleton
@RestApi()
abstract class AdminApi {
  @factoryMethod
  factory AdminApi(Dio dio) = _AdminApi;

  @GET('/admin/summary')
  Future<AdminSummaryModel> summary();

  /// `period` = `today` | `yesterday` | `7d` | `30d`.
  @GET('/admin/dashboard')
  Future<AdminDashboardModel> dashboard(@Query('period') String period);

  /// `q`, `status`, `verified`, `method`, `joinedFrom`, `joinedTo`, `hasReports`, `sort`, `dir`, `page`, `pageSize`.
  @GET('/admin/users')
  Future<AdminUserPageModel> users(@Queries() Map<String, dynamic> query);

  @GET('/admin/users/{id}')
  Future<AdminUserModel> user(@Path('id') String id);

  /// The full number, one at a time (`users.read.pii`, audited).
  @GET('/admin/users/{id}/phone')
  Future<AdminPhoneModel> phone(@Path('id') String id);

  @POST('/admin/users/{id}/logout-all')
  Future<void> logoutAll(@Path('id') String id);

  @POST('/admin/users/{id}/reset-password')
  Future<TemporaryPasswordModel> resetPassword(@Path('id') String id);

  @DELETE('/admin/users/{id}/verification')
  Future<void> removeBadge(@Path('id') String id);

  /// `from`, `to`, `field`, `topic`, `writer`, `status`, `hidden`, `featured`, `reported`, `q`, `sort`, `page`,
  /// `pageSize`.
  @GET('/admin/articles')
  Future<AdminArticlePageModel> articles(@Queries() Map<String, dynamic> query);

  @GET('/admin/articles/{id}')
  Future<AdminArticleRowModel> article(@Path('id') String id);

  @GET('/admin/comments')
  Future<AdminCommentPageModel> comments(@Queries() Map<String, dynamic> query);

  @PUT('/admin/articles/{id}/featured')
  Future<void> feature(@Path('id') String id);

  @DELETE('/admin/articles/{id}/featured')
  Future<void> unfeature(@Path('id') String id);

  /// `status` = `pending` (oldest first) | `approved` | `rejected` (most recently decided first).
  @GET('/admin/verification-requests')
  Future<AdminVerificationPageModel> verificationRequests(
    @Query('status') String status,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/admin/verification-requests/{id}')
  Future<AdminVerificationRequestModel> verificationRequest(@Path('id') String id);

  @POST('/admin/verification-requests/{id}/approve')
  Future<void> approve(@Path('id') String id);

  @POST('/admin/verification-requests/{id}/reject')
  Future<void> reject(@Path('id') String id, @Body() RejectVerificationRequest body);
}
