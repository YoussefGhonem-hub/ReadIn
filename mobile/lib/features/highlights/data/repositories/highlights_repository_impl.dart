import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';
import '../../domain/entities/highlight.dart';
import '../../domain/repositories/highlights_repository.dart';
import '../datasources/highlights_api.dart';
import '../models/highlight_models.dart';

@LazySingleton(as: HighlightsRepository)
class HighlightsRepositoryImpl implements HighlightsRepository {
  HighlightsRepositoryImpl(this._api);

  final HighlightsApi _api;

  // App-wide (a lazy singleton): never closed.
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Result<ArticleHighlights>> forArticle(String articleId, {required String language}) =>
      guardApi(() async => (await _api.forArticle(articleId, language)).toEntity());

  @override
  Future<Result<HighlightCreated>> create(String articleId, {required String language, required HighlightRange range}) async {
    final result = await guardApi(() async {
      final body = CreateHighlightRequest(
        language: language,
        blockId: range.blockId,
        startOffset: range.startOffset,
        endOffset: range.endOffset,
        text: range.text,
      );
      return (await _api.create(articleId, body)).toEntity();
    });
    if (result.isOk) _changes.add(null);
    return result;
  }

  @override
  Future<Result<void>> remove(String highlightId) async {
    final result = await guardApi(() => _api.remove(highlightId));
    // Already gone counts as removed.
    if (result.isOk || result.failureOrNull?.code == FailureCodes.highlightNotFound) _changes.add(null);
    return result;
  }

  @override
  Future<Result<CursorPage<HighlightGroup>>> mine({String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.mine(cursor, limit);
        return CursorPage(items: [for (final g in page.items) g.toEntity()], nextCursor: page.nextCursor);
      });
}
