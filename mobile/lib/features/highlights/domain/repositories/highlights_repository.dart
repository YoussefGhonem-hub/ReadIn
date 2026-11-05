import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';
import '../entities/highlight.dart';

abstract interface class HighlightsRepository {
  /// `GET /articles/{id}/highlights?lang=`: yours (none for guests) and the popular ranges of that version.
  Future<Result<ArticleHighlights>> forArticle(String articleId, {required String language});

  /// `POST /articles/{id}/highlights` for [range] of version [language]. `400 highlight.*` when the API refuses it
  /// (`highlight.text_mismatch`: the article changed meanwhile).
  Future<Result<HighlightCreated>> create(String articleId, {required String language, required HighlightRange range});

  /// `DELETE /highlights/{id}`. `404 highlight.not_found` when it is already gone.
  Future<Result<void>> remove(String highlightId);

  /// `GET /me/highlights?cursor=&limit=`: groups by article version, newest first.
  Future<Result<CursorPage<HighlightGroup>>> mine({String? cursor, int limit = 20});

  /// An event each time one of your highlights is made or removed (Saved → Highlights loads again).
  Stream<void> get changes;
}
