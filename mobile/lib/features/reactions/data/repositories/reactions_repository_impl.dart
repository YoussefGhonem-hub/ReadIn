import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/reactions.dart';
import '../../domain/repositories/reactions_repository.dart';
import '../datasources/reactions_api.dart';
import '../models/reaction_models.dart';

@LazySingleton(as: ReactionsRepository)
class ReactionsRepositoryImpl implements ReactionsRepository {
  ReactionsRepositoryImpl(this._api);

  final ReactionsApi _api;

  @override
  Future<Result<ArticleReactions>> react(String articleId, ReactionType type) =>
      guardApi(() async => (await _api.react(articleId, SetReactionRequest(type: type.name))).toEntity());

  @override
  Future<Result<ArticleReactions>> removeReaction(String articleId) =>
      guardApi(() async => (await _api.removeReaction(articleId)).toEntity());

  @override
  Future<Result<CursorPage<Reactor>>> getReactors(String articleId, {ReactionType? type, String? cursor, int limit = 20}) =>
      guardApi(() async {
        final page = await _api.getReactors(articleId, type?.name, cursor, limit);
        return CursorPage(items: [for (final m in page.items) ?m.toEntity()], nextCursor: page.nextCursor);
      });
}
