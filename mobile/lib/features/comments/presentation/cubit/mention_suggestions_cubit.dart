import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../article/domain/entities/article.dart';
import '../../domain/usecases/comment_usecases.dart';

/// People to `@mention` while typing in the composer (F11): asks `GET /users/mention-suggestions` once typing pauses
/// for [debounce]. An answer for an older query is dropped; a failure just shows no suggestions.
@injectable
class MentionSuggestionsCubit extends Cubit<List<Author>> {
  MentionSuggestionsCubit(this._suggest) : super(const []);

  final SuggestMentions _suggest;

  static const debounce = Duration(milliseconds: 250);

  Timer? _timer;
  String? _query;

  /// The `@word` being typed (without the `@`); null or empty clears the suggestions.
  void search(String? query) {
    final q = query?.trim() ?? '';
    if (q.isEmpty) {
      clear();
      return;
    }
    if (q == _query) return;
    _query = q;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_fetch(q)));
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
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
