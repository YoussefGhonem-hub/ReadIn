import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tags_repository.dart';
import '../datasources/tags_api.dart';

@LazySingleton(as: TagsRepository)
class TagsRepositoryImpl implements TagsRepository {
  TagsRepositoryImpl(this._api);

  final TagsApi _api;

  @override
  Future<Result<ArticleTag>> getTag(String slug) => guardApi(() async => (await _api.getTag(slug)).toEntity());

  @override
  Future<Result<CursorPage<ArticleCard>>> getArticles(String slug, {String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.getArticles(slug, cursor, limit);
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });
}
