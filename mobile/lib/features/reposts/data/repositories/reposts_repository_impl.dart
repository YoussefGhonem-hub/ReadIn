import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/repost_state.dart';
import '../../domain/repositories/reposts_repository.dart';
import '../datasources/reposts_api.dart';
import '../models/repost_models.dart';

@LazySingleton(as: RepostsRepository)
class RepostsRepositoryImpl implements RepostsRepository {
  RepostsRepositoryImpl(this._api);

  final RepostsApi _api;

  @override
  Future<Result<RepostState>> repost(String articleId, {String? caption}) => guardApi(
        () async => (caption == null
                ? await _api.repost(articleId)
                : await _api.repostWithCaption(articleId, RepostRequest(caption: caption)))
            .toEntity(),
      );

  @override
  Future<Result<RepostState>> getRepost(String articleId) =>
      guardApi(() async => (await _api.getRepost(articleId)).toEntity());

  @override
  Future<Result<RepostState>> undoRepost(String articleId) =>
      guardApi(() async => (await _api.undoRepost(articleId)).toEntity());
}
