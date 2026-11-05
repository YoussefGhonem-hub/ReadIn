import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/repost_state.dart';
import '../repositories/reposts_repository.dart';

/// Reposts an article ([reposted] true) or undoes the viewer's repost (F29).
@injectable
class SetReposted {
  const SetReposted(this._repository);

  final RepostsRepository _repository;

  Future<Result<RepostState>> call(String articleId, {required bool reposted}) =>
      reposted ? _repository.repost(articleId) : _repository.undoRepost(articleId);
}
