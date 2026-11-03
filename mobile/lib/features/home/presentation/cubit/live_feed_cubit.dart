import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/realtime/realtime_service.dart';

class LiveFeedState extends Equatable {
  const LiveFeedState({this.counts = const {}, this.hasNewArticles = false});

  /// Live counters by article id; an article without an entry keeps its feed values.
  final Map<String, LiveArticleCounts> counts;

  /// Drives the "مقالات جديدة ↑" banner.
  final bool hasNewArticles;

  LiveFeedState copyWith({Map<String, LiveArticleCounts>? counts, bool? hasNewArticles}) =>
      LiveFeedState(counts: counts ?? this.counts, hasNewArticles: hasNewArticles ?? this.hasNewArticles);

  @override
  List<Object?> get props => [counts, hasNewArticles];
}

/// Live updates for the home feed (F27): counters of the cards on screen and
/// the "new articles" signal. Cards call [watch] when they are built and
/// [unwatch] when the list disposes them, so only cards on (or near) the screen
/// listen; the last values are kept. Every subscription ends in [close].
@injectable
class LiveFeedCubit extends Cubit<LiveFeedState> {
  LiveFeedCubit(this._realtime) : super(const LiveFeedState());

  final RealtimeService _realtime;
  final _subscriptions = <String, StreamSubscription<LiveArticleCounts>>{};
  final _watchers = <String, int>{};
  StreamSubscription<int?>? _feed;
  int? _baseline;
  int? _latest;

  void start() {
    _feed ??= _realtime.latestPublished().listen((publishedAt) {
      _latest = publishedAt;
      // The first value describes what the feed already has (nothing published yet counts as 0).
      _baseline ??= publishedAt ?? 0;
      _setNewArticles(publishedAt != null && publishedAt > _baseline!);
    });
  }

  /// Call when the feed is reloaded: the latest article becomes the baseline.
  void acknowledgeNewArticles() {
    _baseline = _latest ?? 0;
    _setNewArticles(false);
  }

  void _setNewArticles(bool value) {
    if (!isClosed && value != state.hasNewArticles) emit(state.copyWith(hasNewArticles: value));
  }

  void watch(String articleId) {
    _watchers[articleId] = (_watchers[articleId] ?? 0) + 1;
    _subscriptions[articleId] ??= _realtime.watchArticle(articleId).listen((counts) {
      if (!isClosed) emit(state.copyWith(counts: {...state.counts, articleId: counts}));
    });
  }

  void unwatch(String articleId) {
    final remaining = (_watchers[articleId] ?? 1) - 1;
    if (remaining > 0) {
      _watchers[articleId] = remaining;
      return;
    }
    _watchers.remove(articleId);
    unawaited(_subscriptions.remove(articleId)?.cancel());
  }

  @override
  Future<void> close() async {
    await Future.wait([..._subscriptions.values.map((s) => s.cancel()), if (_feed != null) _feed!.cancel()]);
    _subscriptions.clear();
    return super.close();
  }
}
