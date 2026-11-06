import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/repost_state.dart';
import '../repositories/reposts_repository.dart';

/// Reposts an article ([reposted] true) or undoes the viewer's repost (F29). With [caption] (only when reposting) it
/// reposts with the viewer's thoughts, or sets the thoughts of a repost they already made ("" clears them); without
/// one a new repost has none and an existing repost keeps its own.
@injectable
class SetReposted {
  const SetReposted(this._repository);

  final RepostsRepository _repository;

  Future<Result<RepostState>> call(String articleId, {required bool reposted, String? caption}) =>
      reposted ? _repository.repost(articleId, caption: caption) : _repository.undoRepost(articleId);
}

/// The viewer's repost of an article now, with its caption ("Edit your thoughts" starts from it, F29).
@injectable
class GetRepost {
  const GetRepost(this._repository);

  final RepostsRepository _repository;

  Future<Result<RepostState>> call(String articleId) => _repository.getRepost(articleId);
}
