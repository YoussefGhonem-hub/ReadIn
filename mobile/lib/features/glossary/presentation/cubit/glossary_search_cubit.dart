import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/glossary_term.dart';
import '../../domain/usecases/search_glossary_terms.dart';

/// [idle]: nothing typed yet.
enum GlossarySearchStatus { idle, loading, ready, failure }

class GlossarySearchState extends Equatable {
  const GlossarySearchState({this.query = '', this.status = GlossarySearchStatus.idle, this.results = const []});

  final String query;
  final GlossarySearchStatus status;
  final List<GlossaryTermSummary> results;

  @override
  List<Object?> get props => [query, status, results];
}

/// The editor's glossary term picker (F21): searches as the writer types, [debounce] after the last keystroke. An
/// older answer never replaces a newer one.
@injectable
class GlossarySearchCubit extends Cubit<GlossarySearchState> {
  GlossarySearchCubit(this._search) : super(const GlossarySearchState());

  final SearchGlossaryTerms _search;
  static const debounce = Duration(milliseconds: 250);
  Timer? _timer;
  int _generation = 0;

  /// Searches for [query]; [now] skips the debounce (the picker's first search, a retry).
  void search(String query, {bool now = false}) {
    _timer?.cancel();
    final generation = ++_generation;
    final q = query.trim();
    if (q.isEmpty) {
      emit(GlossarySearchState(query: query));
      return;
    }
    emit(GlossarySearchState(query: query, status: GlossarySearchStatus.loading, results: state.results));
    if (now) {
      unawaited(_run(q, query, generation));
    } else {
      _timer = Timer(debounce, () => unawaited(_run(q, query, generation)));
    }
  }

  void retry() => search(state.query, now: true);

  Future<void> _run(String q, String query, int generation) async {
    final result = await _search(q);
    if (isClosed || generation != _generation) return;
    emit(result.fold(
      (_) => GlossarySearchState(query: query, status: GlossarySearchStatus.failure),
      (results) => GlossarySearchState(query: query, status: GlossarySearchStatus.ready, results: results),
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
