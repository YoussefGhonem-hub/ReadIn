import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../entities/follow.dart';
import '../repositories/follow_repository.dart';

/// Follows or unfollows a writer (F12).
@injectable
class SetFollowing {
  const SetFollowing(this._repository);

  final FollowRepository _repository;

  Future<Result<FollowState>> call(String userId, {required bool follow}) =>
      follow ? _repository.follow(userId) : _repository.unfollow(userId);
}

@injectable
class GetSuggestedWriters {
  const GetSuggestedWriters(this._repository);

  final FollowRepository _repository;

  static const limit = 10;

  Future<Result<List<UserSummary>>> call() => _repository.getSuggested(limit: limit);
}

/// Followers / following lists with search. Their screens arrive with the profile (F14); the API is ready.
@injectable
class GetFollowLists {
  const GetFollowLists(this._repository);

  final FollowRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<UserSummary>>> followers(String userId, {String? query, String? cursor}) =>
      _repository.getFollowers(userId, query: query, cursor: cursor, limit: pageSize);

  Future<Result<CursorPage<UserSummary>>> following(String userId, {String? query, String? cursor}) =>
      _repository.getFollowing(userId, query: query, cursor: cursor, limit: pageSize);
}

/// Follows or unfollows a field or a topic, which makes it an interest (F02, F12).
@injectable
class SetInterestFollowed {
  const SetInterestFollowed(this._repository);

  final FollowRepository _repository;

  Future<Result<Interests>> field(String fieldId, {required bool followed}) =>
      _repository.setFieldFollowed(fieldId, followed: followed);

  Future<Result<Interests>> topic(String topicId, {required bool followed}) =>
      _repository.setTopicFollowed(topicId, followed: followed);
}
