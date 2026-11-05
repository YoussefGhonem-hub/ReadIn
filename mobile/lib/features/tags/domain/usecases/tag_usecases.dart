import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/tag.dart';
import '../repositories/tags_repository.dart';

/// The tag page's header (F32): name and article count.
@injectable
class GetTag {
  const GetTag(this._repository);

  final TagsRepository _repository;

  Future<Result<ArticleTag>> call(String slug) => _repository.getTag(slug);
}

/// The tag page's articles, newest first.
@injectable
class GetTagArticles {
  const GetTagArticles(this._repository);

  final TagsRepository _repository;

  Future<Result<CursorPage<ArticleCard>>> call(String slug, {String? cursor}) =>
      _repository.getArticles(slug, cursor: cursor);
}
