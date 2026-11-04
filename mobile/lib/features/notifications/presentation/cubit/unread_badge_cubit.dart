import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/realtime/realtime_service.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/usecases/notification_usecases.dart';

/// The bell's unread count, app-wide (F17, F27): live from `/live/users/{id}/unreadNotifications` while the Realtime
/// Database delivers it ([RealtimeService.unreadLive]), otherwise `GET /me/notifications/unread-count` on sign in, when
/// the database drops out, and on [refresh] (the app coming back to the foreground). Opening the notification center
/// zeroes it ([clear]). 0 for guests.
@lazySingleton
class UnreadBadgeCubit extends Cubit<int> {
  UnreadBadgeCubit(this._realtime, this._unreadCount, SessionCubit session) : super(0) {
    _realtime.unreadNotifications.addListener(_onLiveCount);
    _realtime.unreadLive.addListener(_onLiveChanged);
    _follow(session.state);
    _subscription = session.stream.listen(_follow);
  }

  final RealtimeService _realtime;
  final GetUnreadNotificationCount _unreadCount;
  StreamSubscription<SessionState>? _subscription;
  String? _userId;

  // Bumped by every newer count, so a REST answer that arrives after it is dropped.
  int _version = 0;

  bool get _live => _realtime.unreadLive.value;

  void _follow(SessionState session) {
    if (session.status == SessionStatus.unknown) return; // the stored session isn't restored yet
    final userId = session.isAuthenticated ? session.me?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    _set(userId != null && _live ? _realtime.unreadNotifications.value : 0);
    if (userId != null) unawaited(refresh());
  }

  void _onLiveCount() {
    if (_userId != null && _live) _set(_realtime.unreadNotifications.value);
  }

  void _onLiveChanged() => _live ? _onLiveCount() : unawaited(refresh());

  /// `GET /me/notifications/unread-count`, only while signed in and the database can't tell. Failures keep the count.
  Future<void> refresh() async {
    if (_userId == null || _live || isClosed) return;
    final version = ++_version;
    final result = await _unreadCount();
    if (isClosed || version != _version || _live) return;
    if (result.valueOrNull case final count?) emit(count);
  }

  /// The notification center was opened (`POST /me/notifications/seen`): nothing is new anymore.
  void clear() => _set(0);

  void _set(int count) {
    if (isClosed) return;
    _version++;
    emit(count);
  }

  @override
  Future<void> close() async {
    _realtime.unreadNotifications.removeListener(_onLiveCount);
    _realtime.unreadLive.removeListener(_onLiveChanged);
    await _subscription?.cancel();
    return super.close();
  }
}
