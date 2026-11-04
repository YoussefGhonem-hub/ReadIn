import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/moderation_models.dart';

part 'moderation_api.g.dart';

/// Reporting & moderation (F22): reports (`reports.create`), the queue, actions and the log (`moderation.manage`), and
/// the affected user's notices.
@lazySingleton
@RestApi()
abstract class ModerationApi {
  @factoryMethod
  factory ModerationApi(Dio dio) = _ModerationApi;

  @POST('/reports')
  Future<void> report(@Body() ReportRequest body);

  @GET('/moderation/summary')
  Future<ModerationSummaryModel> summary();

  /// `status` = `open` | `resolved` | `dismissed`; `type` = `article` | `comment` | `user` (null = all).
  @GET('/moderation/reports')
  Future<ModerationQueuePageModel> queue(
    @Query('status') String status,
    @Query('type') String? type,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/moderation/reports/{targetType}/{targetId}')
  Future<ModerationCaseModel> getCase(@Path('targetType') String targetType, @Path('targetId') String targetId);

  @POST('/moderation/actions')
  Future<void> act(@Body() ModerationActionRequest body);

  @GET('/moderation/actions')
  Future<ModerationActionPageModel> log(
    @Query('targetUserId') String? targetUserId,
    @Query('moderatorId') String? moderatorId,
    @Query('targetType') String? targetType,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/me/moderation-notices')
  Future<ModerationNoticesModel> notices();

  @POST('/me/moderation-notices/{id}/acknowledge')
  Future<void> acknowledge(@Path('id') String noticeId);
}
