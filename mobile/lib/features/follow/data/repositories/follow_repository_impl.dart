import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/follow.dart';
import '../../domain/repositories/follow_repository.dart';
import '../datasources/follow_api.dart';
import '../models/follow_models.dart';

@LazySingleton(as: FollowRepository)
class FollowRepositoryImpl implements FollowRepository {
  FollowRepositoryImpl(this._api);

  final FollowApi _api;

  static String? _blankToNull(String? query) => query == null || query.trim().isEmpty ? null : query.trim();

  static CursorPage<UserSummary> _page(UserSummaryPageModel page) =>
      CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);

  @override
  Future<Result<FollowState>> follow(String userId) => guardApi(() async => (await _api.follow(userId)).toEntity());

  @override
  Future<Result<FollowState>> unfollow(String userId) => guardApi(() async => (await _api.unfollow(userId)).toEntity());

  @override
  Future<Result<CursorPage<UserSummary>>> getFollowers(String userId, {String? query, String? cursor, int limit = 20}) =>
      guardApi(() async => _page(await _api.getFollowers(userId, _blankToNull(query), cursor, limit)));

  @override
  Future<Result<CursorPage<UserSummary>>> getFollowing(String userId, {String? query, String? cursor, int limit = 20}) =>
      guardApi(() async => _page(await _api.getFollowing(userId, _blankToNull(query), cursor, limit)));

  @override
  Future<Result<List<UserSummary>>> getSuggested({int limit = 10}) =>
      guardApi(() async => [for (final m in await _api.getSuggested(limit)) m.toEntity()]);

  @override
  Future<Result<Interests>> setFieldFollowed(String fieldId, {required bool followed}) => guardApi(
        () async => (followed ? await _api.followField(fieldId) : await _api.unfollowField(fieldId)).toEntity(),
      );

  @override
  Future<Result<Interests>> setTopicFollowed(String topicId, {required bool followed}) => guardApi(
        () async => (followed ? await _api.followTopic(topicId) : await _api.unfollowTopic(topicId)).toEntity(),
      );
}
