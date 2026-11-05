import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';
import '../entities/highlight.dart';
import '../repositories/highlights_repository.dart';

/// The reader's highlights for one version of an article (F30).
@injectable
class GetArticleHighlights {
  const GetArticleHighlights(this._repository);

  final HighlightsRepository _repository;

  Future<Result<ArticleHighlights>> call(String articleId, {required String language}) =>
      _repository.forArticle(articleId, language: language);
}

/// Highlight (create) and Remove from the reader's selection toolbar.
@injectable
class EditHighlights {
  const EditHighlights(this._repository);

  final HighlightsRepository _repository;

  Future<Result<HighlightCreated>> create(String articleId, {required String language, required HighlightRange range}) =>
      _repository.create(articleId, language: language, range: range);

  Future<Result<void>> remove(String highlightId) => _repository.remove(highlightId);
}

/// Saved → Highlights: your highlights grouped by article version, newest first.
@injectable
class GetMyHighlights {
  const GetMyHighlights(this._repository);

  final HighlightsRepository _repository;

  Future<Result<CursorPage<HighlightGroup>>> call({String? cursor, int limit = 20}) =>
      _repository.mine(cursor: cursor, limit: limit);

  /// One of your highlights was made or removed: the list is out of date.
  Stream<void> get changes => _repository.changes;
}
