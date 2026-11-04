import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/learning_path.dart';
import '../repositories/paths_repository.dart';

/// All published paths (F09), in editorial order.
@injectable
class GetPaths {
  const GetPaths(this._repository);

  final PathsRepository _repository;

  Future<Result<List<LearningPath>>> call({String? fieldSlug}) => _repository.getPaths(fieldSlug: fieldSlug);
}

/// One path with its articles.
@injectable
class GetPath {
  const GetPath(this._repository);

  final PathsRepository _repository;

  Future<Result<PathDetails>> call(String slug) => _repository.getPath(slug);
}

/// The reader's "Next in path" block: null when the article is in no published path.
@injectable
class GetArticlePath {
  const GetArticlePath(this._repository);

  final PathsRepository _repository;

  Future<Result<ArticlePath?>> call(String articleId) => _repository.getArticlePath(articleId);
}

/// The Paths tab of a profile (F14): that user's enrolled paths.
@injectable
class GetUserPaths {
  const GetUserPaths(this._repository);

  final PathsRepository _repository;

  Future<Result<List<LearningPath>>> call(String username) => _repository.getUserPaths(username);
}

/// "My paths": the viewer's enrolled paths.
@injectable
class GetMyPaths {
  const GetMyPaths(this._repository);

  final PathsRepository _repository;

  Future<Result<List<LearningPath>>> call() => _repository.getMyPaths();
}

/// The Home learning path card (F03): the enrolled path in progress, or null.
@injectable
class GetActivePath {
  const GetActivePath(this._repository);

  final PathsRepository _repository;

  Future<Result<LearningPath?>> call() => _repository.getActivePath();
}

/// Enroll in a path or leave it (both idempotent).
@injectable
class SetPathEnrollment {
  const SetPathEnrollment(this._repository);

  final PathsRepository _repository;

  Future<Result<LearningPath>> enroll(String pathId) => _repository.enroll(pathId);

  Future<Result<void>> leave(String pathId) => _repository.leave(pathId);
}
