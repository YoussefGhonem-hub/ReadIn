import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/highlights/domain/entities/highlight.dart';
import 'package:readin/features/highlights/domain/repositories/highlights_repository.dart';
import 'package:readin/shared/rdoc/highlights/rdoc_highlight_text.dart';

/// Scripted `GET/POST/DELETE` highlights, recording the calls.
class FakeHighlightsRepository implements HighlightsRepository {
  final loads = <(String, String)>[];
  final creates = <(String, String, HighlightRange)>[];
  final removes = <String>[];
  ArticleHighlights Function(String articleId, String language) answer =
      (id, language) => ArticleHighlights(articleId: id, language: language);
  Failure? createFailure;

  @override
  Future<Result<ArticleHighlights>> forArticle(String articleId, {required String language}) async {
    loads.add((articleId, language));
    return Ok(answer(articleId, language));
  }

  @override
  Future<Result<HighlightCreated>> create(String articleId, {required String language, required HighlightRange range}) async {
    creates.add((articleId, language, range));
    final failure = createFailure;
    if (failure != null) return Err(failure);
    return Ok(HighlightCreated(
      highlight: Highlight(
        id: 'h-${creates.length}',
        blockId: range.blockId,
        startOffset: range.startOffset,
        endOffset: range.endOffset,
        text: range.text,
        createdAt: DateTime.utc(2026, 11, 5),
      ),
    ));
  }

  @override
  Future<Result<void>> remove(String highlightId) async {
    removes.add(highlightId);
    return const Ok(null);
  }

  @override
  Future<Result<CursorPage<HighlightGroup>>> mine({String? cursor, int limit = 20}) async => const Ok(CursorPage(items: []));

  @override
  Stream<void> get changes => const Stream.empty();
}
