import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/mutes.dart';
import '../../domain/repositories/mutes_repository.dart';
import '../datasources/mutes_api.dart';

@LazySingleton(as: MutesRepository)
class MutesRepositoryImpl implements MutesRepository {
  MutesRepositoryImpl(this._api);

  final MutesApi _api;

  @override
  Future<Result<UserMuteState>> muteUser(String userId) => guardApi(() async => (await _api.muteUser(userId)).toEntity());

  @override
  Future<Result<UserMuteState>> unmuteUser(String userId, {bool restoreFollow = false}) =>
      guardApi(() async => (await _api.unmuteUser(userId, restoreFollow ? true : null)).toEntity());

  @override
  Future<Result<ContentMutes>> setFieldMuted(String fieldId, {required bool muted}) =>
      guardApi(() async => (muted ? await _api.muteField(fieldId) : await _api.unmuteField(fieldId)).toEntity());

  @override
  Future<Result<ContentMutes>> setTopicMuted(String topicId, {required bool muted}) =>
      guardApi(() async => (muted ? await _api.muteTopic(topicId) : await _api.unmuteTopic(topicId)).toEntity());

  @override
  Future<Result<Mutes>> getMutes() => guardApi(() async => (await _api.getMutes()).toEntity());

  @override
  Future<Result<void>> setShowLess(String articleId, {required bool showLess}) =>
      guardApi(() => showLess ? _api.showLess(articleId) : _api.undoShowLess(articleId));
}
