import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/realtime/realtime_service.dart';

/// The open article's live counters (F27, `/live/articles/{id}`) while the reader is on screen. Null until the first
/// value; the reader works the same without any. Paused while the app is in the background, cancelled in [close].
@injectable
class ArticleLiveCubit extends Cubit<LiveArticleCounts?> {
  ArticleLiveCubit(this._realtime) : super(null);

  final RealtimeService _realtime;
  StreamSubscription<LiveArticleCounts>? _subscription;
  String? _articleId;
  bool _paused = false;

  void watch(String articleId) {
    if (articleId == _articleId && (_subscription != null || _paused)) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _articleId = articleId;
    if (!_paused) _listen();
  }

  void _listen() {
    final articleId = _articleId;
    if (articleId == null || isClosed) return;
    _subscription = _realtime.watchArticle(articleId).listen((counts) {
      if (!isClosed && articleId == _articleId) emit(counts);
    });
  }

  /// The app went to the background: stop listening (the socket goes offline too, see [RealtimeService.setForeground]).
  Future<void> pause() async {
    _paused = true;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Back in the foreground: the database sends the current values again on subscribe.
  void resume() {
    if (!_paused) return;
    _paused = false;
    if (_subscription == null) _listen();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
