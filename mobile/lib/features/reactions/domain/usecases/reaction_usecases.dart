import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/reactions.dart';
import '../repositories/reactions_repository.dart';

/// Sets the viewer's reaction, or removes it when the type is null.
@injectable
class SetReaction {
  const SetReaction(this._repository);

  final ReactionsRepository _repository;

  Future<Result<ArticleReactions>> call(String articleId, ReactionType? type) =>
      type == null ? _repository.removeReaction(articleId) : _repository.react(articleId, type);
}

@injectable
class GetReactors {
  const GetReactors(this._repository);

  final ReactionsRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<Reactor>>> call(String articleId, {ReactionType? type, String? cursor}) =>
      _repository.getReactors(articleId, type: type, cursor: cursor, limit: pageSize);
}
