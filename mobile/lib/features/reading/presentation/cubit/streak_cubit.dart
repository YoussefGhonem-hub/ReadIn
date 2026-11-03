import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/reading.dart';
import '../../domain/usecases/reading_usecases.dart';

/// App-wide reading streak for the Home badge (F03, F08). Loads `GET /me/stats` when a user signs in, clears on sign
/// out, and takes the fresher streak from progress reports that complete an article and from the stats sheet.
/// Null for guests and until the first load.
@lazySingleton
class StreakCubit extends Cubit<Streak?> {
  StreakCubit(this._getStats, SessionCubit session) : super(null) {
    _follow(session.state);
    _subscription = session.stream.listen(_follow);
  }

  /// A streak older than this is re-read when the app comes back to the foreground.
  static const staleAfter = Duration(minutes: 15);

  final GetReadingStats _getStats;
  StreamSubscription<SessionState>? _subscription;
  String? _userId;
  DateTime? _freshAt;

  // Bumped by every change, so a load that finishes after a newer streak arrived is dropped.
  int _version = 0;

  /// Re-reads the streak when it may be out of date: after midnight (yesterday's "read today" is no longer true) or
  /// after [staleAfter]. Called when the app is resumed.
  Future<void> refreshIfStale({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final fresh = _freshAt;
    final sameDay = fresh != null && fresh.year == at.year && fresh.month == at.month && fresh.day == at.day;
    if (fresh != null && sameDay && at.difference(fresh) < staleAfter) return;
    await load(now: at);
  }

  void _follow(SessionState session) {
    if (session.status == SessionStatus.unknown) return; // the persisted session isn't restored yet
    final userId = session.isAuthenticated ? session.me?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    _version++;
    if (state != null) emit(null);
    if (userId != null) unawaited(load());
  }

  /// Re-reads the streak (signed in only).
  Future<void> load({DateTime? now}) async {
    if (_userId == null) return;
    final version = ++_version;
    final result = await _getStats();
    if (isClosed || version != _version) return;
    if (result.valueOrNull case final stats?) {
      _freshAt = now ?? DateTime.now();
      emit(stats.streak);
    }
  }

  /// A newer streak: from a report with `completedNow`, or fresh stats.
  void apply(Streak streak) {
    if (_userId == null || isClosed) return;
    _version++;
    _freshAt = DateTime.now();
    emit(streak);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
