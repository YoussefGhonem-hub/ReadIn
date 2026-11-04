import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../auth/presentation/session/session_cubit.dart';

/// The viewer's unsent comment per article (F11, F34): the comments sheet can close (to read the article, open a
/// profile, or by mistake) and the text is there when it opens again, until it is sent. Pull to refresh keeps it.
/// It lives in memory only, and another account (or signing out) starts with none.
@lazySingleton
class CommentDrafts {
  CommentDrafts(SessionCubit session) : _userId = session.state.me?.id {
    _session = session.stream.listen((state) {
      final userId = state.me?.id;
      if (userId == _userId) return;
      _userId = userId;
      _drafts.clear();
    });
  }

  final _drafts = <String, String>{};
  String? _userId;
  StreamSubscription<SessionState>? _session;

  /// The unsent text for [articleId]; empty when there is none.
  String of(String articleId) => _drafts[articleId] ?? '';

  /// Keeps [text] for [articleId]; blank text forgets it.
  void put(String articleId, String text) {
    if (text.trim().isEmpty) {
      _drafts.remove(articleId);
    } else {
      _drafts[articleId] = text;
    }
  }

  @disposeMethod
  Future<void> dispose() async => _session?.cancel();
}
