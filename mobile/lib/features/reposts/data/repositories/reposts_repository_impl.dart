import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/repost_state.dart';
import '../../domain/repositories/reposts_repository.dart';
import '../datasources/reposts_api.dart';

@LazySingleton(as: RepostsRepository)
class RepostsRepositoryImpl implements RepostsRepository {
  RepostsRepositoryImpl(this._api);

  final RepostsApi _api;

  @override
  Future<Result<RepostState>> repost(String articleId) => guardApi(() async => (await _api.repost(articleId)).toEntity());

  @override
  Future<Result<RepostState>> undoRepost(String articleId) =>
      guardApi(() async => (await _api.undoRepost(articleId)).toEntity());
}
