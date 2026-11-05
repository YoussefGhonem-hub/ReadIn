import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';
import '../../domain/entities/highlight.dart';
import '../../domain/usecases/highlight_usecases.dart';

enum ArticleHighlightsStatus { idle, loading, ready, failure }

class ArticleHighlightsState extends Equatable {
  const ArticleHighlightsState({
    this.status = ArticleHighlightsStatus.idle,
    this.articleId,
    this.requested,
    this.language,
    this.mine = const [],
    this.popular = const [],
    this.failure,
  });

  final ArticleHighlightsStatus status;
  final String? articleId;

  /// The version asked for (the one on screen).
  final String? requested;

  /// The version the API answered with: marks are drawn only on that version.
  final String? language;
  final List<Highlight> mine;
  final List<PopularHighlight> popular;
  final Failure? failure;

  ArticleHighlightsState copyWith({List<Highlight>? mine}) => ArticleHighlightsState(
        status: status,
        articleId: articleId,
        requested: requested,
        language: language,
        mine: mine ?? this.mine,
        popular: popular,
        failure: failure,
      );

  /// What the reader draws on version [language] of [articleId], by block id: yours (amber) and the popular ranges.
  /// Nothing for another article or version.
  Map<String, List<RHighlightMark>> marksFor(String articleId, String language) {
    if (articleId != this.articleId || language != this.language) return const {};
    final marks = <String, List<RHighlightMark>>{};
    for (final h in mine) {
      marks.putIfAbsent(h.blockId, () => []).add(
            RHighlightMark(start: h.startOffset, end: h.endOffset, mine: true, id: h.isPending ? null : h.id),
          );
    }
    for (final p in popular) {
      marks.putIfAbsent(p.blockId, () => []).add(RHighlightMark(start: p.startOffset, end: p.endOffset, count: p.count));
    }
    return marks;
  }

  @override
  List<Object?> get props => [status, articleId, requested, language, mine, popular, failure];
}

/// The reader's highlights (F30) for the version on screen: `GET /articles/{id}/highlights?lang=`, then Highlight and
/// Remove, optimistic with rollback. After a change only yours update; the popular ranges refresh on the next open.
@injectable
class ArticleHighlightsCubit extends Cubit<ArticleHighlightsState> {
  ArticleHighlightsCubit(this._get, this._edit) : super(const ArticleHighlightsState());

  final GetArticleHighlights _get;
  final EditHighlights _edit;
  int _loads = 0;
  int _serial = 0;

  /// Loads version [language] of [articleId], unless it is loaded or loading already (a failed load is tried again).
  Future<void> open(String articleId, String language) async {
    if (state.articleId == articleId &&
        state.requested == language &&
        state.status != ArticleHighlightsStatus.failure &&
        state.status != ArticleHighlightsStatus.idle) {
      return;
    }
    await _load(articleId, language);
  }

  /// Loads the version shown again (the article changed under a highlight: `highlight.text_mismatch`).
  Future<void> reload() async {
    final articleId = state.articleId;
    final language = state.requested;
    if (articleId != null && language != null) await _load(articleId, language);
  }

  Future<void> _load(String articleId, String language) async {
    final load = ++_loads;
    emit(ArticleHighlightsState(status: ArticleHighlightsStatus.loading, articleId: articleId, requested: language));
    final result = await _get(articleId, language: language);
    if (isClosed || load != _loads) return;
    emit(result.fold(
      // Nothing to draw, but new highlights still go to the version on screen.
      (failure) => ArticleHighlightsState(
        status: ArticleHighlightsStatus.failure,
        articleId: articleId,
        requested: language,
        language: language,
        failure: failure,
      ),
      (highlights) => ArticleHighlightsState(
        status: ArticleHighlightsStatus.ready,
        articleId: articleId,
        requested: language,
        language: highlights.language,
        mine: highlights.mine,
        popular: highlights.popular,
      ),
    ));
  }

  bool _isShowing(String articleId, String language) => state.articleId == articleId && state.language == language;

  /// Highlights [range] (an [HighlightSelectionStatus.ok] selection): drawn at once, then replaced by what the API made
  /// (which may join some of yours). Completes with the failure, the highlight gone again; null otherwise.
  Future<Failure?> create(HighlightRange range) async {
    final articleId = state.articleId;
    final language = state.language;
    if (articleId == null || language == null) return null;
    final pending = Highlight.pending(range, serial: ++_serial);
    emit(state.copyWith(mine: [...state.mine, pending]));
    final result = await _edit.create(articleId, language: language, range: range);
    if (isClosed) return result.failureOrNull;
    return result.fold(
      (failure) {
        if (_isShowing(articleId, language)) emit(state.copyWith(mine: state.mine.where((h) => h.id != pending.id).toList()));
        return failure;
      },
      (created) {
        if (_isShowing(articleId, language)) {
          final drop = {pending.id, created.highlight.id, ...created.replacedIds};
          emit(state.copyWith(mine: [...state.mine.where((h) => !drop.contains(h.id)), created.highlight]));
        }
        return null;
      },
    );
  }

  /// Removes your highlight [id] at once; it comes back when the API refuses (one already gone counts as removed).
  /// One still being created can't be removed yet.
  Future<Failure?> remove(String id) async {
    final articleId = state.articleId;
    final language = state.language;
    final index = state.mine.indexWhere((h) => h.id == id);
    if (articleId == null || language == null || index < 0 || state.mine[index].isPending) return null;
    final removed = state.mine[index];
    emit(state.copyWith(mine: [...state.mine]..removeAt(index)));
    final failure = (await _edit.remove(id)).failureOrNull;
    if (failure == null || failure.code == FailureCodes.highlightNotFound) return null;
    if (!isClosed && _isShowing(articleId, language) && !state.mine.any((h) => h.id == id)) {
      emit(state.copyWith(mine: [...state.mine]..insert(math.min(index, state.mine.length), removed)));
    }
    return failure;
  }
}
