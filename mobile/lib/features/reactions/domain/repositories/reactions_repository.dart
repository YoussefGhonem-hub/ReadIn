import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/reactions.dart';

abstract interface class ReactionsRepository {
  /// `PUT /articles/{id}/reaction`: sets or changes the viewer's one reaction.
  Future<Result<ArticleReactions>> react(String articleId, ReactionType type);

  /// `DELETE /articles/{id}/reaction` (idempotent).
  Future<Result<ArticleReactions>> removeReaction(String articleId);

  /// `GET /articles/{id}/reactions?type=`: newest first; [type] null = every type.
  Future<Result<CursorPage<Reactor>>> getReactors(String articleId, {ReactionType? type, String? cursor, int limit = 20});
}
