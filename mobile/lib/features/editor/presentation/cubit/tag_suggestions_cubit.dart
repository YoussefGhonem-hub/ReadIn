import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/editor_entities.dart';
import '../../domain/usecases/editor_usecases.dart';

/// Tag autocomplete for the metadata sheet: `GET /tags?q=` once typing pauses for [debounce]; an empty query asks
/// for the most used tags. Answers for an older query are dropped; a failure just shows no suggestions.
@injectable
class TagSuggestionsCubit extends Cubit<List<ArticleTag>> {
  TagSuggestionsCubit(this._suggest) : super(const []);

  final SuggestTags _suggest;

  static const debounce = Duration(milliseconds: 250);

  Timer? _timer;
  String? _query;

  void search(String query) {
    final q = query.trim();
    if (q == _query) return;
    _query = q;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_fetch(q)));
  }

  void clear() {
    _timer?.cancel();
    _query = null;
    if (state.isNotEmpty) emit(const []);
  }

  Future<void> _fetch(String query) async {
    final result = await _suggest(query);
    if (isClosed || query != _query) return;
    emit(result.valueOrNull ?? const []);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
