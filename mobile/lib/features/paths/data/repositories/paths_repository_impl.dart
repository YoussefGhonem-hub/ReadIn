import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../domain/entities/learning_path.dart';
import '../../domain/repositories/paths_repository.dart';
import '../datasources/paths_api.dart';
import '../models/path_models.dart';

@LazySingleton(as: PathsRepository)
class PathsRepositoryImpl implements PathsRepository {
  PathsRepositoryImpl(this._api);

  final PathsApi _api;

  @override
  Future<Result<List<LearningPath>>> getPaths({String? fieldSlug}) =>
      guardApi(() async => _cards(await _api.getPaths(fieldSlug)));

  @override
  Future<Result<PathDetails>> getPath(String slug) => guardApi(() async => (await _api.getPath(slug)).toEntity());

  @override
  Future<Result<ArticlePath?>> getArticlePath(String articleId) => guardApi(() async {
        final response = await _api.getArticlePath(articleId);
        final data = response.data;
        if (response.response.statusCode == 204 || data is! Map<String, dynamic>) return null;
        return ArticlePathModel.fromJson(data).toEntity();
      });

  @override
  Future<Result<List<LearningPath>>> getUserPaths(String username) =>
      guardApi(() async => _cards(await _api.getUserPaths(ProfileRepositoryImpl.handle(username))));

  @override
  Future<Result<List<LearningPath>>> getMyPaths() => guardApi(() async => _cards(await _api.getMyPaths()));

  @override
  Future<Result<LearningPath?>> getActivePath() => guardApi(() async {
        final response = await _api.getActivePath();
        final data = response.data;
        if (response.response.statusCode == 204 || data is! Map<String, dynamic>) return null;
        return PathCardModel.fromJson(data).toEntity();
      });

  @override
  Future<Result<LearningPath>> enroll(String pathId) => guardApi(() async => (await _api.enroll(pathId)).toEntity());

  @override
  Future<Result<void>> leave(String pathId) => guardApi(() => _api.leave(pathId));

  static List<LearningPath> _cards(List<PathCardModel> models) => [for (final m in models) m.toEntity()];
}
